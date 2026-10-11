"""Live fleet: ingest, live/nearby/track in memory, Redis (fakeredis) and DynamoDB, WebSocket, audit."""
import asyncio
import time

import boto3
import fakeredis
import pytest
from fastapi.testclient import TestClient
from moto import mock_aws

from hawa_backend.aws import clients, get_aws_settings
from hawa_backend.core import redis_store
from hawa_backend.core.config import get_settings
from hawa_backend.services import fleet

REGION = "ap-south-1"


def ping(asset="SPR-04", lat=28.6476, lon=77.3158, flow=48.2, speed=14.5, ts=None, **extra):
    return dict(asset_id=asset, lat=lat, lon=lon, pump_flow_lpm=flow, speed_kmh=speed,
                timestamp=ts if ts is not None else time.time(), **extra)


@pytest.fixture(autouse=True)
def _clean():
    fleet.reset_memory()
    redis_store.reset()
    yield
    fleet.reset_memory()
    redis_store.reset()


@pytest.fixture
def client():
    from hawa_backend.api.app import app

    return TestClient(app)


def test_ingest_then_live_devices_and_live_ops(client):
    r = client.post("/v1/telemetry/vehicles", json=[ping(), ping("SWP-07", 28.535, 77.271, flow=0, speed=0)])
    assert r.status_code == 202 and r.json()["accepted"] == 2

    live = client.get("/v1/fleet/live").json()
    assert {i["asset_id"]: i["status"] for i in live["items"]} == {"SPR-04": "Spraying", "SWP-07": "Idle"}

    devices = client.get("/v1/devices").json()
    assert devices["simulated"] is False
    assert devices["items"][0]["id"] in ("SPR-04", "SWP-07") and devices["items"][0]["simulated"] is False

    ops = client.get("/v1/citizen/live-operations").json()
    spr = [v for v in ops["active_fleet"] if v["asset_id"] == "SPR-04"]
    assert ops["live_fleet_count"] == 2 and len(spr) == 1 and spr[0]["live"] is True
    assert spr[0]["status"] == "ACTIVE_SPRAYING"


def test_stale_pings_leave_the_live_fleet(client):
    client.post("/v1/telemetry/vehicles", json=ping(ts=time.time() - 3600))
    assert client.get("/v1/fleet/live").json()["count"] == 0


def test_ingest_key_enforced(client, monkeypatch):
    monkeypatch.setenv("HAWA_INGEST_API_KEY", "device-key")
    get_settings.cache_clear()
    assert client.post("/v1/telemetry/vehicles", json=ping()).status_code == 401
    ok = client.post("/v1/telemetry/vehicles", json=ping(), headers={"X-Api-Key": "device-key"})
    assert ok.status_code == 202


def test_nearby_in_memory(client):
    client.post("/v1/telemetry/vehicles", json=[ping(), ping("SMG-12", 28.6720, 77.1250)])
    near = client.get("/v1/fleet/nearby", params={"lat": 28.6476, "lon": 77.3158, "radius_km": 5}).json()
    assert [i["asset_id"] for i in near["items"]] == ["SPR-04"]
    assert near["items"][0]["distance_m"] < 1


def test_redis_geo_index(client, monkeypatch):
    monkeypatch.setenv("HAWA_REDIS_URL", "redis://test")
    get_settings.cache_clear()
    server = fakeredis.FakeServer()
    redis_store.set_clients(
        async_client=fakeredis.FakeAsyncRedis(server=server, decode_responses=True),
        sync_client=fakeredis.FakeRedis(server=server, decode_responses=True),
    )
    client.post("/v1/telemetry/vehicles", json=[ping(), ping("SMG-12", 28.6720, 77.1250)])
    sync = fakeredis.FakeRedis(server=server, decode_responses=True)
    assert set(sync.zrange(fleet.GEO_KEY, 0, -1)) == {"SPR-04", "SMG-12"}
    hits = sync.geosearch(fleet.GEO_KEY, longitude=77.3158, latitude=28.6476, radius=5, unit="km")
    assert hits == ["SPR-04"]

    fleet.reset_memory()  # reads must come from Redis now
    near = client.get("/v1/fleet/nearby", params={"lat": 28.6476, "lon": 77.3158, "radius_km": 5}).json()
    assert [i["asset_id"] for i in near["items"]] == ["SPR-04"]
    assert client.get("/v1/fleet/live").json()["count"] == 2


def test_dynamodb_track_and_ttl(client, monkeypatch):
    for k, v in {
        "AWS_ACCESS_KEY_ID": "test", "AWS_SECRET_ACCESS_KEY": "test", "HAWA_AWS_ENABLED": "true",
        "HAWA_AWS_REGION": REGION, "HAWA_AWS_FLEET_TABLE": "hawa-fleet-telemetry",
    }.items():
        monkeypatch.setenv(k, v)
    get_aws_settings.cache_clear()
    clients.reset_clients()
    with mock_aws():
        boto3.client("dynamodb", region_name=REGION).create_table(
            TableName="hawa-fleet-telemetry",
            BillingMode="PAY_PER_REQUEST",
            AttributeDefinitions=[{"AttributeName": "asset_id", "AttributeType": "S"},
                                  {"AttributeName": "timestamp", "AttributeType": "S"}],
            KeySchema=[{"AttributeName": "asset_id", "KeyType": "HASH"},
                       {"AttributeName": "timestamp", "KeyType": "RANGE"}],
        )
        now = time.time()
        client.post("/v1/telemetry/vehicles", json=[ping(ts=now - 120), ping(ts=now - 60), ping(ts=now)])
        items = boto3.resource("dynamodb", region_name=REGION).Table("hawa-fleet-telemetry").scan()["Items"]
        assert len(items) == 3 and all(int(i["ttl_epoch"]) > now + 6 * 86400 for i in items)

        fleet.reset_memory()  # the track must come from DynamoDB
        track = client.get("/v1/fleet/SPR-04/track", params={"minutes": 10}).json()
        assert track["count"] == 3 and track["items"][0]["epoch"] < track["items"][-1]["epoch"]
    clients.reset_clients()


def test_missed_machine_audit_uses_live_telemetry(client):
    now = time.time()
    # SPR-04 sprays on site for 20 minutes
    client.post("/v1/telemetry/vehicles", json=[ping(ts=now - 1200 + i * 60) for i in range(21)])
    ok = client.post("/v1/citizen/reports/missed-machine", json={
        "asset_id": "SPR-04", "cell_id": "C-1", "ward": "Anand Vihar", "lat": 28.6476, "lon": 77.3158,
    }).json()
    assert ok["evidence_source"] == "live_telemetry" and ok["verdict"] == "MACHINE_ACTIVE_VERIFIED"
    assert ok["evidence"]["dwell_minutes"] == 20.0

    # SWP-07 never leaves the depot 8 km away
    client.post("/v1/telemetry/vehicles", json=[ping("SWP-07", 28.535, 77.271, flow=0, speed=0, ts=now - 600 + i * 60) for i in range(11)])
    bad = client.post("/v1/citizen/reports/missed-machine", json={
        "asset_id": "SWP-07", "cell_id": "C-2", "ward": "Okhla", "lat": 28.6476, "lon": 77.3158,
    }).json()
    assert bad["verdict"] == "SLA_BREACH_CONFIRMED" and bad["penalty_fine_inr"] == 25000


def test_missed_machine_audit_counts_ten_minute_pings(client):
    # the simulator's default cadence: one ping every 10 minutes, 20 minutes on site
    now = time.time()
    client.post("/v1/telemetry/vehicles", json=[ping(ts=now - 1200 + i * 600) for i in range(3)])
    ok = client.post("/v1/citizen/reports/missed-machine", json={
        "asset_id": "SPR-04", "cell_id": "C-1", "ward": "Anand Vihar", "lat": 28.6476, "lon": 77.3158,
    }).json()
    assert ok["verdict"] == "MACHINE_ACTIVE_VERIFIED" and ok["evidence"]["dwell_minutes"] == 20.0

    # a gap longer than the live window counts only up to HAWA_FLEET_ACTIVE_MINUTES (15)
    pts = [dict(ping(ts=t), epoch=t) for t in (now - 3600, now)]
    assert fleet.evaluate(pts, None, None, 60)["dwell_minutes"] == 15.0

    # No telemetry at all: the simulated auditor answers
    sim = client.post("/v1/citizen/reports/missed-machine", json={"asset_id": "SMG-12", "cell_id": "C-3", "ward": "x"}).json()
    assert sim["evidence_source"] == "simulated"


def test_websocket_snapshot_then_live_pings(client):
    client.post("/v1/telemetry/vehicles", json=ping("SMG-12", 28.672, 77.125))
    with client.websocket_connect("/v1/ws/fleet") as ws:
        snap = ws.receive_json()
        assert snap["type"] == "snapshot" and [i["asset_id"] for i in snap["items"]] == ["SMG-12"]
        client.post("/v1/telemetry/vehicles", json=ping())
        msg = ws.receive_json()
        assert msg["type"] == "ping" and msg["item"]["asset_id"] == "SPR-04" and msg["item"]["status"] == "Spraying"


def test_status_of_thresholds():
    now = time.time()
    base = {"epoch": now, "pump_flow_lpm": 0.0, "speed_kmh": 0.0}
    assert fleet.status_of(dict(base, pump_flow_lpm=6.0), now) == "Spraying"
    assert fleet.status_of(dict(base, speed_kmh=10.0), now) == "En route"
    assert fleet.status_of(base, now) == "Idle"
    assert fleet.status_of(dict(base, epoch=now - 3600), now) == "Offline"
    assert asyncio.run(fleet.live_fleet()) == []
