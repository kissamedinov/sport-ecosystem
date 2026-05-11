from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from uuid import UUID

class FieldBase(BaseModel):
    name: str
    location: str

class FieldCreate(FieldBase):
    pass

class FieldResponse(FieldBase):
    id: UUID
    owner_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True

class FieldSlotBase(BaseModel):
    start_time: datetime
    end_time: datetime
    price: float = Field(..., ge=0)

class FieldSlotCreate(FieldSlotBase):
    pass

class FieldSlotResponse(FieldSlotBase):
    id: UUID
    field_id: UUID
    is_available: bool

    class Config:
        from_attributes = True

class FieldSlotBatchGenerate(BaseModel):
    date: datetime
    start_hour: int = Field(9, ge=0, le=23)
    end_hour: int = Field(22, ge=0, le=24)
    slot_duration_minutes: int = Field(60, gt=0)
    price: float = Field(..., ge=0)
