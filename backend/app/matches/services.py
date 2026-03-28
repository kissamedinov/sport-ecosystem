from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional
from uuid import UUID

from app.matches.models import Match, MatchResult, MatchStatus, ResultStatus, MatchEvent, EventType, MatchPlayerStats, MatchLineup, MatchLineupPlayer, LineupRole, MatchAward, MatchAwardType
from app.matches.schemas import MatchResultCreate, MatchResponse, MatchEventCreate, LineupCreate, MatchAwardCreate
from app.matches import scheduler_service
from app.tournaments.models import Tournament, TournamentRegistration, RegistrationStatus, TournamentGroup
from app.users.models import User
from app.notifications import service as notification_service
from app.notifications.models import NotificationType, EntityType

def generate_tournament_schedule(db: Session, tournament_id: UUID, format: str, num_groups: Optional[int] = None):
    tournament = db.query(Tournament).filter(Tournament.id == tournament_id).first()
    if not tournament:
        raise HTTPException(status_code=404, detail="Tournament not found")
    
    # Get approved teams
    registrations = db.query(TournamentRegistration).filter(
        TournamentRegistration.tournament_id == tournament_id,
        TournamentRegistration.status == RegistrationStatus.APPROVED
    ).all()
    
    team_ids = [r.team_id for r in registrations]
    if len(team_ids) < 2:
        raise HTTPException(status_code=400, detail="Not enough approved teams to generate schedule")

    # Clear existing matches for this tournament if any (or prevent regeneration)
    # For now, let's just generate.
    
    matches = []
    if format == "round_robin":
        matches = scheduler_service.generate_round_robin_schedule(db, tournament_id, team_ids)
    elif format == "groups":
        if not num_groups:
            num_groups = 2 # Default
        matches = scheduler_service.generate_group_stage_schedule(db, tournament_id, team_ids, num_groups)
    else:
        raise HTTPException(status_code=400, detail=f"Format {format} not yet supported for auto-generation")

    db.add_all(matches)
    db.commit()

    # Trigger notifications for each match
    for match in matches:
        # Notify Home Team (simplified: notify all players or just coach? Let's notify tournament managers for now or just generic)
        # Requirements say "support players, parents, coaches...". 
        # For simplicity, we create a notification for the "owner" or specific roles if we had team-user mappings easily available here.
        # Given current models, we'll notify the tournament manager and placeholder for team members.
        notification_service.create_notification(
            db, 
            user_ids=[tournament.owner_id], 
            notification_type=NotificationType.MATCH_SCHEDULED,
            title="Matches Scheduled",
            message=f"New matches have been generated for {tournament.name}",
            entity_type=EntityType.TOURNAMENT,
            entity_id=tournament.id
        )

    return matches

def get_tournament_matches(db: Session, tournament_id: UUID):
    return db.query(Match).filter(Match.tournament_id == tournament_id).all()

def get_all_matches(db: Session):
    return db.query(Match).all()

def submit_match_result(db: Session, match_id: UUID, result_in: MatchResultCreate, current_user: User):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Check if user is coach of one of the teams
    # We'll assume the COACH role is enough for now as per requirements: "Only COACH can submit results"
    # But usually it's the coach of the teams in the match.
    
    existing_result = db.query(MatchResult).filter(MatchResult.match_id == match_id).first()
    if existing_result and existing_result.status == ResultStatus.FINAL:
        raise HTTPException(status_code=400, detail="Cannot edit final results")

    if existing_result:
        existing_result.home_score = result_in.home_score
        existing_result.away_score = result_in.away_score
        existing_result.submitted_by = current_user.id
        existing_result.status = ResultStatus.SUBMITTED
    else:
        new_result = MatchResult(
            match_id=match_id,
            home_score=result_in.home_score,
            away_score=result_in.away_score,
            submitted_by=current_user.id,
            status=ResultStatus.SUBMITTED
        )
        db.add(new_result)
    
    db.commit()
    return {"message": "Result submitted successfully"}

def finalize_match_result(db: Session, match_id: UUID):
    result = db.query(MatchResult).filter(MatchResult.match_id == match_id).first()
    if not result:
        raise HTTPException(status_code=404, detail="Result not found or not submitted yet")
    
    result.status = ResultStatus.FINAL
    
    # Update match status
    match = db.query(Match).filter(Match.id == match_id).first()
    match.status = MatchStatus.FINISHED
    
    # Trigger ELO Rating update
    from app.teams.rating_service import update_team_ratings
    update_team_ratings(
        db, 
        match_id=match.id, 
        home_team_id=match.home_team_id, 
        away_team_id=match.away_team_id, 
        home_score=result.home_score, 
        away_score=result.away_score
    )
    
    db.commit()

    # Trigger Standings update
    from app.tournaments.standings_service import update_standings
    update_standings(db, match.tournament_id, match.home_team_id)
    update_standings(db, match.tournament_id, match.away_team_id)

    # Trigger Notification for Match Result
    # Notify tournament owner
    tournament = db.query(Tournament).filter(Tournament.id == match.tournament_id).first()
    notification_service.create_notification(
        db,
        user_ids=[tournament.owner_id],
        notification_type=NotificationType.MATCH_RESULT,
        title="Match Result Finalized",
        message=f"Result finalized for {match.home_team_id} vs {match.away_team_id}",
        entity_type=EntityType.MATCH,
        entity_id=match.id
    )

    return {"message": "Result finalized, ratings and standings updated successfully"}

def get_tournament_groups(db: Session, tournament_id: UUID):
    return db.query(TournamentGroup).filter(TournamentGroup.tournament_id == tournament_id).all()

def get_match_events(db: Session, match_id: UUID):
    return db.query(MatchEvent).filter(MatchEvent.match_id == match_id).order_by(MatchEvent.minute).all()

def create_match_event(db: Session, match_id: UUID, event_in: MatchEventCreate, current_user: User):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    if event_in.minute < 0 or event_in.minute > 120:
        raise HTTPException(status_code=400, detail="Minute must be between 0 and 120")

    # Validate player/child is in match teams
    is_in_match = False
    if event_in.player_id:
        # Check lineups
        is_in_match = db.query(MatchLineupPlayer).join(MatchLineup).filter(
            MatchLineup.match_id == match_id,
            MatchLineupPlayer.player_id == event_in.player_id
        ).first() is not None
    elif event_in.child_profile_id:
        is_in_match = db.query(MatchLineupPlayer).join(MatchLineup).filter(
            MatchLineup.match_id == match_id,
            MatchLineupPlayer.child_profile_id == event_in.child_profile_id
        ).first() is not None
    
    if not is_in_match:
        raise HTTPException(status_code=400, detail="Player/Child not found in match lineups")

    event = MatchEvent(
        match_id=match_id,
        team_id=event_in.team_id,
        player_id=event_in.player_id,
        child_profile_id=event_in.child_profile_id,
        event_type=event_in.event_type,
        minute=event_in.minute,
        created_by=current_user.id
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event

def create_match_award(db: Session, match_id: UUID, award_in: MatchAwardCreate, current_user: User):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    # Prevent duplicate MVP
    if award_in.award_type == MatchAwardType.MVP:
        existing_mvp = db.query(MatchAward).filter(
            MatchAward.match_id == match_id,
            MatchAward.award_type == MatchAwardType.MVP
        ).first()
        if existing_mvp:
            raise HTTPException(status_code=400, detail="MVP already assigned for this match")

    award = MatchAward(
        match_id=match_id,
        player_id=award_in.player_id,
        child_profile_id=award_in.child_profile_id,
        award_type=award_in.award_type,
        created_by=current_user.id
    )
    db.add(award)
    db.commit()
    db.refresh(award)
    return award

def get_match_awards(db: Session, match_id: UUID):
    return db.query(MatchAward).filter(MatchAward.match_id == match_id).all()

def create_or_update_lineup(db: Session, match_id: UUID, lineup_in: LineupCreate, current_user: User):
    # Verify match exists
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
        
    if lineup_in.team_id not in [match.home_team_id, match.away_team_id]:
        raise HTTPException(status_code=400, detail="Team is not part of this match")

    # Authorization logic
    from app.users.models import Role
    from app.teams.models import Team
    from app.clubs.models import Club, ClubRole, ClubStaff
    from app.academies.models import Academy
    
    team = db.query(Team).filter(Team.id == lineup_in.team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")

    user_roles = {ur.role for ur in current_user.roles}
    is_authorized = False
    
    if Role.ADMIN in user_roles:
        is_authorized = True
    elif Role.CLUB_OWNER in user_roles:
        # Check if user owns the club the team belongs to
        if team.academy and team.academy.club and team.academy.club.owner_id == current_user.id:
            is_authorized = True
    elif Role.COACH in user_roles:
        # Check if user is the coach of this specific team
        if team.coach_id == current_user.id:
            is_authorized = True
            
    if not is_authorized:
        raise HTTPException(status_code=403, detail="Not authorized to submit lineup for this team")

    # Prevent duplicate submission if requested
    existing_lineup = db.query(MatchLineup).filter(
        MatchLineup.match_id == match_id,
        MatchLineup.team_id == lineup_in.team_id
    ).first()

    if existing_lineup:
        raise HTTPException(status_code=400, detail="Lineup already exists for this team in this match")

    # Create lineup
    lineup = MatchLineup(
        match_id=match_id, 
        team_id=lineup_in.team_id,
        submitted_by=current_user.id
    )
    db.add(lineup)
    db.flush()

    # Add players
    from app.teams.models import TeamMembership, MembershipStatus
    from app.users.models import PlayerProfile
    from app.clubs.models import ChildProfile
    
    for p in lineup_in.players:
        if p.player_id:
            profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == p.player_id).first()
            if not profile:
                 raise HTTPException(status_code=400, detail=f"User {p.player_id} has no player profile")
            
            is_member = db.query(TeamMembership).filter(
                TeamMembership.team_id == lineup_in.team_id,
                TeamMembership.player_profile_id == profile.id,
                TeamMembership.status == MembershipStatus.ACTIVE
            ).first()
            if not is_member:
                raise HTTPException(status_code=400, detail=f"Player {p.player_id} is not an active member of the team")
        
        elif p.child_profile_id:
            child = db.query(ChildProfile).filter(ChildProfile.id == p.child_profile_id).first()
            if not child:
                raise HTTPException(status_code=404, detail=f"Child profile {p.child_profile_id} not found")
            
            if child.club_id != team.academy.club_id:
                raise HTTPException(status_code=400, detail=f"Child profile {p.child_profile_id} does not belong to the team's club")
        else:
            raise HTTPException(status_code=400, detail="Each lineup player must have either player_id or child_profile_id")

        lp = MatchLineupPlayer(
            lineup_id=lineup.id,
            player_id=p.player_id,
            child_profile_id=p.child_profile_id,
            is_starting=p.is_starting,
            position=p.position,
            jersey_number=p.jersey_number
        )
        db.add(lp)
    
    db.commit()
    db.refresh(lineup)
    return lineup

def get_match_lineup_by_team(db: Session, match_id: UUID, team_id: UUID):
    lineup = db.query(MatchLineup).filter(
        MatchLineup.match_id == match_id,
        MatchLineup.team_id == team_id
    ).first()
    if not lineup:
        raise HTTPException(status_code=404, detail="Lineup not found")
    return lineup

def get_match_lineups(db: Session, match_id: UUID):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    home_lineup = db.query(MatchLineup).filter(
        MatchLineup.match_id == match_id,
        MatchLineup.team_id == match.home_team_id
    ).first()

    away_lineup = db.query(MatchLineup).filter(
        MatchLineup.match_id == match_id,
        MatchLineup.team_id == match.away_team_id
    ).first()

    return {
        "home_lineup": home_lineup,
        "away_lineup": away_lineup
    }

def delete_match_event(db: Session, event_id: UUID):
    event = db.query(MatchEvent).filter(MatchEvent.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    db.delete(event)
    db.commit()
    return {"message": "Event deleted successfully"}

def get_player_stats(db: Session, player_id: UUID):
    from app.clubs.models import ChildProfile
    player_name = "Unknown"
    user = db.query(User).filter(User.id == player_id).first()
    if user:
        player_name = user.name
    else:
        child = db.query(ChildProfile).filter(ChildProfile.id == player_id).first()
        if child:
            player_name = f"{child.first_name} {child.last_name}"
    
    events = db.query(MatchEvent).filter(
        (MatchEvent.player_id == player_id) | (MatchEvent.child_profile_id == player_id)
    ).all()
    
    awards = db.query(MatchAward).filter(
        (MatchAward.player_id == player_id) | (MatchAward.child_profile_id == player_id)
    ).all()
    
    stats = {
        "player_id": player_id,
        "name": player_name,
        "goals": 0,
        "assists": 0,
        "saves": 0,
        "yellow_cards": 0,
        "red_cards": 0,
        "awards": [a.award_type.value for a in awards]
    }
    
    for e in events:
        if e.event_type == EventType.GOAL:
            stats["goals"] += 1
        elif e.event_type == EventType.ASSIST:
            stats["assists"] += 1
        elif e.event_type == EventType.SAVE:
            stats["saves"] += 1
        elif e.event_type == EventType.YELLOW_CARD:
            stats["yellow_cards"] += 1
        elif e.event_type == EventType.RED_CARD:
            stats["red_cards"] += 1
            
    return stats

def get_tournament_top_scorers(db: Session, tournament_id: UUID):
    match_ids = [m.id for m in db.query(Match).filter(Match.tournament_id == tournament_id).all()]
    from sqlalchemy import func
    from app.clubs.models import ChildProfile
    
    user_goals = db.query(
        MatchEvent.player_id,
        User.name,
        func.count(MatchEvent.id).label("goals")
    ).join(User, User.id == MatchEvent.player_id).filter(
        MatchEvent.match_id.in_(match_ids),
        MatchEvent.event_type == EventType.GOAL
    ).group_by(MatchEvent.player_id, User.name).all()
    
    child_goals = db.query(
        MatchEvent.child_profile_id,
        func.concat(ChildProfile.first_name, " ", ChildProfile.last_name).label("name"),
        func.count(MatchEvent.id).label("goals")
    ).join(ChildProfile, ChildProfile.id == MatchEvent.child_profile_id).filter(
        MatchEvent.match_id.in_(match_ids),
        MatchEvent.event_type == EventType.GOAL
    ).group_by(MatchEvent.child_profile_id, ChildProfile.first_name, ChildProfile.last_name).all()
    
    combined = []
    for g in user_goals:
        combined.append({"player_id": g[0], "name": g[1], "goals": g[2]})
    for g in child_goals:
        combined.append({"player_id": g[0], "name": g[1], "goals": g[2]})
        
    combined.sort(key=lambda x: x["goals"], reverse=True)
    return combined[:10]
