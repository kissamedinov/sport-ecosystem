from pydantic import BaseModel
from uuid import UUID
from typing import Optional
from datetime import datetime
from app.media.models import MediaType

class MediaItemBase(BaseModel):
    user_id: Optional[UUID] = None
    club_id: Optional[UUID] = None
    tournament_id: Optional[UUID] = None
    type: MediaType

class MediaItemCreate(MediaItemBase):
    pass

class MediaItemUpdate(BaseModel):
    type: Optional[MediaType] = None

class MediaItemResponse(MediaItemBase):
    id: UUID
    url: str
    thumbnail_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
