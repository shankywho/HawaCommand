"""SNS broadcasts and subscriptions, FCM, Secrets Manager bootstrap, Kinesis consumer, Redis twin snapshot,
Redis-backed plans and the /v1/me routes."""
import asyncio
import json
import os
import time

import boto3
import fakeredis
import httpx
import pytest
from fastapi.testclient import TestClient
from moto import mock_aws

from hawa_backend.aws import clients, get_aws_settings
from hawa_backend.aws import kinesis_consumer
from hawa_backend.core import config as core_config
from hawa_backend.core import redis_store
from hawa_backend.core.config import get_settings
from hawa_backend.services import alerts, fleet, push, twin_cache

REGION = "ap-south-1"


@pytest.fixture(autouse=True)
def _clean():
    alerts.reset()
    push.reset()
    fleet.reset_memory()
    redis_store.reset()
    yield
    alerts.reset()
    push.reset()
    fleet.reset_memory()
    redis_store.reset()


@pytest.fixture
def client():
    from hawa_backend.api.app import app

    return TestClient(app)


@pytest.fixture
def aws(monkeypatch):
    for k, v in {
        "AWS_ACCESS_KEY_ID": "test", "AWS_SECRET_ACCESS_KEY": "test",
        "HAWA_AWS_ENABLED": "true", "HAWA_AWS_REGION": REGION,
    }.items():
        monkeypatch.setenv(k, v)
    get_aws_settings.cache_clear()
    clients.reset_clients()
    with mock_aws():
        yield
    get_aws_settings.cache_clear()
    clients.reset_clients()


@pytest.fixture
def redis(monkeypatch):
    monkeypatch.setenv("HAWA_REDIS_URL", "redis://test")
    get_settings.cache_clear()
    server = fakeredis.FakeServer()
    redis_store.set_clients(
        async_client=fakeredis.FakeAsyncRedis(server=server, decode_responses=True),
        sync_client=fakeredis.FakeRedis(server=server, decode_responses=True),
    )
    return fakeredis.FakeRedis(server=server, decode_responses=True)


# --------------------------------------------------------------------------- SNS


def test_broadcast_publishes_to_sns_and_lists_it(client, aws, monkeypatch):
    sns = boto3.client("sns", region_name=REGION)
    topic = sns.create_topic(Name="hawa-citizen-push-alerts")["TopicArn"]
    monkeypatch.setenv("HAWA_AWS_ALERTS_TOPIC_ARN", topic)
    monkeypatch.setenv("HAWA_ADMIN_API_KEY", "k")
    get_aws_settings.cache_clear()
    get_settings.cache_clear()

    body = {"type": "INVERSION_WARNING", "ward": "Rohini", "window": "06:00 - 09:30 AM", "expected_pm25": 410,
            "message": "Severe morning inversion expected. Keep vulnerable family members indoors."}
    assert client.post("/v1/alerts/broadcast", json=body).status_code == 401
    out = client.post("/v1/alerts/broadcast", json=body, headers={"X-Api-Key": "k"}).json()
    assert out["snsMessageId"] and out["fcmMessageName"] is None
    assert out["delivered"] == "SNS sent · Push not configured"

    listed = client.get("/v1/alerts").json()
    assert listed["simulated"] is False and listed["items"][0]["id"] == out["id"]
    assert listed["items"][0]["target"] == "Rohini" and listed["items"][0]["channel"] == "SMS"
    assert client.get(f"/v1/alerts/{out['id']}").json()["message"].startswith("Severe")


def test_sns_subscriber_gets_a_ward_filter(client, aws, monkeypatch):
    sns = boto3.client("sns", region_name=REGION)
    topic = sns.create_topic(Name="alerts")["TopicArn"]
    monkeypatch.setenv("HAWA_AWS_ALERTS_TOPIC_ARN", topic)
    get_aws_settings.cache_clear()
    out = client.post("/v1/alerts/subscribers", json={"protocol": "email", "endpoint": "a@b.in", "ward": "Rohini"}).json()
    attrs = sns.get_subscription_attributes(SubscriptionArn=out["subscriptionArn"])["Attributes"]
    assert json.loads(attrs["FilterPolicy"]) == {"ward": ["Rohini", "all"]}
    assert client.post("/v1/alerts/subscribers", json={"protocol": "sms", "endpoint": "98123"}).status_code == 422


def test_subscribers_503_when_unconfigured(client):
    assert client.post("/v1/alerts/subscribers", json={"protocol": "email", "endpoint": "a@b.in"}).status_code == 503


def test_plan_approval_publishes_one_sns_notice(client, aws, monkeypatch):
    sns = boto3.client("sns", region_name=REGION)
    topic = sns.create_topic(Name="alerts")["TopicArn"]
    monkeypatch.setenv("HAWA_AWS_ALERTS_TOPIC_ARN", topic)
    get_aws_settings.cache_clear()
    plan = client.post("/v1/plans/214/approve", json={}).json()
    assert plan["status"] == "approved" and plan["alertMessageId"]
    assert client.get("/v1/alerts").json()["items"][0]["audience"] == "Drivers"


# --------------------------------------------------------------------------- FCM


def _service_account():
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import rsa

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption())
    return {"type": "service_account", "project_id": "hawa-test", "client_email": "fcm@hawa-test.iam.gserviceaccount.com",
            "private_key": pem.decode(), "private_key_id": "abc", "token_uri": "https://oauth2.googleapis.com/token"}


def test_fcm_topic_and_user_sends(client, monkeypatch):
    monkeypatch.setenv("HAWA_FCM_SERVICE_ACCOUNT_JSON", json.dumps(_service_account()))
    get_settings.cache_clear()
    calls = []

    def fake_post(url, data=None, timeout=None):
        calls.append(("token", url, data["grant_type"]))
        return httpx.Response(200, json={"access_token": "ya29.test", "expires_in": 3600}, request=httpx.Request("POST", url))

    async def fake_async_post(self, url, headers=None, json=None):
        calls.append(("send", url, json["message"].get("topic") or json["message"].get("token")))
        if json["message"].get("token") == "dead-token":
            return httpx.Response(404, text='{"error": {"status": "NOT_FOUND", "details": [{"errorCode": "UNREGISTERED"}]}}',
                                  request=httpx.Request("POST", url))
        return httpx.Response(200, json={"name": "projects/hawa-test/messages/1"}, request=httpx.Request("POST", url))

    monkeypatch.setattr(httpx, "post", fake_post)
    monkeypatch.setattr(httpx.AsyncClient, "post", fake_async_post)

    assert asyncio.run(push.send_to_topic("t", "b", {"type": "pollutant_warning"})) == "projects/hawa-test/messages/1"
    assert calls[0] == ("token", "https://oauth2.googleapis.com/token", "urn:ietf:params:oauth:grant-type:jwt-bearer")
    assert calls[1] == ("send", "https://fcm.googleapis.com/v1/projects/hawa-test/messages:send", "hawa-alerts")

    alice = {"Authorization": "Bearer " + __import__("jwt").encode({"sub": "alice"}, key="", algorithm="none")}
    assert client.put("/v1/me/push-token", json={"token": "good-token-123", "platform": "android"}, headers=alice).status_code == 200
    client.put("/v1/me/push-token", json={"token": "dead-token", "platform": "android"}, headers=alice)
    assert asyncio.run(push.send_to_user("alice", "t", "b", {"type": "report_outcome"})) == 1
    assert asyncio.run(push.tokens_for("alice")) == ["good-token-123"]  # the unregistered one was dropped
    assert [c[0] for c in calls].count("token") == 1  # OAuth token is cached


def test_push_is_a_noop_without_credentials():
    assert push.configured() is False
    assert asyncio.run(push.send_to_topic("t", "b", {})) is None


# --------------------------------------------------------------------------- Secrets Manager


def test_bootstrap_secrets_fills_env_without_overriding(aws, monkeypatch):
    sm = boto3.client("secretsmanager", region_name=REGION)
    sm.create_secret(Name="hawa/backend", SecretString=json.dumps({
        "HAWA_JWT_SECRET": "from-secret", "WAQI_TOKEN": "waqi-from-secret", "HAWA_ADMIN_API_KEY": "already-set",
    }))
    monkeypatch.setenv("HAWA_AWS_SECRETS_ID", "hawa/backend")
    monkeypatch.setenv("HAWA_ADMIN_API_KEY", "from-env")
    for k in ("HAWA_JWT_SECRET", "WAQI_TOKEN"):
        monkeypatch.delenv(k, raising=False)
    monkeypatch.setattr(core_config, "_secrets_loaded", False)
    try:
        assert core_config.bootstrap_secrets() == 2
        s = get_settings()
        assert s.jwt_secret == "from-secret" and s.waqi_token == "waqi-from-secret" and s.admin_api_key == "from-env"
    finally:
        for k in ("HAWA_JWT_SECRET", "WAQI_TOKEN"):
            os.environ.pop(k, None)
        core_config._secrets_loaded = True


def test_fcm_credentials_from_secrets_manager(aws, monkeypatch):
    boto3.client("secretsmanager", region_name=REGION).create_secret(
        Name="hawa/firebase/service-account", SecretString=json.dumps(_service_account()))
    monkeypatch.setenv("HAWA_AWS_FCM_SECRET_ID", "hawa/firebase/service-account")
    get_aws_settings.cache_clear()
    assert push.credentials()["project_id"] == "hawa-test"


# --------------------------------------------------------------------------- Kinesis


def test_kinesis_records_reach_the_fleet_and_api_echoes_are_skipped(aws, monkeypatch):
    kinesis = boto3.client("kinesis", region_name=REGION)
    kinesis.create_stream(StreamName="hawa-sensor-data", ShardCount=1)
    monkeypatch.setenv("HAWA_AWS_SENSOR_STREAM", "hawa-sensor-data")
    monkeypatch.setenv("HAWA_AWS_KINESIS_START", "TRIM_HORIZON")
    get_aws_settings.cache_clear()

    iot = {"asset_id": "SPR-04", "lat": 28.6476, "lon": 77.3158, "speed_kmh": 14.5, "pump_flow_lpm": 48.2,
           "timestamp": "2026-10-08T03:00:00Z"}
    echo = dict(iot, asset_id="SMG-12", via="api")
    no_position = {"device_id": "pod-1", "pm25": 120.0}
    for rec in (iot, echo, no_position):
        kinesis.put_record(StreamName="hawa-sensor-data", Data=json.dumps(rec).encode(), PartitionKey="p")

    monkeypatch.setattr(kinesis_consumer, "IDLE_SLEEP_SECONDS", 0.01)

    async def go():
        stop = asyncio.Event()
        task = asyncio.create_task(kinesis_consumer.run(stop))
        for _ in range(200):
            await asyncio.sleep(0.02)
            if fleet._memory.latest:
                break
        stop.set()
        await task

    asyncio.run(go())
    assert list(fleet._memory.latest) == ["SPR-04"]
    assert fleet._memory.latest["SPR-04"]["source"] == "iot"
    assert kinesis_consumer._memory_checkpoints  # checkpoint recorded


def test_api_pings_are_forwarded_to_kinesis(client, aws, monkeypatch):
    kinesis = boto3.client("kinesis", region_name=REGION)
    kinesis.create_stream(StreamName="hawa-sensor-data", ShardCount=1)
    monkeypatch.setenv("HAWA_AWS_SENSOR_STREAM", "hawa-sensor-data")
    get_aws_settings.cache_clear()
    client.post("/v1/telemetry/vehicles", json={"asset_id": "SPR-04", "lat": 28.6, "lon": 77.3, "timestamp": time.time()})
    shard = kinesis.list_shards(StreamName="hawa-sensor-data")["Shards"][0]["ShardId"]
    it = kinesis.get_shard_iterator(StreamName="hawa-sensor-data", ShardId=shard, ShardIteratorType="TRIM_HORIZON")["ShardIterator"]
    records = kinesis.get_records(ShardIterator=it)["Records"]
    assert len(records) == 1 and json.loads(records[0]["Data"])["via"] == "api"


# --------------------------------------------------------------------------- Redis features


def test_twin_snapshot_roundtrip(redis):
    import pandas as pd

    df = pd.DataFrame({"cell_id": ["C-1", "C-2"], "latitude": [28.6, 28.7], "longitude": [77.2, 77.3],
                       "ward": ["Ward-1", "Ward-2"], "pm25_est": [180.5, 95.0]})
    assert twin_cache.save_snapshot(df)
    assert redis.ttl(twin_cache.snapshot_key()) <= 900
    back = twin_cache.load_snapshot()
    assert back.to_dict(orient="records") == df.to_dict(orient="records")


def test_twin_snapshot_absent_without_redis():
    assert twin_cache.load_snapshot() is None and twin_cache.save_snapshot(None) is False


def test_plans_are_shared_through_redis(client, redis):
    from hawa_backend.api.routes import plans

    client.post("/v1/plans/214/approve", json={})
    plans._ACTIVE_PLANS.clear()  # another process: empty local cache
    assert client.get("/v1/plans/214").json()["status"] == "approved"
    assert json.loads(redis.hget(plans.PLANS_KEY, "214"))["status"] == "approved"


def test_alert_subscription_roundtrip(client, redis):
    h = {"Authorization": "Bearer " + __import__("jwt").encode({"sub": "alice"}, key="", algorithm="none")}
    assert client.get("/v1/me/alert-subscription", headers=h).json()["radius_m"] == 1000
    sub = {"radius_m": 2000, "kinds": ["pollutant_warning"], "home": {"lat": 28.645, "lon": 77.19},
           "place_name": {"en": "Karol Bagh"}, "quiet_hours": {"start": "22:00", "end": "06:00"}}
    assert client.put("/v1/me/alert-subscription", json=sub, headers=h).json() == sub
    assert client.get("/v1/me/alert-subscription", headers=h).json() == sub
    assert client.put("/v1/me/alert-subscription", json=dict(sub, kinds=["nope"]), headers=h).status_code == 422


def test_readyz_reports_fallbacks(client):
    services = client.get("/readyz").json()["services"]
    assert services["redis"].startswith("off") and services["aws"] == "disabled" and services["fcm"] == "off"
