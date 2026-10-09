"""Impact verification events."""
from typing import List, Optional
from pydantic import BaseModel
from . import register_event
from ..enums import Verdict


class ImpactPoint(BaseModel):
    t: str
    observed: float
    synthetic: float
    ci_low: float
    ci_high: float


@register_event("impact.verified", "1.0.0")
class ImpactVerified(BaseModel):
    impact_id: str
    intervention_id: str
    asset_id: str
    cell_500m_id: str
    pollutant: str = "pm25"
    effect_pct: float
    ci_low_pct: float
    ci_high_pct: float
    p_value: float
    verdict: Verdict
    donor_cells_count: int
    is_simulated: bool = False
