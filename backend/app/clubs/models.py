import uuid
import enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, func, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class ClubRole(str, enum.Enum):
    OWNER = "OWNER"
    MANAGER = "MANAGER"
    COACH = "COACH"
    PLAYER = "PLAYER"

class ClubMembershipStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    LEFT = "LEFT"
    TRANSFERRED = "TRANSFERRED"

class ClubStaff(Base):
    __tablename__ = "club_staff"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    club_id = Column(UUID(as_uuid=True), ForeignKey("clubs.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    role = Column(Enum(ClubRole), nullable=False)
    status = Column(Enum(ClubMembershipStatus), default=ClubMembershipStatus.ACTIVE, nullable=False)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    left_at = Column(DateTime(timezone=True), nullable=True)

    club = relationship(lambda: Club, back_populates="staff")
    user = relationship("User")

class Club(Base):
    __tablename__ = "clubs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    address = Column(String, nullable=True)
    training_schedule = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", foreign_keys=[owner_id])
    staff = relationship(lambda: ClubStaff, back_populates="club", cascade="all, delete-orphan")
    academies = relationship("Academy", back_populates="club", cascade="all, delete-orphan")

class RequestStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"

class ClubRequest(Base):
    __tablename__ = "club_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    address = Column(String, nullable=False)
    training_schedule = Column(String, nullable=True)
    contact_phone = Column(String, nullable=True)
    social_links = Column(String, nullable=True) # Could be JSON, but String is fine for now
    description = Column(String, nullable=True)
    status = Column(Enum(RequestStatus), default=RequestStatus.PENDING, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    creator = relationship("User")

class InvitationStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    DECLINED = "DECLINED"

class Invitation(Base):
    __tablename__ = "invitations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    club_id = Column(UUID(as_uuid=True), ForeignKey("clubs.id"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=True)
    invited_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    invited_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    child_profile_id = Column(UUID(as_uuid=True), ForeignKey("child_profiles.id"), nullable=True)
    role = Column(Enum(ClubRole), nullable=False) # Reuse ClubRole (OWNER, MANAGER, COACH, PLAYER)
    status = Column(Enum(InvitationStatus), default=InvitationStatus.PENDING, nullable=False)
    is_approved = Column(Boolean, default=True, nullable=False) # Owner approval for staff
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)

    club = relationship("Club")
    team = relationship("Team")
    invited_user = relationship("User", foreign_keys=[invited_user_id])
    inviter = relationship("User", foreign_keys=[invited_by])
    child_profile = relationship("ChildProfile")

class ChildProfile(Base):
    __tablename__ = "child_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    date_of_birth = Column(DateTime(timezone=True), nullable=False)
    position = Column(String, nullable=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    club_id = Column(UUID(as_uuid=True), ForeignKey("clubs.id"), nullable=False)
    linked_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True, unique=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    club = relationship("Club")
    creator = relationship("User", foreign_keys=[created_by])
    linked_user = relationship("User", foreign_keys=[linked_user_id])
