import uuid
import enum
from sqlalchemy import Column, String, Date, DateTime, ForeignKey, Enum, func, Integer, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class TournamentFormat(str, enum.Enum):
    LEAGUE = "LEAGUE"
    GROUP_STAGE = "GROUP_STAGE"
    KNOCKOUT = "KNOCKOUT"

class MatchStatus(str, enum.Enum):
    SCHEDULED = "SCHEDULED"
    FINISHED = "FINISHED"
    CANCELLED = "CANCELLED"

class SurfaceType(str, enum.Enum):
    NATURAL_GRASS = "NATURAL_GRASS"
    ARTIFICIAL_TURF = "ARTIFICIAL_TURF"
    INDOOR = "INDOOR"
    OTHER = "OTHER"

class AgeCategory(str, enum.Enum):
    Y2005 = "2005"
    Y2006 = "2006"
    Y2007 = "2007"
    Y2008 = "2008"
    Y2009 = "2009"
    Y2010 = "2010"
    Y2011 = "2011"
    Y2012 = "2012"
    Y2013 = "2013"
    Y2014 = "2014"
    Y2015 = "2015"
    Y2016 = "2016"
    Y2017 = "2017"
    Y2018 = "2018"
    Y2019 = "2019"
    Y2020 = "2020"
    ADULT = "ADULT"

class RegistrationStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"

class Season(str, enum.Enum):
    SPRING = "SPRING"
    SUMMER = "SUMMER"
    AUTUMN = "AUTUMN"
    WINTER = "WINTER"

class TournamentSeries(Base):
    __tablename__ = "tournament_series"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    organizer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    city = Column(String, nullable=False)
    description = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    organizer = relationship("User")
    editions = relationship("Tournament", back_populates="series", cascade="all, delete-orphan")

class Tournament(Base):
    __tablename__ = "tournaments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    series_id = Column(UUID(as_uuid=True), ForeignKey("tournament_series.id"), nullable=True)
    name = Column(String, nullable=False)
    year = Column(Integer, nullable=True)
    season = Column(Enum(Season, native_enum=False), nullable=True)
    location = Column(String, nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    registration_open = Column(Date, nullable=False)
    registration_close = Column(Date, nullable=False)
    
    # Use native_enum=False for better string compatibility in some DBs
    format = Column(Enum(TournamentFormat, native_enum=False), nullable=False)
    surface_type = Column(Enum(SurfaceType, native_enum=False), default=SurfaceType.NATURAL_GRASS, nullable=True)
    
    # Existing fields for backward compatibility or migration
    age_category = Column(String, nullable=True) # Changed from Enum to String for flexibility
    allowed_age_categories = Column(String, nullable=True) # JSON string
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    
    # Scheduler Configuration
    num_fields = Column(Integer, default=1)
    match_half_duration = Column(Integer, default=20)
    halftime_break_duration = Column(Integer, default=5)
    break_between_matches = Column(Integer, default=10)
    start_time = Column(DateTime, nullable=True)
    end_time = Column(DateTime, nullable=True)
    minimum_rest_slots = Column(Integer, default=1)
    
    # Standing Configuration
    points_for_win = Column(Integer, default=3)
    points_for_draw = Column(Integer, default=1)
    points_for_loss = Column(Integer, default=0)
    
    status = Column(String, default="upcoming", nullable=True)
    history_data = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    series = relationship("TournamentSeries", back_populates="editions")
    divisions = relationship("TournamentDivision", back_populates="edition", cascade="all, delete-orphan")
    registrations = relationship("TournamentRegistration", back_populates="tournament", cascade="all, delete-orphan")
    creator = relationship("User", foreign_keys=[created_by])

class TournamentDivision(Base):
    __tablename__ = "tournament_divisions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tournament_edition_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=False)
    birth_year = Column(Integer, nullable=False)
    max_teams = Column(Integer, nullable=False, default=10)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    edition = relationship("Tournament", back_populates="divisions")
    teams = relationship("TournamentTeam", back_populates="division", cascade="all, delete-orphan")
    matches = relationship("app.matches.models.Match", back_populates="division", cascade="all, delete-orphan")
    awards = relationship("TournamentAward", back_populates="division", cascade="all, delete-orphan")
    player_stats = relationship("TournamentPlayerStats", back_populates="division", cascade="all, delete-orphan")

class TournamentRegistration(Base):
    __tablename__ = "tournament_registrations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tournament_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)
    status = Column(Enum(RegistrationStatus, native_enum=False), default=RegistrationStatus.PENDING, nullable=False)
    registration_data = Column(String, nullable=True) # JSON payload from coach
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    tournament = relationship("Tournament", back_populates="registrations")
    team = relationship("Team")

class TournamentTeam(Base):
    __tablename__ = "tournament_teams"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    division_id = Column(UUID(as_uuid=True), ForeignKey("tournament_divisions.id"), nullable=True) # Required in new flow
    tournament_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=True) # Keep for migration/legacy
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)
    registered_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    status = Column(Enum(RegistrationStatus, native_enum=False), default=RegistrationStatus.PENDING, nullable=False)
    registration_data = Column(String, nullable=True) # JSON payload
    is_locked = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    division = relationship("TournamentDivision", back_populates="teams")
    tournament = relationship("Tournament") # Generic link if needed
    team = relationship("Team")
    squad = relationship("TournamentSquad", back_populates="tournament_team", cascade="all, delete-orphan")

class TournamentSquad(Base):
    __tablename__ = "tournament_squads"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tournament_team_id = Column(UUID(as_uuid=True), ForeignKey("tournament_teams.id"), nullable=False)
    child_profile_id = Column(UUID(as_uuid=True), ForeignKey("child_profiles.id"), nullable=False)
    jersey_number = Column(Integer, nullable=True)
    position = Column(String, nullable=True)
    added_at = Column(DateTime(timezone=True), server_default=func.now())

    tournament_team = relationship("TournamentTeam", back_populates="squad")
    child_profile = relationship("app.clubs.models.ChildProfile")

class TournamentGroup(Base):
    __tablename__ = "tournament_groups"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tournament_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=False)
    name = Column(String, nullable=False)

    tournament = relationship("Tournament")
    teams = relationship("TournamentGroupTeam", back_populates="group", cascade="all, delete-orphan")

class TournamentGroupTeam(Base):
    __tablename__ = "tournament_group_teams"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    group_id = Column(UUID(as_uuid=True), ForeignKey("tournament_groups.id"), nullable=False)
    tournament_team_id = Column(UUID(as_uuid=True), ForeignKey("tournament_teams.id"), nullable=False)

    group = relationship("TournamentGroup", back_populates="teams")
    tournament_team = relationship("TournamentTeam")

class TournamentStandings(Base):
    __tablename__ = "tournament_standings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tournament_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=False)
    division_id = Column(UUID(as_uuid=True), ForeignKey("tournament_divisions.id"), nullable=True)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)

    played = Column(Integer, default=0)
    wins = Column(Integer, default=0)
    draws = Column(Integer, default=0)
    losses = Column(Integer, default=0)
    goals_for = Column(Integer, default=0)
    goals_against = Column(Integer, default=0)
    goal_difference = Column(Integer, default=0)
    points = Column(Integer, default=0)

    group_id = Column(UUID(as_uuid=True), ForeignKey("tournament_groups.id"), nullable=True)

    tournament = relationship("Tournament")
    division = relationship("TournamentDivision")
    team = relationship("Team")
    group = relationship("TournamentGroup")

class ScheduleTaskStatus(str, enum.Enum):
    PENDING = "PENDING"
    GENERATING = "GENERATING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class ScheduleTask(Base):
    __tablename__ = "schedule_tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tournament_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=False)
    status = Column(Enum(ScheduleTaskStatus, native_enum=False), default=ScheduleTaskStatus.PENDING, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    tournament = relationship("Tournament")

class TournamentPlayerStats(Base):
    __tablename__ = "tournament_player_stats"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    division_id = Column(UUID(as_uuid=True), ForeignKey("tournament_divisions.id"), nullable=False)
    child_profile_id = Column(UUID(as_uuid=True), ForeignKey("child_profiles.id"), nullable=False)
    
    goals = Column(Integer, default=0)
    assists = Column(Integer, default=0)
    matches_played = Column(Integer, default=0)
    clean_sheets = Column(Integer, default=0)
    yellow_cards = Column(Integer, default=0)
    red_cards = Column(Integer, default=0)

    division = relationship("TournamentDivision", back_populates="player_stats")
    child_profile = relationship("app.clubs.models.ChildProfile")

class TournamentAward(Base):
    __tablename__ = "tournament_awards"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    division_id = Column(UUID(as_uuid=True), ForeignKey("tournament_divisions.id"), nullable=False)
    child_profile_id = Column(UUID(as_uuid=True), ForeignKey("child_profiles.id"), nullable=False)
    title = Column(String, nullable=False) # e.g., 'Best Player', 'Top Scorer'
    description = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    division = relationship("TournamentDivision", back_populates="awards")
    child_profile = relationship("app.clubs.models.ChildProfile")
