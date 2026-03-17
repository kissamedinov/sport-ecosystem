from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional
from app.notifications.models import NotificationType, EntityType

class NotificationBase(BaseModel):
    id: UUID
    type: NotificationType
    title: str
    message: str
    entity_type: Optional[EntityType] = None
    entity_id: Optional[UUID] = None
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

class UnreadCountResponse(BaseModel):
    count: int
