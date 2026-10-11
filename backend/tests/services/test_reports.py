"""Citizen reports: app-contract routes, automated verification, officer transitions, DynamoDB store."""
import boto3
import pytest
from fastapi.testclient import TestClient
from moto import mock_aws

from hawa_backend.aws import clients, get_aws_settings
from hawa_backend.core.config import get_settings
from hawa_backend.services import geo, push, reports

REGION = "ap-south-1"
TABLE = "hawa-citizen-grievances"


def _token(sub: str) -> str:
    import jwt

    return jwt.encode({"sub": sub, "role": "citizen"}, key="", algorithm="none")


def _body(client_id: str = "c-1", lon: float = 77.19, lat: float = 28.645, category: str = "burning") -> dict:
    return {
        "client_report_id": client_id,
        "photo_key": "report_photo/2026/10/11/abc.jpg",
        "location": {"type": "Point", "coordinates": [lon, lat]},
        "captured_at": "2026-10-11T05:00:00Z",
        "accuracy_m": 12.0,
        "note": "Garbage burning",
        "lang": "en",
        "category": category,
    }


@pytest.fixture(autouse=True)
def _stub_geo(monkeypatch):
    monkeypatch.setattr(
        geo, "locate",
        lambda lat, lon: {"place": "Karol Bagh", "cell_id": "C-41-77", "ward_id": "Ward-3", "pm25": 210.0, "pm10": 300.0},
    )
    monkeypatch.setattr(geo, "attribute", lambda pm25, pm10, hour: ("burning", 0.7))
    reports.reset_memory()
    push.reset()
    yield
    reports.reset_memory()


@pytest.fixture
def client():
    from hawa_backend.api.app import app

    return TestClient(app)


def test_create_verify_and_read_back(client):
    alice = {"Authorization": f"Bearer {_token('alice')}"}
    r = client.post("/v1/reports", json=_body(), headers=alice)
    assert r.status_code == 202
    out = r.json()
    assert out["status"] == "submitted" and out["client_report_id"] == "c-1"

    # Background verification already ran inside the TestClient call
    detail = client.get(f"/v1/reports/{out['report_id']}", headers=alice).json()
    assert detail["status"] == "verified"
    assert [t["status"] for t in detail["timeline"]] == ["submitted", "verifying", "verified"]
    assert detail["verification"]["label"] == "burning" and detail["verification"]["confidence"] == 0.85
    assert detail["ward_id"] == "Ward-3" and detail["cell_id"] == "C-41-77"
    assert detail["location"] == {"type": "Point", "coordinates": [77.19, 28.645]}
    assert detail["is_simulated"] is False

    mine = client.get("/v1/reports/mine", headers=alice).json()
    assert [i["id"] for i in mine["items"]] == [out["report_id"]]
    assert mine["items"][0]["verification_label"] == "burning"
    assert mine["items"][0]["place_name"] == {"en": "Karol Bagh"}

    # Another citizen sees neither the list nor the detail
    bob = {"Authorization": f"Bearer {_token('bob')}"}
    assert client.get("/v1/reports/mine", headers=bob).json()["items"] == []
    assert client.get(f"/v1/reports/{out['report_id']}", headers=bob).status_code == 404


def test_retry_with_same_client_id_is_idempotent(client):
    h = {"Authorization": f"Bearer {_token('alice')}"}
    first = client.post("/v1/reports", json=_body("dup"), headers=h).json()
    second = client.post("/v1/reports", json=_body("dup"), headers=h).json()
    assert first["report_id"] == second["report_id"]
    assert len(client.get("/v1/reports/mine", headers=h).json()["items"]) == 1


def test_outside_delhi_is_rejected(client):
    h = {"Authorization": f"Bearer {_token('alice')}"}
    rid = client.post("/v1/reports", json=_body("far", lon=72.87, lat=19.07), headers=h).json()["report_id"]
    detail = client.get(f"/v1/reports/{rid}", headers=h).json()
    assert detail["status"] == "rejected" and "outside Delhi" in detail["rejection_reason"]


def test_officer_flow_needs_admin_key(client, monkeypatch):
    monkeypatch.setenv("HAWA_ADMIN_API_KEY", "officer-key")
    get_settings.cache_clear()
    h = {"Authorization": f"Bearer {_token('alice')}"}
    rid = client.post("/v1/reports", json=_body("o-1"), headers=h).json()["report_id"]

    assert client.get("/v1/reports").status_code == 401
    assert client.patch(f"/v1/reports/{rid}", json={"status": "ticketed"}).status_code == 401

    admin = {"X-Api-Key": "officer-key"}
    listed = client.get("/v1/reports", params={"ward_id": "Ward-3", "status": "verified"}, headers=admin).json()
    assert listed["count"] == 1 and listed["items"][0]["owner_id"] == "alice"
    assert listed["items"][0]["sla_breach"] is False

    ticketed = client.patch(f"/v1/reports/{rid}", json={"status": "ticketed"}, headers=admin).json()
    assert ticketed["status"] == "ticketed" and ticketed["inspection"]["status"] == "assigned"
    closed = client.patch(
        f"/v1/reports/{rid}",
        json={"status": "closed", "outcome": "closed_confirmed", "outcome_text": "Fire put out, fine issued"},
        headers=admin,
    ).json()
    assert closed["status"] == "closed" and closed["inspection"]["status"] == "closed_confirmed"
    assert client.patch(f"/v1/reports/{rid}", json={"status": "ticketed"}, headers=admin).status_code == 409

    item = client.get("/v1/reports/mine", headers=h).json()["items"][0]
    assert item["status"] == "closed" and item["outcome_text"] == "Fire put out, fine issued"


def test_report_status_push_goes_to_the_reporter(client, monkeypatch):
    sent = []

    async def fake_send(user_id, title, body, data):
        sent.append((user_id, title, data["deep_link"]))
        return 1

    monkeypatch.setattr(push, "send_to_user", fake_send)
    h = {"Authorization": f"Bearer {_token('alice')}"}
    rid = client.post("/v1/reports", json=_body("p-1"), headers=h).json()["report_id"]
    assert sent == [("alice", "Report verified", f"hawa://reports/{rid}")]


@pytest.fixture
def dynamo(monkeypatch):
    for k, v in {
        "AWS_ACCESS_KEY_ID": "test",
        "AWS_SECRET_ACCESS_KEY": "test",
        "HAWA_AWS_ENABLED": "true",
        "HAWA_AWS_REGION": REGION,
        "HAWA_AWS_GRIEVANCES_TABLE": TABLE,
    }.items():
        monkeypatch.setenv(k, v)
    get_aws_settings.cache_clear()
    clients.reset_clients()
    with mock_aws():
        boto3.client("dynamodb", region_name=REGION).create_table(
            TableName=TABLE,
            BillingMode="PAY_PER_REQUEST",
            AttributeDefinitions=[
                {"AttributeName": n, "AttributeType": "S"}
                for n in ("report_id", "created_at", "ward_id", "status", "owner_id")
            ],
            KeySchema=[
                {"AttributeName": "report_id", "KeyType": "HASH"},
                {"AttributeName": "created_at", "KeyType": "RANGE"},
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "WardStatusIndex",
                    "KeySchema": [
                        {"AttributeName": "ward_id", "KeyType": "HASH"},
                        {"AttributeName": "status", "KeyType": "RANGE"},
                    ],
                    "Projection": {"ProjectionType": "ALL"},
                },
                {
                    "IndexName": "OwnerIndex",
                    "KeySchema": [
                        {"AttributeName": "owner_id", "KeyType": "HASH"},
                        {"AttributeName": "created_at", "KeyType": "RANGE"},
                    ],
                    "Projection": {"ProjectionType": "ALL"},
                },
            ],
        )
        yield
    get_aws_settings.cache_clear()
    clients.reset_clients()


def test_dynamodb_store_roundtrip(client, dynamo):
    h = {"Authorization": f"Bearer {_token('alice')}"}
    rid = client.post("/v1/reports", json=_body("d-1"), headers=h).json()["report_id"]

    raw = boto3.resource("dynamodb", region_name=REGION).Table(TABLE).scan()["Items"]
    assert len(raw) == 1 and raw[0]["status"] == "verified" and raw[0]["ward_id"] == "Ward-3"
    assert client.get("/v1/reports/mine", headers=h).json()["items"][0]["id"] == rid

    listed = client.get("/v1/reports", params={"ward_id": "Ward-3", "status": "verified"}).json()
    assert listed["count"] == 1
    assert client.get("/v1/reports", params={"ward_id": "Ward-9"}).json()["count"] == 0


def test_store_failure_is_503_not_silent(client, dynamo, monkeypatch):
    monkeypatch.setenv("HAWA_AWS_GRIEVANCES_TABLE", "missing-table")
    get_aws_settings.cache_clear()
    h = {"Authorization": f"Bearer {_token('alice')}"}
    assert client.post("/v1/reports", json=_body("x"), headers=h).status_code == 503
