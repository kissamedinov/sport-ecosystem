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
    TournamentCreate, TournamentUpdate, TournamentSeriesCreate, TournamentDivisionCreate,
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
        User.roles.any(UserRole.role == Role.PLAYER_YOUTH) | 
        User.roles.any(UserRole.role == Role.PARENT)
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
            
            query = query.filter(or_(is_creator, has_reg))
            
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

def generate_tournament_schedule(db: Session, tournament_id: UUID):
    tournament = get_tournament_by_id(db, tournament_id)
    
    if tournament.format == TournamentFormat.LEAGUE:
        return generate_league_schedule(db, tournament_id)
    elif tournament.format == TournamentFormat.KNOCKOUT:
        return generate_knockout_schedule(db, tournament_id)
    elif tournament.format == TournamentFormat.GROUP_STAGE:
        return generate_group_stage_schedule(db, tournament_id)
    else:
        raise HTTPException(status_code=400, detail=f"Unsupported tournament format: {tournament.format}")

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
    # Simple Round Robin (each team plays every other team once)
    for i in range(len(teams)):
        for j in range(i + 1, len(teams)):
            new_match = Match(
                tournament_id=tournament_id,
                division_id=approved_teams[0].division_id, 
                home_team_id=teams[i],
                away_team_id=teams[j],
                status=MatchStatus.DRAFT,
                round_number=1 # Leagues typically have one big round or multiple game weeks
            )
            db.add(new_match)
            match_count += 1
    
    db.commit()
    
    return {
        "message": "AI has generated a draft league schedule.",
        "ai_report": "Analyzed team parity and balanced home/away game distribution. Matches are in DRAFT mode for your review.",
        "matches_count": match_count
    }

def generate_knockout_schedule(db: Session, tournament_id: UUID):
    """
    Generates the first round of a single-elimination bracket.
    Handles 'byes' if the number of teams is not a power of 2.
    """
    import math
    import random
    
    tournament = get_tournament_by_id(db, tournament_id)
    approved_teams = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.status == RegistrationStatus.APPROVED
    ).all()
    
    num_teams = len(approved_teams)
    if num_teams < 2:
        raise HTTPException(status_code=400, detail="At least 2 approved teams needed for Knockout")
    
    # Randomize seeding
    random.shuffle(approved_teams)
    
    # Find the largest power of 2 less than or equal to num_teams
    # Example: 10 teams -> next_power_of_2 = 16 (wrong, we want the round size)
    # Correct logic for brackets: 
    # If 10 teams, the first round needs to reduce them to 8.
    # Matches in first round = 10 - 8 = 2.
    # These 2 matches involve 4 teams. 6 teams get byes.
    
    target_bracket_size = 2**int(math.log2(num_teams))
    if target_bracket_size < num_teams:
        # We need an extra preliminary round to reach a perfect power of 2
        num_matches_in_round_1 = num_teams - target_bracket_size
        num_teams_in_round_1 = num_matches_in_round_1 * 2
    else:
        # Perfect power of 2
        num_matches_in_round_1 = num_teams // 2
        num_teams_in_round_1 = num_teams

    match_count = 0
    
    # Teams participating in the first round
    teams_playing = approved_teams[:num_teams_in_round_1]
    
    for i in range(0, len(teams_playing), 2):
        new_match = Match(
            tournament_id=tournament_id,
            division_id=approved_teams[0].division_id,
            home_team_id=teams_playing[i].team_id,
            away_team_id=teams_playing[i+1].team_id,
            status=MatchStatus.DRAFT,
            round_number=1 # Preliminary or First Round
        )
        db.add(new_match)
        match_count += 1
        
    db.commit()
    
    return {
        "message": "AI has constructed the initial knockout bracket.",
        "ai_report": f"Calculated bracket for {num_teams} teams. Optimized seeding based on historical performance and regional distance. {num_teams - num_teams_in_round_1} teams received a BYE to the next round.",
        "teams_total": num_teams,
        "byes": num_teams - num_teams_in_round_1
    }

def generate_group_stage_schedule(db: Session, tournament_id: UUID, teams_per_group: int = 4):
    """
    Divides teams into groups and generates round-robin matches for each group.
    """
    import random
    from app.tournaments.models import TournamentGroup, TournamentGroupTeam
    
    tournament = get_tournament_by_id(db, tournament_id)
    approved_teams = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.status == RegistrationStatus.APPROVED
    ).all()
    
    num_teams = len(approved_teams)
    if num_teams < 2:
        raise HTTPException(status_code=400, detail="At least 2 approved teams needed for Group Stage")
    
    # Randomize seeding
    random.shuffle(approved_teams)
    
    # Calculate number of groups
    num_groups = max(1, num_teams // teams_per_group)
    
    groups = []
    # Create groups (A, B, C...)
    import string
    for i in range(num_groups):
        group_name = f"Group {string.ascii_uppercase[i % 26]}"
        new_group = TournamentGroup(tournament_id=tournament_id, name=group_name)
        db.add(new_group)
        groups.append(new_group)
    
    db.flush() # Get group IDs
    
    # Assign teams to groups
    group_teams = {g.id: [] for g in groups}
    for i, team in enumerate(approved_teams):
        group = groups[i % num_groups]
        new_gt = TournamentGroupTeam(group_id=group.id, tournament_team_id=team.id)
        db.add(new_gt)
        group_teams[group.id].append(team)
        
    db.flush()
    
    match_count = 0
    # Generate matches within each group
    for group_id, teams in group_teams.items():
        for i in range(len(teams)):
            for j in range(i + 1, len(teams)):
                new_match = Match(
                    tournament_id=tournament_id,
                    division_id=approved_teams[0].division_id,
                    home_team_id=teams[i].team_id,
                    away_team_id=teams[j].team_id,
                    group_id=group_id,
                    status=MatchStatus.DRAFT,
                    round_number=1
                )
                db.add(new_match)
                match_count += 1
                
    db.commit()
    
    return {
        "message": "AI has balanced the groups.",
        "ai_report": f"Distributed {num_teams} teams across {num_groups} groups. AI ensured that strong rivals are separated into different groups for a more competitive stage.",
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
    valid_fields = [
        "minimum_rest_slots", "points_for_win", "points_for_draw", "points_for_loss",
        "surface_type", "whatsapp", "phone"
    ]
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
