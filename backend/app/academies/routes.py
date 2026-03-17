from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app.database import get_db
from app.users.models import User, Role
from app.common.dependencies import require_role, require_coach
from app.academies import schemas, models, services

router = APIRouter(prefix="/academies", tags=["Academies"])

@router.post("", response_model=schemas.AcademyResponse, status_code=status.HTTP_201_CREATED)
def create_academy(
    academy_in: schemas.AcademyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    """
    Creates a new academy. Only COACH or TEAM_OWNER roles allowed.
    """
    return services.create_academy(db, academy_in, current_user.id)

@router.get("/mine", response_model=Optional[schemas.AcademyResponse])
def get_my_academy(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    """
    Returns the academy owned by the current user.
    """
    return services.get_academy_by_owner(db, current_user.id)

@router.get("/rankings", response_model=List[schemas.AcademyRankingResponse])
def get_academy_rankings(db: Session = Depends(get_db)):
    """
    Returns academy rankings sorted by points descending.
    """
    return services.get_academy_rankings(db)

@router.get("/{id}/teams", response_model=List[schemas.AcademyTeamResponse])
def list_academy_teams(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_academy_teams(db, id)

@router.post("/{id}/teams", response_model=schemas.AcademyTeamResponse)
def add_academy_team(
    id: UUID,
    team_in: schemas.AcademyTeamCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_academy_team(db, id, team_in)

@router.get("/{id}/players", response_model=List[schemas.AcademyPlayerResponse])
def list_academy_players(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_academy_players(db, id)

@router.post("/{id}/players", response_model=schemas.AcademyPlayerResponse)
def add_academy_player(
    id: UUID,
    player_in: schemas.AcademyPlayerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.add_player_to_academy(db, id, player_in)

@router.get("/teams/{team_id}/players", response_model=List[schemas.AcademyTeamPlayerResponse])
def list_team_players(
    team_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_academy_team_players(db, team_id)

@router.post("/teams/{team_id}/players", response_model=schemas.AcademyTeamPlayerResponse)
def add_team_player(
    team_id: UUID,
    player_in: schemas.AcademyTeamPlayerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.add_player_to_team(db, team_id, player_in)

@router.get("/{id}/training", response_model=List[schemas.TrainingSessionResponse])
def list_training_sessions(
    id: UUID,
    team_id: Optional[UUID] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.get_training_sessions(db, id, team_id)

@router.post("/{id}/training", response_model=schemas.TrainingSessionResponse)
def add_training_session(
    id: UUID,
    session_in: schemas.TrainingSessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_training_session(db, id, current_user.id, session_in)

@router.post("/attendance", response_model=schemas.TrainingAttendanceResponse)
def record_training_attendance(
    attendance_in: schemas.TrainingAttendanceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.record_attendance(db, attendance_in)

@router.post("/feedback", response_model=schemas.CoachFeedbackResponse)
def submit_coach_feedback(
    feedback_in: schemas.CoachFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.submit_feedback(db, current_user.id, feedback_in)
