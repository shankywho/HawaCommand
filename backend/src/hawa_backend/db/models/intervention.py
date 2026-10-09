"""Interventions, synthetic-control causal impact, and effectiveness library."""
from datetime import datetime
from typing import Optional
from sqlalchemy import Float, Integer, String, DateTime, JSON, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from ..base import Base, TimestampMixin, SimulatedMixin


class Intervention(Base, TimestampMixin, SimulatedMixin):
    """Physically recorded water spray or mechanical sweeping intervention."""
    __tablename__ = "intervention"

    intervention_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    tag_id: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    asset_id: Mapped[str] = mapped_column(String(32), ForeignKey("asset.asset_id"), index=True)
    task_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    
    start_ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lon: Mapped[float] = mapped_column(Float, nullable=False)
    cell_500m_id: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    
    litres_delivered: Mapped[float] = mapped_column(Float, default=0.0)
    flow_avg_lpm: Mapped[float] = mapped_column(Float, default=0.0)
    
    pm25_before: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    pm25_after: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    
    verification_status: Mapped[str] = mapped_column(String(32), default="pending")  # pending | verified | inconclusive
    verify_after: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class Impact(Base, TimestampMixin, SimulatedMixin):
    """Causally verified impact curve and confidence interval from synthetic control."""
    __tablename__ = "impact"

    impact_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    intervention_id: Mapped[str] = mapped_column(String(36), ForeignKey("intervention.intervention_id"), unique=True)
    pollutant: Mapped[str] = mapped_column(String(16), default="pm25")
    
    effect_pct: Mapped[float] = mapped_column(Float, nullable=False)
    ci_low_pct: Mapped[float] = mapped_column(Float, nullable=False)
    ci_high_pct: Mapped[float] = mapped_column(Float, nullable=False)
    p_value: Mapped[float] = mapped_column(Float, default=0.05)
    
    verdict: Mapped[str] = mapped_column(String(32), default="verified")  # Verified | Inconclusive | No effect
    series: Mapped[list] = mapped_column(JSON, default=list)  # observed vs synthetic control series


class EffectivenessLibrary(Base, TimestampMixin):
    """Empirical learned effectiveness lookup table."""
    __tablename__ = "effectiveness_library"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    cause: Mapped[str] = mapped_column(String(32), nullable=False)
    asset_kind: Mapped[str] = mapped_column(String(32), nullable=False)
    sample_size: Mapped[int] = mapped_column(Integer, default=0)
    effect_pct: Mapped[float] = mapped_column(Float, nullable=False)
    ci_low: Mapped[float] = mapped_column(Float, nullable=False)
    ci_high: Mapped[float] = mapped_column(Float, nullable=False)
