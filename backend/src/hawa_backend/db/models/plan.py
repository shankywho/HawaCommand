"""Intervention plans, task assignments, and review audits."""
from datetime import datetime
from typing import Optional
from sqlalchemy import Float, Integer, String, DateTime, JSON, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from ..base import Base, TimestampMixin, SimulatedMixin


class Plan(Base, TimestampMixin, SimulatedMixin):
    """Daily or reactive operational dispatch plan for an administrative ward."""
    __tablename__ = "plan"

    plan_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    ward_id: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="draft")  # drafting | draft | approved | done
    
    window_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    window_end: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    window_label: Mapped[str] = mapped_column(String(64), nullable=False)
    
    drafted_by: Mapped[str] = mapped_column(String(64), default="AI-ML Optimizer")
    approved_by: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    approved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    approval_note: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    
    headline: Mapped[dict] = mapped_column(JSON, default=dict)
    summary: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True)
    reasoning: Mapped[Optional[str]] = mapped_column(String(2048), nullable=True)
    checks: Mapped[list] = mapped_column(JSON, default=list)


class PlanTask(Base, TimestampMixin):
    """Specific ordered route stop or inspection assignment."""
    __tablename__ = "plan_task"

    task_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    plan_id: Mapped[str] = mapped_column(String(36), ForeignKey("plan.plan_id"), index=True)
    asset_id: Mapped[str] = mapped_column(String(32), ForeignKey("asset.asset_id"), index=True)
    
    op: Mapped[str] = mapped_column(String(8), default="add")  # add | del vs usual route
    time_label: Mapped[str] = mapped_column(String(32), nullable=False)
    place: Mapped[str] = mapped_column(String(256), nullable=False)
    action: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    
    cause: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)
    cause_conf: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    reason: Mapped[str] = mapped_column(String(512), nullable=False)
    
    status: Mapped[str] = mapped_column(String(32), default="dispatched")  # dispatched | in_progress | done | verified
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    intervention_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)


class PlanReview(Base, TimestampMixin):
    """Critique, justification, or objection drafted by LLM agents."""
    __tablename__ = "plan_review"

    review_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    plan_id: Mapped[str] = mapped_column(String(36), ForeignKey("plan.plan_id"), index=True)
    agent_role: Mapped[str] = mapped_column(String(32), nullable=False)  # Planner | Auditor | Forecaster
    objections: Mapped[list] = mapped_column(JSON, default=list)
    suggestions: Mapped[list] = mapped_column(JSON, default=list)
    verdict: Mapped[str] = mapped_column(String(32), default="acceptable")
