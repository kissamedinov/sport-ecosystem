from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.users.models import User
from app.common.dependencies import require_coach, require_player, get_current_user
from app.teams import schemas, services

router = APIRouter(prefix="/teams", tags=["Teams"])

@router.post("", response_model=schemas.TeamResponse, status_code=status.HTTP_201_CREATED)
def create_team(
    team_in: schemas.TeamCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.create_team(db=db, team_in=team_in, current_user=current_user)

@router.get("", response_model=List[schemas.TeamResponse])
def get_teams(db: Session = Depends(get_db)):
    return services.get_teams(db=db)

@router.get("/rankings", response_model=List[schemas.TeamResponse])
def get_rankings(db: Session = Depends(get_db)):
    return services.get_team_rankings(db=db)

@router.get("/mine", response_model=List[schemas.TeamResponse])
def get_my_teams(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.get_my_teams(db=db, user=current_user)

@router.get("/{id}", response_model=schemas.TeamDetailResponse)
def get_team(
    id: UUID,
    db: Session = Depends(get_db)
):
    return services.get_team_by_id(db=db, team_id=id)

@router.post("/{id}/join", response_model=schemas.PlayerTeamResponse, status_code=status.HTTP_201_CREATED)
def request_join_team(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_player)
):
    return services.create_join_request(db=db, team_id=id, current_user=current_user)

@router.patch("/{id}/join-request/{requestId}/approve", response_model=schemas.PlayerTeamResponse)
def approve_join_request(
    id: UUID,
    requestId: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.approve_join_request(db=db, team_id=id, request_id=requestId, current_user=current_user)

@router.patch("/{id}/join-request/{requestId}/reject", response_model=schemas.PlayerTeamResponse)
def reject_join_request(
    id: UUID,
    requestId: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.reject_join_request(db=db, team_id=id, request_id=requestId, current_user=current_user)

@router.post("/{id}/players/{playerId}", response_model=schemas.PlayerTeamResponse)
def add_player_to_team(
    id: UUID,
    playerId: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    return services.add_player_to_team(db=db, team_id=id, player_id=playerId, current_user=current_user)

@router.get("/{id}/players", response_model=List[schemas.PlayerTeamResponse])
def get_team_members(
    id: UUID,
    db: Session = Depends(get_db)
):
    return services.get_team_members(db=db, team_id=id)
