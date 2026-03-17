import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, func, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class ScoutProfile(Base):
    __tablename__ = "scout_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False)
    club_name = Column(String, nullable=True)
    country = Column(String, nullable=True)
    role = Column(String, nullable=True)

    user = relationship("User")

class ScoutReport(Base):
    __tablename__ = "scout_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    scout_id = Column(UUID(as_uuid=True), ForeignKey("scout_profiles.id"), nullable=False)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    technical = Column(Integer, nullable=False) # 1-10
    physical = Column(Integer, nullable=False)
    potential = Column(Integer, nullable=False)
    comment = Column(String, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    scout = relationship("ScoutProfile")
    player = relationship("User")
