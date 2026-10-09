import asyncio
import json
import time

import boto3
import pytest
from fastapi.testclient import TestClient
from moto import mock_aws

from hawa_backend.aws import clients, forecast as aws_forecast, get_aws_settings
from hawa_backend.aws import cache_get, cache_set, get_aws_forecast, publish_alert, publish_sensor_reading, start_dispatch

REGION = "ap-south-1"
FORECAST = {
    "horizons": [
        {"horizon_h": 1, "pm25_p10": 150.0, "pm25_p50": 200.0, "pm25_p90": 260.0},
        {"horizon_h": 24, "pm25_p10": 170.0, "pm25_p50": 230.0, "pm25_p90": 300.0},
    ],
    "grap_stage": "Stage 3",
}


@pytest.fixture
def aws(monkeypatch):
    for k, v in {
        "AWS_ACCESS_KEY_ID": "test",
        "AWS_SECRET_ACCESS_KEY": "test",
        "HAWA_AWS_ENABLED": "true",
        "HAWA_AWS_REGION": REGION,
        "HAWA_AWS_CACHE_TABLE": "hawa-cache",
    }.items():
        monkeypatch.setenv(k, v)
    get_aws_settings.cache_clear()
    clients.reset_clients()
    with mock_aws():
        boto3.client("dynamodb", region_name=REGION).create_table(
            TableName="hawa-cache",
            KeySchema=[{"AttributeName": "pk", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "pk", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield
    get_aws_settings.cache_clear()
    clients.reset_clients()


def test_cache_roundtrip_and_expiry(aws):
    async def go():
        assert await cache_get("k") is None
        assert await cache_set("k", {"a": 1}, ttl_seconds=60)
        assert await cache_get("k") == {"a": 1}
        assert await cache_set("old", {"a": 2}, ttl_seconds=-1)
        assert await cache_get("old") is None

    asyncio.run(go())


def test_forecast_computed_once_then_cached(aws, monkeypatch):
    calls = []
    monkeypatch.setattr(aws_forecast, "_compute", lambda cell_id: calls.append(cell_id) or FORECAST)

    async def go():
        first = await get_aws_forecast("C-1")
        second = await get_aws_forecast("C-1")
        return first, second

    first, second = asyncio.run(go())
    assert first == second == FORECAST
    assert calls == ["C-1"]


def test_forecast_failure_or_bad_payload_returns_none(aws, monkeypatch):
    def boom(cell_id):
        raise RuntimeError("endpoint down")

    monkeypatch.setattr(aws_forecast, "_compute", boom)
    assert asyncio.run(get_aws_forecast("C-2")) is None
    monkeypatch.setattr(aws_forecast, "_compute", lambda c: {"no": "horizons"})
    assert asyncio.run(get_aws_forecast("C-3")) is None


def test_disabled_returns_none(monkeypatch):
    monkeypatch.setenv("HAWA_AWS_ENABLED", "false")
    get_aws_settings.cache_clear()
    assert asyncio.run(get_aws_forecast("C-1")) is None
    get_aws_settings.cache_clear()


def test_state_machine_and_endpoint_paths(aws, monkeypatch):
    monkeypatch.setenv("HAWA_AWS_FORECAST_STATE_MACHINE_ARN", "arn:sm")
    get_aws_settings.cache_clear()
    monkeypatch.setattr(aws_forecast, "_run_state_machine", lambda arn, c: {"via": arn, **FORECAST})
    assert aws_forecast._compute("C-1")["via"] == "arn:sm"
    monkeypatch.delenv("HAWA_AWS_FORECAST_STATE_MACHINE_ARN")
    monkeypatch.setenv("HAWA_AWS_FORECAST_ENDPOINT", "ep")
    get_aws_settings.cache_clear()
    monkeypatch.setattr(aws_forecast, "_invoke_endpoint", lambda ep, c: {"via": ep, **FORECAST})
    assert aws_forecast._compute("C-1")["via"] == "ep"


def test_publish_alert_and_sensor_reading(aws, monkeypatch):
    sns = boto3.client("sns", region_name=REGION)
    topic = sns.create_topic(Name="alerts")["TopicArn"]
    boto3.client("kinesis", region_name=REGION).create_stream(StreamName="sensors", ShardCount=1)
    monkeypatch.setenv("HAWA_AWS_ALERTS_TOPIC_ARN", topic)
    monkeypatch.setenv("HAWA_AWS_SENSOR_STREAM", "sensors")
    get_aws_settings.cache_clear()

    async def go():
        return (
            await publish_alert({"msg": "हवा खराब"}, grap_stage="3"),
            await publish_sensor_reading("pod-1", {"pm25": 120.0}),
        )

    message_id, seq = asyncio.run(go())
    assert message_id and seq


def test_publish_noop_when_unconfigured(aws):
    assert asyncio.run(publish_alert({"x": 1})) is None
    assert asyncio.run(publish_sensor_reading("pod", {})) is None


def test_route_uses_aws_when_enabled_and_falls_back_when_not(aws, monkeypatch):
    from hawa_backend.api.app import app

    monkeypatch.setattr(aws_forecast, "_compute", lambda cell_id: FORECAST)
    client = TestClient(app)
    on = client.get("/v1/forecast/C-9")
    assert on.status_code == 200 and len(on.json()["series"]) == 73
    assert on.json()["series"][1]["p50"] == 200.0

    monkeypatch.setenv("HAWA_AWS_ENABLED", "false")
    get_aws_settings.cache_clear()
    off = client.get("/v1/forecast/C-9")
    assert off.status_code == 200


def test_start_dispatch_runs_state_machine_and_noops_when_unconfigured(aws, monkeypatch):
    plan = {"id": "PLAN-1", "ward": "Ward-1", "approvedAt": "2026-10-03T10:00:00Z", "window": {}, "groups": []}
    assert asyncio.run(start_dispatch(plan)) is None

    sfn = boto3.client("stepfunctions", region_name=REGION)
    arn = sfn.create_state_machine(
        name="dispatch",
        definition=json.dumps({"StartAt": "Done", "States": {"Done": {"Type": "Succeed"}}}),
        roleArn="arn:aws:iam::123456789012:role/sfn",
    )["stateMachineArn"]
    monkeypatch.setenv("HAWA_AWS_DISPATCH_STATE_MACHINE_ARN", arn)
    get_aws_settings.cache_clear()
    execution = asyncio.run(start_dispatch(plan))
    assert execution and ":execution:dispatch:" in execution


def test_approve_plan_has_no_fake_execution_arn_without_aws():
    from hawa_backend.api.app import app

    client = TestClient(app)
    plan_id = client.post("/v1/plans/draft", json={"ward": "All wards"}).json()["id"]
    approved = client.post(f"/v1/plans/{plan_id}/approve", json={}).json()
    assert approved["status"] == "approved"
    assert "executionArn" not in approved
    assert client.get("/v1/plans/does-not-exist").status_code == 404
