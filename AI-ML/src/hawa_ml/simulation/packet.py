"""Packet generator and schema builder matching Proposal §10.6."""
from datetime import datetime, timezone
from typing import List, Optional
from hawa_ml.schemas import TelemetryPacket, DeviceRole, GPSData, PMData, GasData, EnvData, InterventionTelemetry


def create_telemetry_packet(
    dev_id: str,
    role: str,
    seq: int,
    lat: float,
    lon: float,
    spd: float,
    pm25: float,
    pm10: float,
    pm1: Optional[float] = None,
    no2_ppb: Optional[float] = None,
    co_ppb: Optional[float] = None,
    so2_ppb: Optional[float] = None,
    voc_kohm: Optional[float] = None,
    temp: float = 20.0,
    rh: float = 65.0,
    pressure: float = 1013.2,
    flags: Optional[List[str]] = None,
    batt: float = 4.05,
    fw: str = "1.4.2",
    flow_lpm: float = 0.0,
    pump_current_a: float = 0.0,
    spraying: bool = False,
    ts: Optional[datetime] = None,
) -> TelemetryPacket:
    """Instantiate a validated TelemetryPacket conforming to hardware firmware specs."""
    if ts is None:
        ts = datetime.now(timezone.utc)
    if flags is None:
        flags = []
    if rh > 75.0 and "heater_on" not in flags:
        flags.append("heater_on")

    return TelemetryPacket(
        v=1,
        dev=dev_id,
        role=DeviceRole(role),
        seq=seq,
        ts=ts,
        gps=GPSData(lat=round(lat, 5), lon=round(lon, 5), spd=round(spd, 1), hdop=0.9),
        pm=PMData(
            pm1=round(pm1 if pm1 is not None else pm25 * 0.65, 1),
            pm25=round(pm25, 1),
            pm10=round(pm10, 1),
        ),
        gas=GasData(
            no2_ppb=round(no2_ppb, 1) if no2_ppb is not None else 35.0,
            co_ppb=round(co_ppb, 1) if co_ppb is not None else 1200.0,
            so2_ppb=round(so2_ppb, 1) if so2_ppb is not None else 8.0,
            voc_kohm=round(voc_kohm, 1) if voc_kohm is not None else 45.0,
        ),
        env=EnvData(t=round(temp, 1), rh=round(rh, 1), p=round(pressure, 1)),
        flags=flags,
        fw=fw,
        batt=round(batt, 2),
        intervention=InterventionTelemetry(
            flow_lpm=round(flow_lpm, 1),
            pump_current_a=round(pump_current_a, 2),
            spraying=spraying,
        ) if role == "TAG" else None,
    )
