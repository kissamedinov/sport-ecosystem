from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from uuid import UUID
from datetime import datetime, timedelta
from app.fields import models, schemas

def create_field(db: Session, field_in: schemas.FieldCreate, owner_id: UUID):
    new_field = models.Field(
        name=field_in.name,
        location=field_in.location,
        owner_id=owner_id
    )
    db.add(new_field)
    db.commit()
    db.refresh(new_field)
    return new_field

def create_field_slot_manual(db: Session, field_id: UUID, slot_in: schemas.FieldSlotCreate, user_id: UUID):
    field = db.query(models.Field).filter(models.Field.id == field_id).first()
    if not field or field.owner_id != user_id:
        raise HTTPException(status_code=403, detail="Not the owner of this field")
        
    new_slot = models.FieldSlot(
        field_id=field_id,
        start_time=slot_in.start_time,
        end_time=slot_in.end_time,
        price=slot_in.price,
        is_available=True
    )
    db.add(new_slot)
    db.commit()
    db.refresh(new_slot)
    return new_slot

def generate_field_slots(
    db: Session, 
    field_id: UUID, 
    date: datetime, 
    start_hour: int, 
    end_hour: int, 
    slot_duration_minutes: int,
    price: float
):
    """
    Automatically generates time slots for a field on a specific date.
    Example: 9:00 to 21:00 with 60 min slots.
    """
    field = db.query(models.Field).filter(models.Field.id == field_id).first()
    if not field:
        raise HTTPException(status_code=404, detail="Field not found")

    current_time = date.replace(hour=start_hour, minute=0, second=0, microsecond=0)
    end_time = date.replace(hour=end_hour, minute=0, second=0, microsecond=0)
    
    slots_created = 0
    while current_time + timedelta(minutes=slot_duration_minutes) <= end_time:
        slot_end = current_time + timedelta(minutes=slot_duration_minutes)
        
        # Check if slot already exists to avoid duplicates
        exists = db.query(models.FieldSlot).filter(
            models.FieldSlot.field_id == field_id,
            models.FieldSlot.start_time == current_time
        ).first()
        
        if not exists:
            new_slot = models.FieldSlot(
                field_id=field_id,
                start_time=current_time,
                end_time=slot_end,
                price=price,
                is_available=True
            )
            db.add(new_slot)
            slots_created += 1
        
        current_time = slot_end
        
    db.commit()
    return {"message": f"Successfully generated {slots_created} slots."}

def get_available_slots(db: Session, field_id: UUID, start_date: datetime = None):
    query = db.query(models.FieldSlot).filter(
        models.FieldSlot.field_id == field_id,
        models.FieldSlot.is_available == True
    )
    if start_date:
        query = query.filter(models.FieldSlot.start_time >= start_date)
    
    return query.order_by(models.FieldSlot.start_time).all()
