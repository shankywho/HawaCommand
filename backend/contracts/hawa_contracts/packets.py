"""Edge -> Cloud MQTT packet schemas and validation rules (§4)."""
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, field_validator


# Validation failure reason codes for DLQ routing
REASON_MALFORMED = "malformed_json"
REASON_INVALID_DEVICE = "invalid_device_id"
REASON_FUTURE_TIMESTAMP = "timestamp_in_future"
REASON_OUT_OF_BOUNDS = "coordinates_outside_delhi"
REASON_IMPOSSIBLE_CONCENTRATION = "impossible_pm_concentration"
REASON_STALE_REPLAY = "stale_sd_replay"
REASON_HARDWARE_FAULT = "hardware_fan_stall"


class TelemetryPacket(BaseModel):
    """Raw 30 s sensor reading emitted by mobile/sentinel pods (HawaPod-M/S)."""
    dev: str = Field(..., description="Device ID, e.g. HPM-0142")
    seq: int = Field(..., ge=0, description="Monotonically increasing sequence number")
    ts: str = Field(..., description="UTC ISO-8601 timestamp with Z")
    lat: float = Field(..., ge=-90.0, le=90.0)
    lon: float = Field(..., ge=-180.0, le=180.0)
    spd: float = Field(0.0, ge=0.0, description="Speed in km/h")
    
    # Particulates (ug/m3)
    pm1: Optional[float] = Field(None, ge=0.0, le=2000.0)
    pm25: float = Field(..., ge=0.0, le=2000.0, description="Raw PM2.5 in ug/m3")
    pm10: Optional[float] = Field(None, ge=0.0, le=3000.0, description="Raw PM10 in ug/m3")
    
    # Meteorology
    rh: float = Field(..., ge=0.0, le=100.0, description="Relative humidity %")
    t: float = Field(..., ge=-10.0, le=60.0, description="Temperature in Celsius")
    p: Optional[float] = Field(None, ge=800.0, le=1100.0, description="Pressure in hPa")
    
    # Gas signals (ppb, ppm, kohm)
    no2_ppb: Optional[float] = Field(None, ge=0.0)
    co_ppb: Optional[float] = Field(None, ge=0.0)
    nh3_ppb: Optional[float] = Field(None, ge=0.0)
    voc_kohm: Optional[float] = Field(None, ge=0.0, description="BME680 gas resistance in kOhm")
    co2_ppm: Optional[float] = Field(None, ge=300.0, le=5000.0)
    
    flags: List[str] = Field(default_factory=list, description="Hardware & status flags")
    is_simulated: bool = Field(False, description="Flag indicating synthetic or virtual sensor")

    @field_validator("pm10")
    @classmethod
    def validate_pm10_ratio(cls, v: Optional[float], info) -> Optional[float]:
        # If pm10 is provided, it should generally be >= pm25
        pm25 = info.data.get("pm25")
        if v is not None and pm25 is not None and v < pm25:
            # Tolerant adjust for optical noise
            return max(v, pm25)
        return v


class DeviceEventPacket(BaseModel):
    """Spike or diagnostic events published immediately on priority topic."""
    dev: str
    seq: int
    ts: str
    type: str = Field(..., description="Event type: spike | boot | tamper | health")
    data: Dict[str, Any] = Field(default_factory=dict)
    is_simulated: bool = False


class SprayPacket(BaseModel):
    """Intervention tracking telemetry emitted by HawaTag on anti-smog guns/sprinklers."""
    tag: str = Field(..., description="HawaTag ID, e.g. HTG-0012")
    asset: str = Field(..., description="Target asset ID, e.g. AST-SPR-0012")
    seq: int
    ts: str
    lat: float
    lon: float
    action: str = Field(..., description="'start' | 'stop' | 'pulse'")
    flow_lpm: float = Field(0.0, ge=0.0, description="Water flow rate in litres per minute")
    pump_a: float = Field(0.0, ge=0.0, description="Pump current in Amperes")
    litres_cum: float = Field(0.0, ge=0.0, description="Cumulative litres delivered in session")
    pm25_local: Optional[float] = None
    pm10_local: Optional[float] = None
    is_simulated: bool = False


def validate_packet(packet: TelemetryPacket, now_dt: Optional[datetime] = None) -> Optional[str]:
    """Validate packet against Delhi spatial box and temporal constraints."""
    if now_dt is None:
        now_dt = datetime.now(timezone.utc)

    # Check timestamp not in future (> 60 s clock skew)
    try:
        packet_time = datetime.fromisoformat(packet.ts.replace("Z", "+00:00"))
        if (packet_time - now_dt).total_seconds() > 60:
            return REASON_FUTURE_TIMESTAMP
    except Exception:
        return REASON_MALFORMED

    # Delhi NCR rough bounding box: lat 28.2 to 28.9, lon 76.8 to 77.4
    if not (28.2 <= packet.lat <= 28.9 and 76.8 <= packet.lon <= 77.4):
        return REASON_OUT_OF_BOUNDS

    if "fan_stall" in packet.flags:
        return REASON_HARDWARE_FAULT

    return None
