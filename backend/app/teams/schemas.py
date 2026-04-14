from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime
from uuid import UUID
from app.users.schemas import UserResponse

class TeamBase(BaseModel):
    name: str
    academy_id: Optional[UUID] = None
    age_category: Optional[str] = None
    birth_year: Optional[int] = None
    division: Optional[str] = "Group A"

class TeamCreate(TeamBase):
    pass

class TeamResponse(TeamBase):
    id: UUID
    coach_id: UUID
    created_at: datetime

    class Config:
        orm_mode = True
        from_attributes = True

class PlayerTeamResponse(BaseModel):
    id: UUID
    team_id: UUID
    player_id: UUID
    joined_at: datetime
    left_at: Optional[datetime] = None
    player: Optional[UserResponse] = None

    class Config:
        orm_mode = True
        from_attributes = True

class TeamMatchResponse(BaseModel):
    id: UUID
    tournament_id: UUID
    home_team_id: UUID
    away_team_id: UUID
    home_score: int
    away_score: int
    status: str
    start_time: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class TeamDetailResponse(TeamResponse):
    coach: UserResponse
    players: List[PlayerTeamResponse] = []
    recent_matches: List[TeamMatchResponse] = []
    form: List[str] = [] # e.g. ["W", "D", "L"]

    model_config = ConfigDict(from_attributes=True)

# Aliases kept for backward compatibility with route files
YouthTeamBase = TeamBase
YouthTeamCreate = TeamCreate
YouthTeamResponse = TeamResponse
YouthTeamDetailResponse = TeamDetailResponse
PlayerYouthTeamResponse = PlayerTeamResponse
