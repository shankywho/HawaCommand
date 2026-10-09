"""Integration tests for HawaCommand REST API endpoints."""
import pytest
from httpx import ASGITransport, AsyncClient
from hawa_backend.api.app import create_app

app = create_app()


@pytest.mark.asyncio
async def test_health_probes():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        r_health = await client.get("/healthz")
        assert r_health.status_code == 200
        assert r_health.json() == {"status": "ok"}

        r_ready = await client.get("/readyz")
        assert r_ready.status_code == 200
        assert r_ready.json()["status"] == "ready"


@pytest.mark.asyncio
async def test_hotspots_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Default hour = 0
        res = await client.get("/v1/hotspots")
        assert res.status_code == 200
        data = res.json()
        assert "items" in data
        assert len(data["items"]) == 10
        first = data["items"][0]
        assert "cellId" in first
        assert "pm25" in first
        assert "band" in first
        assert "cause" in first
        assert "suspectPin" in first

        # Query with ward filter
        res_ward = await client.get("/v1/hotspots?ward=West")
        assert res_ward.status_code == 200
        data_ward = res_ward.json()
        assert all(item["ward"] == "West" for item in data_ward["items"])


@pytest.mark.asyncio
async def test_forecast_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/v1/forecast")
        assert res.status_code == 200
        data = res.json()
        assert "grap" in data
        assert "series" in data
        assert len(data["series"]) == 73
        grap = data["grap"]
        assert grap["stage"] in {"I", "II", "III", "IV"}
        assert 0 < grap["probability"] < 1
        assert data["wards"] and data["wards"] == sorted(data["wards"], key=lambda w: -w["peopleHours"])


@pytest.mark.asyncio
async def test_plans_lifecycle():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # List plans
        res_list = await client.get("/v1/plans")
        assert res_list.status_code == 200
        plans_data = res_list.json()
        assert "items" in plans_data
        assert len(plans_data["items"]) >= 1
        plan_id = plans_data["items"][0]["id"]

        # Get plan detail
        res_detail = await client.get(f"/v1/plans/{plan_id}")
        assert res_detail.status_code == 200
        detail = res_detail.json()
        assert detail["id"] == plan_id
        assert detail["status"] == "draft"
        assert "headline" in detail
        assert "groups" in detail
        assert "checks" in detail

        # Apply suggestion
        res_sug = await client.post(f"/v1/plans/{plan_id}/suggestions/com-01/apply")
        assert res_sug.status_code == 200
        updated = res_sug.json()
        applied_comment = next(c for c in updated["comments"] if c["id"] == "com-01")
        assert applied_comment["status"] == "applied"

        # Approve plan
        res_app = await client.post(f"/v1/plans/{plan_id}/approve", json={"note": "Approved for Thursday morning"})
        assert res_app.status_code == 200
        approved = res_app.json()
        assert approved["status"] == "approved"
        assert "executionArn" not in approved  # AWS dispatch is off in tests

        # Compare / What-If
        res_comp = await client.get(f"/v1/plans/{plan_id}/compare")
        assert res_comp.status_code == 200
        comp = res_comp.json()
        assert "deltaPct" in comp
        assert len(comp["rows"]) >= 1


@pytest.mark.asyncio
async def test_devices_fleet():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/v1/devices")
        assert res.status_code == 200
        data = res.json()
        assert "items" in data
        assert len(data["items"]) >= 2
        sprinkler = next(a for a in data["items"] if a["id"] == "T-12")
        assert sprinkler["kind"] == "sprinkler"
        assert sprinkler["tag"]["pumpOn"] is True


@pytest.mark.asyncio
async def test_impact_and_library():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res_imp = await client.get("/v1/impact")
        assert res_imp.status_code == 200
        data_imp = res_imp.json()
        assert "summary" in data_imp
        assert data_imp["items"][0]["impact"]["verdict"] == "Verified"

        res_lib = await client.get("/v1/impact/library")
        assert res_lib.status_code == 200
        lib = res_lib.json()
        assert "items" in lib
        assert len(lib["items"]) >= 3


@pytest.mark.asyncio
async def test_alerts_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/v1/alerts")
        assert res.status_code == 200
        data = res.json()
        assert "counts" in data
        assert len(data["items"]) >= 2


@pytest.mark.asyncio
async def test_driver_route_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/v1/driver/route?asset=T-12")
        assert res.status_code == 200
        route = res.json()
        assert route["asset"] == "T-12"
        assert len(route["stops"]) == 3
        assert "placeHi" in route["stops"][0]


@pytest.mark.asyncio
async def test_context_headers():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        req_id = "test-req-999"
        corr_id = "test-corr-888"
        headers = {"x-request-id": req_id, "x-correlation-id": corr_id}
        res = await client.get("/healthz", headers=headers)
        assert res.headers.get("x-request-id") == req_id
        assert res.headers.get("x-correlation-id") == corr_id


@pytest.mark.asyncio
async def test_open_air_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/open/v1/air?limit=5")
        assert res.status_code == 200
        data = res.json()
        assert data["unit"] == "ug/m3" and data["pollutant"] == "pm25"
        assert 0 < len(data["cells"]) <= 5
        cell = data["cells"][0]
        assert {"cellId", "ward", "lon", "lat", "pm25", "band"} <= set(cell)


@pytest.mark.asyncio
async def test_impact_has_series_matching_effect():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/v1/impact")
        assert res.status_code == 200
        impact = res.json()["items"][0]["impact"]
        series = impact["series"]
        assert len(series) > 10
        deepest = min(p["observed"] / p["control"] - 1 for p in series)
        assert abs(deepest * 100 - impact["effectPct"]) < 5
        assert all(p["lo"] < p["control"] < p["hi"] for p in series)
