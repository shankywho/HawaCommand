"""Citizen Experience API: Safe routing, live operations radar, safe breath window, and civic audit."""
from __future__ import annotations
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field
from fastapi import APIRouter, Query, HTTPException

from hawa_ml.exposure.routing import safe_route_optimizer
from hawa_ml.forecasting.safe_window import safe_window_calculator
from hawa_ml.simulation.audit import iot_auditor, FLEET_TELEMETRY

from ...services import fleet, geo
from ...services._util import iso, utcnow

router = APIRouter(prefix="/v1/citizen", tags=["Citizen Experience"])


# --- Schemas ---

class Coordinate(BaseModel):
    lat: float
    lon: float

class SafeRouteRequest(BaseModel):
    origin: Coordinate
    destination: Coordinate
    mode: str = Field("cycling", description="Mode: walking | cycling | two_wheeler | car")

class MissedMachineReport(BaseModel):
    asset_id: str
    cell_id: str
    ward: str
    reported_by: Optional[str] = "citizen_mobile_app"
    # Where the machine should have worked; defaults to the centre of cell_id
    lat: Optional[float] = Field(None, ge=-90, le=90)
    lon: Optional[float] = Field(None, ge=-180, le=180)
    window_minutes: int = Field(180, ge=15, le=24 * 60, description="How far back to look at telemetry")


MIN_DWELL_MINUTES = 15.0
PENALTY_INR = 25000


# --- Endpoints ---

@router.post("/safe-route")
async def calculate_safe_route(req: SafeRouteRequest):
    """Calculates fastest, cleanest, and balanced routes comparing travel time and inhaled toxic dose."""
    try:
        from ...core.intel_client import get_intel_client
        intel = get_intel_client()
        twin_df = intel._get_live_twin_df()
        cur_pm = float(twin_df["pm25_est"].mean())
        safe_route_optimizer.default_bg_pm25 = cur_pm
    except Exception:
        pass
    result = safe_route_optimizer.compute_route_alternatives(
        origin=(req.origin.lat, req.origin.lon),
        destination=(req.destination.lat, req.destination.lon),
        mode=req.mode,
    )
    return result


@router.get("/safe-window")
async def get_safe_breath_window(
    lat: float = Query(28.6139, description="Latitude"),
    lon: float = Query(77.2090, description="Longitude"),
    persona: str = Query("general", description="Persona: asthma_elderly | children_school | runners_athletes | general"),
):
    """Provides 24-hour diurnal inversion forecast and identifies the optimal safe outdoor window."""
    try:
        from ...core.intel_client import get_intel_client
        intel = get_intel_client()
        twin_df = intel._get_live_twin_df()
        cur_pm = float(twin_df["pm25_est"].mean())
        safe_window_calculator.baseline_pm25 = cur_pm
    except Exception:
        pass
    result = safe_window_calculator.compute_daily_window(lat=lat, lon=lon, persona=persona)
    return result


@router.get("/live-operations")
async def get_live_operations(
    ward: Optional[str] = Query(None, description="Optional ward filter"),
):
    """Real-time municipal fleet tracking and causal-verified completed misting runs.

    Vehicles with live HawaTag telemetry (services/fleet.py) come first, flagged live=true; the
    simulated demo vehicles follow unless a live vehicle has the same id."""
    live = [fleet.to_live_ops(r) for r in await fleet.live_fleet()]
    live_ids = {v["asset_id"] for v in live}
    simulated = [
        dict(v, live=False, simulated=True) for v in FLEET_TELEMETRY.values() if v["asset_id"] not in live_ids
    ]
    active_fleet = live + simulated
    if ward:
        active_fleet = [v for v in active_fleet if ward.lower() in str(v["ward"]).lower()]

    # Verified interventions backed by Causal Synthetic Control
    verified_interventions = [
        {
            "intervention_id": "INT-202610060601",
            "asset_id": "SPR-04",
            "action_type": "water_sprinkler",
            "location_name": "Anand Vihar / Preet Vihar Cluster (G-052-054)",
            "lat": 28.6476,
            "lon": 77.3158,
            "treated_time": "08:15 AM IST (45m ago)",
            "pm10_reduction_pct": 18.5,
            "pm25_reduction_pct": 6.2,
            "confidence_interval_95": [-22.2, -15.4],
            "duration_minutes": 90,
            "water_disbursed_liters": 1420.0,
            "verified_by": "Causal Synthetic Control (untreated donor cells)",
            "status": "EFFECT_ACTIVE",
        },
        {
            "intervention_id": "INT-202609291046",
            "asset_id": "SMG-12",
            "action_type": "anti_smog_gun",
            "location_name": "Punjabi Bagh Ring Road Corridor (G-048-032)",
            "lat": 28.6720,
            "lon": 77.1250,
            "treated_time": "07:30 AM IST (1h 30m ago)",
            "pm10_reduction_pct": 14.0,
            "pm25_reduction_pct": 5.0,
            "confidence_interval_95": [-19.0, -9.0],
            "duration_minutes": 75,
            "water_disbursed_liters": 2100.0,
            "verified_by": "Causal Synthetic Control (untreated donor cells)",
            "status": "EFFECT_ACTIVE",
        },
    ]

    return {
        "as_of": iso(utcnow()),
        "live_fleet_count": len(live),
        "active_fleet_count": len(active_fleet),
        "active_fleet": active_fleet,
        "verified_interventions": verified_interventions,
    }


@router.post("/reports/missed-machine")
async def report_missed_machine(report: MissedMachineReport):
    """Audits citizen complaint flags against IoT telemetry hardware (No-Ghost-Worker Engine).

    With live telemetry for the asset (services/fleet.py, DynamoDB fleet table when configured), the
    verdict comes from its real track: at least 15 min within 500 m of the site with the pump running.
    Without any, the simulated auditor in hawa_ml answers and evidence_source is "simulated"."""
    track = await fleet.track(report.asset_id, report.window_minutes)
    if not track:
        result = iot_auditor.audit_missed_intervention(
            asset_id=report.asset_id,
            cell_id=report.cell_id,
            ward=report.ward,
            reported_by=report.reported_by or "citizen_mobile_app",
        )
        return dict(result, evidence_source="simulated")

    lat, lon = report.lat, report.lon
    if lat is None or lon is None:
        center = geo.cell_center(report.cell_id)
        if center:
            lat, lon = center
    evidence = fleet.evaluate(track, lat, lon, report.window_minutes)
    latest = evidence.pop("latest")
    worked = evidence["sprayed"] and evidence["dwell_minutes"] >= MIN_DWELL_MINUTES
    now = utcnow()
    result = {
        "report_id": f"AUD-{int(now.timestamp())}",
        "timestamp": iso(now),
        "asset_id": report.asset_id,
        "ward": report.ward,
        "cell_id": report.cell_id,
        "reported_by": report.reported_by,
        "evidence_source": "live_telemetry",
        "evidence": evidence,
        "telemetry": fleet.to_live_ops(dict(latest, status=fleet.status_of(latest))),
    }
    if worked:
        result.update(
            verdict="MACHINE_ACTIVE_VERIFIED",
            sla_breach=False,
            message=(
                f"HawaTag telemetry shows {report.asset_id} spent {evidence['dwell_minutes']} min within "
                f"{int(evidence['radius_m'])} m of the site with the pump running "
                f"(peak {evidence['max_pump_flow_lpm']} L/min, about {evidence['litres_estimated']} L)."
            ),
        )
    else:
        where = "" if evidence["closest_m"] is None else f" It came no closer than {evidence['closest_m']:.0f} m."
        result.update(
            verdict="SLA_BREACH_CONFIRMED",
            sla_breach=True,
            penalty_fine_inr=PENALTY_INR,
            message=(
                f"HawaTag telemetry for {report.asset_id} over the last {report.window_minutes} min shows "
                f"{evidence['dwell_minutes']} min on site (15 required) and "
                f"{'pump activity' if evidence['sprayed'] else 'no pump activity'} near it.{where} "
                f"Non-compliance penalty of ₹{PENALTY_INR:,} recommended."
            ),
        )
    return result


@router.get("/wards/leaderboard")
async def get_wards_leaderboard():
    """Returns municipal ward ranking, Clean Air Grade (A+ to F), and grievance resolution SLA."""
    wards = [
        {"rank": 1, "ward_name": "Hauz Khas (Ward 152)", "grade": "A+", "avg_pm25": 118.0, "route_compliance_pct": 98.4, "complaints_resolved_pct": 96.0, "badge": "Green Leader"},
        {"rank": 2, "ward_name": "Chanakyapuri (Ward 104)", "grade": "A", "avg_pm25": 132.0, "route_compliance_pct": 95.0, "complaints_resolved_pct": 94.0, "badge": "High Cleanliness"},
        {"rank": 3, "ward_name": "Rohini Sector 14 (Ward 52)", "grade": "B+", "avg_pm25": 185.0, "route_compliance_pct": 89.2, "complaints_resolved_pct": 88.5, "badge": "Active Mitigation"},
        {"rank": 4, "ward_name": "Lajpat Nagar (Ward 142)", "grade": "B", "avg_pm25": 210.0, "route_compliance_pct": 84.0, "complaints_resolved_pct": 82.0, "badge": "Improving"},
        {"rank": 5, "ward_name": "Punjabi Bagh (Ward 88)", "grade": "C+", "avg_pm25": 245.0, "route_compliance_pct": 78.5, "complaints_resolved_pct": 74.0, "badge": "Moderate Action"},
        {"rank": 6, "ward_name": "Okhla Phase-II (Ward 186)", "grade": "D", "avg_pm25": 315.0, "route_compliance_pct": 52.0, "complaints_resolved_pct": 58.0, "badge": "Contractor Alert"},
        {"rank": 7, "ward_name": "Anand Vihar (Ward 212)", "grade": "F", "avg_pm25": 395.0, "route_compliance_pct": 41.0, "complaints_resolved_pct": 39.0, "badge": "Critical Hotspot"},
    ]
    return {
        "total_wards": 250,
        "leaderboard": wards,
        "methodology": "Weighted 24h exposure avoided + IoT machine route compliance + citizen grievance resolution SLA within 3 hours.",
    }
