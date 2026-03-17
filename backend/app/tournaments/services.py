from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List
from uuid import UUID
from datetime import date

from app.tournaments.models import (
    Tournament, TournamentRegistration, RegistrationStatus, TournamentTeam, 
    TournamentStandings, TournamentMatch, TournamentFormat, MatchStatus, 
    TournamentSquad, TournamentMatchPlayerStats, TournamentSeries, TournamentDivision,
    MatchSheet, MatchSheetPlayer, TournamentPlayerStats, TournamentAward
)
from app.tournaments.schemas import (
    TournamentCreate, TournamentSeriesCreate, TournamentDivisionCreate,
    MatchSheetCreate, TournamentAwardCreate
)
from app.users.models import User, Role, PlayerProfile
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
    # Find all players and parents who match the age category
    # This is a broad notification. For simplicity, we notify everyone with PLAYER_YOUTH or PARENT role.
    # In a real app, we would filter by age and child's age.
    eligible_roles = [Role.PLAYER_YOUTH, Role.PARENT]
    users_to_notify = db.query(User).filter(User.roles.any(role=Role.PLAYER_YOUTH) | User.roles.any(role=Role.PARENT)).all()
    
    for user in users_to_notify:
        notification_service.create_notification(
            db,
            user.id,
            notification_type=NotificationType.TOURNAMENT_START, # Assuming this is available or use another
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
    
    # Requirement: Only COACH or TEAM_OWNER can register teams.
    from app.teams.models import Team, Academy
    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
        
    user_roles = {ur.role for ur in current_user.roles}
    is_coach = Role.COACH in user_roles and team.coach_id == current_user.id
    is_owner = Role.TEAM_OWNER in user_roles and team.academy_id and db.query(Academy).filter(Academy.id == team.academy_id, Academy.owner_id == current_user.id).first()
    
    if not (is_coach or is_owner):
        raise HTTPException(status_code=403, detail="Operation not permitted. Only the team's coach or owner can register it.")
    
    # Check registration dates
    today = date.today()
    if today < tournament.registration_open or today > tournament.registration_close:
        raise HTTPException(status_code=400, detail="Registration is closed or not yet open")
    
    # Age Category validation (Birth Year check)
    if team.birth_year and team.birth_year != division.birth_year:
         raise HTTPException(
            status_code=400, 
            detail=f"Team birth year ({team.birth_year}) does not match division requirement ({division.birth_year})"
        )
    
    # Check if already registered in this division
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
    
    # Requirement: Notify Coach when team is accepted (APPROVED)
    if status == RegistrationStatus.APPROVED:
        from app.teams.models import Team
        team = db.query(Team).filter(Team.id == team_id).first()
        notification_service.create_notification(
            db,
            team.coach_id,
            notification_type=NotificationType.BOOKING_APPROVED, # Using existing type or TOURNAMENT_START
            title="Team Accepted!",
            message=f"Your team {team.name} has been approved for {tournament.name}.",
            entity_type=EntityType.TOURNAMENT,
            entity_id=tournament_id
        )
    
    # If approved, initialize standings for this team if not exists
    if status == RegistrationStatus.APPROVED:
        existing_standing = db.query(TournamentStandings).filter(
            TournamentStandings.tournament_id == tournament_id,
            TournamentStandings.team_id == team_id
        ).first()
        if not existing_standing:
            new_standing = TournamentStandings(
                tournament_id=tournament_id,
                team_id=team_id
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
    
    # Notify Team (simplified: notifying the coach of the team)
    # We need to fetch team to get coach_id
    from app.teams.models import Team
    team = db.query(Team).filter(Team.id == reg.team_id).first()
    notification_service.create_notification(
        db,
        team.coach_id,
        notification_type=NotificationType.BOOKING_APPROVED, # Re-using approved status or better TOURNAMENT_START if we had it
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
    
    # Simple Round Robin (Every team plays every other team once)
    teams = [t.team_id for t in approved_teams]
    match_count = 0
    for i in range(len(teams)):
        for j in range(i + 1, len(teams)):
            new_match = TournamentMatch(
                tournament_id=tournament_id,
                home_team_id=teams[i],
                away_team_id=teams[j],
                status=MatchStatus.SCHEDULED
            )
            db.add(new_match)
            match_count += 1
    
    db.commit()
    
    # Notify involved parties
    from app.notifications.match_notifications import notify_match_scheduled
    # We need to refresh or fetch the matches to get their IDs if they were just added
    # For simplicity, we'll re-query
    matches = db.query(TournamentMatch).filter(TournamentMatch.tournament_id == tournament_id).all()
    for m in matches:
        notify_match_scheduled(db, m.id)

    return {"matches_generated": match_count}

def update_match_result(db: Session, match_id: UUID, home_score: int, away_score: int):
    match = db.query(TournamentMatch).filter(TournamentMatch.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    match.home_score = home_score
    match.away_score = away_score
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
    
    # Calculate stats from finished matches
    home_matches = db.query(TournamentMatch).filter(
        TournamentMatch.tournament_id == tournament_id,
        TournamentMatch.home_team_id == team_id,
        TournamentMatch.status == MatchStatus.FINISHED
    ).all()
    
    away_matches = db.query(TournamentMatch).filter(
        TournamentMatch.tournament_id == tournament_id,
        TournamentMatch.away_team_id == team_id,
        TournamentMatch.status == MatchStatus.FINISHED
    ).all()
    
    played = 0
    wins = 0
    draws = 0
    losses = 0
    gf = 0
    ga = 0
    
    for m in home_matches:
        played += 1
        gf += m.home_score
        ga += m.away_score
        if m.home_score > m.away_score: wins += 1
        elif m.home_score == m.away_score: draws += 1
        else: losses += 1
        
    for m in away_matches:
        played += 1
        gf += m.away_score
        ga += m.home_score
        if m.away_score > m.home_score: wins += 1
        elif m.away_score == m.home_score: draws += 1
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
    return db.query(TournamentMatch).filter(TournamentMatch.tournament_id == tournament_id).order_by(TournamentMatch.start_time).all()

def add_player_to_tournament_squad(db: Session, tournament_team_id: UUID, player_id: UUID):
    # Check for profile
    profile = db.query(PlayerProfile).filter(PlayerProfile.user_id == player_id).first()
    if not profile:
        profile = PlayerProfile(user_id=player_id)
        db.add(profile)
        db.flush()

    new_squad_member = TournamentSquad(
        tournament_team_id=tournament_team_id,
        player_profile_id=profile.id
    )
    db.add(new_squad_member)
    db.commit()
    return new_squad_member

def record_match_player_stats(db: Session, match_id: UUID, player_profile_id: UUID, stats: dict):
    # Requirement: Enable player statistics tracking per match
    db_stats = db.query(TournamentMatchPlayerStats).filter(
        TournamentMatchPlayerStats.match_id == match_id,
        TournamentMatchPlayerStats.player_profile_id == player_profile_id
    ).first()
    
    is_new = False
    if not db_stats:
        db_stats = TournamentMatchPlayerStats(
            match_id=match_id,
            player_profile_id=player_profile_id
        )
        db.add(db_stats)
        is_new = True
    
    # Store old values for diff update
    old_goals = db_stats.goals if not is_new else 0
    old_assists = db_stats.assists if not is_new else 0
    old_yellow = db_stats.yellow_cards if not is_new else 0
    old_red = db_stats.red_cards if not is_new else 0
    
    db_stats.goals = stats.get("goals", 0)
    db_stats.assists = stats.get("assists", 0)
    db_stats.yellow_cards = stats.get("yellow_cards", 0)
    db_stats.red_cards = stats.get("red_cards", 0)
    db_stats.is_goalkeeper = stats.get("is_goalkeeper", False)
    
    db.commit()
    db.refresh(db_stats)
    
    # Update Division Aggregated Stats
    update_tournament_player_stats(
        db, 
        db_stats.match.division_id, 
        player_profile_id, 
        goals_diff=db_stats.goals - old_goals,
        assists_diff=db_stats.assists - old_assists,
        matches_diff=1 if is_new else 0,
        yellow_diff=db_stats.yellow_cards - old_yellow,
        red_diff=db_stats.red_cards - old_red
    )
    
    return db_stats

def update_tournament_player_stats(
    db: Session, 
    division_id: UUID, 
    player_profile_id: UUID, 
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
        TournamentPlayerStats.player_profile_id == player_profile_id
    ).first()
    
    if not agg_stats:
        agg_stats = TournamentPlayerStats(
            division_id=division_id,
            player_profile_id=player_profile_id
        )
        db.add(agg_stats)
    
    agg_stats.goals += goals_diff
    agg_stats.assists += assists_diff
    agg_stats.matches_played += matches_diff
    agg_stats.yellow_cards += yellow_diff
    agg_stats.red_cards += red_diff
    agg_stats.clean_sheets += clean_sheets_diff
    
    db.commit()

def submit_match_sheet(db: Session, sheet_in: MatchSheetCreate, current_user: User):
    match = db.query(TournamentMatch).filter(TournamentMatch.id == sheet_in.match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
        
    # Validation: Only team coach can submit
    from app.teams.models import Team
    team = db.query(Team).filter(Team.id == sheet_in.team_id).first()
    if team.coach_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the team's coach can submit the match sheet")
        
    new_sheet = MatchSheet(
        match_id=sheet_in.match_id,
        team_id=sheet_in.team_id,
        submitted_by=current_user.id
    )
    db.add(new_sheet)
    db.flush()
    
    for p in sheet_in.players:
        sheet_player = MatchSheetPlayer(
            match_sheet_id=new_sheet.id,
            player_profile_id=p.player_profile_id,
            jersey_number=p.jersey_number,
            is_starting=p.is_starting
        )
        db.add(sheet_player)
        
    db.commit()
    db.refresh(new_sheet)
    return new_sheet

def assign_tournament_award(db: Session, award_in: TournamentAwardCreate):
    new_award = TournamentAward(**award_in.model_dump())
    db.add(new_award)
    db.commit()
    db.refresh(new_award)
    
    # Requirement: Trigger notification for awards
    # Notify Player
    from app.users.models import User, ParentChildRelation
    player_user = db.query(User).filter(User.id == new_award.player_profile.user_id).first()
    if player_user:
        notification_service.create_notification(
            db,
            player_user.id,
            notification_type=NotificationType.BOOKING_APPROVED, # Or a generic ACHIEVEMENT type
            title="New Award!",
            message=f"Congratulations! You've been awarded: {new_award.title}",
            entity_type=EntityType.PLAYER,
            entity_id=new_award.player_profile_id
        )
        
        # Notify Parent
        parent_relations = db.query(ParentChildRelation).filter(ParentChildRelation.child_id == player_user.id).all()
        for rel in parent_relations:
            notification_service.create_notification(
                db,
                rel.parent_id,
                notification_type=NotificationType.BOOKING_APPROVED,
                title="Child Achievement!",
                message=f"Your child {player_user.name} has received an award: {new_award.title}",
                entity_type=EntityType.PLAYER,
                entity_id=new_award.player_profile_id
            )
            
    return new_award

def get_player_awards(db: Session, player_profile_id: UUID):
    return db.query(TournamentAward).filter(TournamentAward.player_profile_id == player_profile_id).all()

def get_match_player_stats(db: Session, match_id: UUID):
    return db.query(TournamentMatchPlayerStats).filter(TournamentMatchPlayerStats.match_id == match_id).all()
def add_to_tournament_squad(db: Session, tt_id: UUID, squad_in: TournamentSquadCreate, current_user: User):
    tt = db.query(TournamentTeam).filter(TournamentTeam.id == tt_id).first()
    if not tt:
        raise HTTPException(status_code=404, detail="Tournament team registration not found")
        
    # Check if user is the coach of the team
    from app.teams.models import Team
    team = db.query(Team).filter(Team.id == tt.team_id).first()
    if team.coach_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the coach can manage the tournament squad")
        
    for p in squad_in.players:
        # Check if already in squad
        existing = db.query(TournamentSquad).filter(
            TournamentSquad.tournament_team_id == tt_id,
            TournamentSquad.player_profile_id == p.player_profile_id
        ).first()
        
        if existing:
            existing.jersey_number = p.jersey_number
            existing.position = p.position
        else:
            new_member = TournamentSquad(
                tournament_team_id=tt_id,
                player_profile_id=p.player_profile_id,
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
    # auth check same as above
    from app.teams.models import Team
    team = db.query(Team).filter(Team.id == tt.team_id).first()
    if team.coach_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the coach can manage the tournament squad")
        
    db.query(TournamentSquad).filter(
        TournamentSquad.tournament_team_id == tt_id,
        TournamentSquad.player_profile_id == profile_id
    ).delete()
    db.commit()
    return {"message": "Player removed from squad"}
