"""Intervention spray tracking events."""
from typing import Optional
from pydantic import BaseModel
from . import register_event


@register_event("intervention.spray_started", "1.0.0")
class SprayStarted(BaseModel):
    tag_id: str
    asset_id: str
    ts: str
    lat: float
    lon: float
    cell_500m_id: str
    flow_lpm: float
    is_simulated: bool = False


@register_event("intervention.spray_stopped", "1.0.0")
class SprayStopped(BaseModel):
    intervention_id: str
    tag_id: str
    asset_id: str
    start_ts: str
    end_ts: str
    duration_seconds: int
    lat: float
    lon: float
    cell_500m_id: str
    litres_delivered: float
    pm25_before: Optional[float] = None
    pm25_after: Optional[float] = None
    task_id: Optional[str] = None
    is_simulated: bool = False
