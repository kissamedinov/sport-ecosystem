import uuid
import enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class ClubTeamType(str, enum.Enum):
    AMATEUR = "AMATEUR"
    SEMI_PRO = "SEMI_PRO"
    PRO = "PRO"

class ClubTeam(Base):
    __tablename__ = "club_teams"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    creator_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    team_type = Column(Enum(ClubTeamType), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    creator = relationship("User")
    players = relationship("ClubTeamMembership", back_populates="club_team", cascade="all, delete-orphan")

class ClubTeamMembership(Base):
    __tablename__ = "club_team_memberships"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    team_id = Column(UUID(as_uuid=True), ForeignKey("club_teams.id"), nullable=False)
    player_profile_id = Column(UUID(as_uuid=True), ForeignKey("player_profiles.id"), nullable=False)
    position = Column(String, nullable=True)
    jersey_number = Column(String, nullable=True)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

    club_team = relationship("ClubTeam", back_populates="players")
    player_profile = relationship("PlayerProfile")
