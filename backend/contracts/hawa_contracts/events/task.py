"""Task lifecycle events for machine dispatch and inspection targets."""
from typing import Optional
from pydantic import BaseModel
from . import register_event
from ..enums import TaskStatus


@register_event("task.dispatched", "1.0.0")
class TaskDispatched(BaseModel):
    task_id: str
    plan_id: str
    asset_id: str
    place: str
    target_time: str
    scheduled_start: str
    scheduled_end: str
    status: TaskStatus = TaskStatus.DISPATCHED


@register_event("task.done", "1.0.0")
class TaskDone(BaseModel):
    task_id: str
    plan_id: str
    asset_id: str
    completed_at: str
    intervention_id: Optional[str] = None
    source: str = "hawa_tag"  # "hawa_tag" | "manual"


@register_event("task.verified", "1.0.0")
class TaskVerified(BaseModel):
    task_id: str
    intervention_id: str
    impact_id: str
    verdict: str
    effect_pct: float
