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

def get_user_bookings(db: Session, user_id: UUID):
    return db.query(Booking).filter(Booking.user_id == user_id).all()

def get_user_payments(db: Session, user_id: UUID):
    from app.bookings.models import Payment
    return db.query(Payment).filter(Payment.user_id == user_id).all()

def cancel_field_booking(db: Session, booking_id: UUID, user_id: UUID):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    # Check if user is the one who booked OR the field owner
    field = db.query(Field).filter(Field.id == booking.field_id).first()
    if booking.user_id != user_id and field.owner_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to cancel this booking")
        
    if booking.status == BookingStatus.CANCELLED:
        return booking
        
    # Rule: Check if cancellation is too late (e.g. less than 12 hours before)
    now = datetime.now()
    if booking.start_time - now < timedelta(hours=12):
        # We still allow cancellation, but maybe with a flag or separate status
        # For now, let's just log it or allow it
        pass
        
    booking.status = BookingStatus.CANCELLED
    
    # Free up slots if they were linked (if we use a Slot table)
    # Looking at create_field_booking, it currently uses direct time overlap,
    # but if we have FieldSlot records, we should mark them available.
    slots = db.query(FieldSlot).filter(
        FieldSlot.field_id == booking.field_id,
        FieldSlot.start_time >= booking.start_time,
        FieldSlot.end_time <= booking.end_time
    ).all()
    
    for slot in slots:
        slot.is_available = True
        
    db.commit()
    
    # Notify other party
    notify_user_id = field.owner_id if user_id == booking.user_id else booking.user_id
    notification_service.create_notification(
        db,
        user_ids=[notify_user_id],
        notification_type=NotificationType.BOOKING_CANCELLED,
        title="Booking Cancelled",
        message=f"Booking for {field.name} on {booking.start_time} has been cancelled.",
        entity_type=EntityType.BOOKING,
        entity_id=booking.id
    )
    
    return booking
