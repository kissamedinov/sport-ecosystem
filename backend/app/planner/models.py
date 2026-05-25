import uuid
from sqlalchemy import Column, String, Date, DateTime, ForeignKey, Boolean, func
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class CoachTask(Base):
    __tablename__ = "coach_tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    coach_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    time = Column(String, nullable=True)
    category = Column(String, nullable=False, default="TRAINING")
    date = Column(Date, nullable=False)
    done = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
