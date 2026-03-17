import uuid
from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class PlayerMatchStats(Base):
    __tablename__ = "player_match_stats"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), nullable=False)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)

    # minutes_played removed
    goals = Column(Integer, default=0)
    assists = Column(Integer, default=0)
    yellow_cards = Column(Integer, default=0)
    red_cards = Column(Integer, default=0)

    rating = Column(Float, nullable=True) # 1-10 scale usually
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    player = relationship("User")
    # match = relationship("Match") # Assuming Match model exists from previous implementation
    # team = relationship("Team") # Assuming Team model exists

class PlayerCareerStats(Base):
    __tablename__ = "player_career_stats"

    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    matches_played = Column(Integer, default=0)
    goals = Column(Integer, default=0)
    assists = Column(Integer, default=0)
    yellow_cards = Column(Integer, default=0)
    red_cards = Column(Integer, default=0)
    # minutes_played removed
    best_player_awards = Column(Integer, default=0)
    rating = Column(Float, default=0.0)

    player = relationship("User")
