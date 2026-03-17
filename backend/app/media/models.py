import uuid
import enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, func
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base

class MediaType(str, enum.Enum):
    AVATAR = "AVATAR"
    CLUB_LOGO = "CLUB_LOGO"
    TOURNAMENT_LOGO = "TOURNAMENT_LOGO"
    OTHER = "OTHER"

class OwnerType(str, enum.Enum):
    USER = "USER"
    CLUB = "CLUB"
    TOURNAMENT = "TOURNAMENT"
    ACADEMY = "ACADEMY"
    MATCH = "MATCH"

class MediaItem(Base):
    __tablename__ = "media_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    club_id = Column(UUID(as_uuid=True), ForeignKey("club_teams.id"), nullable=True)
    tournament_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=True)
    
    type = Column(Enum(MediaType), nullable=False)
    url = Column(String, nullable=False)
    thumbnail_url = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User")
    club = relationship("ClubTeam")
    tournament = relationship("Tournament")
