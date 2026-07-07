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
from app.matches.models import Match, MatchStatus, MatchResult, MatchEvent, EventType, ResultStatus, MatchLineup, MatchLineupPlayer, MatchPlayerStats, MatchAward
from app.tournaments import schemas
from app.tournaments.schemas import (
    TournamentCreate, TournamentUpdate, TournamentSeriesCreate, TournamentDivisionCreate,
    TournamentAwardCreate, TournamentSquadCreate
)
from app.users.models import User, Role
from app.clubs.models import ChildProfile
from app.notifications import service as notification_service
from app.notifications.models import NotificationType, EntityType
from app.teams.models import TeamMembership, Team, MembershipStatus

def notify_match_participants(db: Session, match: Match, title: str, message: str, notification_type: NotificationType):
    """Notifies all players and coaches of both teams in a match."""
    team_ids = [match.home_team_id, match.away_team_id]
    
    # Get all player user IDs for these teams
    memberships = db.query(TeamMembership).filter(
        TeamMembership.team_id.in_(team_ids),
        TeamMembership.player_id.isnot(None)
    ).all()
    
    user_ids = {m.player_id for m in memberships}
    
    # Also notify coaches
    teams = db.query(Team).filter(Team.id.in_(team_ids)).all()
    for team in teams:
        if team.coach_id:
            user_ids.add(team.coach_id)
            
    if user_ids:
        notification_service.create_notification(
            db=db,
            user_ids=list(user_ids),
            notification_type=notification_type,
            title=title,
            message=message,
            entity_type=EntityType.MATCH,
            entity_id=match.id
        )

def notify_team_members(db: Session, team_id: UUID, title: str, message: str, notification_type: NotificationType, entity_type: EntityType, entity_id: UUID):
    """Notifies all players and the coach of a specific team."""
    memberships = db.query(TeamMembership).filter(
        TeamMembership.team_id == team_id,
        TeamMembership.player_id.isnot(None)
    ).all()
    
    user_ids = {m.player_id for m in memberships}
    
    team = db.query(Team).filter(Team.id == team_id).first()
    if team and team.coach_id:
        user_ids.add(team.coach_id)
        
    if user_ids:
        notification_service.create_notification(
            db=db,
            user_ids=list(user_ids),
            notification_type=notification_type,
            title=title,
            message=message,
            entity_type=entity_type,
            entity_id=entity_id
        )

def create_tournament_series(db: Session, series_in: TournamentSeriesCreate):
    new_series = TournamentSeries(**series_in.model_dump())
    db.add(new_series)
    db.commit()
    db.refresh(new_series)
    return new_series

def update_tournament_series(db: Session, series_id: UUID, series_in: schemas.TournamentSeriesUpdate):
    series = db.query(TournamentSeries).filter(TournamentSeries.id == series_id).first()
    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tournament Series not found"
        )
    update_data = series_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(series, field, value)
    db.commit()
    db.refresh(series)
    return series

def get_tournament_series(db: Session):
    return db.query(TournamentSeries).all()

def get_tournament_series_detail(db: Session, series_id: UUID):
    from app.stats.models import PlayerMatchStats
    from sqlalchemy import text
    
    series = db.query(TournamentSeries).filter(TournamentSeries.id == series_id).first()
    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tournament series not found"
        )
        
    # Get all editions (tournaments) under this series
    editions = db.query(Tournament).filter(Tournament.series_id == series_id).order_by(Tournament.start_date.desc()).all()
    edition_ids = [e.id for e in editions]
    
    # Compile champions list
    champions = []
    for edition in editions:
        # Get all divisions in this edition
        divisions = db.query(TournamentDivision).filter(TournamentDivision.tournament_edition_id == edition.id).all()
        for div in divisions:
            # Get standings for this division, sort to find the champion (#1 rank)
            standings = db.query(TournamentStandings).filter(
                TournamentStandings.tournament_id == edition.id,
                TournamentStandings.division_id == div.id
            ).all()
            
            if standings:
                # Sort: points desc, goal_difference desc, goals_for desc
                standings.sort(key=lambda s: (s.points or 0, s.goal_difference or 0, s.goals_for or 0), reverse=True)
                champ_stand = standings[0]
                
                # Fetch team name
                team_name = db.execute(text("SELECT name FROM teams WHERE id = :team_id"), {"team_id": champ_stand.team_id}).scalar()
                
                champions.append({
                    "tournament_id": edition.id,
                    "tournament_name": edition.name,
                    "division_id": div.id,
                    "division_name": div.name or f"U-{div.birth_year}",
                    "team_id": champ_stand.team_id,
                    "team_name": team_name or "Unknown Team",
                    "year": edition.year,
                    "season": edition.season.value if edition.season else None
                })
                
    # Compile all-time team leaderboard
    team_stats = {}
    if edition_ids:
        # Get all standings records for tournaments in this series
        all_standings = db.query(TournamentStandings).filter(TournamentStandings.tournament_id.in_(edition_ids)).all()
        for s in all_standings:
            if s.team_id not in team_stats:
                team_name = db.execute(text("SELECT name FROM teams WHERE id = :team_id"), {"team_id": s.team_id}).scalar()
                logo_url = None
                team_stats[s.team_id] = {
                    "team_id": s.team_id,
                    "team_name": team_name or "Unknown Team",
                    "logo_url": logo_url,
                    "played": 0,
                    "wins": 0,
                    "draws": 0,
                    "losses": 0,
                    "goals_for": 0,
                    "goals_against": 0,
                    "goal_difference": 0,
                    "points": 0
                }
            
            entry = team_stats[s.team_id]
            entry["played"] += s.played or 0
            entry["wins"] += s.wins or 0
            entry["draws"] += s.draws or 0
            entry["losses"] += s.losses or 0
            entry["goals_for"] += s.goals_for or 0
            entry["goals_against"] += s.goals_against or 0
            entry["goal_difference"] += s.goal_difference or 0
            entry["points"] += s.points or 0

    team_leaderboard = list(team_stats.values())
    # Sort leaderboard by points, then goal_difference, then wins
    team_leaderboard.sort(key=lambda x: (x["points"], x["goal_difference"], x["wins"]), reverse=True)
    
    # Compile all-time player leaderboard (goals/assists)
    player_stats = {}
    if edition_ids:
        # Get all match player stats for matches in these tournaments
        match_player_stats = db.query(PlayerMatchStats).join(Match).filter(Match.tournament_id.in_(edition_ids)).all()
        for ps in match_player_stats:
            if ps.player_id not in player_stats:
                player_name = db.execute(text("SELECT name FROM users WHERE id = :player_id"), {"player_id": ps.player_id}).scalar()
                avatar_url = db.execute(text("SELECT avatar_url FROM users WHERE id = :player_id"), {"player_id": ps.player_id}).scalar()
                player_stats[ps.player_id] = {
                    "player_id": ps.player_id,
                    "player_name": player_name or "Unknown Player",
                    "avatar_url": avatar_url,
                    "goals": 0,
                    "assists": 0,
                    "yellow_cards": 0,
                    "red_cards": 0
                }
                
            entry = player_stats[ps.player_id]
            entry["goals"] += ps.goals or 0
            entry["assists"] += ps.assists or 0
            entry["yellow_cards"] += ps.yellow_cards or 0
            entry["red_cards"] += ps.red_cards or 0
            
    player_leaderboard = list(player_stats.values())
    # Sort players by goals desc, then assists desc
    player_leaderboard.sort(key=lambda x: (x["goals"], x["assists"]), reverse=True)
    # Cap leaderboard at top 20 players for performance and UI sanity
    player_leaderboard = player_leaderboard[:20]

    return {
        "id": series.id,
        "name": series.name,
        "city": series.city,
        "description": series.description,
        "logo_url": series.logo_url,
        "organizer_id": series.organizer_id,
        "created_at": series.created_at,
        "editions": editions,
        "champions": champions,
        "team_leaderboard": team_leaderboard,
        "player_leaderboard": player_leaderboard
    }

def create_tournament_division(db: Session, division_in: TournamentDivisionCreate):
    new_division = TournamentDivision(**division_in.model_dump())
    db.add(new_division)
    db.commit()
    db.refresh(new_division)
    return new_division

def get_tournament_divisions(db: Session, edition_id: UUID):
    return db.query(TournamentDivision).filter(TournamentDivision.tournament_edition_id == edition_id).all()

def update_tournament_division(db: Session, division_id: UUID, division_in: schemas.TournamentDivisionUpdate):
    division = db.query(TournamentDivision).filter(TournamentDivision.id == division_id).first()
    if not division:
        raise HTTPException(status_code=404, detail="Division not found")
    
    update_data = division_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(division, field, value)
    
    db.commit()
    db.refresh(division)
    return division

def delete_tournament_division(db: Session, division_id: UUID):
    division = db.query(TournamentDivision).filter(TournamentDivision.id == division_id).first()
    if not division:
        raise HTTPException(status_code=404, detail="Division not found")
    
    db.delete(division)
    db.commit()
    return {"status": "success"}

def create_tournament(db: Session, tournament_in: TournamentCreate, current_user: User):
    # Only use fields that exist in the Tournament model to avoid unexpected keyword errors
    tournament_data = tournament_in.model_dump(exclude_unset=True)
    
    # List of valid columns in Tournament model
    valid_cols = {c.name for c in Tournament.__table__.columns}
    filtered_data = {k: v for k, v in tournament_data.items() if k in valid_cols}
    
    new_tournament = Tournament(**filtered_data)
    new_tournament.created_by = current_user.id
    db.add(new_tournament)
    db.commit()
    db.refresh(new_tournament)
    
    # Requirement: Notify eligible users of tournament registration opening
    try:
        notify_eligible_users_of_tournament(db, new_tournament)
    except Exception as e:
        print(f"Non-critical error in notification: {e}")
    
    return new_tournament

def update_tournament(db: Session, tournament_id: UUID, tournament_in: TournamentUpdate):
    tournament = get_tournament_by_id(db, tournament_id)
    
    update_data = tournament_in.model_dump(exclude_unset=True)
    
    # List of valid columns in Tournament model
    valid_cols = {c.name for c in Tournament.__table__.columns}
    
    for field, value in update_data.items():
        if field in valid_cols:
            setattr(tournament, field, value)
            
    db.commit()
    db.refresh(tournament)
    return tournament

def notify_eligible_users_of_tournament(db: Session, tournament: Tournament):
    from app.users.models import UserRole
    users_to_notify = db.query(User).filter(
        User.roles.any(UserRole.role == Role.COACH) | 
        User.roles.any(UserRole.role == Role.CLUB_MANAGER)
    ).all()
    
    user_ids = [u.id for u in users_to_notify]
    if not user_ids:
        return

    notification_service.create_notification(
        db,
        user_ids,
        notification_type=NotificationType.TOURNAMENT_START,
        title="New Tournament Open!",
        message=f"Tournament {tournament.name} is now open for registration until {tournament.registration_close}.",
        entity_type=EntityType.TOURNAMENT,
        entity_id=tournament.id
    )

def get_tournaments(db: Session, season: Optional[Season] = None, year: Optional[int] = None, city: Optional[str] = None, current_user_id: Optional[UUID] = None):
    try:
        query = db.query(Tournament)
        if season:
            query = query.filter(Tournament.season == season)
        if year:
            query = query.filter(Tournament.year == year)
        if city:
            query = query.filter(Tournament.location.ilike(f"%{city}%"))
            
        if current_user_id:
            from sqlalchemy import or_, exists
            # Tournament is mine if I created it OR if my team is in one of its divisions
            is_creator = Tournament.created_by == current_user_id
            
            # Check if user has a team registered in any division of this tournament
            has_reg = exists().where(
                (TournamentTeam.tournament_id == Tournament.id) & 
                (TournamentTeam.registered_by == current_user_id)
            )

            # Check if user is an active player in any team registered in this tournament
            is_player = exists().where(
                (TournamentTeam.tournament_id == Tournament.id) &
                (TeamMembership.team_id == TournamentTeam.team_id) &
                (TeamMembership.player_id == current_user_id) &
                (TeamMembership.status == MembershipStatus.ACTIVE)
            )
            
            query = query.filter(or_(is_creator, has_reg, is_player))
            
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
    
    from app.teams.models import Team
    from app.academies.models import Academy
    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
        
    user_roles = {ur.role for ur in current_user.roles}
    is_coach = Role.COACH in user_roles and team.coach_id == current_user.id
    is_owner = Role.TEAM_OWNER in user_roles and team.academy_id and db.query(Academy).filter(Academy.id == team.academy_id, Academy.owner_id == current_user.id).first()
    is_organizer = Role.TOURNAMENT_ORGANIZER in user_roles and tournament.created_by == current_user.id
    
    if not (is_coach or is_owner or is_organizer):
        raise HTTPException(status_code=403, detail="Operation not permitted. Only the team's coach/owner or the tournament organizer can register it.")
    
    if not is_organizer:
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
    
    status = RegistrationStatus.APPROVED if is_organizer else RegistrationStatus.PENDING
    
    new_team_reg = TournamentTeam(
        division_id=division_id,
        tournament_id=tournament.id,
        team_id=team_id,
        registered_by=current_user.id,
        status=status,
        registration_data=registration_data
    )
    db.add(new_team_reg)
    db.commit()
    db.refresh(new_team_reg)
    
    if status == RegistrationStatus.APPROVED:
        existing_standing = db.query(TournamentStandings).filter(
            TournamentStandings.tournament_id == tournament.id,
            TournamentStandings.team_id == team_id
        ).first()
        if not existing_standing:
            new_standing = TournamentStandings(
                tournament_id=tournament.id,
                team_id=team_id,
                division_id=division_id
            )
            db.add(new_standing)
            db.commit()
            
    return new_team_reg

def get_tournament_teams(db: Session, tournament_id: UUID):
    return db.query(TournamentTeam).filter(TournamentTeam.tournament_id == tournament_id).all()

def update_tournament_team_status(
    db: Session, 
    tournament_id: UUID, 
    team_id: UUID, 
    status: Optional[RegistrationStatus] = None,
    registration_data: Optional[str] = None
):
    team_reg = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.team_id == team_id
    ).first()
    if not team_reg:
        raise HTTPException(status_code=404, detail="Team registration not found")
    
    old_status = team_reg.status
    if status is not None:
        team_reg.status = status
    if registration_data is not None:
        team_reg.registration_data = registration_data
        
    db.commit()
    db.refresh(team_reg)
    
    if status == RegistrationStatus.APPROVED and old_status != RegistrationStatus.APPROVED:
        team = db.query(Team).filter(Team.id == team_id).first()
        notify_team_members(
            db=db,
            team_id=team_id,
            title="Team Accepted! 🏆",
            message=f"Your team {team.name} has been approved for the tournament!",
            notification_type=NotificationType.TOURNAMENT_START, # Or a more specific type if available
            entity_type=EntityType.TOURNAMENT,
            entity_id=tournament_id
        )

        # Notify all active players in the team
        active_player_ids = [m.player_id for m in team.memberships if m.status == MembershipStatus.ACTIVE and m.player_id]
        if active_player_ids:
            notification_service.create_notification(
                db,
                active_player_ids,
                notification_type=NotificationType.TOURNAMENT_START,
                title="Tournament Registered!",
                message=f"Your team {team.name} has been registered for tournament {team_reg.tournament.name}!",
                entity_type=EntityType.TOURNAMENT,
                entity_id=tournament_id
            )
    
    if team_reg.status == RegistrationStatus.APPROVED:
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
    else:
        # If the team is no longer approved, remove it from standings
        db.query(TournamentStandings).filter(
            TournamentStandings.tournament_id == tournament_id,
            TournamentStandings.team_id == team_id
        ).delete(synchronize_session=False)
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

def get_team_time_preference(db: Session, tournament_id: UUID, team_id: UUID):
    import json
    tt = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.team_id == team_id
    ).first()
    if tt and tt.registration_data:
        try:
            data = json.loads(tt.registration_data)
            pref = data.get("time_pref")
            return pref
        except:
            pass
    return None

def is_time_pref_satisfied(pref: Optional[str], match_time):
    if not pref:
        return True
    t = match_time.time()
    from datetime import time
    if pref == "morning":
        return t < time(13, 0)
    elif pref == "afternoon":
        return t >= time(13, 0)
    return True

def generate_tournament_schedule(db: Session, tournament_id: UUID):
    tournament = get_tournament_by_id(db, tournament_id)
    
    # Clean up any existing matches of this tournament first to avoid duplicate schedules & conflicts
    match_ids = [m.id for m in db.query(Match).filter(Match.tournament_id == tournament_id).all()]
    if match_ids:
        # Delete related child records first to satisfy FK constraints
        db.query(MatchAward).filter(MatchAward.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(MatchEvent).filter(MatchEvent.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(MatchPlayerStats).filter(MatchPlayerStats.match_id.in_(match_ids)).delete(synchronize_session=False)
        
        # Lineups
        lineup_ids = [l.id for l in db.query(MatchLineup).filter(MatchLineup.match_id.in_(match_ids)).all()]
        if lineup_ids:
            db.query(MatchLineupPlayer).filter(MatchLineupPlayer.lineup_id.in_(lineup_ids)).delete(synchronize_session=False)
            db.query(MatchLineup).filter(MatchLineup.id.in_(lineup_ids)).delete(synchronize_session=False)
            
        db.query(MatchResult).filter(MatchResult.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(Match).filter(Match.id.in_(match_ids)).delete(synchronize_session=False)
        db.commit()
    
    if tournament.format == TournamentFormat.LEAGUE:
        return generate_league_schedule(db, tournament_id)
    elif tournament.format == TournamentFormat.KNOCKOUT:
        return generate_knockout_schedule(db, tournament_id)
    elif tournament.format == TournamentFormat.GROUP_STAGE:
        return generate_group_stage_schedule(db, tournament_id)
    else:
        raise HTTPException(status_code=400, detail=f"Unsupported tournament format: {tournament.format}")

def generate_league_schedule(db: Session, tournament_id: UUID):
    import json
    import uuid
    from datetime import timedelta, datetime
    
    tournament = get_tournament_by_id(db, tournament_id)
    approved_teams = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.status == RegistrationStatus.APPROVED
    ).all()
    
    if len(approved_teams) < 2:
        raise HTTPException(status_code=400, detail="At least 2 approved teams needed to generate schedule")
    
    # Group teams by division_id
    from collections import defaultdict
    division_teams = defaultdict(list)
    for t in approved_teams:
        division_teams[t.division_id].append(t.team_id)
        
    # Parse field_ids if they exist
    field_ids = []
    if getattr(tournament, "field_ids", None):
        try:
            field_ids = json.loads(tournament.field_ids)
        except:
            pass
    
    num_fields = len(field_ids) if field_ids else tournament.num_fields
    if num_fields < 1: num_fields = 1
    
    # Pre-fetch preferences for all approved teams
    team_prefs = {}
    for team in approved_teams:
        team_prefs[team.team_id] = get_team_time_preference(db, tournament_id, team.team_id)
        
    match_count = 0
    
    # Configuration for timing
    current_time = tournament.start_time or tournament.start_date
    if isinstance(current_time, str):
        current_time = datetime.fromisoformat(current_time)
        
    match_duration = (tournament.match_half_duration * 2) + tournament.halftime_break_duration + tournament.break_between_matches
    
    slot_index = 0
    
    for div_id, div_teams in division_teams.items():
        if len(div_teams) < 2:
            continue
            
        # Circle Method to generate round robin rounds without team overlap
        lst = list(div_teams)
        if len(lst) % 2 != 0:
            lst.append(None) # dummy team for BYE
            
        n = len(lst)
        num_rounds = n - 1
        
        for r in range(num_rounds):
            round_fixtures = []
            for i in range(n // 2):
                home = lst[i]
                away = lst[n - 1 - i]
                if home is not None and away is not None:
                    if r % 2 == 0:
                        round_fixtures.append((home, away))
                    else:
                        round_fixtures.append((away, home))
                        
            # Generate next N slot definitions taking day roll-over into account
            slots_def = []
            for _ in range(len(round_fixtures)):
                field_slot = slot_index % num_fields
                time_offset = slot_index // num_fields
                match_start = current_time + timedelta(minutes=time_offset * match_duration)
                
                # Check if exceeds day's end_time
                if tournament.end_time:
                    day_end = datetime.combine(match_start.date(), tournament.end_time.time())
                    if match_start + timedelta(minutes=match_duration) > day_end:
                        # Move current_time to next day and start scheduling round from beginning of day
                        current_time = current_time + timedelta(days=1)
                        if tournament.start_time:
                            current_time = datetime.combine(current_time.date(), tournament.start_time.time())
                        else:
                            current_time = datetime.combine(current_time.date(), current_time.time())
                        slot_index = 0
                        field_slot = 0
                        time_offset = 0
                        match_start = current_time
                
                field_uuid = None
                if field_ids:
                    field_uuid = uuid.UUID(field_ids[field_slot])
                    
                slots_def.append({
                    "slot_index": slot_index,
                    "field_uuid": field_uuid,
                    "match_start": match_start
                })
                slot_index += 1
                
            # Map round_fixtures to slots_def respecting preferences
            assigned_fixtures = {} # slot_index -> fixture
            unassigned_fixtures = list(round_fixtures)
            
            # Priority 1: Match slots that satisfy preferences of both teams
            for slot in slots_def:
                for fixture in unassigned_fixtures:
                    pref_home = team_prefs.get(fixture[0])
                    pref_away = team_prefs.get(fixture[1])
                    if is_time_pref_satisfied(pref_home, slot["match_start"]) and is_time_pref_satisfied(pref_away, slot["match_start"]):
                        assigned_fixtures[slot["slot_index"]] = fixture
                        unassigned_fixtures.remove(fixture)
                        break
                        
            # Priority 2: Fallback
            for slot in slots_def:
                if slot["slot_index"] not in assigned_fixtures:
                    if unassigned_fixtures:
                        fixture = unassigned_fixtures.pop(0)
                        assigned_fixtures[slot["slot_index"]] = fixture
                        
            # Create Match objects in database
            for slot in slots_def:
                fixture = assigned_fixtures.get(slot["slot_index"])
                if fixture:
                    new_match = Match(
                        tournament_id=tournament_id,
                        division_id=div_id, 
                        home_team_id=fixture[0],
                        away_team_id=fixture[1],
                        field_id=slot["field_uuid"],
                        match_date=slot["match_start"],
                        status=MatchStatus.DRAFT,
                        round_number=r + 1
                    )
                    db.add(new_match)
                    match_count += 1
                
            # Push slot_index to next clean slot multiple of num_fields so next round starts clean
            if slot_index % num_fields != 0:
                slot_index = ((slot_index // num_fields) + 1) * num_fields
                
            # Rotate list keeping the first fixed
            lst = [lst[0]] + [lst[-1]] + lst[1:-1]
    
    db.commit()
    
    return {
        "message": "AI has generated a draft league schedule with field assignments.",
        "ai_report": f"Scheduled {match_count} matches across {num_fields} fields. Optimized for minimal team wait times and balanced field usage.",
        "matches_count": match_count
    }

def generate_knockout_schedule(db: Session, tournament_id: UUID):
    import math
    import random
    import json
    import uuid
    from datetime import timedelta, date, datetime
    
    tournament = get_tournament_by_id(db, tournament_id)
    approved_teams = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.status == RegistrationStatus.APPROVED
    ).all()
    
    num_teams = len(approved_teams)
    if num_teams < 2:
        raise HTTPException(status_code=400, detail="At least 2 approved teams needed for Knockout")
    
    field_ids = []
    if getattr(tournament, "field_ids", None):
        try:
            field_ids = json.loads(tournament.field_ids)
        except:
            pass
    num_fields = len(field_ids) if field_ids else tournament.num_fields
    if num_fields < 1: num_fields = 1
    
    # Randomize seeding
    random.shuffle(approved_teams)
    
    # Calculate K (largest power of 2 <= num_teams)
    # T is the nearest power of 2 >= num_teams
    if num_teams & (num_teams - 1) == 0:
        K = num_teams
        has_preliminary = False
    else:
        K = 2**int(math.log2(num_teams))
        has_preliminary = True

    # Total rounds
    # If no preliminary round, rounds are 1 .. log2(K)
    # If preliminary round, rounds are 1 (preliminary) .. log2(K) + 1
    if not has_preliminary:
        max_round = int(math.log2(K))
    else:
        max_round = int(math.log2(K)) + 1

    # Timing config
    current_time = tournament.start_time or tournament.start_date
    if isinstance(current_time, str):
        current_time = datetime.fromisoformat(current_time)
    if isinstance(current_time, date) and not isinstance(current_time, datetime):
        current_time = datetime.combine(current_time, datetime.min.time())
        
    match_duration = (tournament.match_half_duration * 2) + tournament.halftime_break_duration + tournament.break_between_matches

    created_matches = {} # Keyed by (round_number, bracket_position)
    matches_to_add = []

    # Let's build the tree starting from max_round down to 1
    for r in range(max_round, 0, -1):
        # Determine number of matches in this round
        if r == 1 and has_preliminary:
            num_matches_in_round = num_teams - K
        else:
            # For round r (1-indexed), the number of matches is K / 2**r (if no prelims)
            # or K / 2**(r - 1) (if prelims)
            round_power = r - 1 if not has_preliminary else r - 2
            num_matches_in_round = K // (2**(round_power + 1))

        # Date for this round: each round played on a different day (consecutive days)
        round_start_time = current_time + timedelta(days=r - 1)

        for pos in range(num_matches_in_round):
            # Calculate field and time offset for this round
            field_slot = pos % num_fields
            time_offset = pos // num_fields
            match_start = round_start_time + timedelta(minutes=time_offset * match_duration)
            
            field_uuid = None
            if field_ids:
                try:
                    field_uuid = uuid.UUID(field_ids[field_slot])
                except:
                    pass

            new_match = Match(
                id=uuid.uuid4(),
                tournament_id=tournament_id,
                division_id=approved_teams[0].division_id,
                field_id=field_uuid,
                match_date=match_start,
                status=MatchStatus.DRAFT,
                round_number=r,
                bracket_position=pos
            )
            created_matches[(r, pos)] = new_match
            matches_to_add.append(new_match)

    # Link the matches
    for (r, pos), m in created_matches.items():
        if r < max_round:
            # If r == 1 and we have a preliminary round, it feeds into Round 2 Match (pos // 2)
            # Otherwise, it feeds into Round (r+1) Match (pos // 2)
            next_round = 2 if (r == 1 and has_preliminary) else r + 1
            parent_match = created_matches.get((next_round, pos // 2))
            if parent_match:
                m.next_match_id = parent_match.id

    # Team assignments
    if not has_preliminary:
        # All teams assigned in Round 1
        for pos in range(K // 2):
            m = created_matches[(1, pos)]
            m.home_team_id = approved_teams[2 * pos].team_id
            m.away_team_id = approved_teams[2 * pos + 1].team_id
    else:
        # First 2*(N-K) teams play in Round 1
        num_prelim_matches = num_teams - K
        for pos in range(num_prelim_matches):
            m = created_matches[(1, pos)]
            m.home_team_id = approved_teams[2 * pos].team_id
            m.away_team_id = approved_teams[2 * pos + 1].team_id

        # Remaining (2*K - N) teams get BYEs and are placed in Round 2
        bye_teams = approved_teams[2 * num_prelim_matches:]
        bye_index = 0
        
        for pos in range(K // 2):
            m = created_matches[(2, pos)]
            
            # Check Home slot: if it's not fed by Round 1, assign a BYE team
            if 2 * pos >= num_prelim_matches:
                if bye_index < len(bye_teams):
                    m.home_team_id = bye_teams[bye_index].team_id
                    bye_index += 1
            
            # Check Away slot: if it's not fed by Round 1, assign a BYE team
            if 2 * pos + 1 >= num_prelim_matches:
                if bye_index < len(bye_teams):
                    m.away_team_id = bye_teams[bye_index].team_id
                    bye_index += 1

    db.add_all(matches_to_add)
    db.commit()
    
    return {
        "message": "AI has constructed the full knockout playoff bracket with automatic advancement links.",
        "ai_report": f"Calculated playoff tree with {max_round} rounds for {num_teams} teams. {len(matches_to_add)} total matches generated.",
        "teams_total": num_teams,
        "rounds_total": max_round,
        "matches_count": len(matches_to_add)
    }

def generate_group_stage_schedule(db: Session, tournament_id: UUID, teams_per_group: int = 4):
    import random
    import json
    from datetime import timedelta, datetime
    from app.tournaments.models import TournamentGroup, TournamentGroupTeam
    
    tournament = get_tournament_by_id(db, tournament_id)
    approved_teams = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.status == RegistrationStatus.APPROVED
    ).all()
    
    num_teams = len(approved_teams)
    if num_teams < 2:
        raise HTTPException(status_code=400, detail="At least 2 approved teams needed for Group Stage")
    
    # Parse field_ids
    field_ids = []
    if getattr(tournament, "field_ids", None):
        try:
            field_ids = json.loads(tournament.field_ids)
        except:
            pass
    num_fields = len(field_ids) if field_ids else tournament.num_fields
    if num_fields < 1: num_fields = 1

    # Check if groups already exist for this tournament
    existing_groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == tournament_id).all()
    if existing_groups:
        groups = existing_groups
        group_teams = {}
        for g in groups:
            group_teams[g.id] = []
            gt_entries = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == g.id).all()
            for gt in gt_entries:
                t = db.query(TournamentTeam).filter(TournamentTeam.id == gt.tournament_team_id).first()
                if t:
                    group_teams[g.id].append(t)
                    # Sync standings group_id just in case
                    standing = db.query(TournamentStandings).filter(
                        TournamentStandings.tournament_id == tournament_id,
                        TournamentStandings.team_id == t.team_id
                    ).first()
                    if standing:
                        standing.group_id = g.id
    else:
        # Randomize seeding
        random.shuffle(approved_teams)
        
        num_groups = max(1, num_teams // teams_per_group)
        groups = []
        import string
        for i in range(num_groups):
            group_name = f"Group {string.ascii_uppercase[i % 26]}"
            new_group = TournamentGroup(tournament_id=tournament_id, name=group_name)
            db.add(new_group)
            groups.append(new_group)
        
        db.flush()
        
        group_teams = {g.id: [] for g in groups}
        for i, team in enumerate(approved_teams):
            group = groups[i % num_groups]
            new_gt = TournamentGroupTeam(group_id=group.id, tournament_team_id=team.id)
            db.add(new_gt)
            group_teams[group.id].append(team)
            
            # Sync standings group_id
            standing = db.query(TournamentStandings).filter(
                TournamentStandings.tournament_id == tournament_id,
                TournamentStandings.team_id == team.team_id
            ).first()
            if standing:
                standing.group_id = group.id
            
        db.flush()
    num_groups = len(groups)
    
    # Pre-fetch preferences for all approved teams
    team_prefs = {}
    for team in approved_teams:
        team_prefs[team.team_id] = get_team_time_preference(db, tournament_id, team.team_id)
        
    match_count = 0
    all_match_starts = []
    # Timing config
    current_time = tournament.start_time or tournament.start_date
    if isinstance(current_time, str):
        current_time = datetime.fromisoformat(current_time)
        
    match_duration = (tournament.match_half_duration * 2) + tournament.halftime_break_duration + tournament.break_between_matches

    # Use Circle Method for each group stage group round robin
    rounds_of_group = {}
    for group_id, teams in group_teams.items():
        lst = [t.team_id for t in teams]
        if len(lst) % 2 != 0:
            lst.append(None)
            
        n = len(lst)
        group_rounds = []
        num_rounds = n - 1
        
        for r in range(num_rounds):
            round_fixtures = []
            for i in range(n // 2):
                home = lst[i]
                away = lst[n - 1 - i]
                if home is not None and away is not None:
                    if r % 2 == 0:
                        round_fixtures.append((home, away, group_id))
                    else:
                        round_fixtures.append((away, home, group_id))
            group_rounds.append(round_fixtures)
            lst = [lst[0]] + [lst[-1]] + lst[1:-1]
            
        rounds_of_group[group_id] = group_rounds

    # Merge group stage rounds to parallelize matches and prevent team overlaps
    max_rounds = max(len(rounds_of_group[g_id]) for g_id in group_teams.keys())
    slot_index = 0
    base_start_time = tournament.start_time or tournament.start_date
    if isinstance(base_start_time, str):
        base_start_time = datetime.fromisoformat(base_start_time)
    
    for r in range(max_rounds):
        # Cadence override: Round 3 (r = 2) must be scheduled on the second day (Day 2)
        if r == 2:
            current_time = base_start_time + timedelta(days=1)
            if tournament.start_time:
                current_time = datetime.combine(current_time.date(), tournament.start_time.time())
            slot_index = 0
        elif r == 0:
            current_time = base_start_time
            if tournament.start_time:
                current_time = datetime.combine(current_time.date(), tournament.start_time.time())
            slot_index = 0

        round_fixtures = []
        for g_id in group_teams.keys():
            if r < len(rounds_of_group[g_id]):
                round_fixtures.extend(rounds_of_group[g_id][r])
                
        # Generate N slot definitions for this round
        slots_def = []
        for _ in range(len(round_fixtures)):
            field_slot = slot_index % num_fields
            time_offset = slot_index // num_fields
            match_start = current_time + timedelta(minutes=time_offset * match_duration)
            
            # Check if exceeds day's end_time
            if tournament.end_time:
                day_end = datetime.combine(match_start.date(), tournament.end_time.time())
                if match_start + timedelta(minutes=match_duration) > day_end:
                    current_time = current_time + timedelta(days=1)
                    if tournament.start_time:
                        current_time = datetime.combine(current_time.date(), tournament.start_time.time())
                    else:
                        current_time = datetime.combine(current_time.date(), current_time.time())
                    slot_index = 0
                    field_slot = 0
                    time_offset = 0
                    match_start = current_time
            
            field_uuid = None
            if field_ids:
                field_uuid = uuid.UUID(field_ids[field_slot])
                
            slots_def.append({
                "slot_index": slot_index,
                "field_uuid": field_uuid,
                "match_start": match_start
            })
            all_match_starts.append(match_start)
            slot_index += 1
            
        # Map round_fixtures to slots_def respecting preferences
        assigned_fixtures = {} # slot_index -> fixture
        unassigned_fixtures = list(round_fixtures)
        
        # Priority 1: Match slots that satisfy preferences of both teams
        for slot in slots_def:
            for fixture in unassigned_fixtures:
                pref_home = team_prefs.get(fixture[0])
                pref_away = team_prefs.get(fixture[1])
                if is_time_pref_satisfied(pref_home, slot["match_start"]) and is_time_pref_satisfied(pref_away, slot["match_start"]):
                    assigned_fixtures[slot["slot_index"]] = fixture
                    unassigned_fixtures.remove(fixture)
                    break
                    
        # Priority 2: Fallback
        for slot in slots_def:
            if slot["slot_index"] not in assigned_fixtures:
                if unassigned_fixtures:
                    fixture = unassigned_fixtures.pop(0)
                    assigned_fixtures[slot["slot_index"]] = fixture
                    
        # Create Match objects in database
        for slot in slots_def:
            fixture = assigned_fixtures.get(slot["slot_index"])
            if fixture:
                new_match = Match(
                    tournament_id=tournament_id,
                    division_id=approved_teams[0].division_id,
                    home_team_id=fixture[0],
                    away_team_id=fixture[1],
                    group_id=fixture[2],
                    field_id=slot["field_uuid"],
                    match_date=slot["match_start"],
                    status=MatchStatus.DRAFT,
                    round_number=r + 1
                )
                db.add(new_match)
                match_count += 1
                
        # Pad slot_index to next clean multiple of num_fields for next round
        if slot_index % num_fields != 0:
            slot_index = ((slot_index // num_fields) + 1) * num_fields
            
    # Pre-create Playoff matches (Semis, Finals, Placements) if exactly 2 groups
    if num_groups == 2:
        import uuid
        max_match_time = max(all_match_starts) if all_match_starts else current_time
        playoff_start_date = max_match_time + timedelta(minutes=match_duration + 30)
        
        sf1_id = uuid.uuid4()
        sf2_id = uuid.uuid4()
        final_id = uuid.uuid4()
        third_place_id = uuid.uuid4()
        
        sf1_field = uuid.UUID(field_ids[0]) if field_ids else None
        sf2_field = uuid.UUID(field_ids[1 % num_fields]) if field_ids else None
        
        sf1_time = playoff_start_date
        if num_fields > 1:
            sf2_time = playoff_start_date
        else:
            sf2_time = playoff_start_date + timedelta(minutes=match_duration)
            
        division_id = approved_teams[0].division_id if approved_teams else None
        
        # SF 1: A1 vs B2
        sf1 = Match(
            id=sf1_id,
            tournament_id=tournament_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=sf1_time,
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=1,
            bracket_position=0,
            next_match_id=final_id
        )
        
        # SF 2: B1 vs A2
        sf2 = Match(
            id=sf2_id,
            tournament_id=tournament_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=sf2_time,
            field_id=sf2_field,
            status=MatchStatus.DRAFT,
            round_number=1,
            bracket_position=1,
            next_match_id=final_id
        )
        
        # Final and 3rd place: same day, 30 mins after Semifinals finish
        final_date = playoff_start_date + timedelta(minutes=match_duration + 30)
        
        final_match = Match(
            id=final_id,
            tournament_id=tournament_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=final_date + timedelta(minutes=match_duration),
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=2,
            bracket_position=0
        )
        
        third_place_match = Match(
            id=third_place_id,
            tournament_id=tournament_id,
            division_id=division_id,
            home_team_id=None,
            away_team_id=None,
            match_date=final_date,
            field_id=sf1_field,
            status=MatchStatus.DRAFT,
            round_number=2,
            bracket_position=1
        )
        
        db.add_all([sf1, sf2, final_match, third_place_match])
        
        # Consolation/placement matches
        if num_teams >= 6:
            m5 = Match(
                id=uuid.uuid4(),
                tournament_id=tournament_id,
                division_id=division_id,
                home_team_id=None,
                away_team_id=None,
                match_date=sf1_time,
                field_id=uuid.UUID(field_ids[2 % num_fields]) if num_fields > 2 and field_ids else sf1_field,
                status=MatchStatus.DRAFT,
                round_number=1,
                bracket_position=2
            )
            db.add(m5)
            
        if num_teams >= 8:
            m7 = Match(
                id=uuid.uuid4(),
                tournament_id=tournament_id,
                division_id=division_id,
                home_team_id=None,
                away_team_id=None,
                match_date=sf2_time,
                field_id=uuid.UUID(field_ids[3 % num_fields]) if num_fields > 3 and field_ids else sf2_field,
                status=MatchStatus.DRAFT,
                round_number=1,
                bracket_position=3
            )
            db.add(m7)
            
    db.commit()
    
    return {
        "message": "AI has balanced the groups and assigned field slots.",
        "ai_report": f"Distributed {num_teams} teams across {num_groups} groups. Matches scheduled across {num_fields} fields starting from {current_time.strftime('%H:%M')}.",
        "groups_count": num_groups,
        "total_matches": match_count
    }

def finalize_tournament_schedule(db: Session, tournament_id: UUID):
    """
    Moves all DRAFT matches to SCHEDULED status.
    """
    matches = db.query(Match).filter(
        Match.tournament_id == tournament_id,
        Match.status == MatchStatus.DRAFT
    ).all()
    
    for m in matches:
        m.status = MatchStatus.SCHEDULED
        # Notify participants
        notify_match_participants(
            db=db,
            match=m,
            title="Match Scheduled! ⚽",
            message=f"New match scheduled: {m.home_team.name} vs {m.away_team.name}",
            notification_type=NotificationType.MATCH_SCHEDULED
        )
        
    db.commit()
    return {"message": f"Schedule finalized. {len(matches)} matches are now public."}

def swap_teams_in_groups(db: Session, tournament_id: UUID, team_a_id: UUID, team_b_id: UUID):
    """
    Swaps two teams between their respective groups.
    """
    from app.tournaments.models import TournamentGroupTeam
    
    # 1. Find group assignments
    assign_a = db.query(TournamentGroupTeam).join(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.team_id == team_a_id
    ).first()
    
    assign_b = db.query(TournamentGroupTeam).join(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.team_id == team_b_id
    ).first()
    
    if not assign_a or not assign_b:
        raise HTTPException(status_code=404, detail="One or both teams not found in group assignments")
        
    # 2. Swap group IDs
    group_a_id = assign_a.group_id
    assign_a.group_id = assign_b.group_id
    assign_b.group_id = group_a_id
    
    # 3. IMPORTANT: We must also update or regenerate matches!
    # For simplicity in this step, we'll suggest deleting draft matches and regenerating,
    # OR we can manually update the home/away team IDs in existing draft matches.
    # Let's do the manual update for matches in DRAFT status.
    
    # This is complex because matches are based on team_ids. 
    # Swapping teams in groups usually means the WHOLE group schedule needs a refresh.
    # Simpler approach: delete draft matches for these two groups and regenerate them.
    
    affected_groups = [assign_a.group_id, assign_b.group_id]
    db.query(Match).filter(
        Match.tournament_id == tournament_id,
        Match.status == MatchStatus.DRAFT,
        Match.group_id.in_(affected_groups)
    ).delete()
    
    db.commit()
    
    # Re-generate matches for these two groups
    for g_id in affected_groups:
        teams = db.query(TournamentTeam).join(TournamentGroupTeam).filter(
            TournamentGroupTeam.group_id == g_id
        ).all()
        
        for i in range(len(teams)):
            for j in range(i + 1, len(teams)):
                new_match = Match(
                    tournament_id=tournament_id,
                    division_id=teams[0].division_id,
                    home_team_id=teams[i].team_id,
                    away_team_id=teams[j].team_id,
                    group_id=g_id,
                    status=MatchStatus.DRAFT,
                    round_number=1
                )
                db.add(new_match)
                
    db.commit()
    return {"message": "Teams swapped successfully and group matches recalculated."}

def get_tournament_groups(db: Session, tournament_id: UUID):
    from app.tournaments.models import TournamentGroup, TournamentGroupTeam, TournamentTeam
    from app.teams.models import Team
    
    groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == tournament_id).all()
    res = []
    for g in groups:
        teams_res = []
        gt_list = db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id == g.id).all()
        for gt in gt_list:
            t_team = db.query(TournamentTeam).filter(TournamentTeam.id == gt.tournament_team_id).first()
            if t_team:
                team_obj = db.query(Team).filter(Team.id == t_team.team_id).first()
                if team_obj:
                    teams_res.append({
                        "id": str(t_team.id),
                        "team_id": str(team_obj.id),
                        "name": team_obj.name,
                        "logo_url": None
                    })
        res.append({
            "id": str(g.id),
            "name": g.name,
            "teams": teams_res
        })
    return res

def draw_tournament_groups(db: Session, tournament_id: UUID, num_groups: int, assignments: dict):
    from app.tournaments.models import TournamentGroup, TournamentGroupTeam, TournamentTeam, TournamentStandings
    from app.matches.models import Match, MatchAward, MatchEvent, MatchPlayerStats, MatchLineup, MatchLineupPlayer, MatchResult
    import string
    
    # 1. Clean existing matches and their dependencies
    match_ids = [m.id for m in db.query(Match).filter(Match.tournament_id == tournament_id).all()]
    if match_ids:
        db.query(MatchAward).filter(MatchAward.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(MatchEvent).filter(MatchEvent.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(MatchPlayerStats).filter(MatchPlayerStats.match_id.in_(match_ids)).delete(synchronize_session=False)
        
        lineup_ids = [l.id for l in db.query(MatchLineup).filter(MatchLineup.match_id.in_(match_ids)).all()]
        if lineup_ids:
            db.query(MatchLineupPlayer).filter(MatchLineupPlayer.lineup_id.in_(lineup_ids)).delete(synchronize_session=False)
            db.query(MatchLineup).filter(MatchLineup.id.in_(lineup_ids)).delete(synchronize_session=False)
            
        db.query(MatchResult).filter(MatchResult.match_id.in_(match_ids)).delete(synchronize_session=False)
        db.query(Match).filter(Match.id.in_(match_ids)).delete(synchronize_session=False)
        db.commit()
        
    # 2. Clean existing groups
    groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == tournament_id).all()
    group_ids = [g.id for g in groups]
    if group_ids:
        db.query(TournamentStandings).filter(TournamentStandings.group_id.in_(group_ids)).update({TournamentStandings.group_id: None}, synchronize_session=False)
        db.flush()
        db.query(TournamentGroupTeam).filter(TournamentGroupTeam.group_id.in_(group_ids)).delete(synchronize_session=False)
        db.query(TournamentGroup).filter(TournamentGroup.id.in_(group_ids)).delete(synchronize_session=False)
        db.commit()
        
    # 2. Get approved teams
    approved_teams = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.status == RegistrationStatus.APPROVED
    ).all()
    
    if not approved_teams:
        raise HTTPException(status_code=400, detail="No approved teams in this tournament to draw")
        
    # 3. Create Groups
    created_groups = {}
    for i in range(num_groups):
        g_name = f"Group {string.ascii_uppercase[i % 26]}"
        g_obj = TournamentGroup(tournament_id=tournament_id, name=g_name)
        db.add(g_obj)
        db.flush()
        created_groups[g_name] = g_obj
        
    # 4. If assignments are not provided, distribute using AI/Smart Draw
    if not assignments:
        import random
        shuffled = list(approved_teams)
        random.shuffle(shuffled)
        for idx, team in enumerate(shuffled):
            g_name = f"Group {string.ascii_uppercase[(idx % num_groups) % 26]}"
            g_obj = created_groups[g_name]
            db.add(TournamentGroupTeam(group_id=g_obj.id, tournament_team_id=team.id))
            
            # Sync standings group_id
            standing = db.query(TournamentStandings).filter(
                TournamentStandings.tournament_id == tournament_id,
                TournamentStandings.team_id == team.team_id
            ).first()
            if standing:
                standing.group_id = g_obj.id
    else:
        # Map of team_id -> TournamentTeam
        team_map = {str(t.team_id): t for t in approved_teams}
        for g_name, team_ids in assignments.items():
            g_obj = created_groups.get(g_name)
            if not g_obj:
                continue
            for t_id in team_ids:
                team_reg = team_map.get(str(t_id))
                if team_reg:
                    db.add(TournamentGroupTeam(group_id=g_obj.id, tournament_team_id=team_reg.id))
                    
                    # Sync standings group_id
                    standing = db.query(TournamentStandings).filter(
                        TournamentStandings.tournament_id == tournament_id,
                        TournamentStandings.team_id == team_reg.team_id
                    ).first()
                    if standing:
                        standing.group_id = g_obj.id
                    
    db.commit()
    return get_tournament_groups(db, tournament_id)

def update_match_result(db: Session, match_id: UUID, home_score: int, away_score: int, home_penalty_score: Optional[int] = None, away_penalty_score: Optional[int] = None):
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    match.home_score = home_score
    match.away_score = away_score
    match.home_penalty_score = home_penalty_score
    match.away_penalty_score = away_penalty_score
    
    # Update or create MatchResult
    result = db.query(MatchResult).filter(MatchResult.match_id == match_id).first()
    if not result:
        result = MatchResult(
            match_id=match_id,
            home_score=home_score,
            away_score=away_score,
            home_penalty_score=home_penalty_score,
            away_penalty_score=away_penalty_score,
            status=ResultStatus.FINAL,
            submitted_by=match.tournament.created_by if match.tournament else match.id # Organizer or fallback
        )
        db.add(result)
    else:
        result.home_score = home_score
        result.away_score = away_score
        result.home_penalty_score = home_penalty_score
        result.away_penalty_score = away_penalty_score
        result.status = ResultStatus.FINAL
        
    match.status = MatchStatus.FINISHED
    
    # Automatic playoff advancement logic
    if match.next_match_id:
        if home_score == away_score:
            if home_penalty_score is None or away_penalty_score is None or home_penalty_score == away_penalty_score:
                raise HTTPException(
                    status_code=400,
                    detail="Playoff matches must have a winner. Draw scores require penalty shootout results."
                )
            is_home_winner = home_penalty_score > away_penalty_score
        else:
            is_home_winner = home_score > away_score
            
        winner_id = match.home_team_id if is_home_winner else match.away_team_id
        loser_id = match.away_team_id if is_home_winner else match.home_team_id
        
        next_match = db.query(Match).filter(Match.id == match.next_match_id).first()
        if next_match:
            if match.bracket_position is not None:
                if match.bracket_position % 2 == 0:
                    next_match.home_team_id = winner_id
                else:
                    next_match.away_team_id = winner_id
                db.add(next_match)
                
                # If there is a 3rd place match (same round as next_match, position = next_match.position + 1)
                third_place_match = db.query(Match).filter(
                    Match.tournament_id == match.tournament_id,
                    Match.round_number == next_match.round_number,
                    Match.bracket_position == next_match.bracket_position + 1
                ).first()
                if third_place_match:
                    if match.bracket_position % 2 == 0:
                        third_place_match.home_team_id = loser_id
                    else:
                        third_place_match.away_team_id = loser_id
                    db.add(third_place_match)
                
    db.commit()
    
    # Notify participants about the final score
    notify_match_participants(
        db=db,
        match=match,
        title="Match Result! 🏆",
        message=f"Final score: {match.home_team.name} {home_score} - {away_score} {match.away_team.name}",
        notification_type=NotificationType.MATCH_RESULT
    )
    
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
        Match.status == MatchStatus.FINISHED,
        Match.group_id.isnot(None)
    ).all()
    
    away_matches = db.query(Match).join(MatchResult).filter(
        Match.tournament_id == tournament_id,
        Match.away_team_id == team_id,
        Match.status == MatchStatus.FINISHED,
        Match.group_id.isnot(None)
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
    valid_fields = [
        "minimum_rest_slots", "points_for_win", "points_for_draw", "points_for_loss",
        "surface_type", "whatsapp", "phone"
    ]
    standings = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == tournament_id
    ).order_by(
        TournamentStandings.points.desc(),
        TournamentStandings.goal_difference.desc(),
        TournamentStandings.goals_for.desc()
    ).all()

    from app.teams.models import Team
    from app.tournaments.models import TournamentDivision
    result = []
    for s in standings:
        team = db.query(Team).filter(Team.id == s.team_id).first()
        division = db.query(TournamentDivision).filter(TournamentDivision.id == s.division_id).first()
        result.append({
            "team_id": s.team_id,
            "team_name": team.name if team else "Unknown Team",
            "division_id": s.division_id,
            "division_name": division.name if division else "Division",
            "played": s.played,
            "wins": s.wins,
            "draws": s.draws,
            "losses": s.losses,
            "goals_for": s.goals_for,
            "goals_against": s.goals_against,
            "goal_difference": s.goal_difference,
            "points": s.points,
            "group_id": s.group_id,
            "group_name": s.group.name if s.group else None
        })
    return result

def get_tournament_matches(db: Session, tournament_id: UUID):
    matches = db.query(Match).filter(Match.tournament_id == tournament_id).order_by(Match.match_date).all()
    
    from app.teams.models import Team
    
    result_list = []
    for m in matches:
        home_team = db.query(Team).filter(Team.id == m.home_team_id).first() if m.home_team_id else None
        away_team = db.query(Team).filter(Team.id == m.away_team_id).first() if m.away_team_id else None
        
        # Fetch field name if available
        from app.fields.models import Field
        field = db.query(Field).filter(Field.id == m.field_id).first() if m.field_id else None
        # Convert to dict and add names
        match_dict = {
            "id": m.id,
            "tournament_id": m.tournament_id,
            "division_id": m.division_id,
            "home_team_id": m.home_team_id,
            "away_team_id": m.away_team_id,
            "field_id": m.field_id,
            "field_name": field.name if field else None,
            "match_date": m.match_date,
            "status": m.status,
            "group_id": m.group_id,
            "round_number": m.round_number,
            "bracket_position": m.bracket_position,
            "next_match_id": m.next_match_id,
            "home_team_name": home_team.name if home_team else None,
            "away_team_name": away_team.name if away_team else None,
            "result": m.result
        }
        result_list.append(match_dict)
        
    return result_list

def update_match_details(db: Session, match_id: UUID, details: dict):
    from app.matches.models import Match
    from app.teams.models import Team
    from datetime import datetime
    
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
        
    if "field_id" in details:
        f_id = details["field_id"]
        if f_id and str(f_id).strip() != "":
            try:
                match.field_id = UUID(str(f_id).strip())
            except ValueError:
                match.field_id = None
        else:
            match.field_id = None
            
    if "match_date" in details:
        m_date = details["match_date"]
        if m_date:
            if isinstance(m_date, str):
                match.match_date = datetime.fromisoformat(m_date.replace("Z", "+00:00"))
            else:
                match.match_date = m_date
        else:
            match.match_date = None
            
    db.commit()
    db.refresh(match)
    
    home_team = db.query(Team).filter(Team.id == match.home_team_id).first() if match.home_team_id else None
    away_team = db.query(Team).filter(Team.id == match.away_team_id).first() if match.away_team_id else None
    
    from app.fields.models import Field
    field = db.query(Field).filter(Field.id == match.field_id).first() if match.field_id else None
    return {
        "id": match.id,
        "tournament_id": match.tournament_id,
        "division_id": match.division_id,
        "home_team_id": match.home_team_id,
        "away_team_id": match.away_team_id,
        "field_id": match.field_id,
        "field_name": field.name if field else None,
        "match_date": match.match_date,
        "status": match.status,
        "group_id": match.group_id,
        "round_number": match.round_number,
        "bracket_position": match.bracket_position,
        "next_match_id": match.next_match_id,
        "home_team_name": home_team.name if home_team else None,
        "away_team_name": away_team.name if away_team else None,
        "result": match.result
    }

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
        TournamentPlayerStats.player_profile_id == child_profile_id
    ).first()
    
    if not agg_stats:
        agg_stats = TournamentPlayerStats(
            division_id=division_id,
            player_profile_id=child_profile_id
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
    squad = db.query(TournamentSquad).filter(TournamentSquad.tournament_team_id == tt_id).all()
    return [
        {
            "id": member.id,
            "child_profile_id": member.child_profile_id,
            "jersey_number": member.jersey_number,
            "position": member.position,
            "tournament_team_id": member.tournament_team_id,
            "player_name": member.child_profile.name if member.child_profile else "Unknown Player",
        }
        for member in squad
    ]

def get_tournament_leaderboards(db: Session, tournament_id: UUID):
    from sqlalchemy import func, desc, or_
    from app.tournaments.models import Tournament, TournamentDivision, TournamentSquad, TournamentTeam
    from app.matches.models import Match, MatchEvent, EventType, MatchPlayerStats
    from app.users.models import PlayerProfile, User
    from app.clubs.models import ChildProfile
    from app.teams.models import Team
    
    tournament = db.query(Tournament).filter(Tournament.id == tournament_id).first()
    if not tournament:
        return []
        
    divisions = db.query(TournamentDivision).filter(TournamentDivision.tournament_edition_id == tournament_id).all()
    if not divisions:
        class VirtualDiv:
            def __init__(self, id, name):
                self.id = id
                self.name = name
        divisions = [VirtualDiv(tournament.id, tournament.name)]

    final_result = []

    for div in divisions:
        div_id = div.id
        if hasattr(div, 'tournament_edition_id'):
            matches = db.query(Match).filter(Match.tournament_id == tournament_id, Match.division_id == div_id).all()
            if not matches:
                div_teams = db.query(TournamentTeam).filter(TournamentTeam.division_id == div_id).all()
                div_team_ids = [tt.team_id for tt in div_teams]
                if div_team_ids:
                    matches = db.query(Match).filter(
                        Match.tournament_id == tournament_id,
                        or_(Match.home_team_id.in_(div_team_ids), Match.away_team_id.in_(div_team_ids))
                    ).all()
        else:
            matches = db.query(Match).filter(Match.tournament_id == tournament_id).all()
            
        match_ids = [m.id for m in matches]
        
        player_goals = {}
        player_assists = {}
        player_team_map = {}
        
        if match_ids:
            events = db.query(MatchEvent).filter(MatchEvent.match_id.in_(match_ids)).all()
            for e in events:
                pid = e.child_profile_id or e.player_id
                if not pid:
                    continue
                pid_str = str(pid)
                if e.team_id:
                    player_team_map[pid_str] = str(e.team_id)
                    
                if e.event_type in [EventType.GOAL, EventType.PENALTY_GOAL]:
                    player_goals[pid_str] = player_goals.get(pid_str, 0) + 1
                elif e.event_type == EventType.ASSIST:
                    player_assists[pid_str] = player_assists.get(pid_str, 0) + 1
                    
            pstats = db.query(MatchPlayerStats).filter(MatchPlayerStats.match_id.in_(match_ids)).all()
            for ps in pstats:
                pid = ps.child_profile_id or ps.player_id
                if not pid:
                    continue
                pid_str = str(pid)
                if ps.team_id:
                    player_team_map[pid_str] = str(ps.team_id)
                if ps.goals:
                    player_goals[pid_str] = max(player_goals.get(pid_str, 0), ps.goals)
                if ps.assists:
                    player_assists[pid_str] = max(player_assists.get(pid_str, 0), ps.assists)

        def resolve_player_info(pid_str, val):
            try:
                pid_uuid = UUID(pid_str)
            except Exception:
                return None
                
            name = "Unknown Player"
            child = db.query(ChildProfile).filter(ChildProfile.id == pid_uuid).first()
            if child:
                name = f"{child.first_name} {child.last_name}"
            else:
                user = db.query(User).filter(User.id == pid_uuid).first()
                if user:
                    name = user.name or f"{user.first_name} {user.last_name}"
                else:
                    prof = db.query(PlayerProfile).filter(PlayerProfile.id == pid_uuid).first()
                    if prof and prof.user:
                        name = prof.user.name or f"{prof.user.first_name} {prof.user.last_name}"

            team_name = "Team"
            t_id_str = player_team_map.get(pid_str)
            if t_id_str:
                try:
                    team = db.query(Team).filter(Team.id == UUID(t_id_str)).first()
                    if team:
                        team_name = team.name
                except Exception:
                    pass

            return {
                "player_id": pid_str,
                "name": name,
                "team_name": team_name,
                "value": int(val)
            }

        scorers_list = []
        for pid_str, goals in sorted(player_goals.items(), key=lambda x: x[1], reverse=True):
            if goals > 0:
                info = resolve_player_info(pid_str, goals)
                if info:
                    scorers_list.append(info)
        scorers_list = scorers_list[:10]

        assists_list = []
        for pid_str, assists in sorted(player_assists.items(), key=lambda x: x[1], reverse=True):
            if assists > 0:
                info = resolve_player_info(pid_str, assists)
                if info:
                    assists_list.append(info)
        assists_list = assists_list[:10]

        ga_map = {}
        all_pids = set(player_goals.keys()).union(set(player_assists.keys()))
        for pid_str in all_pids:
            ga_map[pid_str] = player_goals.get(pid_str, 0) + player_assists.get(pid_str, 0)

        ga_list = []
        for pid_str, ga in sorted(ga_map.items(), key=lambda x: x[1], reverse=True):
            if ga > 0:
                info = resolve_player_info(pid_str, ga)
                if info:
                    g = player_goals.get(pid_str, 0)
                    a = player_assists.get(pid_str, 0)
                    info["display_value"] = f"{ga} ({g}+{a})"
                    ga_list.append(info)
        ga_list = ga_list[:10]

        final_result.append({
            "division_id": str(div.id),
            "division_name": getattr(div, 'name', 'Основной Дивизион'),
            "scorers": scorers_list,
            "assists": assists_list,
            "clean_sheets": [],
            "goal_plus_pass": ga_list
        })

    return final_result

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

def generate_playoffs_from_groups(db: Session, tournament_id: UUID):
    import json
    import uuid
    from datetime import timedelta, datetime
    from app.tournaments.models import TournamentGroup
    from app.matches.models import Match, MatchStatus
    from app.tournaments.models import TournamentStandings
    
    tournament = get_tournament_by_id(db, tournament_id)
    if tournament.format != TournamentFormat.GROUP_STAGE:
        raise HTTPException(status_code=400, detail="Playoffs can only be generated for GROUP_STAGE tournaments")
        
    # Check if all group stage matches are finished
    group_matches = db.query(Match).filter(
        Match.tournament_id == tournament_id,
        Match.group_id.isnot(None)
    ).all()
    
    if not group_matches:
        raise HTTPException(status_code=400, detail="No group stage matches found")
        
    for m in group_matches:
        if m.status != MatchStatus.FINISHED:
            raise HTTPException(
                status_code=400, 
                detail="Not all group stage matches are finished. Please finish all group matches before generating playoffs."
            )
            
    # Get groups
    groups = db.query(TournamentGroup).filter(TournamentGroup.tournament_id == tournament_id).all()
    if len(groups) != 2:
        raise HTTPException(status_code=400, detail="Playoff generation is currently optimized for exactly 2 groups")
        
    # Calculate group standings and sort
    group_standings = {}
    for grp in groups:
        standings = db.query(TournamentStandings).filter(
            TournamentStandings.tournament_id == tournament_id,
            TournamentStandings.group_id == grp.id
        ).order_by(
            TournamentStandings.points.desc(),
            TournamentStandings.goal_difference.desc(),
            TournamentStandings.goals_for.desc()
        ).all()
        if len(standings) < 2:
            raise HTTPException(status_code=400, detail=f"Group {grp.name} must have at least 2 teams")
        group_standings[grp.id] = [s.team_id for s in standings]
        
    # We sort groups alphabetically to distinguish Group A and Group B
    sorted_groups = sorted(groups, key=lambda g: g.name)
    group_a_id = sorted_groups[0].id
    group_b_id = sorted_groups[1].id
    
    # Seeding
    A1_id = group_standings[group_a_id][0]
    A2_id = group_standings[group_a_id][1]
    B1_id = group_standings[group_b_id][0]
    B2_id = group_standings[group_b_id][1]
    
    # Calculate start time for playoffs: same day afternoon
    match_duration = (tournament.match_half_duration * 2) + tournament.halftime_break_duration + tournament.break_between_matches
    last_match_date = max(m.match_date for m in group_matches if m.match_date is not None)
    playoff_start_date = last_match_date + timedelta(minutes=match_duration + 30)
    
    # Fields config
    field_ids = []
    if getattr(tournament, "field_ids", None):
        try:
            field_ids = json.loads(tournament.field_ids)
        except:
            pass
    num_fields = len(field_ids) if field_ids else tournament.num_fields
    if num_fields < 1: num_fields = 1
    
    # Clean up existing playoff matches (group_id = None)
    db.query(Match).filter(
        Match.tournament_id == tournament_id,
        Match.group_id.is_(None)
    ).delete(synchronize_session=False)
    db.commit()
    
    # Create SF and Final matches
    sf1_id = uuid.uuid4()
    sf2_id = uuid.uuid4()
    final_id = uuid.uuid4()
    third_place_id = uuid.uuid4()
    
    sf1_field = uuid.UUID(field_ids[0]) if field_ids else None
    sf2_field = uuid.UUID(field_ids[1 % num_fields]) if field_ids else None
    
    sf1_time = playoff_start_date
    # SF2 played after SF1 on same field, or same time on different field
    if num_fields > 1:
        sf2_time = playoff_start_date
    else:
        sf2_time = playoff_start_date + timedelta(minutes=match_duration)
        
    division_id = group_matches[0].division_id if group_matches else None
    
    # SF 1: A1 vs B2
    sf1 = Match(
        id=sf1_id,
        tournament_id=tournament_id,
        division_id=division_id,
        home_team_id=A1_id,
        away_team_id=B2_id,
        match_date=sf1_time,
        field_id=sf1_field,
        status=MatchStatus.DRAFT,
        round_number=1,
        bracket_position=0,
        next_match_id=final_id
    )
    # SF 2: B1 vs A2
    sf2 = Match(
        id=sf2_id,
        tournament_id=tournament_id,
        division_id=division_id,
        home_team_id=B1_id,
        away_team_id=A2_id,
        match_date=sf2_time,
        field_id=sf2_field,
        status=MatchStatus.DRAFT,
        round_number=1,
        bracket_position=1,
        next_match_id=final_id
    )
    
    # Final and 3rd place: same day, 30 mins after Semifinals finish
    final_date = playoff_start_date + timedelta(minutes=match_duration + 30)
        
    final_match = Match(
        id=final_id,
        tournament_id=tournament_id,
        division_id=division_id,
        home_team_id=None,
        away_team_id=None,
        match_date=final_date + timedelta(minutes=match_duration),
        field_id=sf1_field,
        status=MatchStatus.DRAFT,
        round_number=2,
        bracket_position=0
    )
    
    third_place_match = Match(
        id=third_place_id,
        tournament_id=tournament_id,
        division_id=division_id,
        home_team_id=None,
        away_team_id=None,
        match_date=final_date,
        field_id=sf1_field,
        status=MatchStatus.DRAFT,
        round_number=2,
        bracket_position=1
    )
    
    db.add_all([sf1, sf2, final_match, third_place_match])
    
    # Placement/consolation matches
    placement_matches_created = 0
    if getattr(tournament, "has_placement_matches", False):
        # 5th place match: A3 vs B3
        if len(group_standings[group_a_id]) >= 3 and len(group_standings[group_b_id]) >= 3:
            A3_id = group_standings[group_a_id][2]
            B3_id = group_standings[group_b_id][2]
            m5 = Match(
                id=uuid.uuid4(),
                tournament_id=tournament_id,
                division_id=division_id,
                home_team_id=A3_id,
                away_team_id=B3_id,
                match_date=sf1_time,
                field_id=uuid.UUID(field_ids[2 % num_fields]) if num_fields > 2 and field_ids else sf1_field,
                status=MatchStatus.DRAFT,
                round_number=1,
                bracket_position=2
            )
            db.add(m5)
            placement_matches_created += 1
            
        # 7th place match: A4 vs B4
        if len(group_standings[group_a_id]) >= 4 and len(group_standings[group_b_id]) >= 4:
            A4_id = group_standings[group_a_id][3]
            B4_id = group_standings[group_b_id][3]
            m7 = Match(
                id=uuid.uuid4(),
                tournament_id=tournament_id,
                division_id=division_id,
                home_team_id=A4_id,
                away_team_id=B4_id,
                match_date=sf2_time,
                field_id=uuid.UUID(field_ids[3 % num_fields]) if num_fields > 3 and field_ids else sf2_field,
                status=MatchStatus.DRAFT,
                round_number=1,
                bracket_position=3
            )
            db.add(m7)
            placement_matches_created += 1
            
    db.commit()
    
    return {
        "status": "success",
        "message": "Playoffs successfully generated from Group Stage standings.",
        "sf_count": 2,
        "final_count": 1,
        "third_place_count": 1,
        "placement_matches_count": placement_matches_created
    }
