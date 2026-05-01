from __future__ import annotations
from pydantic import BaseModel, EmailStr, ConfigDict
from uuid import UUID
from datetime import datetime
from typing import List, Optional
from app.clubs.models import ClubRole, ClubMembershipStatus, RequestStatus, InvitationStatus

class ClubBase(BaseModel):
    name: str
    city: str

class ClubCreate(ClubBase):
    address: Optional[str] = None
    training_schedule: Optional[str] = None
    whatsapp: Optional[str] = None
    instagram: Optional[str] = None

class ClubResponse(ClubBase):
    id: UUID
    owner_id: UUID
    address: Optional[str] = None
    training_schedule: Optional[str] = None
    whatsapp: Optional[str] = None
    instagram: Optional[str] = None
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class ClubRequestBase(BaseModel):
    name: str
    city: str
    address: str
    training_schedule: Optional[str] = None
    contact_phone: Optional[str] = None
    social_links: Optional[str] = None
    description: Optional[str] = None

class ClubRequestCreate(ClubRequestBase):
    pass

class ClubRequestResponse(ClubRequestBase):
    id: UUID
    created_by: UUID
    status: RequestStatus
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class InvitationBase(BaseModel):
    invited_user_id: UUID
    role: ClubRole
    club_id: UUID
    team_id: Optional[UUID] = None
    child_profile_id: Optional[UUID] = None
    expires_at: Optional[datetime] = None

class InvitationCreate(InvitationBase):
    pass

class InvitationResponse(InvitationBase):
    id: UUID
    invited_by: UUID
    status: InvitationStatus
    is_approved: bool
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class ClubStaffBase(BaseModel):
    user_id: UUID
    role: ClubRole

class ClubStaffCreate(ClubStaffBase):
    team_id: UUID
    jersey_number: Optional[int] = None
    position: Optional[str] = None

class ClubPlayerAdd(BaseModel):
    player_user_id: UUID
    team_id: UUID
    jersey_number: Optional[int] = None
    position: Optional[str] = None

class ClubStaffResponse(ClubStaffBase):
    id: UUID
    club_id: UUID
    status: ClubMembershipStatus
    joined_at: datetime
    left_at: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)

class PlayerResponse(BaseModel):
    user_id: UUID
    name: str
    profile_id: UUID
    position: Optional[str] = None
    jersey_number: Optional[int] = None
    model_config = ConfigDict(from_attributes=True)

class ChildProfileBase(BaseModel):
    first_name: str
    last_name: str
    date_of_birth: datetime
    position: Optional[str] = None

class ChildProfileCreate(ChildProfileBase):
    club_id: UUID

class ChildProfileResponse(ChildProfileBase):
    id: UUID
    created_by: UUID
    club_id: UUID
    linked_user_id: Optional[UUID] = None
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class AcademyBase(BaseModel):
    name: str
    city: str
    address: str

class AcademyCreate(AcademyBase):
    pass

class AcademyResponse(AcademyBase):
    id: UUID
    club_id: UUID
    owner_id: UUID
    logo_url: Optional[str] = None
    teams_count: Optional[int] = 0
    players_count: Optional[int] = 0
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class TeamCreateInAcademy(BaseModel):
    name: str
    birth_year: Optional[int] = None
    coach_id: UUID

class TeamResponseSimplified(BaseModel):
    id: UUID
    name: str
    academy_id: UUID
    academy_name: Optional[str] = None
    city: str
    coach_id: UUID
    rating: int = 0
    matches_played: int = 0
    wins: int = 0
    draws: int = 0
    losses: int = 0
    birth_year: Optional[int] = None
    age_category: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

class CoachPlayerResponse(BaseModel):
    user_id: UUID
    name: str
    profile_id: UUID
    position: Optional[str] = None
    jersey_number: Optional[int] = None

class CoachTeamResponse(BaseModel):
    id: UUID
    name: str
    birth_year: Optional[int] = None
    players: List[CoachPlayerResponse]
    wins: int = 0
    draws: int = 0
    losses: int = 0
    goals_scored: int = 0
    goals_conceded: int = 0
    clean_sheets: int = 0
    elo_rating: int = 1200
    form: List[str] = []

class CoachMatchResponse(BaseModel):
    id: UUID
    tournament_name: str
    home_team_name: str
    away_team_name: str
    home_team_id: UUID
    away_team_id: UUID
    scheduled_at: Optional[datetime] = None

class CoachPerformanceStats(BaseModel):
    matches_played: int = 0
    wins: int = 0
    draws: int = 0
    losses: int = 0
    goals_scored: int = 0
    goals_conceded: int = 0
    clean_sheets: int = 0

class CoachDashboardResponse(BaseModel):
    name: str
    teams: List[CoachTeamResponse]
    upcoming_matches: List[CoachMatchResponse]
    performance_stats: Optional[CoachPerformanceStats] = None
    rating: float = 0.0
    is_certified: bool = False
    specialty: str = "Tactics & Youth Development"
    club_name: Optional[str] = None

class ClubDashboardResponse(BaseModel):
    club: ClubResponse
    academies: List[AcademyResponse]
    teams: List[TeamResponseSimplified]
    players: List[PlayerResponse] = []
    coaches: List[PlayerResponse] = []
    managers: List[PlayerResponse] = []
    child_profiles: List[ChildProfileResponse] = []
    players_count: int
    coaches_count: int
    managers_count: int = 0
    pending_invitations: List[InvitationResponse] = []
    statistics: dict = {
        "new_coaches_30d": 0,
        "new_players_30d": 0,
        "academies_count": 0,
        "teams_count": 0
    }

class CareerRecord(BaseModel):
    club_name: str
    team_name: str
    joined_at: datetime
    left_at: Optional[datetime] = None
    status: str

class PlayerCareerResponse(BaseModel):
    player_name: str
    career_history: List[CareerRecord]
    total_goals: int
    total_assists: int
    awards: List[str]

class MatchSheetPlayerCreate(BaseModel):
    player_profile_id: UUID
    is_starting: bool = True
    jersey_number: Optional[int] = None

class MatchSheetCreate(BaseModel):
    match_id: UUID
    team_id: UUID
    players: List[MatchSheetPlayerCreate]

# Rebuild models to resolve forward references or complex types in Pydantic v2
for model in [
    ClubBase, ClubCreate, ClubResponse,
    ClubRequestBase, ClubRequestCreate, ClubRequestResponse,
    InvitationBase, InvitationCreate, InvitationResponse,
    ClubStaffBase, ClubStaffCreate, ClubPlayerAdd, ClubStaffResponse,
    PlayerResponse, ChildProfileBase, ChildProfileCreate, ChildProfileResponse,
    AcademyBase, AcademyCreate, AcademyResponse,
    TeamCreateInAcademy, TeamResponseSimplified,
    CoachPlayerResponse, CoachTeamResponse,
    CoachMatchResponse, CoachPerformanceStats, CoachDashboardResponse, ClubDashboardResponse,
    CareerRecord, PlayerCareerResponse,
    MatchSheetPlayerCreate, MatchSheetCreate
]:
    model.model_rebuild()
