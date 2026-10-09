"""Forecast and GRAP outlook events."""
from typing import Dict, List, Optional
from pydantic import BaseModel
from . import register_event
from ..enums import GrapStage


class ForecastPoint(BaseModel):
    h: int
    p10: float
    p50: float
    p90: float


@register_event("forecast.issued", "1.0.0")
class ForecastIssued(BaseModel):
    forecast_run_id: str
    as_of: str
    ward_id: str
    horizon_hours: int
    points: List[ForecastPoint]
    grap_stage_outlook: GrapStage
    is_simulated: bool = False


@register_event("school.safe_window_computed", "1.0.0")
class SchoolSafeWindowComputed(BaseModel):
    school_id: str
    date: str
    safe_window_start: str
    safe_window_end: str
    expected_pm25: float
    recommendation: str
