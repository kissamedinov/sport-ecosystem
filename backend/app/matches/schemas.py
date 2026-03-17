from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from uuid import UUID
from app.matches.models import MatchStatus, ResultStatus, EventType, LineupRole

class MatchResultBase(BaseModel):
    home_score: int = Field(..., ge=0)
    away_score: int = Field(..., ge=0)

class MatchResultCreate(MatchResultBase):
    pass

class MatchResultResponse(MatchResultBase):
    id: UUID
    match_id: UUID
    status: ResultStatus
    submitted_by: UUID
    created_at: datetime

    class Config:
        from_attributes = True

class MatchBase(BaseModel):
    tournament_id: UUID
    home_team_id: UUID
    away_team_id: UUID
    round_number: int
    match_date: Optional[datetime] = None
    group_id: Optional[UUID] = None

class MatchResponse(MatchBase):
    id: UUID
    status: MatchStatus
    created_at: datetime
    result: Optional[MatchResultResponse] = None

    class Config:
        from_attributes = True

class TournamentGroupBase(BaseModel):
    name: str

class TournamentGroupResponse(TournamentGroupBase):
    id: UUID
    tournament_id: UUID

    class Config:
        from_attributes = True

class StandingEntry(BaseModel):
    team_id: UUID
    team_name: str
    played: int = 0
    wins: int = 0
    draws: int = 0
    losses: int = 0
    goals_for: int = 0
    goals_against: int = 0
    goal_difference: int = 0
    points: int = 0
    rating: int = 1000

class TournamentStandings(BaseModel):
    tournament_id: UUID
    standings: List[StandingEntry]

class MatchEventBase(BaseModel):
    event_type: EventType
    minute: int
    team_id: Optional[UUID] = None
    player_id: Optional[UUID] = None

class MatchEventCreate(MatchEventBase):
    pass

class MatchEventResponse(MatchEventBase):
    id: UUID
    match_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True

class LineupPlayerBase(BaseModel):
    player_id: UUID
    role: LineupRole
    position: Optional[str] = None
    jersey_number: Optional[int] = None

class LineupPlayerResponse(LineupPlayerBase):
    id: UUID
    
    class Config:
        from_attributes = True

class LineupCreate(BaseModel):
    team_id: UUID
    players: List[LineupPlayerBase]

class LineupResponse(BaseModel):
    id: UUID
    match_id: UUID
    team_id: UUID
    players: List[LineupPlayerResponse]
    created_at: datetime

    class Config:
        from_attributes = True

class MatchLineupsResponse(BaseModel):
    home_lineup: Optional[LineupResponse] = None
    away_lineup: Optional[LineupResponse] = None
