from sqlalchemy.orm import Session
from fastapi import HTTPException
from uuid import UUID
from app.bookings.models import Booking, Payment, PaymentStatus, BookingStatus, PaymentMethod
from app.tournaments.models import TournamentRegistration, RegistrationStatus
from app.notifications import service as notification_service
from app.notifications.models import NotificationType, EntityType

def create_payment(db: Session, user_id: UUID, amount: float, payment_method: PaymentMethod, booking_id: UUID | None = None, tournament_id: UUID | None = None):
    new_payment = Payment(
        booking_id=booking_id,
        tournament_id=tournament_id,
        user_id=user_id,
        amount=amount,
        payment_method=payment_method,
        status=PaymentStatus.PENDING
    )
    db.add(new_payment)
    db.commit()
    db.refresh(new_payment)
    return new_payment

def confirm_payment(db: Session, payment_id: UUID):
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment record not found")
        
    payment.status = PaymentStatus.SUCCESS
    
    # Update related entities
    if payment.booking_id:
        booking = db.query(Booking).filter(Booking.id == payment.booking_id).first()
        if booking:
            booking.payment_status = PaymentStatus.SUCCESS
            booking.status = BookingStatus.CONFIRMED
            
    if payment.tournament_id:
        # Assuming payment.user_id is the person who registered
        registration = db.query(TournamentRegistration).filter(
            TournamentRegistration.tournament_id == payment.tournament_id,
            TournamentRegistration.status == RegistrationStatus.PENDING
            # We might need team_id here if we want to be specific, 
            # but for now let's assume one pending registration per user/tournament
        ).first()
        if registration:
            registration.status = RegistrationStatus.APPROVED
    
    db.commit()
    
    # Trigger notification
    notification_service.create_notification(
        db,
        payment.user_id,
        NotificationType.PAYMENT_CONFIRMED,
        "Payment Successful",
        f"Your payment of {payment.amount} has been successfully processed.",
        EntityType.PAYMENT,
        payment.id
    )
    return {"message": "Payment confirmed and statuses updated"}
