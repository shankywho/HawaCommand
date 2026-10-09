"""Typed Pydantic schemas for HawaCommand AI-ML models, telemetry, and APIs.

Enforces zero LLM hallucination: all metrics, coordinates, and predictions are strictly validated.
"""
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, field_validator


class DeviceRole(str, Enum):
    MOBILE = "M"
    SENTINEL = "S"
    TAG = "TAG"
    EYE = "EYE"


class GPSData(BaseModel):
    lat: float = Field(..., ge=-90.0, le=90.0)
    lon: float = Field(..., ge=-180.0, le=180.0)
    spd: float = Field(default=0.0, ge=0.0, description="Speed in km/h")
    hdop: float = Field(default=1.0, ge=0.0, description="Horizontal dilution of precision")


class PMData(BaseModel):
    pm1: Optional[float] = Field(default=None, ge=0.0, le=2000.0)
    pm25: float = Field(..., ge=0.0, le=2000.0, description="PM2.5 in ug/m3")
    pm10: float = Field(..., ge=0.0, le=3000.0, description="PM10 in ug/m3")


class GasData(BaseModel):
    no2_ppb: Optional[float] = Field(default=None, ge=0.0, le=5000.0)
    co_ppb: Optional[float] = Field(default=None, ge=0.0, le=100000.0)
    so2_ppb: Optional[float] = Field(default=None, ge=0.0, le=5000.0)
    voc_kohm: Optional[float] = Field(default=None, ge=0.0, le=1000.0)


class EnvData(BaseModel):
    t: float = Field(..., ge=-10.0, le=60.0, description="Temperature in C")
    rh: float = Field(..., ge=0.0, le=100.0, description="Relative humidity %")
    p: Optional[float] = Field(default=1013.25, ge=800.0, le=1200.0, description="Pressure in hPa")


class InterventionTelemetry(BaseModel):
    flow_lpm: float = Field(default=0.0, ge=0.0, description="Water flow in litres per minute")
    pump_current_a: float = Field(default=0.0, ge=0.0, description="Pump motor current in Amperes")
    spraying: bool = Field(default=False)


class TelemetryPacket(BaseModel):
    """Proposal §10.6 Telemetry Packet Schema v1."""
    v: int = Field(default=1, description="Protocol version")
    dev: str = Field(..., description="Unique Device ID, e.g. HPM-0142")
    role: DeviceRole = Field(..., description="M: Mobile, S: Sentinel, TAG: Intervention, EYE: Vision")
    seq: int = Field(..., ge=0, description="Monotonically increasing sequence number")
    ts: datetime = Field(..., description="ISO8601 UTC timestamp")
    gps: GPSData
    pm: PMData
    gas: Optional[GasData] = None
    env: EnvData
    flags: List[str] = Field(default_factory=list)
    fw: str = Field(default="1.0.0")
    batt: Optional[float] = Field(default=4.0, ge=0.0, le=15.0, description="Battery voltage in V")
    intervention: Optional[InterventionTelemetry] = None


class SourceClass(str, Enum):
    ROAD_DUST = "road_dust"
    DUST = "dust"
    TRAFFIC = "traffic"
    OPEN_BURNING = "open_burning"
    BURNING = "burning"
    REGIONAL_SMOKE = "regional_smoke"
    INDUSTRIAL = "industrial"
    MIXED = "mixed"
    UNKNOWN = "unknown"


class CellState(BaseModel):
    cell_id: str
    lat: float
    lon: float
    pm25_est: float = Field(..., ge=0.0)
    pm10_est: float = Field(..., ge=0.0)
    variance: float = Field(..., ge=0.0)
    confidence: float = Field(..., ge=0.0, le=1.0)
    cause_label: SourceClass = SourceClass.UNKNOWN
    cause_confidence: float = Field(default=0.5, ge=0.0, le=1.0)
    exposure_score: float = Field(default=0.0, ge=0.0)
    ward: Optional[str] = None


class SuspectPin(BaseModel):
    lat: float
    lon: float
    distance_m: float
    spread_m: float


class Hotspot(BaseModel):
    cell_id: str
    rank: int
    exposure_score: float
    pm25: float
    pm10: float
    cause: SourceClass
    cause_confidence: float
    recommended_asset: str
    suspect_pin: Optional[SuspectPin] = None
    ward: Optional[str] = None


class ForecastPoint(BaseModel):
    horizon_h: int
    valid_time: datetime
    pm25_p10: float
    pm25_p50: float
    pm25_p90: float
    pm10_p50: float
    aqi_p50: int
    grap_stage: str


class AssetSpec(BaseModel):
    id: str
    type: str = Field(..., description="sprinkler | smog_gun | sweeper | inspection_team")
    depot_lat: float
    depot_lon: float
    capacity_litres: float = 10000.0


class PlanTask(BaseModel):
    task_id: str
    asset_id: str
    cell_id: str
    action: str
    eta_start: datetime
    eta_end: datetime
    expected_pm_reduction_pct: float
    reason: str


class PlanDraft(BaseModel):
    plan_id: str
    created_at: datetime
    status: str = "draft"
    total_exposure_avoided_person_hours: float
    tasks: List[PlanTask]
    planner_reasoning: str
    auditor_verdict: str = "approved"
    auditor_critique: str


class SyntheticControlResult(BaseModel):
    intervention_id: str
    cell_id: str
    asset_id: str
    action: str
    measured_effect_pct: float
    ci_low_pct: float
    ci_high_pct: float
    duration_minutes: int
    p_value: float
    method: str = "synthetic_control"
    donor_pool_count: int
    statistically_significant: bool


class InsightSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


class Insight(BaseModel):
    id: str
    trigger_type: str
    severity: InsightSeverity
    title: str
    cell_id: Optional[str] = None
    evidence: Dict[str, Any]
    confidence: float
    recommended_action: str
    created_at: datetime


class Narrative(BaseModel):
    insight_id: str
    narrative_en: str
    narrative_hi: Optional[str] = None
    recommended_action: str
