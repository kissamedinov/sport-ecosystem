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
    from datetime import date, time
    
    # Dynamic Auto-Generation of Slots (Rolling 14-day window)
    today = date.today()
    
    # 1. Determine price from latest slots of this field
    last_slot = db.query(models.FieldSlot).filter(
        models.FieldSlot.field_id == field_id
    ).order_by(models.FieldSlot.start_time.desc()).first()
    base_price = last_slot.price if last_slot else 15000.0
    
    # 2. Iterate through next 14 days and create missing slots
    for day_offset in range(14):
        slot_date = today + timedelta(days=day_offset)
        
        # Check if slots exist for this date
        # Check for 08:00 slot to represent this date
        check_time = datetime.combine(slot_date, time(hour=8, minute=0))
        exists = db.query(models.FieldSlot).filter(
            models.FieldSlot.field_id == field_id,
            models.FieldSlot.start_time == check_time
        ).first()
        
        if not exists:
            # Generate slots config (08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00, 22:00, 00:00)
            slot_times = [8, 10, 12, 14, 16, 18, 20, 22, 0]
            for start_hour in slot_times:
                slot_start = datetime.combine(slot_date, time(hour=start_hour, minute=0))
                if start_hour == 0:
                    slot_start = datetime.combine(slot_date + timedelta(days=1), time(hour=0, minute=0))
                
                slot_end = slot_start + timedelta(minutes=90)
                
                # Double check to prevent unique constraint crash
                already_exists = db.query(models.FieldSlot).filter(
                    models.FieldSlot.field_id == field_id,
                    models.FieldSlot.start_time == slot_start
                ).first()
                
                if not already_exists:
                    new_slot = models.FieldSlot(
                        field_id=field_id,
                        start_time=slot_start,
                        end_time=slot_end,
                        price=base_price,
                        is_available=True
                    )
                    db.add(new_slot)
            db.commit()

    query = db.query(models.FieldSlot).filter(
        models.FieldSlot.field_id == field_id,
        models.FieldSlot.is_available == True
    )
    if start_date:
        query = query.filter(models.FieldSlot.start_time >= start_date)
    
    return query.order_by(models.FieldSlot.start_time).all()

def get_fields(db: Session):
    return db.query(models.Field).all()
