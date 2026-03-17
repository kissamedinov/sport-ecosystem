from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from uuid import UUID
from datetime import datetime

from app.bookings.models import BookingRequest, Booking, BookingRequestStatus, BookingStatus, PaymentStatus
from app.fields.models import FieldSlot, Field
from app.users.models import User
from app.notifications import service as notification_service
from app.notifications.models import NotificationType, EntityType

def create_field_booking(db: Session, field_id: UUID, user_id: UUID, start_time: datetime, end_time: datetime):
    # Check for overlaps
    overlapping = db.query(Booking).filter(
        Booking.field_id == field_id,
        Booking.status != BookingStatus.CANCELLED,
        Booking.start_time < end_time,
        Booking.end_time > start_time
    ).first()
    
    if overlapping:
        raise HTTPException(status_code=400, detail="Field is already booked for this time period")
    
    # Calculate price (simplified: assuming flat rate per hour from somewhere or just a mock)
    # In a real app, you'd fetch this from the Field model or a PriceTable
    total_price = 50.0 # Mock price
    
    new_booking = Booking(
        field_id=field_id,
        user_id=user_id,
        start_time=start_time,
        end_time=end_time,
        status=BookingStatus.PENDING,
        payment_status=PaymentStatus.PENDING
    )
    db.add(new_booking)
    db.commit()
    db.refresh(new_booking)
    
    # Trigger notification to field owner
    field = db.query(Field).filter(Field.id == field_id).first()
    notification_service.create_notification(
        db,
        user_ids=[field.owner_id],
        notification_type=NotificationType.BOOKING_REQUEST,
        title="New Field Booking",
        message=f"A new booking has been made for {field.name} from {start_time} to {end_time}",
        entity_type=EntityType.BOOKING,
        entity_id=new_booking.id
    )
    
    return new_booking

def get_field_bookings(db: Session, field_id: UUID):
    return db.query(Booking).filter(Booking.field_id == field_id).all()

def get_user_payments(db: Session, user_id: UUID):
    from app.bookings.models import Payment
    return db.query(Payment).filter(Payment.user_id == user_id).all()
