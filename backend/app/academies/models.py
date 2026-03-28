import uuid
import enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, func, Integer, Float, Boolean, Date, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class AgeGroup(str, enum.Enum):
    U7 = "U7"
    U9 = "U9"
    U11 = "U11"
    U13 = "U13"
    U15 = "U15"
    U17 = "U17"

class AcademyPlayerStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    LEFT = "LEFT"

class AttendanceStatus(str, enum.Enum):
    PRESENT = "PRESENT"
    ABSENT = "ABSENT"
    LATE = "LATE"
    INJURED = "INJURED"

class Academy(Base):
    __tablename__ = "football_academies"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    club_id = Column(UUID(as_uuid=True), ForeignKey("clubs.id"), nullable=False)
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    address = Column(String, nullable=False)
    description = Column(String, nullable=True)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    club = relationship("Club", back_populates="academies")
    owner = relationship("User", foreign_keys=[owner_id])
    teams = relationship("AcademyTeam", back_populates="academy", cascade="all, delete-orphan")
    youth_teams = relationship("Team", back_populates="academy")
    players = relationship("AcademyPlayer", back_populates="academy", cascade="all, delete-orphan")
    managed_users = relationship("User", back_populates="academy", foreign_keys="[User.academy_id]")

class AcademyTeam(Base):
    __tablename__ = "academy_teams"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    name = Column(String, nullable=False)
    age_group = Column(Enum(AgeGroup), nullable=False)
    coach_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    academy = relationship("Academy", back_populates="teams")
    coach = relationship("User")
    players = relationship("AcademyTeamPlayer", back_populates="team", cascade="all, delete-orphan")

class AcademyPlayer(Base):
    __tablename__ = "academy_players"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    player_profile_id = Column(UUID(as_uuid=True), ForeignKey("player_profiles.id"), nullable=True)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    status = Column(Enum(AcademyPlayerStatus), default=AcademyPlayerStatus.ACTIVE, nullable=False)

    player_user = relationship("User")
    player_profile = relationship("PlayerProfile")
    academy = relationship("Academy", back_populates="players")

class AcademyTeamPlayer(Base):
    __tablename__ = "academy_team_players"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    player_profile_id = Column(UUID(as_uuid=True), ForeignKey("player_profiles.id"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("academy_teams.id"), nullable=False)
    position = Column(String, nullable=True)
    jersey_number = Column(Integer, nullable=True)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

    player_profile = relationship("PlayerProfile")
    team = relationship("AcademyTeam", back_populates="players")

class TrainingSession(Base):
    __tablename__ = "training_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("academy_teams.id"), nullable=False)
    coach_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    date = Column(Date, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    description = Column(String, nullable=True)

    academy = relationship("Academy")
    team = relationship("AcademyTeam")
    coach = relationship("User")
    attendance = relationship("TrainingAttendance", back_populates="session", cascade="all, delete-orphan")

class TrainingAttendance(Base):
    __tablename__ = "training_attendance"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    training_id = Column(UUID(as_uuid=True), ForeignKey("training_sessions.id"), nullable=False)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    status = Column(Enum(AttendanceStatus), nullable=False)
    note = Column(String, nullable=True)

    session = relationship("TrainingSession", back_populates="attendance")
    player = relationship("User")

class CoachFeedback(Base):
    __tablename__ = "coach_feedback"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    coach_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    
    technical = Column(Integer, nullable=False) # e.g., 1-10
    tactical = Column(Integer, nullable=False)
    physical = Column(Integer, nullable=False)
    discipline = Column(Integer, nullable=False)
    
    comment = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    player = relationship("User", foreign_keys=[player_id])
    coach = relationship("User", foreign_keys=[coach_id])
    academy = relationship("Academy")

class AcademyRanking(Base):
    __tablename__ = "academy_rankings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False, unique=True)
    points = Column(Integer, default=0, nullable=False)
    tournaments_played = Column(Integer, default=0, nullable=False)
    tournaments_won = Column(Integer, default=0, nullable=False)
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    academy = relationship("Academy")
