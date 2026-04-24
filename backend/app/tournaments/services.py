from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional
from uuid import UUID
from datetime import date

from app.tournaments.models import (
    Tournament, TournamentRegistration, RegistrationStatus, TournamentTeam, 
    TournamentStandings, TournamentFormat, 
    TournamentSquad, TournamentSeries, TournamentDivision,
    TournamentPlayerStats, TournamentAward, Season
)
from app.matches.models import Match, MatchStatus, MatchResult, MatchEvent, EventType, ResultStatus
from app.tournaments.schemas import (
    TournamentCreate, TournamentSeriesCreate, TournamentDivisionCreate,
    TournamentAwardCreate, TournamentSquadCreate
)
from app.users.models import User, Role
from app.clubs.models import ChildProfile
from app.notifications import service as notification_service
from app.notifications.models import NotificationType, EntityType

def create_tournament_series(db: Session, series_in: TournamentSeriesCreate):
    new_series = TournamentSeries(**series_in.model_dump())
    db.add(new_series)
    db.commit()
    db.refresh(new_series)
    return new_series

def get_tournament_series(db: Session):
    return db.query(TournamentSeries).all()

def create_tournament_division(db: Session, division_in: TournamentDivisionCreate):
    new_division = TournamentDivision(**division_in.model_dump())
    db.add(new_division)
    db.commit()
    db.refresh(new_division)
    return new_division

def get_tournament_divisions(db: Session, edition_id: UUID):
    return db.query(TournamentDivision).filter(TournamentDivision.tournament_edition_id == edition_id).all()

def create_tournament(db: Session, tournament_in: TournamentCreate, current_user: User):
    new_tournament = Tournament(**tournament_in.model_dump())
    new_tournament.created_by = current_user.id
    db.add(new_tournament)
    db.commit()
    db.refresh(new_tournament)
    
    # Requirement: Notify eligible users of tournament registration opening
    notify_eligible_users_of_tournament(db, new_tournament)
    
    return new_tournament

def notify_eligible_users_of_tournament(db: Session, tournament: Tournament):
    eligible_roles = [Role.PLAYER_YOUTH, Role.PARENT]
    users_to_notify = db.query(User).filter(User.roles.any(role=Role.PLAYER_YOUTH) | User.roles.any(role=Role.PARENT)).all()
    
    for user in users_to_notify:
        notification_service.create_notification(
            db,
            user.id,
            notification_type=NotificationType.TOURNAMENT_START,
            title="New Tournament Open!",
            message=f"Tournament {tournament.name} is now open for registration until {tournament.registration_close}.",
            entity_type=EntityType.TOURNAMENT,
            entity_id=tournament.id
        )

def get_tournaments(db: Session, season: Optional[Season] = None, year: Optional[int] = None):
    try:
        query = db.query(Tournament)
        if season:
            query = query.filter(Tournament.season == season)
        if year:
            query = query.filter(Tournament.year == year)
        return query.all()
    except Exception as e:
        print(f"Error fetching tournaments: {e}")
        raise e

def get_tournament_by_id(db: Session, tournament_id: UUID):
    tournament = db.query(Tournament).filter(Tournament.id == tournament_id).first()
    if not tournament:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tournament not found")
    return tournament

def register_tournament_team(db: Session, division_id: UUID, team_id: UUID, registration_data: str, current_user: User):
    division = db.query(TournamentDivision).filter(TournamentDivision.id == division_id).first()
    if not division:
        raise HTTPException(status_code=404, detail="Division not found")
    
    tournament = division.edition
    
    from app.teams.models import Team, Academy
    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
        
    user_roles = {ur.role for ur in current_user.roles}
    is_coach = Role.COACH in user_roles and team.coach_id == current_user.id
    is_owner = Role.TEAM_OWNER in user_roles and team.academy_id and db.query(Academy).filter(Academy.id == team.academy_id, Academy.owner_id == current_user.id).first()
    
    if not (is_coach or is_owner):
        raise HTTPException(status_code=403, detail="Operation not permitted. Only the team's coach or owner can register it.")
    
    today = date.today()
    if today < tournament.registration_open or today > tournament.registration_close:
        raise HTTPException(status_code=400, detail="Registration is closed or not yet open")
    
    if team.birth_year and team.birth_year != division.birth_year:
         raise HTTPException(
            status_code=400, 
            detail=f"Team birth year ({team.birth_year}) does not match division requirement ({division.birth_year})"
        )
    
    existing = db.query(TournamentTeam).filter(
        TournamentTeam.division_id == division_id,
        TournamentTeam.team_id == team_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Team already registered for this division")
    
    new_team_reg = TournamentTeam(
        division_id=division_id,
        tournament_id=tournament.id,
        team_id=team_id,
        registered_by=current_user.id,
        status=RegistrationStatus.PENDING,
        registration_data=registration_data
    )
    db.add(new_team_reg)
    db.commit()
    db.refresh(new_team_reg)
    
    return new_team_reg

def get_tournament_teams(db: Session, tournament_id: UUID):
    return db.query(TournamentTeam).filter(TournamentTeam.tournament_id == tournament_id).all()

def update_tournament_team_status(db: Session, tournament_id: UUID, team_id: UUID, status: RegistrationStatus):
    team_reg = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.team_id == team_id
    ).first()
    if not team_reg:
        raise HTTPException(status_code=404, detail="Team registration not found")
    
    team_reg.status = status
    db.commit()
    db.refresh(team_reg)
    
    if status == RegistrationStatus.APPROVED:
        from app.teams.models import Team
        team = db.query(Team).filter(Team.id == team_id).first()
        notification_service.create_notification(
            db,
            team.coach_id,
            notification_type=NotificationType.BOOKING_APPROVED,
            title="Team Accepted!",
            message=f"Your team {team.name} has been approved for the tournament.",
            entity_type=EntityType.TOURNAMENT,
            entity_id=tournament_id
        )
    
    if status == RegistrationStatus.APPROVED:
        existing_standing = db.query(TournamentStandings).filter(
            TournamentStandings.tournament_id == tournament_id,
            TournamentStandings.team_id == team_id
        ).first()
        if not existing_standing:
            new_standing = TournamentStandings(
                tournament_id=tournament_id,
                team_id=team_id,
                division_id=team_reg.division_id
            )
            db.add(new_standing)
            db.commit()
            
    return team_reg

def approve_registration(db: Session, tournament_id: UUID, registration_id: UUID):
    reg = db.query(TournamentRegistration).filter(
        TournamentRegistration.id == registration_id,
        TournamentRegistration.tournament_id == tournament_id
    ).first()
    if not reg:
        raise HTTPException(status_code=404, detail="Registration not found")
    
    reg.status = RegistrationStatus.APPROVED
    db.commit()
    
    from app.teams.models import Team
    team = db.query(Team).filter(Team.id == reg.team_id).first()
    notification_service.create_notification(
        db,
        team.coach_id,
        notification_type=NotificationType.BOOKING_APPROVED,
        title="Tournament Registration Approved",
        message=f"Your team {team.name} has been approved for the tournament!",
        entity_type=EntityType.TOURNAMENT,
        entity_id=tournament_id
    )
    return reg

def reject_registration(db: Session, tournament_id: UUID, registration_id: UUID):
    reg = db.query(TournamentRegistration).filter(
        TournamentRegistration.id == registration_id,
        TournamentRegistration.tournament_id == tournament_id
    ).first()
    if not reg:
        raise HTTPException(status_code=404, detail="Registration not found")
    
    reg.status = RegistrationStatus.REJECTED
    db.commit()
    return reg

def get_registrations(db: Session, tournament_id: UUID):
    return db.query(TournamentRegistration).filter(TournamentRegistration.tournament_id == tournament_id).all()

def get_tournaments_by_series(db: Session, series_name: str):
    return db.query(Tournament).filter(Tournament.series_name == series_name).order_by(Tournament.start_date.desc()).all()

def generate_league_schedule(db: Session, tournament_id: UUID):
    tournament = get_tournament_by_id(db, tournament_id)
    approved_teams = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.status == RegistrationStatus.APPROVED
    ).all()
    
    if len(approved_teams) < 2:
        raise HTTPException(status_code=400, detail="At least 2 approved teams needed to generate schedule")
    
    teams = [t.team_id for t in approved_teams]
    match_count = 0
    for i in range(len(teams)):
        for j in range(i + 1, len(teams)):
            new_match = Match(
                tournament_id=tournament_id,
                division_id=approved_teams[0].division_id, # Simplified for demo
                home_team_id=teams[i],
                away_team_id=teams[j],
                status=MatchStatus.SCHEDULED
            )
            db.add(new_match)
            match_count += 1
    
    db.commit()
    
    from app.notifications.match_notifications import notify_match_scheduled
    matches = db.query(Match).filter(Match.tournament_id == tournament_id).all()
    for m in matches:
        notify_match_scheduled(db, m.id)

    return {"matches_generated": match_count}

def update_match_result(db: Session, match_id: UUID, home_score: int, away_score: int):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Update or create MatchResult
    result = db.query(MatchResult).filter(MatchResult.match_id == match_id).first()
    if not result:
        result = MatchResult(
            match_id=match_id,
            home_score=home_score,
            away_score=away_score,
            status=ResultStatus.FINAL,
            submitted_by=match.tournament.created_by # Organizer
        )
        db.add(result)
    else:
        result.home_score = home_score
        result.away_score = away_score
        result.status = ResultStatus.FINAL
        
    match.status = MatchStatus.FINISHED
    db.commit()
    
    # Update Standings
    update_team_standing(db, match.tournament_id, match.home_team_id)
    update_team_standing(db, match.tournament_id, match.away_team_id)
    
    return match

def update_team_standing(db: Session, tournament_id: UUID, team_id: UUID):
    tournament = get_tournament_by_id(db, tournament_id)
    standing = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == tournament_id,
        TournamentStandings.team_id == team_id
    ).first()
    
    if not standing:
        standing = TournamentStandings(tournament_id=tournament_id, team_id=team_id)
        db.add(standing)
    
    # Calculate stats from finished matches with results
    home_matches = db.query(Match).join(MatchResult).filter(
        Match.tournament_id == tournament_id,
        Match.home_team_id == team_id,
        Match.status == MatchStatus.FINISHED
    ).all()
    
    away_matches = db.query(Match).join(MatchResult).filter(
        Match.tournament_id == tournament_id,
        Match.away_team_id == team_id,
        Match.status == MatchStatus.FINISHED
    ).all()
    
    played = 0
    wins = 0
    draws = 0
    losses = 0
    gf = 0
    ga = 0
    
    for m in home_matches:
        played += 1
        gf += m.result.home_score
        ga += m.result.away_score
        if m.result.home_score > m.result.away_score: wins += 1
        elif m.result.home_score == m.result.away_score: draws += 1
        else: losses += 1
        
    for m in away_matches:
        played += 1
        gf += m.result.away_score
        ga += m.result.home_score
        if m.result.away_score > m.result.home_score: wins += 1
        elif m.result.away_score == m.result.home_score: draws += 1
        else: losses += 1
        
    standing.played = played
    standing.wins = wins
    standing.draws = draws
    standing.losses = losses
    standing.goals_for = gf
    standing.goals_against = ga
    standing.goal_difference = gf - ga
    standing.points = (wins * tournament.points_for_win) + (draws * tournament.points_for_draw) + (losses * tournament.points_for_loss)
    
    db.commit()

def get_tournament_standings(db: Session, tournament_id: UUID):
    return db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == tournament_id
    ).order_by(
        TournamentStandings.points.desc(),
        TournamentStandings.goal_difference.desc(),
        TournamentStandings.goals_for.desc()
    ).all()

def get_tournament_matches(db: Session, tournament_id: UUID):
    return db.query(Match).filter(Match.tournament_id == tournament_id).order_by(Match.match_date).all()

def add_player_to_tournament_squad(db: Session, tournament_team_id: UUID, player_id: UUID):
    profile = db.query(ChildProfile).filter(ChildProfile.linked_user_id == player_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Child profile not found for this player")

    new_squad_member = TournamentSquad(
        tournament_team_id=tournament_team_id,
        child_profile_id=profile.id
    )
    db.add(new_squad_member)
    db.commit()
    return new_squad_member

def record_match_player_stats(db: Session, match_id: UUID, player_profile_id: UUID, stats: dict):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
        
    # In Tournament 2.0, we use MatchEvent for discrete actions
    # We clear previous events for this match/player to avoid duplicates if re-reporting
    db.query(MatchEvent).filter(
        MatchEvent.match_id == match_id,
        MatchEvent.child_profile_id == player_profile_id
    ).delete()
    
    events_to_add = []
    
    # Goals
    for _ in range(stats.get("goals", 0)):
        events_to_add.append(MatchEvent(
            match_id=match_id,
            child_profile_id=player_profile_id,
            event_type=EventType.GOAL,
            minute=0 # Simplified
        ))
        
    # Assists
    for _ in range(stats.get("assists", 0)):
        events_to_add.append(MatchEvent(
            match_id=match_id,
            child_profile_id=player_profile_id,
            event_type=EventType.ASSIST,
            minute=0
        ))
        
    # Cards
    for _ in range(stats.get("yellow_cards", 0)):
        events_to_add.append(MatchEvent(
            match_id=match_id,
            child_profile_id=player_profile_id,
            event_type=EventType.YELLOW_CARD,
            minute=0
        ))
        
    if stats.get("red_cards", 0) > 0:
        events_to_add.append(MatchEvent(
            match_id=match_id,
            child_profile_id=player_profile_id,
            event_type=EventType.RED_CARD,
            minute=0
        ))
        
    db.add_all(events_to_add)
    db.commit()
    
    # Update Division Aggregated Stats
    update_tournament_player_stats(
        db, 
        match.division_id, 
        player_profile_id, 
        goals_diff=stats.get("goals", 0),
        assists_diff=stats.get("assists", 0),
        matches_diff=1,
        yellow_diff=stats.get("yellow_cards", 0),
        red_diff=stats.get("red_cards", 0)
    )
    
    return {"status": "success", "events_recorded": len(events_to_add)}

def update_tournament_player_stats(
    db: Session, 
    division_id: UUID, 
    child_profile_id: UUID, 
    goals_diff: int = 0,
    assists_diff: int = 0,
    matches_diff: int = 0,
    yellow_diff: int = 0,
    red_diff: int = 0,
    clean_sheets_diff: int = 0
):
    if not division_id: return
    
    agg_stats = db.query(TournamentPlayerStats).filter(
        TournamentPlayerStats.division_id == division_id,
        TournamentPlayerStats.child_profile_id == child_profile_id
    ).first()
    
    if not agg_stats:
        agg_stats = TournamentPlayerStats(
            division_id=division_id,
            child_profile_id=child_profile_id
        )
        db.add(agg_stats)
    
    agg_stats.goals += goals_diff
    agg_stats.assists += assists_diff
    agg_stats.matches_played += matches_diff
    agg_stats.yellow_cards += yellow_diff
    agg_stats.red_cards += red_diff
    agg_stats.clean_sheets += clean_sheets_diff
    
    db.commit()

def assign_tournament_award(db: Session, award_in: TournamentAwardCreate):
    new_award = TournamentAward(**award_in.model_dump())
    db.add(new_award)
    db.commit()
    db.refresh(new_award)
    return new_award

def get_player_awards(db: Session, child_profile_id: UUID):
    return db.query(TournamentAward).filter(TournamentAward.child_profile_id == child_profile_id).all()

def add_to_tournament_squad(db: Session, tt_id: UUID, squad_in: TournamentSquadCreate, current_user: User):
    tt = db.query(TournamentTeam).filter(TournamentTeam.id == tt_id).first()
    if not tt:
        raise HTTPException(status_code=404, detail="Tournament team registration not found")
        
    from app.teams.models import Team
    team = db.query(Team).filter(Team.id == tt.team_id).first()
    if team.coach_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the coach can manage the tournament squad")
        
    for p in squad_in.players:
        existing = db.query(TournamentSquad).filter(
            TournamentSquad.tournament_team_id == tt_id,
            TournamentSquad.child_profile_id == p.child_profile_id
        ).first()
        
        if existing:
            existing.jersey_number = p.jersey_number
            existing.position = p.position
        else:
            new_member = TournamentSquad(
                tournament_team_id=tt_id,
                child_profile_id=p.child_profile_id,
                jersey_number=p.jersey_number,
                position=p.position
            )
            db.add(new_member)
            
    db.commit()
    return {"message": "Squad updated successfully"}

def get_tournament_squad(db: Session, tt_id: UUID):
    return db.query(TournamentSquad).filter(TournamentSquad.tournament_team_id == tt_id).all()

def remove_from_tournament_squad(db: Session, tt_id: UUID, profile_id: UUID, current_user: User):
    tt = db.query(TournamentTeam).filter(TournamentTeam.id == tt_id).first()
    from app.teams.models import Team
    team = db.query(Team).filter(Team.id == tt.team_id).first()
    if team.coach_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the coach can manage the tournament squad")
        
    db.query(TournamentSquad).filter(
        TournamentSquad.tournament_team_id == tt_id,
        TournamentSquad.child_profile_id == profile_id
    ).delete()
    db.commit()
    return {"message": "Player removed from squad"}
