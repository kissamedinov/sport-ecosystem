from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import date, datetime


class TaskCreate(BaseModel):
    title: str
    time: Optional[str] = None
    category: str = "TRAINING"
    date: date


class TaskToggle(BaseModel):
    done: bool


class TaskOut(BaseModel):
    id: UUID
    title: str
    time: Optional[str]
    category: str
    date: date
    done: bool
    created_at: datetime

    class Config:
        from_attributes = True
