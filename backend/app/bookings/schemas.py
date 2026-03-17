from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from uuid import UUID
from app.bookings.models import BookingRequestStatus, BookingStatus, PaymentStatus, PaymentMethod

class BookingRequestBase(BaseModel):
    field_id: UUID
    slot_id: UUID
    message: Optional[str] = None

class BookingRequestCreate(BookingRequestBase):
    pass

class BookingRequestResponse(BookingRequestBase):
    id: UUID
    user_id: UUID
    status: BookingRequestStatus
    created_at: datetime

    class Config:
        from_attributes = True

class FieldBookingBase(BaseModel):
    field_id: UUID
    start_time: datetime
    end_time: datetime

class FieldBookingCreate(FieldBookingBase):
    pass

class FieldBookingResponse(FieldBookingBase):
    id: UUID
    user_id: UUID
    status: BookingStatus
    payment_status: PaymentStatus
    created_at: datetime

    class Config:
        from_attributes = True

class PaymentBase(BaseModel):
    amount: float
    currency: str = "USD"
    payment_method: PaymentMethod = PaymentMethod.OTHER

class PaymentCreate(PaymentBase):
    booking_id: Optional[UUID] = None
    tournament_id: Optional[UUID] = None

class PaymentResponse(PaymentBase):
    id: UUID
    user_id: UUID
    booking_id: Optional[UUID] = None
    tournament_id: Optional[UUID] = None
    status: PaymentStatus
    created_at: datetime

    class Config:
        from_attributes = True
