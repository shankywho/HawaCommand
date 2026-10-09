"""Unit tests for Phase 7: FastAPI serving layer, cycle pipelines, and demo seed."""
from fastapi.testclient import TestClient
import pytest

from hawa_ml.api.main import app
from hawa_ml.pipelines.cycle import run_3hour_cycle
from scripts.demo_seed import seed_demo_scenario

client = TestClient(app)


def test_api_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert "models" in data


def test_api_twin():
    resp = client.get("/twin?limit=25")
    assert resp.status_code == 200
    data = resp.json()
    assert data["returned_cells"] <= 25
    assert len(data["cells"]) > 0
    assert "pm25_est" in data["cells"][0]
    assert "confidence" in data["cells"][0]


def test_api_forecast():
    resp = client.get("/forecast/G-052-054?pm25=220.0")
    assert resp.status_code == 200
    data = resp.json()
    assert data["cell_id"] == "G-052-054"
    assert "summary" in data
    assert len(data["points"]) == 7


def test_api_hotspots():
    resp = client.get("/hotspots?limit=5")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 5
    assert data[0]["exposure_score"] >= data[1]["exposure_score"]
    assert "recommended_asset" in data[0]


def test_api_plans_draft_and_simulate():
    # Draft plan
    draft_payload = {
        "ward": "all",
        "limit_hotspots": 4,
        "assets": [
            {"id": "SPR-01", "type": "sprinkler", "depot_lat": 28.64, "depot_lon": 77.30, "capacity_litres": 8000}
        ],
    }
    resp = client.post("/plans/draft", json=draft_payload)
    assert resp.status_code == 200
    plan_data = resp.json()
    assert plan_data["plan_id"].startswith("PLAN-")
    assert plan_data["auditor_verdict"] in ["approved", "revise"]

    # Simulate What-If
    sim_resp = client.post(f"/plans/{plan_data['plan_id']}/simulate", json={})
    assert sim_resp.status_code == 200
    sim_data = sim_resp.json()
    assert "ai_plan" in sim_data
    assert "usual_fixed_route_baseline" in sim_data
    assert sim_data["comparison"]["gain_percentage"] > 0


def test_api_causal_verify():
    resp = client.post("/interventions/INT-TEST-01/verify")
    assert resp.status_code == 200
    data = resp.json()
    assert data["method"] == "synthetic_control"
    assert "measured_effect_pct" in data
    assert data["acceptance_check_passed"] is True


def test_api_insights():
    resp = client.get("/insights")
    assert resp.status_code == 200
    data = resp.json()
    assert data["count"] > 0
    assert "narrative" in data["insights"][0]
    assert "narrative_en" in data["insights"][0]["narrative"]


def test_api_ingest_telemetry():
    packet_payload = {
        "v": 1,
        "dev": "HPM-TEST-INGEST",
        "role": "M",
        "seq": 2045,
        "ts": "2026-11-12T08:00:00Z",
        "gps": {"lat": 28.6331, "lon": 77.2194, "spd": 24.5, "hdop": 0.8},
        "pm": {"pm1": 85.0, "pm25": 145.0, "pm10": 235.0},
        "env": {"t": 21.0, "rh": 72.0, "p": 1013.0},
        "flags": [],
    }
    resp = client.post("/ingest/telemetry", json=packet_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data["ingested_count"] == 1
    assert data["records"][0]["calibrated_pm25"] > 0


def test_api_effectiveness_library():
    resp = client.get("/effectiveness-library")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["records"]) >= 4


def test_demo_seed_and_cycle_execution():
    # 1. Test demo seed script
    seed_demo_scenario()
    # 2. Test operational cycle
    cycle_out = run_3hour_cycle()
    assert "plan" in cycle_out
    assert cycle_out["plan"]["total_exposure_avoided_person_hours"] > 0
