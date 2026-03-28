import uuid
import enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Boolean, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class NotificationType(str, enum.Enum):
    MATCH_SCHEDULED = "MATCH_SCHEDULED"
    MATCH_RESULT = "MATCH_RESULT"
    BEST_PLAYER = "BEST_PLAYER"
    TRAINING_REMINDER = "TRAINING_REMINDER"
    TRAINING_FEEDBACK = "TRAINING_FEEDBACK"
    TOURNAMENT_START = "TOURNAMENT_START"
    BOOKING_REQUEST = "BOOKING_REQUEST"
    BOOKING_APPROVED = "BOOKING_APPROVED"
    PAYMENT_CONFIRMED = "PAYMENT_CONFIRMED"
    TEAM_INVITE = "TEAM_INVITE"
    PLAYER_SELECTED = "PLAYER_SELECTED"
    CLUB_REQUEST = "CLUB_REQUEST"
    CLUB_APPROVED = "CLUB_APPROVED"
    CLUB_REJECTED = "CLUB_REJECTED"
    PARENT_LINK_REQUEST = "PARENT_LINK_REQUEST"

class EntityType(str, enum.Enum):
    MATCH = "MATCH"
    TOURNAMENT = "TOURNAMENT"
    TRAINING = "TRAINING"
    BOOKING = "BOOKING"
    PAYMENT = "PAYMENT"
    ACADEMY = "ACADEMY"
    PLAYER = "PLAYER"

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    type = Column(Enum(NotificationType, native_enum=False), nullable=False)
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    entity_type = Column(Enum(EntityType, native_enum=False), nullable=True)
    entity_id = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    targets = relationship("NotificationTarget", back_populates="notification", cascade="all, delete-orphan")

class NotificationTarget(Base):
    __tablename__ = "notification_targets"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    notification_id = Column(UUID(as_uuid=True), ForeignKey("notifications.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    is_read = Column(Boolean, default=False)
    read_at = Column(DateTime(timezone=True), nullable=True)

    notification = relationship("Notification", back_populates="targets")
    user = relationship("User", backref="notification_received")
