from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime, date, time
from uuid import UUID
from enum import Enum

# Enums
class AgeGroup(str, Enum):
    U7 = "U7"
    U9 = "U9"
    U11 = "U11"
    U13 = "U13"
    U15 = "U15"
    U17 = "U17"

class DayOfWeek(str, Enum):
    MONDAY = "MONDAY"
    TUESDAY = "TUESDAY"
    WEDNESDAY = "WEDNESDAY"
    THURSDAY = "THURSDAY"
    FRIDAY = "FRIDAY"
    SATURDAY = "SATURDAY"
    SUNDAY = "SUNDAY"

class AcademyPlayerStatus(str, Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    LEFT = "LEFT"

class AttendanceStatus(str, Enum):
    PRESENT = "PRESENT"
    ABSENT = "ABSENT"
    LATE = "LATE"
    INJURED = "INJURED"

# Academy schemas
class AcademyBase(BaseModel):
    name: str
    city: str
    address: str
    description: Optional[str] = None

class AcademyCreate(AcademyBase):
    pass

class AcademyResponse(AcademyBase):
    id: UUID
    owner_id: UUID
    club_id: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# Academy Team schemas
class AcademyTeamBase(BaseModel):
    name: str
    age_group: str

class AcademyTeamCreate(AcademyTeamBase):
    coach_id: Optional[UUID] = None

class AcademyTeamResponse(AcademyTeamBase):
    id: UUID
    academy_id: UUID
    coach_id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# Academy Player schemas
class AcademyPlayerBase(BaseModel):
    player_profile_id: UUID
    status: AcademyPlayerStatus = AcademyPlayerStatus.ACTIVE

class AcademyPlayerCreate(AcademyPlayerBase):
    pass

class AcademyPlayerResponse(AcademyPlayerBase):
    id: UUID
    academy_id: UUID
    joined_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# Academy Team Player schemas
class AcademyTeamPlayerBase(BaseModel):
    player_profile_id: UUID
    position: Optional[str] = None
    jersey_number: Optional[int] = None

class AcademyTeamPlayerCreate(AcademyTeamPlayerBase):
    pass

class AcademyTeamPlayerResponse(AcademyTeamPlayerBase):
    id: UUID
    team_id: UUID
    joined_at: datetime

    model_config = ConfigDict(from_attributes=True)

# Training Session schemas
class TrainingSessionBase(BaseModel):
    date: date
    start_time: time
    end_time: time
    description: Optional[str] = None

class TrainingSessionCreate(TrainingSessionBase):
    team_ids: List[UUID]

class TrainingSessionResponse(TrainingSessionBase):
    id: UUID
    academy_id: UUID
    coach_id: UUID
    team_ids: List[UUID] = []

    model_config = ConfigDict(from_attributes=True)

# Training Attendance schemas
class TrainingAttendanceBase(BaseModel):
    player_id: UUID
    status: AttendanceStatus
    note: Optional[str] = None

class TrainingAttendanceCreate(TrainingAttendanceBase):
    training_id: UUID

class TrainingAttendanceResponse(TrainingAttendanceBase):
    id: UUID
    training_id: UUID

    model_config = ConfigDict(from_attributes=True)

# Coach Feedback schemas
class CoachFeedbackBase(BaseModel):
    technical: int
    tactical: int
    physical: int
    discipline: int
    comment: Optional[str] = None

class CoachFeedbackCreate(CoachFeedbackBase):
    player_id: UUID
    academy_id: UUID

class CoachFeedbackResponse(CoachFeedbackBase):
    id: UUID
    player_id: UUID
    coach_id: UUID
    academy_id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class AcademyRankingResponse(BaseModel):
    id: UUID
    academy_id: UUID
    points: int
    tournaments_played: int
    tournaments_won: int
    last_updated: datetime
    academy: Optional[AcademyBase] = None

    model_config = ConfigDict(from_attributes=True)

# Training Schedule schemas
class TrainingScheduleBase(BaseModel):
    day_of_week: DayOfWeek
    start_time: time
    end_time: time
    location: Optional[str] = None
    branch_id: Optional[UUID] = None

class TrainingScheduleCreate(TrainingScheduleBase):
    team_ids: List[UUID]

class TrainingScheduleBatchCreate(BaseModel):
    schedules: List[TrainingScheduleCreate]

class TrainingScheduleResponse(TrainingScheduleBase):
    id: UUID
    academy_id: UUID
    team_ids: List[UUID] = []

    model_config = ConfigDict(from_attributes=True)

# Academy Branch schemas
class AcademyBranchBase(BaseModel):
    name: str # e.g., "Summer Branch", "Winter Branch"
    address: str
    description: Optional[str] = None

class AcademyBranchCreate(AcademyBranchBase):
    pass

class AcademyBranchResponse(AcademyBranchBase):
    id: UUID
    academy_id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# Academy Billing Config schemas
class AcademyBillingConfigBase(BaseModel):
    monthly_subscription_fee: Optional[float] = None
    per_session_fee: Optional[float] = None
    currency: str = "KZT"

class AcademyBillingConfigCreate(AcademyBillingConfigBase):
    pass

class AcademyBillingConfigResponse(AcademyBillingConfigBase):
    id: UUID
    academy_id: UUID

    model_config = ConfigDict(from_attributes=True)

# Summary schemas
class AttendanceSummary(BaseModel):
    total_sessions: int
    present: int
    absent: int
    late: int
    injured: int

class BillingSummary(BaseModel):
    player_id: UUID
    player_name: str
    attendance: AttendanceSummary
    base_fee: float
    additional_fees: float
    total_owed: float
    currency: str
class AcademyCompositePlayerResponse(BaseModel):
    id: str
    full_name: str
    birth_year: Optional[int] = None
    team_name: str

    model_config = ConfigDict(from_attributes=True)
