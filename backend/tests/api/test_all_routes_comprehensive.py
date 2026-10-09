"""Exhaustive route validation test suite ensuring NO route is broken, missing, or regressively altered.

Tests all 27 registered endpoints across:
- Health and liveness probes
- Hotspots & Digital Twin
- 72h Forecast & cell-level forecast
- Action plans (list, detail, draft, approve, request-changes, apply-suggestion, compare, simulate)
- Fleet devices & HawaTag telemetry
- Causal impact (list, library, verify, and aliases)
- Multi-channel alerts
- Driver turn-by-turn routes
"""
import pytest
from httpx import ASGITransport, AsyncClient

from hawa_backend.api.app import create_app

app = create_app()


@pytest.mark.asyncio
async def test_all_health_probes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        for path in ["/healthz", "/health", "/livez", "/v1/health"]:
            r = await client.get(path)
            assert r.status_code == 200, f"Failed on {path}: {r.text}"
            assert r.json() == {"status": "ok"}

        r_ready = await client.get("/readyz")
        assert r_ready.status_code == 200
        assert r_ready.json()["status"] == "ready"


@pytest.mark.asyncio
async def test_hotspots_and_twin_routes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Hotspots list
        r1 = await client.get("/v1/hotspots")
        assert r1.status_code == 200
        data1 = r1.json()
        assert "items" in data1
        assert len(data1["items"]) > 0
        first_cell_id = data1["items"][0]["cellId"]

        # 2. Hotspots with filters
        r2 = await client.get("/v1/hotspots?hour=4&ward=West&threshold=200")
        assert r2.status_code == 200
        assert r2.json()["hour"] == 4

        # 3. Single hotspot detail
        r3 = await client.get(f"/v1/hotspots/{first_cell_id}")
        assert r3.status_code == 200
        assert r3.json()["cellId"] == first_cell_id

        # 4. Single hotspot 404
        r4 = await client.get("/v1/hotspots/NON_EXISTENT_CELL")
        assert r4.status_code == 404

        # 5. Digital twin
        r5 = await client.get("/v1/twin?limit=50")
        assert r5.status_code == 200
        twin_data = r5.json()
        assert "cells" in twin_data or "items" in twin_data


@pytest.mark.asyncio
async def test_forecast_routes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Ward / City level forecast
        r1 = await client.get("/v1/forecast")
        assert r1.status_code == 200
        f_data = r1.json()
        assert "series" in f_data
        assert len(f_data["series"]) == 73
        assert "grap" in f_data

        # 2. Ward filtered forecast
        r2 = await client.get("/v1/forecast?ward=North%20West")
        assert r2.status_code == 200
        assert r2.json()["ward"] == "North West"

        # 3. Specific cell forecast
        r3 = await client.get("/v1/forecast/C-2863-7721")
        assert r3.status_code == 200
        cell_f = r3.json()
        assert "series" in cell_f


@pytest.mark.asyncio
async def test_plans_complete_lifecycle_routes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. List plans
        r_list = await client.get("/v1/plans")
        assert r_list.status_code == 200
        assert "items" in r_list.json()

        # 2. Draft new plan
        r_draft = await client.post("/v1/plans/draft", json={"ward": "ward-084", "windowStart": "2026-11-13T06:00:00Z"})
        assert r_draft.status_code == 200
        draft_plan = r_draft.json()
        draft_id = draft_plan["id"]
        assert draft_plan["status"] == "draft"

        # 3. Get plan detail
        r_get = await client.get(f"/v1/plans/{draft_id}")
        assert r_get.status_code == 200
        assert r_get.json()["id"] == draft_id

        # 4. Compare plan (GET)
        r_comp = await client.get(f"/v1/plans/{draft_id}/compare")
        assert r_comp.status_code == 200
        assert "deltaPct" in r_comp.json()

        # 5. Simulate plan (POST alias)
        r_sim = await client.post(f"/v1/plans/{draft_id}/simulate")
        assert r_sim.status_code == 200
        assert "deltaPct" in r_sim.json()

        # 6. Apply suggestion on draft plan
        r_sug = await client.post(f"/v1/plans/{draft_id}/suggestions/com-01/apply")
        assert r_sug.status_code == 200

        # 7. Request changes on draft plan
        r_chg = await client.post(f"/v1/plans/{draft_id}/request-changes", json={"note": "Shift schedule earlier"})
        assert r_chg.status_code == 200
        assert r_chg.json()["status"] == "changes_requested"

        # 8. Approve draft plan
        r_app = await client.post(f"/v1/plans/{draft_id}/approve", json={"note": "Approved by commissioner"})
        assert r_app.status_code == 200
        assert r_app.json()["status"] == "approved"
        assert "executionArn" not in r_app.json()  # AWS dispatch is off in tests

        # Clean up in-memory plans store to keep test isolation
        from hawa_backend.api.routes.plans import _ACTIVE_PLANS
        _ACTIVE_PLANS.pop(draft_id, None)
        _ACTIVE_PLANS.pop("214", None)



@pytest.mark.asyncio
async def test_fleet_devices_routes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        r = await client.get("/v1/devices")
        assert r.status_code == 200
        data = r.json()
        assert "items" in data
        assert len(data["items"]) >= 2
        first = data["items"][0]
        assert "id" in first
        assert "kind" in first
        assert "tag" in first


@pytest.mark.asyncio
async def test_impact_and_verification_routes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Impact list
        r1 = await client.get("/v1/impact")
        assert r1.status_code == 200
        assert "items" in r1.json()

        # 2. Effectiveness library
        r2 = await client.get("/v1/impact/library")
        assert r2.status_code == 200
        assert len(r2.json()["items"]) >= 3

        # 3. Explicit verification via /v1/impact/{id}/verify (POST and GET)
        r3_post = await client.post("/v1/impact/INT-9912/verify")
        assert r3_post.status_code == 200
        assert r3_post.json()["verdict"] in ("Verified", "Inconclusive")

        r3_get = await client.get("/v1/impact/INT-9912/verify")
        assert r3_get.status_code == 200

        # 4. Explicit verification via /v1/interventions/{id}/verify (POST and GET)
        r4_post = await client.post("/v1/interventions/INT-9912/verify")
        assert r4_post.status_code == 200
        assert r4_post.json()["method"] == "synthetic_control"

        r4_get = await client.get("/v1/interventions/INT-9912/verify")
        assert r4_get.status_code == 200


@pytest.mark.asyncio
async def test_alerts_routes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        r = await client.get("/v1/alerts")
        assert r.status_code == 200
        data = r.json()
        assert "counts" in data
        assert "items" in data


@pytest.mark.asyncio
async def test_driver_route_routes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        r = await client.get("/v1/driver/route?asset=T-12")
        assert r.status_code == 200
        route = r.json()
        assert route["asset"] == "T-12"
        assert len(route["stops"]) >= 1
        assert "placeHi" in route["stops"][0]
