from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import date, timedelta, datetime
import calendar
from app.academies.models import (
    Academy, AcademyRanking, AcademyTeam, AcademyPlayer, 
    AcademyTeamPlayer, TrainingSession, TrainingAttendance, 
    CoachFeedback, TrainingSchedule, AcademyBillingConfig, DayOfWeek, AttendanceStatus
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
        academy_team = db.query(AcademyTeam).filter(AcademyTeam.coach_id == standing.team.coach_id).first() 
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

def get_user_related_academy(db: Session, user_id: UUID) -> Optional[Academy]:
    # 1. Check if owner
    academy = db.query(Academy).filter(Academy.owner_id == user_id).first()
    if academy:
        return academy
    
    # 2. Check if owner of a club that has academies
    club = db.query(Club).filter(Club.owner_id == user_id).first()
    if club:
        academy = db.query(Academy).filter(Academy.club_id == club.id).first()
        if academy:
            return academy
    
    # 3. Check if coach of any team in any academy
    team = db.query(AcademyTeam).filter(AcademyTeam.coach_id == user_id).first()
    if team:
        return db.query(Academy).filter(Academy.id == team.academy_id).first()
        
    return None

def get_academy_teams(db: Session, academy_id: UUID) -> List[Team]:
    from app.teams.models import Team
    # If this is a club owner, they might want all teams across branches? 
    # For now, stick to the specific academy but ensure they HAVE access (already done in route)
    return db.query(Team).filter(Team.academy_id == academy_id).all()

def create_academy_team(db: Session, academy_id: UUID, team_in: schemas.AcademyTeamCreate) -> AcademyTeam:
    new_team = AcademyTeam(
        academy_id=academy_id,
        name=team_in.name,
        age_group=team_in.age_group,
        coach_id=team_in.coach_id
    )
    db.add(new_team)
    db.commit()
    db.refresh(new_team)
    return new_team

def get_academy_players(db: Session, academy_id: UUID) -> List[TeamMembership]:
    from app.teams.models import TeamMembership, Team
    return db.query(TeamMembership).join(Team).filter(Team.academy_id == academy_id).all()

def add_player_to_academy(db: Session, academy_id: UUID, player_in: schemas.AcademyPlayerCreate) -> AcademyPlayer:
    new_player = AcademyPlayer(
        academy_id=academy_id,
        player_profile_id=player_in.player_profile_id,
        status=player_in.status
    )
    db.add(new_player)
    db.commit()
    db.refresh(new_player)
    return new_player

def get_academy_team_players(db: Session, team_id: UUID) -> List[AcademyTeamPlayer]:
    return db.query(AcademyTeamPlayer).filter(AcademyTeamPlayer.team_id == team_id).all()

def add_player_to_team(db: Session, team_id: UUID, player_in: schemas.AcademyTeamPlayerCreate) -> AcademyTeamPlayer:
    new_team_player = AcademyTeamPlayer(
        team_id=team_id,
        player_profile_id=player_in.player_profile_id,
        position=player_in.position,
        jersey_number=player_in.jersey_number
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
        from app.teams.models import Team
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
        day_of_week=schedule_in.day_of_week,
        start_time=schedule_in.start_time,
        end_time=schedule_in.end_time,
        location=schedule_in.location
    )
    # Link teams
    if schedule_in.team_ids:
        from app.teams.models import Team
        teams = db.query(Team).filter(Team.id.in_(schedule_in.team_ids)).all()
        new_schedule.teams = teams

    db.add(new_schedule)
    db.commit()
    db.refresh(new_schedule)
    return new_schedule

def get_academy_schedules(db: Session, academy_id: UUID, team_id: Optional[UUID] = None) -> List[TrainingSchedule]:
    query = db.query(TrainingSchedule).filter(TrainingSchedule.academy_id == academy_id)
    if team_id:
        query = query.join(TrainingSchedule.teams).filter(Team.id == team_id)
    return query.all()

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
                    # Get academy owner or the coach of the first team as default
                    default_coach_id = db.query(Academy).filter(Academy.id == academy_id).first().owner_id
                    if sched.teams:
                        default_coach_id = sched.teams[0].coach_id

                    new_session = TrainingSession(
                        academy_id=academy_id,
                        coach_id=default_coach_id,
                        date=current_day,
                        start_time=sched.start_time,
                        end_time=sched.end_time,
                        description=f"Automated session from multi-team schedule"
                    )
                    new_session.teams = list(sched.teams)
                    db.add(new_session)
                    sessions_created += 1
        current_day += timedelta(days=1)
    
    db.commit()
    return sessions_created

def move_player_between_teams(db: Session, player_profile_id: UUID, target_team_id: UUID) -> Optional[AcademyTeamPlayer]:
    # Remove from existing academy teams if any
    db.query(AcademyTeamPlayer).filter(AcademyTeamPlayer.player_profile_id == player_profile_id).delete()
    
    # Add to new team
    new_team_player = AcademyTeamPlayer(
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
