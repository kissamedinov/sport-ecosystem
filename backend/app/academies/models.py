import uuid
import enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, func, Integer, Float, Boolean, Date, Time, Table
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

class DayOfWeek(str, enum.Enum):
    MONDAY = "MONDAY"
    TUESDAY = "TUESDAY"
    WEDNESDAY = "WEDNESDAY"
    THURSDAY = "THURSDAY"
    FRIDAY = "FRIDAY"
    SATURDAY = "SATURDAY"
    SUNDAY = "SUNDAY"

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
    schedules = relationship("TrainingSchedule", back_populates="academy", cascade="all, delete-orphan")
    branches = relationship("AcademyBranch", back_populates="academy", cascade="all, delete-orphan")
    billing_config = relationship("AcademyBillingConfig", back_populates="academy", uselist=False, cascade="all, delete-orphan")

class AcademyTeam(Base):
    __tablename__ = "academy_teams"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    name = Column(String, nullable=False)
    age_group = Column(String, nullable=False)
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

# Association table for multi-team training sessions
training_session_teams = Table(
    "training_session_teams",
    Base.metadata,
    Column("training_session_id", UUID(as_uuid=True), ForeignKey("training_sessions.id", ondelete="CASCADE"), primary_key=True),
    Column("team_id", UUID(as_uuid=True), ForeignKey("academy_teams.id", ondelete="CASCADE"), primary_key=True),
)

# Association table for multi-team training schedules
training_schedule_teams = Table(
    "training_schedule_teams",
    Base.metadata,
    Column("training_schedule_id", UUID(as_uuid=True), ForeignKey("academy_training_schedules.id", ondelete="CASCADE"), primary_key=True),
    Column("team_id", UUID(as_uuid=True), ForeignKey("academy_teams.id", ondelete="CASCADE"), primary_key=True),
)

class TrainingSession(Base):
    __tablename__ = "training_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    coach_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    date = Column(Date, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    description = Column(String, nullable=True)

    academy = relationship("Academy")
    teams = relationship("AcademyTeam", secondary=training_session_teams)
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

class AcademyBranch(Base):
    __tablename__ = "academy_branches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    name = Column(String, nullable=False) # e.g., "Summer Branch", "Winter Branch"
    address = Column(String, nullable=False)
    description = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    academy = relationship("Academy", back_populates="branches")
    schedules = relationship("TrainingSchedule", back_populates="branch")

class TrainingSchedule(Base):
    __tablename__ = "academy_training_schedules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False)
    branch_id = Column(UUID(as_uuid=True), ForeignKey("academy_branches.id"), nullable=True)
    day_of_week = Column(Enum(DayOfWeek), nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    location = Column(String, nullable=True) # Specific field/room

    academy = relationship("Academy", back_populates="schedules")
    branch = relationship("AcademyBranch", back_populates="schedules")
    teams = relationship("AcademyTeam", secondary=training_schedule_teams)

    @property
    def team_ids(self):
        return [t.id for t in self.teams]

class AcademyBillingConfig(Base):
    __tablename__ = "academy_billing_configs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    academy_id = Column(UUID(as_uuid=True), ForeignKey("football_academies.id"), nullable=False, unique=True)
    monthly_subscription_fee = Column(Float, nullable=True)
    per_session_fee = Column(Float, nullable=True)
    currency = Column(String, default="KZT", nullable=False)

    academy = relationship("Academy", back_populates="billing_config")
