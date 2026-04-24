import uuid
import enum
from sqlalchemy import Column, String, Date, DateTime, Enum, func, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base

class Role(str, enum.Enum):
    ADMIN = "ADMIN"
    TOURNAMENT_MANAGER = "TOURNAMENT_MANAGER"
    REFEREE = "REFEREE"
    COACH = "COACH"
    PLAYER_ADULT = "PLAYER_ADULT"
    PLAYER_CHILD = "PLAYER_CHILD"
    PARENT = "PARENT"
    FIELD_OWNER = "FIELD_OWNER"
    SCOUT = "SCOUT"
    TOURNAMENT_ORGANIZER = "TOURNAMENT_ORGANIZER"
    ACADEMY_ADMIN = "ACADEMY_ADMIN"
    TEAM_OWNER = "TEAM_OWNER"
    PLAYER_YOUTH = "PLAYER_YOUTH"
    CLUB_OWNER = "CLUB_OWNER"
    CLUB_MANAGER = "CLUB_MANAGER"

class RelationType(str, enum.Enum):
    FATHER = "FATHER"
    MOTHER = "MOTHER"
    GUARDIAN = "GUARDIAN"

class ParentChildStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    DECLINED = "DECLINED"

class DominantFoot(str, enum.Enum):
    RIGHT = "RIGHT"
    LEFT = "LEFT"
    BOTH = "BOTH"

class UserRole(Base):
    __tablename__ = "user_roles"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    role = Column(Enum(Role), primary_key=True)

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    date_of_birth = Column(Date, nullable=True)
    phone = Column(String, nullable=True)
    bio = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=True)
    onboarding_completed = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    roles = relationship("UserRole", backref="user", cascade="all, delete-orphan")
    academy = relationship("Academy", back_populates="managed_users", foreign_keys=[academy_id])
    player_profile = relationship("PlayerProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")

class PlayerProfile(Base):
    __tablename__ = "player_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, unique=True)
    preferred_position = Column(String, nullable=True) # e.g., 'ST', 'CM', 'CB'
    dominant_foot = Column(Enum(DominantFoot), nullable=True, default=DominantFoot.RIGHT)
    height = Column(String, nullable=True) # e.g., '175cm'
    weight = Column(String, nullable=True) # e.g., '70kg'
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="player_profile")
    memberships = relationship("TeamMembership", back_populates="player_profile")

class ParentChildRelation(Base):
    __tablename__ = "parent_child_relations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    parent_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    child_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    relation_type = Column(Enum(RelationType), nullable=False)
    status = Column(Enum(ParentChildStatus), default=ParentChildStatus.PENDING, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    parent = relationship("User", foreign_keys=[parent_id])
    child = relationship("User", foreign_keys=[child_id])

class Permission(Base):
    __tablename__ = "permissions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, unique=True, nullable=False)
    description = Column(String, nullable=True)

class RolePermission(Base):
    __tablename__ = "role_permissions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role = Column(Enum(Role), nullable=False)
    permission_id = Column(UUID(as_uuid=True), ForeignKey("permissions.id"), nullable=False)

    permission = relationship("Permission")
