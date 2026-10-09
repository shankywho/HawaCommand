"""Digital twin and hotspot state update events."""
from typing import List, Optional
from pydantic import BaseModel
from . import register_event
from ..enums import AqiCategory, CauseLabel


@register_event("twin.updated", "1.0.0")
class TwinUpdated(BaseModel):
    twin_run_id: str
    as_of: str
    tile_version: str
    active_cells_count: int
    mean_pm25: float
    simulated_share: float
    is_simulated: bool = False


@register_event("hotspot.updated", "1.0.0")
class HotspotUpdated(BaseModel):
    hotspot_id: str
    cell_500m_id: str
    place: str
    ward_id: str
    lat: float
    lon: float
    pm25: float
    aqi_category: AqiCategory
    cause: CauseLabel
    cause_confidence: float
    exposure_person_hours: float
    rank: int
    suspect_description: Optional[str] = None
    is_simulated: bool = False
