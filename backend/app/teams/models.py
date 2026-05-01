import uuid
import enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, func, Integer, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class JoinStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"

class MembershipRole(str, enum.Enum):
    PLAYER = "PLAYER"
    CAPTAIN = "CAPTAIN"

class MembershipStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    TRANSFERRED = "TRANSFERRED"
    LEFT = "LEFT"

class Team(Base):
    __tablename__ = "teams"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    name = Column(String, nullable=False)
    age_category = Column(String, nullable=True)
    birth_year = Column(Integer, nullable=True)
    division = Column(String, nullable=True, default="Group A") # A/B composition
    is_active = Column(Boolean, default=True)
    coach_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    academy = relationship("Academy", back_populates="youth_teams")
    coach = relationship("User", foreign_keys=[coach_id])
    memberships = relationship("TeamMembership", back_populates="team", cascade="all, delete-orphan")
    rating_history = relationship("TeamRatingHistory", back_populates="team", cascade="all, delete-orphan")

class TeamRatingHistory(Base):
    __tablename__ = "team_rating_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), nullable=True)
    rating_after = Column(Integer, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    team = relationship("Team", back_populates="rating_history")

class TeamMembership(Base):
    __tablename__ = "team_memberships"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True) # Added for convenience
    player_profile_id = Column(UUID(as_uuid=True), ForeignKey("player_profiles.id"), nullable=False)
    role = Column(Enum(MembershipRole), default=MembershipRole.PLAYER, nullable=False)
    status = Column(Enum(MembershipStatus), default=MembershipStatus.ACTIVE, nullable=False)
    join_status = Column(Enum(JoinStatus), default=JoinStatus.APPROVED, nullable=False)
    child_profile_id = Column(UUID(as_uuid=True), ForeignKey("child_profiles.id"), nullable=True)
    jersey_number = Column(Integer, nullable=True)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    left_at = Column(DateTime(timezone=True), nullable=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    team = relationship("Team", back_populates="memberships")
    player_profile = relationship("PlayerProfile", back_populates="memberships")
    player = relationship("User") # Added for easier access
    child_profile = relationship("ChildProfile")

    @property
    def full_name(self):
        if self.player_profile:
            return f"{self.player_profile.first_name} {self.player_profile.last_name}"
        return ""
