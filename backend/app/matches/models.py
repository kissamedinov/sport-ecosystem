import uuid
import enum
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Enum, func, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base

class MatchStatus(str, enum.Enum):
    SCHEDULED = "SCHEDULED"
    FINISHED = "FINISHED"
    CANCELED = "CANCELED"

class ResultStatus(str, enum.Enum):
    SUBMITTED = "SUBMITTED"
    FINAL = "FINAL"

class LineupRole(str, enum.Enum):
    STARTING = "STARTING"
    SUBSTITUTE = "SUBSTITUTE"

class LineupStatus(str, enum.Enum):
    SUBMITTED = "SUBMITTED"
    CONFIRMED = "CONFIRMED"

class EventType(str, enum.Enum):
    GOAL = "GOAL"
    ASSIST = "ASSIST"
    SAVE = "SAVE"
    YELLOW_CARD = "YELLOW_CARD"
    RED_CARD = "RED_CARD"
    OWN_GOAL = "OWN_GOAL"
    PENALTY_GOAL = "PENALTY_GOAL"
    BEST_PLAYER = "BEST_PLAYER"

class MatchAwardType(str, enum.Enum):
    MVP = "MVP"
    BEST_GOALKEEPER = "BEST_GOALKEEPER"
    BEST_DEFENDER = "BEST_DEFENDER"
    BEST_STRIKER = "BEST_STRIKER"



class Match(Base):
    __tablename__ = "matches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tournament_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=False)
    home_team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)
    away_team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)
    field_id = Column(UUID(as_uuid=True), nullable=True) # Field service not yet fully implemented
    group_id = Column(UUID(as_uuid=True), ForeignKey("tournament_groups.id"), nullable=True)
    round_number = Column(Integer, nullable=False, default=1)
    match_date = Column(DateTime(timezone=True), nullable=True)
    status = Column(Enum(MatchStatus), default=MatchStatus.SCHEDULED, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    tournament = relationship("Tournament")
    home_team = relationship("Team", foreign_keys=[home_team_id])
    away_team = relationship("Team", foreign_keys=[away_team_id])
    group = relationship("app.tournaments.models.TournamentGroup")
    result = relationship("MatchResult", back_populates="match", uselist=False)

class MatchResult(Base):
    __tablename__ = "match_results"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), unique=True, nullable=False)
    home_score = Column(Integer, nullable=False, default=0)
    away_score = Column(Integer, nullable=False, default=0)
    status = Column(Enum(ResultStatus), default=ResultStatus.SUBMITTED, nullable=False)
    submitted_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    match = relationship("Match", back_populates="result")
    submitter = relationship("User")

class MatchLineup(Base):
    __tablename__ = "match_lineups"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)
    submitted_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    status = Column(Enum(LineupStatus), default=LineupStatus.SUBMITTED, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    match = relationship("Match")
    team = relationship("Team")
    submitter = relationship("User")
    players = relationship("MatchLineupPlayer", back_populates="lineup", cascade="all, delete-orphan")

class MatchLineupPlayer(Base):
    __tablename__ = "match_lineup_players"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lineup_id = Column(UUID(as_uuid=True), ForeignKey("match_lineups.id"), nullable=False)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    child_profile_id = Column(UUID(as_uuid=True), ForeignKey("child_profiles.id"), nullable=True)
    
    is_starting = Column(Boolean, default=True, nullable=False)
    role = Column(Enum(LineupRole), default=LineupRole.STARTING, nullable=False)
    position = Column(String, nullable=True) # GK, DF, MF, FW
    jersey_number = Column(Integer, nullable=True)

    lineup = relationship("MatchLineup", back_populates="players")
    player = relationship("User")
    child_profile = relationship("ChildProfile")

class MatchPlayerStats(Base):
    __tablename__ = "match_player_stats"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), nullable=False)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=False)

    goals = Column(Integer, default=0)
    assists = Column(Integer, default=0)
    yellow_cards = Column(Integer, default=0)
    red_cards = Column(Integer, default=0)
    # minutes_played removed as per rule change
    pass
    is_best_player = Column(Boolean, default=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    match = relationship("Match")
    player = relationship("User")
    team = relationship("Team")

class MatchEvent(Base):
    __tablename__ = "match_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id"), nullable=True)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    child_profile_id = Column(UUID(as_uuid=True), ForeignKey("child_profiles.id"), nullable=True)
    event_type = Column(Enum(EventType), nullable=False)
    minute = Column(Integer, nullable=False)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    match = relationship("Match")
    team = relationship("Team")
    player = relationship("User", foreign_keys=[player_id])
    child_profile = relationship("ChildProfile")
    creator = relationship("User", foreign_keys=[created_by])

class MatchAward(Base):
    __tablename__ = "match_awards"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), nullable=False)
    player_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    child_profile_id = Column(UUID(as_uuid=True), ForeignKey("child_profiles.id"), nullable=True)
    award_type = Column(Enum(MatchAwardType), nullable=False)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    match = relationship("Match")
    player = relationship("User", foreign_keys=[player_id])
    child_profile = relationship("ChildProfile")
    creator = relationship("User", foreign_keys=[created_by])
