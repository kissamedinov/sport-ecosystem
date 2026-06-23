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
    import json
    from datetime import timedelta
    
    tournament = get_tournament_by_id(db, tournament_id)
    approved_teams = db.query(TournamentTeam).filter(
        TournamentTeam.tournament_id == tournament_id,
        TournamentTeam.status == RegistrationStatus.APPROVED
    ).all()
    
    if len(approved_teams) < 2:
        raise HTTPException(status_code=400, detail="At least 2 approved teams needed to generate schedule")
    
    # Parse field_ids if they exist
    field_ids = []
    if getattr(tournament, "field_ids", None):
        try:
            field_ids = json.loads(tournament.field_ids)
        except:
            pass
    
    num_fields = len(field_ids) if field_ids else tournament.num_fields
    if num_fields < 1: num_fields = 1
    
    teams = [t.team_id for t in approved_teams]
    match_count = 0
    
    # Configuration for timing
    current_time = tournament.start_time or tournament.start_date
    if isinstance(current_time, str):
        from datetime import datetime
        current_time = datetime.fromisoformat(current_time)
        
    match_duration = (tournament.match_half_duration * 2) + tournament.halftime_break_duration + tournament.break_between_matches
    slot_index = 0
    
    # Simple Round Robin
    for i in range(len(teams)):
        for j in range(i + 1, len(teams)):
            # Calculate field and time slot
            field_slot = slot_index % num_fields
            time_offset = slot_index // num_fields
            
            match_start = current_time + timedelta(minutes=time_offset * match_duration)
            
            # Check if exceeds day's end_time
            if tournament.end_time:
                day_end = datetime.combine(match_start.date(), tournament.end_time.time())
                if match_start + timedelta(minutes=match_duration) > day_end:
                    # Move to next day
                    match_start = match_start + timedelta(days=1)
                    match_start = datetime.combine(match_start.date(), tournament.start_time.time() if tournament.start_time else match_start.time())
                    # Reset slot index or handle differently? 
                    # For simplicity, we just keep incrementing slot_index but adjust match_start
            
            field_uuid = None
            if field_ids:
                field_uuid = uuid.UUID(field_ids[field_slot])
            
            new_match = Match(
                tournament_id=tournament_id,
                division_id=approved_teams[0].division_id, 
                home_team_id=teams[i],
                away_team_id=teams[j],
                field_id=field_uuid,
                match_date=match_start,
                status=MatchStatus.DRAFT,
                round_number=1
            )
            db.add(new_match)
            match_count += 1
            slot_index += 1
    
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
            # For round r (1-indexed), the number of matches is K / 2**(r - 1) (if no prelims)
            # or K / 2**(r - 2) (if prelims)
            round_power = r - 1 if not has_preliminary else r - 2
            if round_power < 0:
                num_matches_in_round = K
            else:
                num_matches_in_round = K // (2**round_power)

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
    from datetime import timedelta
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
        
    db.flush()
    
    match_count = 0
    # Timing config
    current_time = tournament.start_time or tournament.start_date
    if isinstance(current_time, str):
        from datetime import datetime
        current_time = datetime.fromisoformat(current_time)
        
    match_duration = (tournament.match_half_duration * 2) + tournament.halftime_break_duration + tournament.break_between_matches
    slot_index = 0

    # Generate matches within each group
    for group_id, teams in group_teams.items():
        for i in range(len(teams)):
            for j in range(i + 1, len(teams)):
                field_slot = slot_index % num_fields
                time_offset = slot_index // num_fields
                match_start = current_time + timedelta(minutes=time_offset * match_duration)
                
                field_uuid = None
                if field_ids:
                    field_uuid = uuid.UUID(field_ids[field_slot])

                new_match = Match(
                    tournament_id=tournament_id,
                    division_id=approved_teams[0].division_id,
                    home_team_id=teams[i].team_id,
                    away_team_id=teams[j].team_id,
                    group_id=group_id,
                    field_id=field_uuid,
                    match_date=match_start,
                    status=MatchStatus.DRAFT,
                    round_number=1
                )
                db.add(new_match)
                match_count += 1
                slot_index += 1
                
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
    
    # Automatic playoff advancement logic
    if match.next_match_id:
        if home_score == away_score:
            raise HTTPException(
                status_code=400,
                detail="Playoff matches must have a winner. Draw scores are not allowed."
            )
        winner_id = match.home_team_id if home_score > away_score else match.away_team_id
        
        next_match = db.query(Match).filter(Match.id == match.next_match_id).first()
        if next_match:
            if match.bracket_position is not None:
                if match.bracket_position % 2 == 0:
                    next_match.home_team_id = winner_id
                else:
                    next_match.away_team_id = winner_id
                db.add(next_match)
                
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
            "group_id": s.group_id
        })
    return result

def get_tournament_matches(db: Session, tournament_id: UUID):
    matches = db.query(Match).filter(Match.tournament_id == tournament_id).order_by(Match.match_date).all()
    
    from app.teams.models import Team
    
    result_list = []
    for m in matches:
        # Get team names
        home_team = db.query(Team).filter(Team.id == m.home_team_id).first()
        away_team = db.query(Team).filter(Team.id == m.away_team_id).first()
        
        # Convert to dict and add names
        match_dict = {
            "id": m.id,
            "tournament_id": m.tournament_id,
            "division_id": m.division_id,
            "home_team_id": m.home_team_id,
            "away_team_id": m.away_team_id,
            "field_id": m.field_id,
            "match_date": m.match_date,
            "status": m.status,
            "group_id": m.group_id,
            "home_team_name": home_team.name if home_team else "Home Team",
            "away_team_name": away_team.name if away_team else "Away Team",
            "result": m.result
        }
        result_list.append(match_dict)
        
    return result_list

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
    from sqlalchemy import func, desc
    from app.tournaments.models import TournamentPlayerStats, TournamentDivision, TournamentSquad, TournamentTeam
    from app.users.models import PlayerProfile
    from app.teams.models import Team
    
    divisions = db.query(TournamentDivision).filter(TournamentDivision.tournament_edition_id == tournament_id).all()
    
    if not divisions:
        return []
    
    final_result = []

    def format_player_data(stats_list, div_id):
        result = []
        for stat in stats_list:
            if stat[1] == 0:
                continue
            player = db.query(PlayerProfile).filter(PlayerProfile.id == stat.player_profile_id).first()
            if not player:
                continue
            
            squad_entry = db.query(TournamentSquad).join(TournamentTeam).filter(
                TournamentSquad.player_profile_id == stat.player_profile_id,
                TournamentTeam.tournament_id == tournament_id
            ).first()
            
            team_name = "Unknown"
            if squad_entry and squad_entry.tournament_team:
                team = db.query(Team).filter(Team.id == squad_entry.tournament_team.team_id).first()
                if team:
                    team_name = team.name

            user_name = "Unknown Player"
            if player.user:
                user_name = player.user.name or f"{player.user.first_name} {player.user.last_name}"
                
            result.append({
                "player_id": str(stat.player_profile_id),
                "name": user_name,
                "team_name": team_name,
                "value": int(stat[1])
            })
        return result

    for div in divisions:
        div_id = div.id
        
        top_scorers = db.query(
            TournamentPlayerStats.player_profile_id,
            func.sum(TournamentPlayerStats.goals).label('total_goals')
        ).filter(
            TournamentPlayerStats.division_id == div_id
        ).group_by(
            TournamentPlayerStats.player_profile_id
        ).order_by(
            desc('total_goals')
        ).limit(10).all()

        top_assists = db.query(
            TournamentPlayerStats.player_profile_id,
            func.sum(TournamentPlayerStats.assists).label('total_assists')
        ).filter(
            TournamentPlayerStats.division_id == div_id
        ).group_by(
            TournamentPlayerStats.player_profile_id
        ).order_by(
            desc('total_assists')
        ).limit(10).all()

        top_clean_sheets = db.query(
            TournamentPlayerStats.player_profile_id,
            func.sum(TournamentPlayerStats.clean_sheets).label('total_clean_sheets')
        ).filter(
            TournamentPlayerStats.division_id == div_id
        ).group_by(
            TournamentPlayerStats.player_profile_id
        ).order_by(
            desc('total_clean_sheets')
        ).limit(10).all()

        top_goal_plus_pass = db.query(
            TournamentPlayerStats.player_profile_id,
            (func.sum(TournamentPlayerStats.goals) + func.sum(TournamentPlayerStats.assists)).label('total_ga')
        ).filter(
            TournamentPlayerStats.division_id == div_id
        ).group_by(
            TournamentPlayerStats.player_profile_id
        ).order_by(
            desc('total_ga')
        ).limit(10).all()

        final_result.append({
            "division_id": str(div.id),
            "division_name": div.name,
            "scorers": format_player_data(top_scorers, div_id),
            "assists": format_player_data(top_assists, div_id),
            "clean_sheets": format_player_data(top_clean_sheets, div_id),
            "goal_plus_pass": format_player_data(top_goal_plus_pass, div_id)
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
