from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import date, datetime
from typing import Optional, List
from uuid import UUID
from app.users.models import Role

class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    password: str
    role: Role = Role.PLAYER_ADULT
    date_of_birth: Optional[date] = None
    phone: Optional[str] = None

class UserResponse(UserBase):
    id: UUID
    role: Role
    roles: List[str] = []
    created_at: datetime
    date_of_birth: Optional[date] = None
    phone: Optional[str] = None

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
