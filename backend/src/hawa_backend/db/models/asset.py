"""Municipal anti-pollution assets and machine shifts."""
from datetime import datetime
from typing import Optional
from sqlalchemy import Float, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from ..base import Base, TimestampMixin, SimulatedMixin


class Asset(Base, TimestampMixin, SimulatedMixin):
    """Anti-pollution machine or field inspection team."""
    __tablename__ = "asset"

    asset_id: Mapped[str] = mapped_column(String(32), primary_key=True)
    kind: Mapped[str] = mapped_column(String(32), nullable=False)  # sprinkler | smog_gun | sweeper | inspection
    label: Mapped[str] = mapped_column(String(128), nullable=False)
    ward_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    status: Mapped[str] = mapped_column(String(32), default="available")  # Spraying | En route | Done | Idle | etc.
    capacity_litres: Mapped[float] = mapped_column(Float, default=5000.0)
    tag_id: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)  # Attached HawaTag


class AssetShift(Base, TimestampMixin):
    """Driver assignment and active operating shift."""
    __tablename__ = "asset_shift"

    shift_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    asset_id: Mapped[str] = mapped_column(String(32), ForeignKey("asset.asset_id"), index=True)
    driver_user_id: Mapped[str] = mapped_column(String(36), index=True)
    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
