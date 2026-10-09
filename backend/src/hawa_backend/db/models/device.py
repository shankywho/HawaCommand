"""Sensor devices, calibrations, events, and raw/cleaned readings."""
from datetime import datetime
from typing import Optional
from sqlalchemy import Float, Integer, String, Boolean, DateTime, JSON, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from ..base import Base, TimestampMixin, SimulatedMixin


class Device(Base, TimestampMixin, SimulatedMixin):
    """Registered low-cost IoT sensor (HawaPod-M, HawaPod-S, HawaTag)."""
    __tablename__ = "device"

    device_id: Mapped[str] = mapped_column(String(32), primary_key=True)
    role: Mapped[str] = mapped_column(String(16), nullable=False)  # M | S | TAG | EYE
    placement: Mapped[str] = mapped_column(String(32), default="mobile")
    status: Mapped[str] = mapped_column(String(32), default="active")
    trust_score: Mapped[float] = mapped_column(Float, default=1.0)
    current_vehicle_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    calibration_version: Mapped[str] = mapped_column(String(32), default="v1.0.0")


class Reading(Base, SimulatedMixin):
    """Calibrated air quality observation emitted by mobile/sentinel sensors."""
    __tablename__ = "reading"
    __table_args__ = (
        UniqueConstraint("device_id", "seq", "ts", name="uq_reading_device_seq_ts"),
    )

    reading_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    device_id: Mapped[str] = mapped_column(String(32), ForeignKey("device.device_id"), index=True)
    seq: Mapped[int] = mapped_column(Integer, nullable=False)
    ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lon: Mapped[float] = mapped_column(Float, nullable=False)
    cell_500m_id: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    cell_1km_id: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    
    pm25: Mapped[float] = mapped_column(Float, nullable=False)
    pm10: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    pm25_raw: Mapped[float] = mapped_column(Float, nullable=False)
    pm10_raw: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    
    rh: Mapped[float] = mapped_column(Float, nullable=False)
    t: Mapped[float] = mapped_column(Float, nullable=False)
    speed_kmh: Mapped[float] = mapped_column(Float, default=0.0)
    indicative_aqi: Mapped[int] = mapped_column(Integer, nullable=False)
    flags: Mapped[Optional[dict]] = mapped_column(JSON, default=list)


class DeviceEvent(Base, SimulatedMixin):
    """Hardware spike, tamper, boot, or diagnostic event."""
    __tablename__ = "device_event"

    event_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    device_id: Mapped[str] = mapped_column(String(32), ForeignKey("device.device_id"), index=True)
    seq: Mapped[int] = mapped_column(Integer, nullable=False)
    ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    type: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    confirmed_by_cloud: Mapped[bool] = mapped_column(Boolean, default=False)
