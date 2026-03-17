from fastapi import APIRouter, Depends, status, Body, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app.database import get_db
from app.users.models import User, Role
from app.common.dependencies import get_current_user, require_role, require_coach, require_match_reporter, require_permission
from app.matches import schemas, services, standings_service

router = APIRouter(tags=["Matches"])

@router.get("/tournaments/{id}/matches", response_model=List[schemas.MatchResponse])
def get_tournament_matches(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_matches(db, id)

@router.get("/matches", response_model=List[schemas.MatchResponse])
def get_all_matches(
    tournament_id: Optional[UUID] = None,
    db: Session = Depends(get_db)
):
    if tournament_id:
        return services.get_tournament_matches(db, tournament_id)
    return services.get_all_matches(db)

@router.post("/matches/{id}/submit-result")
def submit_result(
    id: UUID,
    result_in: schemas.MatchResultCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission("EDIT_MATCH_STATS"))
):
    return services.submit_match_result(db, id, result_in, current_user)

@router.patch("/matches/{id}/finalize-result")
def finalize_result(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission("EDIT_MATCH_STATS"))
):
    return services.finalize_match_result(db, id)

@router.get("/tournaments/{id}/groups", response_model=List[schemas.TournamentGroupResponse])
def get_tournament_groups(id: UUID, db: Session = Depends(get_db)):
    return services.get_tournament_groups(db, id)

@router.post("/matches/{id}/events", response_model=schemas.MatchEventResponse)
def create_match_event(
    id: UUID,
    event_in: schemas.MatchEventCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_match_reporter)
):
    return services.create_match_event(db, id, event_in)

@router.get("/matches/{id}/events", response_model=List[schemas.MatchEventResponse])
def get_match_events(id: UUID, db: Session = Depends(get_db)):
    return services.get_match_events(db, id)

@router.delete("/events/{id}")
def delete_match_event(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_match_reporter)
):
    return services.delete_match_event(db, id)
@router.post("/matches/{id}/lineup", response_model=schemas.LineupResponse)
def create_lineup(
    id: UUID,
    lineup_in: schemas.LineupCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    # Additional check: ensure coach belongs to the team they are submitting for
    # (Simplified for now, assuming require_coach handles general authorization)
    return services.create_or_update_lineup(db, id, lineup_in)

@router.get("/matches/{id}/lineup", response_model=schemas.MatchLineupsResponse)
def get_match_lineups(id: UUID, db: Session = Depends(get_db)):
    return services.get_match_lineups(db, id)

@router.patch("/matches/{id}/lineup/{team_id}", response_model=schemas.LineupResponse)
def update_lineup(
    id: UUID,
    team_id: UUID,
    lineup_in: schemas.LineupCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coach)
):
    # Ensure team_id matches payload
    if team_id != lineup_in.team_id:
        raise HTTPException(status_code=400, detail="Team ID mismatch")
    return services.create_or_update_lineup(db, id, lineup_in)
