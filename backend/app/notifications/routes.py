from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.notifications import service, schemas
from app.users.models import User
from app.common.dependencies import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])

@router.get("/", response_model=List[schemas.NotificationBase])
def get_my_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return service.get_user_notifications(db, current_user.id)

@router.get("/user/{user_id}", response_model=List[schemas.NotificationBase])
def get_user_notifications(
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from app.users import models as user_models
    relation = db.query(user_models.ParentChildRelation).filter(
        user_models.ParentChildRelation.parent_id == current_user.id,
        user_models.ParentChildRelation.child_id == user_id,
        user_models.ParentChildRelation.status == user_models.ParentChildStatus.ACCEPTED
    ).first()
    
    if not relation and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="You do not have permission to view these notifications")
        
    return service.get_user_notifications(db, user_id)

@router.patch("/{id}/read", response_model=schemas.NotificationBase)
def mark_notification_read(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    notification = service.mark_as_read(db, id, current_user.id)
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notification

@router.get("/unread-count", response_model=schemas.UnreadCountResponse)
def get_my_unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    count = service.get_unread_count(db, current_user.id)
    return {"count": count}
