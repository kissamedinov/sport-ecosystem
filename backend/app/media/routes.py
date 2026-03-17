from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app.database import get_db
from app.media import service, schemas, models
from app.users.models import User
from app.common.dependencies import get_current_user

router = APIRouter(prefix="/media", tags=["Media"])

@router.post("/upload", response_model=schemas.MediaItemResponse)
def upload_media(
    type: models.MediaType = Form(...),
    user_id: Optional[UUID] = Form(None),
    club_id: Optional[UUID] = Form(None),
    tournament_id: Optional[UUID] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not any([user_id, club_id, tournament_id]):
        raise HTTPException(status_code=400, detail="Owner ID must be provided")
        
    return service.save_media_item(
        db, file, type, user_id, club_id, tournament_id
    )

@router.get("/users/{user_id}", response_model=List[schemas.MediaItemResponse])
def get_user_media(user_id: UUID, db: Session = Depends(get_db)):
    return service.get_media_by_user(db, user_id)

@router.get("/clubs/{club_id}", response_model=List[schemas.MediaItemResponse])
def get_club_media(club_id: UUID, db: Session = Depends(get_db)):
    return service.get_media_by_club(db, club_id)

@router.get("/tournaments/{tournament_id}", response_model=List[schemas.MediaItemResponse])
def get_tournament_media(tournament_id: UUID, db: Session = Depends(get_db)):
    return service.get_media_by_tournament(db, tournament_id)

@router.patch("/{media_id}", response_model=schemas.MediaItemResponse)
def update_media(
    media_id: UUID, 
    type: models.MediaType = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return service.update_media_item(db, media_id, type)

@router.delete("/{media_id}")
def delete_media(
    media_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return service.delete_media_item(db, media_id)
