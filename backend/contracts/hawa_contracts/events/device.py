"""Device events: spikes, calibrations, and diagnostics."""
from typing import Any, Dict, Optional
from pydantic import BaseModel
from . import register_event


@register_event("device.spike", "1.0.0")
class DeviceSpike(BaseModel):
    device_id: str
    seq: int
    ts: str
    lat: float
    lon: float
    cell_500m_id: str
    pm25_spike: float
    pm25_baseline: float
    rise_factor: float
    confirmed_by_cloud: bool
    is_simulated: bool = False


@register_event("device.calibrated", "1.0.0")
class DeviceCalibrated(BaseModel):
    device_id: str
    pollutant: str
    version: str
    coeff_a: float
    coeff_b: float
    coeff_c: float
    r2_score: float
    mae_score: float
    applied_at: str
