from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional
from uuid import UUID

from app.matches.models import Match, MatchResult, MatchStatus, ResultStatus, MatchEvent, EventType, MatchPlayerStats, MatchLineup, MatchLineupPlayer, LineupRole
from app.matches.schemas import MatchResultCreate, MatchResponse, MatchEventCreate, LineupCreate
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

def create_match_event(db: Session, match_id: UUID, event_in: MatchEventCreate):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # 1. Validation: Verify player_id is in the lineup if provided
    if event_in.player_id:
        lineup = db.query(MatchLineup).filter(
            MatchLineup.match_id == match_id,
            MatchLineup.team_id == event_in.team_id
        ).first()
        
        if not lineup:
            raise HTTPException(status_code=400, detail="Team lineup not declared for this match")
            
        is_in_lineup = db.query(MatchLineupPlayer).filter(
            MatchLineupPlayer.lineup_id == lineup.id,
            MatchLineupPlayer.player_id == event_in.player_id
        ).first()
        
        if not is_in_lineup:
            raise HTTPException(status_code=400, detail="Player not found in the team lineage")

    # Proceed with creating event
    event = MatchEvent(
        match_id=match_id,
        team_id=event_in.team_id,
        player_id=event_in.player_id,
        event_type=event_in.event_type,
        minute=event_in.minute
    )
    db.add(event)
    # ... rest of the original logic for stats update ...
    if event_in.player_id:
        stats = db.query(MatchPlayerStats).filter(
            MatchPlayerStats.match_id == match_id,
            MatchPlayerStats.player_id == event_in.player_id
        ).first()
        
        if not stats:
            stats = MatchPlayerStats(
                match_id=match_id,
                player_id=event_in.player_id,
                team_id=event_in.team_id or (match.home_team_id if event_in.player_id else None)
            )
            db.add(stats)
        
        if event_in.event_type in [EventType.GOAL, EventType.PENALTY_GOAL]:
            stats.goals += 1
        elif event_in.event_type == EventType.ASSIST:
            stats.assists += 1
        elif event_in.event_type == EventType.YELLOW_CARD:
            stats.yellow_cards += 1
        elif event_in.event_type == EventType.RED_CARD:
            stats.red_cards += 1
        elif event_in.event_type == EventType.BEST_PLAYER:
            stats.is_best_player = True

        from app.stats.models import PlayerCareerStats
        career = db.query(PlayerCareerStats).filter(PlayerCareerStats.player_id == event_in.player_id).first()
        if career:
            if event_in.event_type in [EventType.GOAL, EventType.PENALTY_GOAL]:
                career.goals += 1
            elif event_in.event_type == EventType.ASSIST:
                career.assists += 1
            elif event_in.event_type == EventType.YELLOW_CARD:
                career.yellow_cards += 1
            elif event_in.event_type == EventType.RED_CARD:
                career.red_cards += 1
            elif event_in.event_type == EventType.BEST_PLAYER:
                career.best_player_awards += 1

    db.commit()
    db.refresh(event)
    return event

def create_or_update_lineup(db: Session, match_id: UUID, lineup_in: LineupCreate):
    # Verify match exists
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
        
    if lineup_in.team_id not in [match.home_team_id, match.away_team_id]:
        raise HTTPException(status_code=400, detail="Team is not part of this match")

    # Get or create lineup
    lineup = db.query(MatchLineup).filter(
        MatchLineup.match_id == match_id,
        MatchLineup.team_id == lineup_in.team_id
    ).first()

    if lineup:
        # Clear existing players for update
        db.query(MatchLineupPlayer).filter(MatchLineupPlayer.lineup_id == lineup.id).delete()
    else:
        lineup = MatchLineup(match_id=match_id, team_id=lineup_in.team_id)
        db.add(lineup)
        db.flush()

    # Add players
    for p in lineup_in.players:
        lp = MatchLineupPlayer(
            lineup_id=lineup.id,
            player_id=p.player_id,
            role=p.role,
            position=p.position,
            jersey_number=p.jersey_number
        )
        db.add(lp)
    
    db.commit()
    db.refresh(lineup)
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

def get_match_events(db: Session, match_id: UUID):
    return db.query(MatchEvent).filter(MatchEvent.match_id == match_id).order_by(MatchEvent.minute).all()

def delete_match_event(db: Session, event_id: UUID):
    event = db.query(MatchEvent).filter(MatchEvent.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Revert stats if player_id is provided
    if event.player_id:
        stats = db.query(MatchPlayerStats).filter(
            MatchPlayerStats.match_id == event.match_id,
            MatchPlayerStats.player_id == event.player_id
        ).first()
        
        if stats:
            if event.event_type in [EventType.GOAL, EventType.PENALTY_GOAL]:
                stats.goals = max(0, stats.goals - 1)
            elif event.event_type == EventType.ASSIST:
                stats.assists = max(0, stats.assists - 1)
            elif event.event_type == EventType.YELLOW_CARD:
                stats.yellow_cards = max(0, stats.yellow_cards - 1)
            elif event.event_type == EventType.RED_CARD:
                stats.red_cards = max(0, stats.red_cards - 1)
            elif event.event_type == EventType.BEST_PLAYER:
                stats.is_best_player = False

        from app.stats.models import PlayerCareerStats
        career = db.query(PlayerCareerStats).filter(PlayerCareerStats.player_id == event.player_id).first()
        if career:
            if event.event_type in [EventType.GOAL, EventType.PENALTY_GOAL]:
                career.goals = max(0, career.goals - 1)
            elif event.event_type == EventType.ASSIST:
                career.assists = max(0, career.assists - 1)
            elif event.event_type == EventType.YELLOW_CARD:
                career.yellow_cards = max(0, career.yellow_cards - 1)
            elif event.event_type == EventType.RED_CARD:
                career.red_cards = max(0, career.red_cards - 1)
            elif event.event_type == EventType.BEST_PLAYER:
                career.best_player_awards = max(0, career.best_player_awards - 1)

    db.delete(event)
    db.commit()
    return {"message": "Event deleted successfully"}
