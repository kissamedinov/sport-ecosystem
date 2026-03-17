from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import date, datetime
from uuid import UUID
from app.tournaments.models import TournamentFormat, AgeCategory, RegistrationStatus, SurfaceType, Season, MatchStatus as TournamentMatchStatus
from app.teams.schemas import TeamResponse

class TournamentBase(BaseModel):
    name: str
    location: str
    start_date: date
    end_date: date
    registration_open: date
    registration_close: date
    format: TournamentFormat
    age_category: AgeCategory
    allowed_age_categories: Optional[str] = None # JSON list
    created_by: Optional[UUID] = None
    history_data: Optional[str] = None # JSON string
    num_fields: int = 1
    match_half_duration: int = 20
    halftime_break_duration: int = 5
    break_between_matches: int = 10
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    minimum_rest_slots: int = 1
    points_for_win: int = 3
    points_for_draw: int = 1
    points_for_loss: int = 0
    status: Optional[str] = "upcoming"
    surface_type: Optional[SurfaceType] = SurfaceType.NATURAL_GRASS
    series_name: Optional[str] = None # Legacy
    series_id: Optional[UUID] = None
    year: Optional[int] = None
    season: Optional[Season] = None

class TournamentCreate(TournamentBase):
    pass

class TournamentResponse(TournamentBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class TournamentRegistrationBase(BaseModel):
    tournament_id: UUID
    team_id: UUID

class TournamentRegistrationCreate(TournamentRegistrationBase):
    registration_data: Optional[str] = None # JSON payload

class TournamentRegistrationResponse(TournamentRegistrationBase):
    id: UUID
    status: RegistrationStatus
    registration_data: Optional[str] = None
    created_at: datetime
    team: Optional[TeamResponse] = None

    model_config = ConfigDict(from_attributes=True)

class TournamentDetailResponse(TournamentResponse):
    registrations: List[TournamentRegistrationResponse] = []

    model_config = ConfigDict(from_attributes=True)

class TournamentGroupTeamResponse(BaseModel):
    id: UUID
    tournament_team_id: UUID

    model_config = ConfigDict(from_attributes=True)

class TournamentGroupResponse(BaseModel):
    id: UUID
    name: str
    teams: List[TournamentGroupTeamResponse] = []

    model_config = ConfigDict(from_attributes=True)

class TournamentStandingsResponse(BaseModel):
    team_id: UUID
    team_name: Optional[str] = None
    played: int
    wins: int
    draws: int
    losses: int
    goals_for: int
    goals_against: int
    goal_difference: int
    points: int
    group_id: Optional[UUID] = None

    model_config = ConfigDict(from_attributes=True)

class ScheduleTaskResponse(BaseModel):
    id: UUID
    tournament_id: UUID
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class TournamentMatchResponse(BaseModel):
    id: UUID
    tournament_id: UUID
    home_team_id: UUID
    away_team_id: UUID
    field_number: Optional[int] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    status: TournamentMatchStatus = TournamentMatchStatus.SCHEDULED
    home_score: int = 0
    away_score: int = 0
    group_id: Optional[UUID] = None

    model_config = ConfigDict(from_attributes=True)

class TournamentTeamResponse(BaseModel):
    id: UUID
    division_id: Optional[UUID] = None
    tournament_id: Optional[UUID] = None
    team_id: UUID
    status: RegistrationStatus
    team: TeamResponse

    model_config = ConfigDict(from_attributes=True)

class TournamentSeriesBase(BaseModel):
    name: str
    city: str
    description: Optional[str] = None

class TournamentSeriesCreate(TournamentSeriesBase):
    organizer_id: UUID

class TournamentSeriesResponse(TournamentSeriesBase):
    id: UUID
    organizer_id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class TournamentDivisionBase(BaseModel):
    tournament_edition_id: UUID
    birth_year: int
    max_teams: int = 10

class TournamentDivisionCreate(TournamentDivisionBase):
    pass

class TournamentDivisionResponse(TournamentDivisionBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class MatchSheetPlayerBase(BaseModel):
    player_profile_id: UUID
    jersey_number: Optional[int] = None
    is_starting: bool = True

class MatchSheetCreate(BaseModel):
    match_id: UUID
    team_id: UUID
    players: List[MatchSheetPlayerBase]

class MatchPlayerStatsCreate(BaseModel):
    goals: int = 0
    assists: int = 0
    yellow_cards: int = 0
    red_cards: int = 0
    is_goalkeeper: bool = False

class TournamentAwardCreate(BaseModel):
    division_id: UUID
    player_profile_id: UUID
    title: str
    description: Optional[str] = None

class TournamentAwardResponse(BaseModel):
    id: UUID
    division_id: UUID
    player_profile_id: UUID
    title: str
    description: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class TournamentPlayerStatsResponse(BaseModel):
    division_id: UUID
    player_profile_id: UUID
    goals: int
    assists: int
    matches_played: int
    clean_sheets: int
    yellow_cards: int
    red_cards: int

    model_config = ConfigDict(from_attributes=True)

class TournamentSquadMemberBase(BaseModel):
    player_profile_id: UUID
    jersey_number: Optional[int] = None
    position: Optional[str] = None

class TournamentSquadCreate(BaseModel):
    players: List[TournamentSquadMemberBase]

class TournamentSquadMemberResponse(TournamentSquadMemberBase):
    id: UUID
    tournament_team_id: UUID

    model_config = ConfigDict(from_attributes=True)
