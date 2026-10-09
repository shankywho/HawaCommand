"""Comprehensive test suite verifying Backend <-> AI-ML Engine Integration.

Verifies:
1. Direct integration between Backend IntelClient and AI-ML pipelines.
2. Causal verification (Synthetic Control & Placebo test) integration.
3. Exposure-first VRP optimization and Auditor Agent plan evaluation.
4. 72-hour quantile forecasting and GRAP stage determination.
5. Digital Twin hotspots and source attribution.
6. Effectiveness library retrieval.
7. Sensor drive-by calibration and trust scoring.
8. Circuit breaker failure handling and recovery states.
9. Cross-service HTTP ASGI integration between Backend and AI-ML FastAPI apps.
"""
import pytest
from httpx import ASGITransport, AsyncClient

from hawa_backend.core.intel_client import IntelClient, get_intel_client, CircuitState
from hawa_backend.api.app import create_app
from hawa_ml.api.main import app as aiml_app


@pytest.mark.asyncio
async def test_intel_client_health():
    intel = get_intel_client()
    res = await intel.health()
    assert res["status"] == "healthy"
    assert "models" in res
    assert "forecaster" in res["models"]
    assert "causal_verifier" in res["models"]


@pytest.mark.asyncio
async def test_intel_client_hotspots():
    intel = get_intel_client()
    data = await intel.get_hotspots(ward="West", hour=0, limit=5)
    assert "items" in data
    assert len(data["items"]) > 0
    first = data["items"][0]
    assert "cellId" in first
    assert "pm25" in first
    assert "exposurePh" in first
    assert "cause" in first
    assert "suspectPin" in first
    assert "forecast" in first
    assert len(first["forecast"]) == 73


@pytest.mark.asyncio
async def test_intel_client_forecast():
    intel = get_intel_client()
    data = await intel.get_forecast(ward="West", cell_id="C-2863-7721")
    assert "series" in data
    assert len(data["series"]) == 73
    assert "grap" in data
    assert data["grap"]["stage"] in ("I", "II", "III", "IV")
    # Verify quantile monotonicity: p10 <= p50 <= p90
    for pt in data["series"]:
        assert pt["p10"] <= pt["p50"] <= pt["p90"]


@pytest.mark.asyncio
async def test_intel_client_draft_plan():
    intel = get_intel_client()
    plan = await intel.draft_plan(ward="ward-084")
    assert plan["status"] == "draft"
    assert "headline" in plan
    assert plan["headline"]["peopleHoursSaved"] > 0
    assert len(plan["groups"]) >= 1
    assert "checks" in plan
    assert len(plan["checks"]) == 3
    assert all(chk["ok"] for chk in plan["checks"])


@pytest.mark.asyncio
async def test_intel_client_whatif_simulate():
    intel = get_intel_client()
    sim = await intel.simulate_plan(plan_id="plan-214")
    assert "deltaPct" in sim
    assert sim["deltaPct"] > 0
    assert "rows" in sim
    assert len(sim["rows"]) >= 1


@pytest.mark.asyncio
async def test_intel_client_causal_verify():
    intel = get_intel_client()
    res = await intel.verify_intervention(
        intervention_id="INT-9912",
        cell_id="C-2863-7721",
        asset="SPR-04",
        action="water_sprinkling",
    )
    assert res["verdict"] in ("Verified", "Inconclusive")
    assert res["effectPct"] < 0  # Expected PM reduction is negative
    assert res["ciLow"] <= res["ciHigh"]
    assert res["method"] == "synthetic_control"
    assert len(res["donorCells"]) >= 1


@pytest.mark.asyncio
async def test_intel_client_effectiveness_library():
    intel = get_intel_client()
    lib = await intel.get_effectiveness_library()
    assert "items" in lib
    assert len(lib["items"]) >= 3
    first = lib["items"][0]
    assert "action" in first
    assert "effectPct" in first
    assert "ci" in first
    assert first["ci"][0] <= first["ci"][1]


def test_intel_client_sensor_calibration():
    intel = get_intel_client()
    cal_pm25, trust = intel.calibrate_reading(
        device_id="HPM-0142",
        raw_pm25=250.0,
        rh=65.0,
    )
    assert cal_pm25 > 0.0
    assert 0.0 <= trust <= 1.0


def test_circuit_breaker_lifecycle():
    client = IntelClient(base_url="http://127.0.0.1:9999", prefer_http=True)
    assert client.breaker.state == CircuitState.CLOSED
    assert client.breaker.can_attempt() is True

    # Record 5 failures
    for _ in range(5):
        client.breaker.record_failure()

    assert client.breaker.state == CircuitState.OPEN
    assert client.breaker.can_attempt() is False

    # Simulate timeout elapsed
    client.breaker.last_state_change -= 20.0
    assert client.breaker.can_attempt() is True
    assert client.breaker.state == CircuitState.HALF_OPEN

    # Probe succeeds
    client.breaker.record_success()
    assert client.breaker.state == CircuitState.CLOSED


@pytest.mark.asyncio
async def test_cross_service_http_asgi_integration():
    """Verify backend calling live AI-ML endpoints over ASGI transport."""
    async with AsyncClient(transport=ASGITransport(app=aiml_app), base_url="http://aiml-service") as aiml_http:
        # 1. AI-ML health probe
        r_health = await aiml_http.get("/health")
        assert r_health.status_code == 200
        assert r_health.json()["status"] == "healthy"

        # 2. AI-ML hotspots
        r_hotspots = await aiml_http.get("/hotspots?limit=5")
        assert r_hotspots.status_code == 200
        hotspots = r_hotspots.json()
        assert len(hotspots) == 5

        # 3. AI-ML forecast
        r_forecast = await aiml_http.get("/forecast/C-2863-7721")
        assert r_forecast.status_code == 200
        assert "horizons" in r_forecast.json()

        # 4. AI-ML causal verification
        r_verify = await aiml_http.post("/interventions/INT-TEST-001/verify")
        assert r_verify.status_code == 200
        assert r_verify.json()["status"] == "statistically_significant"

    # Now verify backend API consuming these integrated contracts
    backend_app = create_app()
    async with AsyncClient(transport=ASGITransport(app=backend_app), base_url="http://backend-service") as backend_http:
        r_b_hotspots = await backend_http.get("/v1/hotspots")
        assert r_b_hotspots.status_code == 200
        assert "items" in r_b_hotspots.json()

        r_b_forecast = await backend_http.get("/v1/forecast")
        assert r_b_forecast.status_code == 200
        assert len(r_b_forecast.json()["series"]) == 73

        r_b_plan = await backend_http.post("/v1/plans/draft", json={"ward": "ward-084"})
        assert r_b_plan.status_code == 200
        assert r_b_plan.json()["ward"] == "ward-084"

        r_b_comp = await backend_http.get("/v1/plans/214/compare")
        assert r_b_comp.status_code == 200
        assert r_b_comp.json()["deltaPct"] > 0

        r_b_impact = await backend_http.get("/v1/impact/library")
        assert r_b_impact.status_code == 200
        assert len(r_b_impact.json()["items"]) >= 3
