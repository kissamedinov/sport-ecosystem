from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import date
from app.academies.models import Academy, AcademyRanking, AcademyTeam, AcademyPlayer, AcademyTeamPlayer, TrainingSession, TrainingAttendance, CoachFeedback
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

def get_academy_by_owner(db: Session, owner_id: UUID) -> Optional[Academy]:
    return db.query(Academy).filter(Academy.owner_id == owner_id).first()

def get_academy_teams(db: Session, academy_id: UUID) -> List[AcademyTeam]:
    return db.query(AcademyTeam).filter(AcademyTeam.academy_id == academy_id).all()

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

def get_academy_players(db: Session, academy_id: UUID) -> List[AcademyPlayer]:
    return db.query(AcademyPlayer).filter(AcademyPlayer.academy_id == academy_id).all()

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
        team_id=session_in.team_id,
        coach_id=coach_id,
        date=session_in.date,
        start_time=session_in.start_time,
        end_time=session_in.end_time,
        description=session_in.description
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)
    return new_session

def get_training_sessions(db: Session, academy_id: UUID, team_id: Optional[UUID] = None) -> List[TrainingSession]:
    query = db.query(TrainingSession).filter(TrainingSession.academy_id == academy_id)
    if team_id:
        query = query.filter(TrainingSession.team_id == team_id)
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
