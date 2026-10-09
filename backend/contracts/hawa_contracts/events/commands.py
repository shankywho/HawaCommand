"""Command events published to trigger analytical and operational workflows."""
from typing import List, Optional
from pydantic import BaseModel
from . import register_event
from ..enums import PlanMode


@register_event("cmd.twin.rebuild", "1.0.0")
class CmdTwinRebuild(BaseModel):
    as_of: str
    lookback_minutes: int = 60
    trigger: str = "scheduler"


@register_event("cmd.forecast.run", "1.0.0")
class CmdForecastRun(BaseModel):
    as_of: str
    horizons_hours: int = 72
    master: bool = False


@register_event("cmd.plan.draft", "1.0.0")
class CmdPlanDraft(BaseModel):
    plan_id: str
    mode: PlanMode
    ward_id: str
    window_start: str
    window_end: str
    target_date: str


@register_event("cmd.verify.run", "1.0.0")
class CmdVerifyRun(BaseModel):
    intervention_id: str
    as_of: str


@register_event("cmd.dispatch.release", "1.0.0")
class CmdDispatchRelease(BaseModel):
    plan_id: str
    release_at: str
