"""Seed a consistent, realistic demo scenario for hackathon video demonstrations.

Seeds:
1. Hotspots near 3 schools (Anand Vihar, Punjabi Bagh)
2. 72-hour forecast spike crossing into CAQM GRAP Stage 3
3. A HawaTag sprinkler intervention with known recoverable effect (-18.5% PM10 cut)
4. Full telemetry stream from 6 mobile pods and school sentinels
"""
import json
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

# Add src to sys.path
BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE_DIR / "src"))

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.simulation.interventions import InterventionManager
from hawa_ml.simulation.device_sim import FleetSimulator
from hawa_ml.exposure.engine import exposure_engine
from hawa_ml.twin.grid import load_grid
from hawa_ml.causal.effectiveness_library import effectiveness_library

logger = configure_logging("demo_seed")


def seed_demo_scenario():
    logger.info("=== Seeding HawaCommand Demo Scenario ===")

    now = datetime.now(timezone.utc)

    # 1. Inject Ground-Truth Intervention for Verification Demo
    interv_mgr = InterventionManager()
    interv = interv_mgr.inject_default_demo_intervention(
        cell_id="G-052-054",
        lat=28.6476,
        lon=77.3158,
        action="water_sprinkler",
    )
    logger.info(f"Seeded Intervention: {interv.intervention_id} at Anand Vihar (true cut: -{interv.true_pm10_reduction_pct}%)")

    # 2. Generate Simulated Fleet Telemetry Stream (JSONL)
    sim = FleetSimulator(n_buses=8, n_schools=4, n_sprinklers=2)
    telemetry_file = settings.INTERIM_DATA_DIR / "simulated_telemetry.jsonl"
    count = sim.run_file_mode(telemetry_file, n_steps=40)
    logger.info(f"Seeded Telemetry: {count} packets in {telemetry_file}")

    # 3. Create Demo Scenario Summary JSON for Web Console & Video
    demo_scenario = {
        "scenario_name": "Delhi Winter Morning Inversion & School Defense",
        "created_at": now.isoformat(),
        "hotspots": [
            {
                "cell_id": "G-052-054",
                "location_name": "Anand Vihar / Preet Vihar Cluster",
                "pm25": 285.0,
                "pm10": 435.0,
                "cause": "road_dust",
                "cause_confidence": 0.84,
                "schools_nearby": 3,
                "exposure_score": 38400.0,
                "recommended_action": "water_sprinkler",
            },
            {
                "cell_id": "G-048-032",
                "location_name": "Punjabi Bagh Ring Road Corridor",
                "pm25": 165.0,
                "pm10": 290.0,
                "cause": "traffic",
                "cause_confidence": 0.78,
                "schools_nearby": 1,
                "exposure_score": 19200.0,
                "recommended_action": "traffic_advisory",
            },
            {
                "cell_id": "G-038-044",
                "location_name": "Okhla Phase-II Industrial Outskirts",
                "pm25": 315.0,
                "pm10": 340.0,
                "cause": "open_burning",
                "cause_confidence": 0.88,
                "schools_nearby": 0,
                "exposure_score": 14500.0,
                "recommended_action": "inspection_team",
            },
        ],
        "forecast_outlook": {
            "peak_time": (now + timedelta(hours=24)).strftime("%A 8:00 AM"),
            "pm25_p50": 295.0,
            "pm25_p90": 365.0,
            "grap_stage": "Stage 3 (Severe)",
            "lead_time_hours": 24,
        },
        "injected_intervention": {
            "intervention_id": interv.intervention_id,
            "cell_id": interv.cell_id,
            "action": interv.action_type,
            "true_reduction_pct": interv.true_pm10_reduction_pct,
            "duration_minutes": interv.duration_minutes,
        },
    }

    out_json = settings.FIXTURES_DIR / "demo_scenario.json"
    settings.FIXTURES_DIR.mkdir(parents=True, exist_ok=True)
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(demo_scenario, f, indent=2)
    logger.info(f"Saved complete demo scenario package -> {out_json}")
    logger.info("=== Demo Seeding Complete ===")


if __name__ == "__main__":
    seed_demo_scenario()
