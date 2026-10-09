"""Community and field alerts."""
from datetime import datetime
from typing import Optional
from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from ..base import Base, TimestampMixin, SimulatedMixin


class Alert(Base, TimestampMixin, SimulatedMixin):
    """Bilingual public or targeted alert."""
    __tablename__ = "alert"

    alert_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    audience: Mapped[str] = mapped_column(String(32), nullable=False)  # School | Citizens | Drivers | etc.
    channel: Mapped[str] = mapped_column(String(32), nullable=False)   # WhatsApp | SMS | FCM
    
    title: Mapped[str] = mapped_column(String(256), nullable=False)
    body_en: Mapped[str] = mapped_column(String(1024), nullable=False)
    body_hi: Mapped[str] = mapped_column(String(1024), nullable=False)
    
    recipient_phone: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)
    safe_window: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    status: Mapped[str] = mapped_column(String(32), default="delivered")


class AlertDelivery(Base, TimestampMixin):
    """Specific dispatch delivery record across communication channels."""
    __tablename__ = "alert_delivery"

    delivery_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    alert_id: Mapped[str] = mapped_column(String(36), ForeignKey("alert.alert_id"), index=True)
    channel: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="sent")  # sent | delivered | failed
    delivered_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
