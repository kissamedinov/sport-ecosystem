from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.users.models import User, Role
from app.common.dependencies import get_current_user, require_role, require_permission
from app.fields import schemas, models

router = APIRouter(prefix="/fields", tags=["Fields"])

@router.post("/{id}/slots", response_model=schemas.FieldSlotResponse, status_code=status.HTTP_201_CREATED)
def create_slot(
    id: UUID,
    slot_in: schemas.FieldSlotCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission("EDIT_FIELD"))
):
    # Verify field ownership
    field = db.query(models.Field).filter(models.Field.id == id).first()
    if not field or field.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not the owner of this field")
        
    new_slot = models.FieldSlot(
        field_id=id,
        start_time=slot_in.start_time,
        end_time=slot_in.end_time,
        price=slot_in.price,
        is_available=True
    )
    db.add(new_slot)
    db.commit()
    db.refresh(new_slot)
    return new_slot

@router.get("/{id}/slots", response_model=List[schemas.FieldSlotResponse])
def get_available_slots(id: UUID, db: Session = Depends(get_db)):
    return db.query(models.FieldSlot).filter(
        models.FieldSlot.field_id == id,
        models.FieldSlot.is_available == True
    ).all()
