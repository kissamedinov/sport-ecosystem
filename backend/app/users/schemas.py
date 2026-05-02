from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import date, datetime
from typing import Optional, List
from uuid import UUID
from app.users.models import Role, ParentChildStatus

class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    password: str
    role: Role = Role.PLAYER_ADULT
    date_of_birth: Optional[date] = None
    phone: Optional[str] = None
class UserUpdate(BaseModel):
    name: Optional[str] = None
    date_of_birth: Optional[date] = None
    phone: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None

class UserResponse(UserBase):
    id: UUID
    role: Role
    roles: List[str] = []
    created_at: datetime
    date_of_birth: Optional[date] = None
    phone: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    unique_code: Optional[str] = None
    onboarding_completed: bool = False

    model_config = ConfigDict(from_attributes=True)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[str] = None
    role: Optional[Role] = None

class ParentChildRequestResponse(BaseModel):
    id: UUID
    parent_id: UUID
    parent_name: str
    status: ParentChildStatus
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class ChildCreateByParent(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    password: str
    date_of_birth: date
    academy_invite_code: Optional[str] = None

class LinkChildByEmailRequest(BaseModel):
    email: EmailStr
