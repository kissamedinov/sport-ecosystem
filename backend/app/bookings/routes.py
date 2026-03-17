from fastapi import APIRouter, Depends, status, Body, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.users.models import User, Role
from app.common.dependencies import get_current_user, require_permission
from app.bookings import schemas, services, payment_service

router = APIRouter(tags=["Bookings"])

@router.post("/fields/{field_id}/book", response_model=schemas.FieldBookingResponse, status_code=status.HTTP_201_CREATED)
def book_field(
    field_id: UUID,
    booking_in: schemas.FieldBookingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return services.create_field_booking(db, field_id, current_user.id, booking_in.start_time, booking_in.end_time)

@router.post("/payments", response_model=schemas.PaymentResponse)
def create_payment(
    payment_in: schemas.PaymentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return payment_service.create_payment(
        db, 
        current_user.id, 
        payment_in.amount, 
        payment_in.payment_method, 
        payment_in.booking_id, 
        payment_in.tournament_id
    )

@router.get("/users/{user_id}/payments", response_model=List[schemas.PaymentResponse])
def get_user_payments(
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Additional logic: check if current_user matches user_id or is admin
    if current_user.id != user_id and current_user.role != Role.ADMIN:
        raise HTTPException(status_code=403, detail="Not authorized to view these payments")
    return services.get_user_payments(db, user_id)

@router.get("/fields/{field_id}/bookings", response_model=List[schemas.FieldBookingResponse])
def get_field_bookings(
    field_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if user is owner of field or admin
    from app.fields.models import Field
    field = db.query(Field).filter(Field.id == field_id).first()
    if not field:
        raise HTTPException(status_code=404, detail="Field not found")
    if field.owner_id != current_user.id and current_user.role != Role.ADMIN:
        raise HTTPException(status_code=403, detail="Not authorized to view these bookings")
    return services.get_field_bookings(db, field_id)

@router.post("/payments/{payment_id}/confirm")
def confirm_payment(
    payment_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user) # In reality, webhook or admin
):
    return payment_service.confirm_payment(db, payment_id)
