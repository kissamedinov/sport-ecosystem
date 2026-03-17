from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.stats import service, schemas
from app.users.models import User
from app.common.dependencies import get_current_user, get_parent_children_ids

router = APIRouter(prefix="/stats", tags=["Stats"])

@router.get("/history/{player_id}", response_model=List[schemas.MatchHistoryItem])
def get_match_history(
    player_id: UUID, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    children_ids: List[UUID] = Depends(get_parent_children_ids)
):
    # Authorization: Self, Admin, or Child of Parent
    is_admin = any(ur.role == "ADMIN" for ur in current_user.roles)
    is_parent_of_player = player_id in children_ids
    
    if not (current_user.id == player_id or is_admin or is_parent_of_player):
        raise HTTPException(status_code=403, detail="Not authorized to view this player's stats")
        
    return service.get_match_history(db, player_id)

@router.get("/career/{player_id}", response_model=schemas.PlayerCareerStatsResponse)
def get_career_stats(
    player_id: UUID, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    children_ids: List[UUID] = Depends(get_parent_children_ids)
):
    # Authorization: Self, Admin, or Child of Parent
    is_admin = any(ur.role == "ADMIN" for ur in current_user.roles)
    is_parent_of_player = player_id in children_ids
    
    if not (current_user.id == player_id or is_admin or is_parent_of_player):
        raise HTTPException(status_code=403, detail="Not authorized to view this player's stats")
        
    stats = service.get_player_career_stats(db, player_id)
    if not stats:
        raise HTTPException(status_code=404, detail="Stats not found")
    return stats
