"""Telemetry events emitted by the ingest pipeline."""
from typing import List, Optional
from pydantic import BaseModel
from . import register_event
from ..enums import AqiCategory


@register_event("reading.cleaned", "1.0.0")
class ReadingCleaned(BaseModel):
    reading_id: str
    device_id: str
    ts: str
    seq: int
    lat: float
    lon: float
    cell_500m_id: str
    cell_1km_id: str
    ward_id: Optional[str] = None
    
    # Calibrated values
    pm25: float
    pm10: Optional[float] = None
    pm25_raw: float
    pm10_raw: Optional[float] = None
    
    rh: float
    t: float
    speed_kmh: float
    indicative_aqi: int
    aqi_category: AqiCategory
    calibration_version: str
    is_simulated: bool = False


@register_event("reading.rejected", "1.0.0")
class ReadingRejected(BaseModel):
    device_id: str
    seq: int
    ts: str
    reason: str
    raw_payload: str
