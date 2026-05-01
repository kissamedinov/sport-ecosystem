from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import date, timedelta, datetime
import calendar
from app.teams.models import Team, TeamMembership, MembershipRole, MembershipStatus
from app.academies.models import (
    Academy, AcademyRanking, AcademyPlayer, 
    TrainingSession, TrainingAttendance, 
    CoachFeedback, TrainingSchedule, AcademyBranch, AcademyBillingConfig, DayOfWeek, AttendanceStatus
)
from app.users.models import User, PlayerProfile
from app.clubs.models import Club
from app.tournaments.models import TournamentStandings
from app.academies import schemas

def calculate_academy_rankings(db: Session, tournament_id: str):
    """
    Recalculates academy rankings after a tournament.
    Points are distributed to the academy based on their teams' final rank.
    1st: 100, 2nd: 70, 3rd: 50, 4th: 30
    Only the top 4 teams are rewarded.
    """
    
    # 1. Get final standings for the tournament
    standings = db.query(TournamentStandings).filter(
        TournamentStandings.tournament_id == tournament_id
    ).order_by(
        TournamentStandings.points.desc(),
        TournamentStandings.goal_difference.desc(),
        TournamentStandings.goals_for.desc()
    ).all()
    
    if not standings:
        return

    point_distribution = {0: 100, 1: 70, 2: 50, 3: 30}
    academy_points_gained = {}

    for index, standing in enumerate(standings[:4]):
        points_to_award = point_distribution.get(index, 0)
        academy_team = db.query(Team).filter(Team.id == standing.team.id).first() 
        if academy_team:
            acc_id = academy_team.academy_id
            academy_points_gained[acc_id] = academy_points_gained.get(acc_id, 0) + points_to_award

    for acc_id, points in academy_points_gained.items():
        ranking = db.query(AcademyRanking).filter(AcademyRanking.academy_id == acc_id).first()
        if not ranking:
            ranking = AcademyRanking(academy_id=acc_id)
            db.add(ranking)
        
        ranking.points += points
        ranking.tournaments_played += 1
        if points == 100:
            ranking.tournaments_won += 1
            
    db.commit()

# --- Academy Management ---

def create_academy(db: Session, academy_in: schemas.AcademyCreate, owner_id: UUID) -> Academy:
    new_academy = Academy(
        name=academy_in.name,
        city=academy_in.city,
        address=academy_in.address,
        description=academy_in.description,
        owner_id=owner_id
    )
    db.add(new_academy)
    db.commit()
    db.refresh(new_academy)
    return new_academy

# --- Academy Branches ---

def create_academy_branch(db: Session, academy_id: UUID, branch_in: schemas.AcademyBranchCreate) -> AcademyBranch:
    new_branch = AcademyBranch(
        academy_id=academy_id,
        name=branch_in.name,
        address=branch_in.address,
        description=branch_in.description
    )
    db.add(new_branch)
    db.commit()
    db.refresh(new_branch)
    return new_branch

def get_academy_branches(db: Session, academy_id: UUID) -> List[AcademyBranch]:
    return db.query(AcademyBranch).filter(AcademyBranch.academy_id == academy_id).all()

def get_user_related_academy(db: Session, user_id: UUID) -> Optional[Academy]:
    print(f"[DEBUG] Fetching academy for user: {user_id}")
    # 1. Check if owner
    academy = db.query(Academy).filter(Academy.owner_id == user_id).first()
    if academy:
        print(f"[DEBUG] Found academy via direct ownership: {academy.id}")
        return academy
    
    # 2. Check if owner of a club that has academies
    print(f"[DEBUG] Checking club ownership...")
    club = db.query(Club).filter(Club.owner_id == user_id).first()
    if club:
        print(f"[DEBUG] Found club: {club.id}, looking for its academies...")
        academy = db.query(Academy).filter(Academy.club_id == club.id).first()
        if academy:
            print(f"[DEBUG] Found academy via club: {academy.id}")
            return academy
    
    # 3. Check if coach of any team in any academy
    print(f"[DEBUG] Checking coach status...")
    team = db.query(Team).filter(Team.coach_id == user_id).first()
    if team:
        print(f"[DEBUG] Found team coached by user (via AcademyTeam): {team.id}")
        return db.query(Academy).filter(Academy.id == team.academy_id).first()
        
    print("[DEBUG] No academy found for this user.")
    return None

def get_academy_teams(db: Session, academy_id: UUID, user_id: Optional[UUID] = None) -> List[Team]:
    from app.clubs.models import Club
    
    # If user_id provided, check if they are a club owner
    if user_id:
        club = db.query(Club).filter(Club.owner_id == user_id).first()
        if club:
            # Aggregate teams from ALL academies of this club
            return db.query(Team).join(Academy).filter(Academy.club_id == club.id).all()
            
    return db.query(Team).filter(Team.academy_id == academy_id).all()

def create_academy_team(db: Session, academy_id: UUID, team_in: schemas.AcademyTeamCreate) -> Team:
    new_team = Team(
        academy_id=academy_id,
        name=team_in.name,
        age_category=team_in.age_group,
        coach_id=team_in.coach_id
    )
    db.add(new_team)
    db.commit()
    db.refresh(new_team)
    return new_team

def get_academy_players(db: Session, academy_id: UUID, user_id: Optional[UUID] = None) -> List[AcademyPlayer]:
    from app.clubs.models import Club
    
    if user_id:
        club = db.query(Club).filter(Club.owner_id == user_id).first()
        if club:
            # Aggregate players from ALL academies of this club
            return db.query(AcademyPlayer).join(Academy).filter(Academy.club_id == club.id).all()

    return db.query(AcademyPlayer).filter(AcademyPlayer.academy_id == academy_id).all()

def add_player_to_academy(db: Session, academy_id: UUID, player_in: schemas.AcademyPlayerCreate) -> AcademyPlayer:
    # Get user_id from profile
    profile = db.query(PlayerProfile).filter(PlayerProfile.id == player_in.player_profile_id).first()
    if not profile:
        raise Exception("Player profile not found")
    
    # Check if already in academy
    existing = db.query(AcademyPlayer).filter(AcademyPlayer.academy_id == academy_id, AcademyPlayer.player_profile_id == player_in.player_profile_id).first()
    if existing:
        return existing

    new_player = AcademyPlayer(
        academy_id=academy_id,
        player_id=profile.user_id,
        player_profile_id=player_in.player_profile_id,
        status=player_in.status
    )
    db.add(new_player)
    
    # Also ensure they are in the club staff if academy belongs to a club
    academy = db.query(Academy).filter(Academy.id == academy_id).first()
    if academy and academy.club_id:
        from app.clubs.models import ClubStaff, ClubRole, ClubMembershipStatus
        staff_exists = db.query(ClubStaff).filter(ClubStaff.club_id == academy.club_id, ClubStaff.user_id == profile.user_id).first()
        if not staff_exists:
            new_staff = ClubStaff(
                club_id=academy.club_id,
                user_id=profile.user_id,
                role=ClubRole.PLAYER,
                status=ClubMembershipStatus.ACTIVE
            )
            db.add(new_staff)
            
    db.commit()
    db.refresh(new_player)
    return new_player

def get_academy_team_players(db: Session, team_id: UUID) -> List[TeamMembership]:
    return db.query(TeamMembership).filter(TeamMembership.team_id == team_id, TeamMembership.status == MembershipStatus.ACTIVE).all()

def add_player_to_team(db: Session, team_id: UUID, player_in: schemas.AcademyTeamPlayerCreate) -> TeamMembership:
    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        raise Exception("Team not found")
    
    # Ensure player is in academy registry
    add_player_to_academy(db, team.academy_id, schemas.AcademyPlayerCreate(player_profile_id=player_in.player_profile_id))

    # Check if already in team
    existing = db.query(TeamMembership).filter(TeamMembership.team_id == team_id, TeamMembership.player_profile_id == player_in.player_profile_id).first()
    if existing:
        existing.status = MembershipStatus.ACTIVE
        db.commit()
        return existing

    profile = db.query(PlayerProfile).filter(PlayerProfile.id == player_in.player_profile_id).first()
    new_team_player = TeamMembership(
        team_id=team_id,
        player_id=profile.user_id if profile else None,
        player_profile_id=player_in.player_profile_id,
        jersey_number=player_in.jersey_number,
        status=MembershipStatus.ACTIVE
    )
    db.add(new_team_player)
    db.commit()
    db.refresh(new_team_player)
    return new_team_player

def create_training_session(db: Session, academy_id: UUID, coach_id: UUID, session_in: schemas.TrainingSessionCreate) -> TrainingSession:
    new_session = TrainingSession(
        academy_id=academy_id,
        coach_id=coach_id,
        date=session_in.date,
        start_time=session_in.start_time,
        end_time=session_in.end_time,
        description=session_in.description
    )
    # Link teams
    if session_in.team_ids:
        teams = db.query(Team).filter(Team.id.in_(session_in.team_ids)).all()
        new_session.teams = teams

    db.add(new_session)
    db.commit()
    db.refresh(new_session)
    return new_session

def get_training_sessions(db: Session, academy_id: UUID, team_id: Optional[UUID] = None) -> List[TrainingSession]:
    query = db.query(TrainingSession).filter(TrainingSession.academy_id == academy_id)
    if team_id:
        query = query.join(TrainingSession.teams).filter(Team.id == team_id) # Need import Team inside or top
    return query.all()

def record_attendance(db: Session, attendance_in: schemas.TrainingAttendanceCreate) -> TrainingAttendance:
    attendance = db.query(TrainingAttendance).filter(
        TrainingAttendance.training_id == attendance_in.training_id,
        TrainingAttendance.player_id == attendance_in.player_id
    ).first()
    
    if attendance:
        attendance.status = attendance_in.status
        attendance.note = attendance_in.note
    else:
        attendance = TrainingAttendance(
            training_id=attendance_in.training_id,
            player_id=attendance_in.player_id,
            status=attendance_in.status,
            note=attendance_in.note
        )
        db.add(attendance)
    
    db.commit()
    db.refresh(attendance)
    return attendance

def record_attendance_batch(db: Session, batch_in: schemas.TrainingAttendanceBatchCreate) -> List[TrainingAttendance]:
    """
    Creates or updates multiple attendance records in a single transaction.
    """
    results = []
    for record in batch_in.records:
        attendance = db.query(TrainingAttendance).filter(
            TrainingAttendance.training_id == batch_in.training_id,
            TrainingAttendance.player_id == record.player_id
        ).first()
        
        if attendance:
            attendance.status = record.status
            attendance.note = record.note
        else:
            attendance = TrainingAttendance(
                training_id=batch_in.training_id,
                player_id=record.player_id,
                status=record.status,
                note=record.note
            )
            db.add(attendance)
        results.append(attendance)
    
    db.commit()
    return results

def submit_feedback(db: Session, coach_id: UUID, feedback_in: schemas.CoachFeedbackCreate) -> CoachFeedback:
    feedback = CoachFeedback(
        player_id=feedback_in.player_id,
        coach_id=coach_id,
        academy_id=feedback_in.academy_id,
        technical=feedback_in.technical,
        tactical=feedback_in.tactical,
        physical=feedback_in.physical,
        discipline=feedback_in.discipline,
        comment=feedback_in.comment
    )
    db.add(feedback)
    db.commit()
    db.refresh(feedback)
    return feedback

# --- CRM Features (Schedules, Movements, Billing) ---

def create_training_schedule(db: Session, academy_id: UUID, schedule_in: schemas.TrainingScheduleCreate) -> TrainingSchedule:
    new_schedule = TrainingSchedule(
        academy_id=academy_id,
        branch_id=schedule_in.branch_id,
        day_of_week=schedule_in.day_of_week,
        start_time=schedule_in.start_time,
        end_time=schedule_in.end_time,
        location=schedule_in.location
    )
    # Link teams
    if schedule_in.team_ids:
        teams = db.query(Team).filter(Team.id.in_(schedule_in.team_ids)).all()
        new_schedule.teams = teams

    db.add(new_schedule)
    db.commit()
    db.refresh(new_schedule)
    return new_schedule

def create_training_schedules_batch(db: Session, academy_id: UUID, batch_in: schemas.TrainingScheduleBatchCreate) -> List[TrainingSchedule]:
    results = []
    for sched_in in batch_in.schedules:
        new_sched = create_training_schedule(db, academy_id, sched_in)
        results.append(new_sched)
    return results

def get_academy_schedules(db: Session, academy_id: UUID, team_id: Optional[UUID] = None) -> List[TrainingSchedule]:
    query = db.query(TrainingSchedule).filter(TrainingSchedule.academy_id == academy_id)
    if team_id:
        query = query.join(TrainingSchedule.teams).filter(Team.id == team_id)
    return query.all()

def delete_training_schedule(db: Session, schedule_id: UUID) -> bool:
    schedule = db.query(TrainingSchedule).filter(TrainingSchedule.id == schedule_id).first()
    if schedule:
        db.delete(schedule)
        db.commit()
        return True
    return False

def generate_sessions_from_schedules(db: Session, academy_id: UUID, start_date: date, end_date: date) -> int:
    """
    Generates single TrainingSession records from recurring schedules for a date range.
    """
    schedules = db.query(TrainingSchedule).filter(TrainingSchedule.academy_id == academy_id).all()
    sessions_created = 0

    # Map enum to python weekday (Monday=0, Sunday=6)
    day_map = {
        DayOfWeek.MONDAY: 0,
        DayOfWeek.TUESDAY: 1,
        DayOfWeek.WEDNESDAY: 2,
        DayOfWeek.THURSDAY: 3,
        DayOfWeek.FRIDAY: 4,
        DayOfWeek.SATURDAY: 5,
        DayOfWeek.SUNDAY: 6
    }

    current_day = start_date
    while current_day <= end_date:
        weekday = current_day.weekday()
        for sched in schedules:
            if day_map.get(sched.day_of_week) == weekday:
                # For multi-team, check if a session with SAME teams/time/date exists
                # Simplifying: check if ANY session at that academy/time/date exists for these teams
                exists = db.query(TrainingSession).filter(
                    TrainingSession.academy_id == academy_id,
                    TrainingSession.date == current_day,
                    TrainingSession.start_time == sched.start_time
                ).first()
                
                if not exists:
                    # Fallback to academy owner if no teams/coaches specified
                    academy = db.query(Academy).filter(Academy.id == academy_id).first()
                    default_coach_id = academy.owner_id if academy else None
                    
                    if sched.teams and sched.teams[0].coach_id:
                        default_coach_id = sched.teams[0].coach_id

                    if not default_coach_id:
                        continue # Cannot create session without a coach

                    new_session = TrainingSession(
                        academy_id=academy_id,
                        coach_id=default_coach_id,
                        date=current_day,
                        start_time=sched.start_time,
                        end_time=sched.end_time,
                        description=f"Automated session from schedule"
                    )
                    new_session.teams = list(sched.teams)
                    db.add(new_session)
                    sessions_created += 1
        current_day += timedelta(days=1)
    
    db.commit()
    return sessions_created

def move_player_between_teams(db: Session, player_profile_id: UUID, target_team_id: UUID) -> Optional[TeamMembership]:
    # Remove from existing academy teams if any
    db.query(TeamMembership).filter(TeamMembership.player_profile_id == player_profile_id).update(dict(status=MembershipStatus.LEFT))
    
    # Add to new team
    new_team_player = TeamMembership(
        team_id=target_team_id,
        player_profile_id=player_profile_id
    )
    db.add(new_team_player)
    db.commit()
    db.refresh(new_team_player)
    return new_team_player

def get_billing_configuration(db: Session, academy_id: UUID) -> Optional[AcademyBillingConfig]:
    return db.query(AcademyBillingConfig).filter(AcademyBillingConfig.academy_id == academy_id).first()

def update_billing_configuration(db: Session, academy_id: UUID, config_in: schemas.AcademyBillingConfigCreate) -> AcademyBillingConfig:
    config = db.query(AcademyBillingConfig).filter(AcademyBillingConfig.academy_id == academy_id).first()
    if not config:
        config = AcademyBillingConfig(academy_id=academy_id)
        db.add(config)
    
    config.monthly_subscription_fee = config_in.monthly_subscription_fee
    config.per_session_fee = config_in.per_session_fee
    config.currency = config_in.currency
    
    db.commit()
    db.refresh(config)
    return config

def get_player_billing_summary(db: Session, academy_id: UUID, player_id: UUID, month: int, year: int) -> schemas.BillingSummary:
    """
    Calculates billing based on attendance for a specific month.
    """
    # 1. Get attendance
    start_date = date(year, month, 1)
    _, last_day = calendar.monthrange(year, month)
    end_date = date(year, month, last_day)

    attendance_records = db.query(TrainingAttendance).join(TrainingSession).filter(
        TrainingSession.academy_id == academy_id,
        TrainingAttendance.player_id == player_id,
        TrainingSession.date >= start_date,
        TrainingSession.date <= end_date
    ).all()

    summary = {
        "total_sessions": len(attendance_records),
        "present": sum(1 for r in attendance_records if r.status == AttendanceStatus.PRESENT),
        "absent": sum(1 for r in attendance_records if r.status == AttendanceStatus.ABSENT),
        "late": sum(1 for r in attendance_records if r.status == AttendanceStatus.LATE),
        "injured": sum(1 for r in attendance_records if r.status == AttendanceStatus.INJURED),
    }

    # 2. Get billing config
    config = get_billing_configuration(db, academy_id)
    monthly_fee = config.monthly_subscription_fee if config and config.monthly_subscription_fee else 0.0
    per_session_fee = config.per_session_fee if config and config.per_session_fee else 0.0
    
    # Calculate additional fees from per-session attendance if no monthly subscription
    attendance_cost = summary["present"] * per_session_fee if not monthly_fee else 0.0
    
    # Get user name
    user = db.query(User).filter(User.id == player_id).first()
    
    return schemas.BillingSummary(
        player_id=player_id,
        player_name=user.name if user else "Unknown",
        attendance=schemas.AttendanceSummary(**summary),
        base_fee=monthly_fee,
        additional_fees=attendance_cost,
        total_owed=monthly_fee + attendance_cost,
        currency=config.currency if config else "KZT"
    )

def get_players_activities(db: Session, player_ids: List[UUID]) -> List[TrainingSession]:
    """
    Returns all upcoming training sessions for a list of player profiles.
    """
    # 1. Find all AcademyTeams these players belong to
    
    team_ids = db.query(TeamMembership.team_id).filter(
        TeamMembership.player_profile_id.in_(player_ids), TeamMembership.status == MembershipStatus.ACTIVE
    ).all()
    team_ids = [t[0] for t in team_ids]

    if not team_ids:
        return []

    # 2. Find sessions linked to these teams
    # Note: TrainingSession.teams is a many-to-many relationship
    from app.academies.models import TrainingSession
    from app.academies.models import training_session_teams
    
    sessions = db.query(TrainingSession).join(training_session_teams).filter(
        training_session_teams.c.team_id.in_(team_ids)
    ).order_by(TrainingSession.date, TrainingSession.start_time).all()

    return sessions
