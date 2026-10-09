"""Plan lifecycle events."""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel
from . import register_event
from ..enums import PlanMode, PlanStatus


@register_event("plan.drafted", "1.0.0")
class PlanDrafted(BaseModel):
    plan_id: str
    ward_id: str
    mode: PlanMode
    status: PlanStatus
    drafted_at: str
    drafted_by: str
    total_tasks: int
    assets_assigned: int
    people_hours_saved: float
    is_simulated: bool = False


@register_event("plan.approved", "1.0.0")
class PlanApproved(BaseModel):
    plan_id: str
    ward_id: str
    approved_at: str
    approved_by_user_id: str
    note: Optional[str] = None


@register_event("plan.dispatched", "1.0.0")
class PlanDispatched(BaseModel):
    plan_id: str
    ward_id: str
    dispatched_at: str
    tasks_count: int
