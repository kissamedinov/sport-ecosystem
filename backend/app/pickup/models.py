import uuid
import enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, func, Integer, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class PickupGameStatus(str, enum.Enum):
    OPEN = "OPEN"
    FULL = "FULL"
    FINISHED = "FINISHED"
    CANCELED = "CANCELED"

class PickupTeam(str, enum.Enum):
    A = "A"
    B = "B"

class PickupGame(Base):
    __tablename__ = "pickup_games"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    creator_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    field_id = Column(UUID(as_uuid=True), nullable=False) # Simplified for now, or link to Fields model

    date = Column(DateTime, nullable=False)
    start_time = Column(Time, nullable=False)
    duration = Column(Integer, nullable=False) # Minutes

    max_players = Column(Integer, nullable=False)
    skill_level = Column(String, nullable=True)
    status = Column(Enum(PickupGameStatus), default=PickupGameStatus.OPEN, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    creator = relationship("User")
    players = relationship("PickupGamePlayers", back_populates="game", cascade="all, delete-orphan")

class PickupGamePlayers(Base):
    __tablename__ = "pickup_game_players"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    game_id = Column(UUID(as_uuid=True), ForeignKey("pickup_games.id"), nullable=False)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    team = Column(Enum(PickupTeam), nullable=True)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

    game = relationship("PickupGame", back_populates="players")
    player = relationship("User")
