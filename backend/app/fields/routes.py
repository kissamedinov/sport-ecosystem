from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.users.models import User, Role
from app.common.dependencies import get_current_user, require_role, require_permission
from app.fields import schemas, models

from app.fields import schemas, models, services

router = APIRouter(prefix="/fields", tags=["Fields"])

@router.post("", response_model=schemas.FieldResponse, status_code=status.HTTP_201_CREATED)
def create_field(
    field_in: schemas.FieldCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.create_field(db, field_in, current_user.id)

@router.post("/{id}/slots", response_model=schemas.FieldSlotResponse, status_code=status.HTTP_201_CREATED)
def create_slot(
    id: UUID,
    slot_in: schemas.FieldSlotCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Manual slot creation
    return services.create_field_slot_manual(db, id, slot_in, current_user.id)

@router.post("/{id}/slots/generate", status_code=status.HTTP_201_CREATED)
def generate_slots(
    id: UUID,
    gen_in: schemas.FieldSlotBatchGenerate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify ownership is inside service or here
    return services.generate_field_slots(
        db, id, gen_in.date, gen_in.start_hour, gen_in.end_hour, 
        gen_in.slot_duration_minutes, gen_in.price
    )

@router.get("/{id}/slots", response_model=List[schemas.FieldSlotResponse])
def get_available_slots(id: UUID, db: Session = Depends(get_db)):
    return services.get_available_slots(db, id)
