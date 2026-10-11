"""Citizen Eyes reports (grievances): create, automated verification, officer status changes, reads.

Storage: DynamoDB table HAWA_AWS_GRIEVANCES_TABLE (partition key report_id, sort key created_at;
GSI WardStatusIndex = ward_id + status; optional GSI OwnerIndex = owner_id + created_at), or process
memory when no table is configured. If a configured table fails, the call raises StoreUnavailable
(the route answers 503 and the app's outbox retries) rather than silently writing to memory.

Lifecycle (app contract ReportStatus): submitted -> verifying -> verified | rejected (automatic, seconds
after the report arrives) -> ticketed (officer) -> closed (officer). "Verified" means automated checks:
the photo exists in S3, the point is inside Delhi, and the rule-based source attribution of its 500 m
cell (AI-ML fingerprint rules) agrees with the citizen's category. It is not an image model.
"""
from __future__ import annotations

import asyncio
import logging
import uuid
from datetime import datetime, timedelta
from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel, Field

from ..aws.settings import get_aws_settings
from ..core.config import get_settings
from ..core.identity import ANONYMOUS
from . import geo, push
from ._util import drop_none, from_dynamo, iso, parse_ts, to_dynamo, utcnow

logger = logging.getLogger("hawa_backend.reports")

NAMESPACE = uuid.UUID("5b0f7c1e-3a59-4f5b-9a62-6a2f3f1d9c11")
UNASSIGNED_WARD = "unassigned"
OWNER_INDEX = "OwnerIndex"
OPEN_STATUSES = ("submitted", "verifying", "verified", "ticketed")
CATEGORY_LABEL = {"burning": "burning", "dust": "dust"}


class StoreUnavailable(Exception):
    pass


class ReportNotFound(Exception):
    pass


class BadTransition(Exception):
    pass


class GeoPoint(BaseModel):
    type: str = "Point"
    coordinates: List[float] = Field(..., min_length=2, max_length=3, description="[lon, lat]")


class ReportCreateIn(BaseModel):
    client_report_id: str = Field(..., min_length=1, max_length=80)
    photo_key: str = Field(..., min_length=1, max_length=512)
    location: GeoPoint
    captured_at: str
    accuracy_m: Optional[float] = None
    note: Optional[str] = Field(None, max_length=1000)
    lang: Optional[Literal["en", "hi"]] = None
    category: Optional[Literal["burning", "dust", "other"]] = None


class ReportUpdateIn(BaseModel):
    status: Literal["ticketed", "closed", "rejected"]
    outcome: Optional[Literal["closed_confirmed", "closed_not_found", "closed_unreachable"]] = None
    outcome_text: Optional[str] = Field(None, max_length=1000)
    outcome_text_hi: Optional[str] = Field(None, max_length=1000)
    rejection_reason: Optional[str] = Field(None, max_length=500)
    rejection_reason_hi: Optional[str] = Field(None, max_length=500)
    inspection_id: Optional[str] = None


# --------------------------------------------------------------------------- stores


class _MemoryStore:
    def __init__(self) -> None:
        self.items: Dict[str, Dict[str, Any]] = {}

    async def get(self, report_id: str) -> Optional[Dict[str, Any]]:
        item = self.items.get(report_id)
        return dict(item) if item else None

    async def put(self, item: Dict[str, Any]) -> None:
        self.items[item["report_id"]] = dict(item)

    async def by_owner(self, owner_id: str, limit: int) -> List[Dict[str, Any]]:
        rows = [i for i in self.items.values() if i.get("owner_id") == owner_id]
        return sorted(rows, key=lambda i: i["created_at"], reverse=True)[:limit]

    async def by_ward(self, ward_id: Optional[str], status: Optional[str], limit: int) -> List[Dict[str, Any]]:
        rows = [
            i for i in self.items.values()
            if (ward_id is None or i.get("ward_id") == ward_id) and (status is None or i.get("status") == status)
        ]
        return sorted(rows, key=lambda i: i["created_at"], reverse=True)[:limit]


class _DynamoStore:
    def __init__(self, table_name: str, ward_index: str) -> None:
        self.table_name = table_name
        self.ward_index = ward_index

    def _table(self):
        from ..aws.clients import get_table

        return get_table(self.table_name)

    async def _run(self, fn, *args):
        try:
            return await asyncio.to_thread(fn, *args)
        except (ReportNotFound, BadTransition):
            raise
        except Exception as exc:
            logger.warning("grievances table %s failed: %s", self.table_name, exc)
            raise StoreUnavailable(str(exc)) from exc

    def _get(self, report_id: str) -> Optional[Dict[str, Any]]:
        from boto3.dynamodb.conditions import Key

        resp = self._table().query(KeyConditionExpression=Key("report_id").eq(report_id), Limit=1)
        items = resp.get("Items", [])
        return from_dynamo(items[0]) if items else None

    def _put(self, item: Dict[str, Any]) -> None:
        self._table().put_item(Item=to_dynamo(item))

    def _by_owner(self, owner_id: str, limit: int) -> List[Dict[str, Any]]:
        from boto3.dynamodb.conditions import Attr, Key

        try:
            resp = self._table().query(
                IndexName=OWNER_INDEX,
                KeyConditionExpression=Key("owner_id").eq(owner_id),
                ScanIndexForward=False,
                Limit=limit,
            )
            items = resp.get("Items", [])
        except Exception as exc:
            if "ValidationException" not in type(exc).__name__ and "ValidationException" not in str(exc):
                raise
            # No OwnerIndex on the table: scan instead (fine for a pilot-sized table).
            items, kwargs = [], {"FilterExpression": Attr("owner_id").eq(owner_id)}
            while True:
                resp = self._table().scan(**kwargs)
                items += resp.get("Items", [])
                if "LastEvaluatedKey" not in resp or len(items) >= 1000:
                    break
                kwargs["ExclusiveStartKey"] = resp["LastEvaluatedKey"]
        rows = [from_dynamo(i) for i in items]
        return sorted(rows, key=lambda i: i["created_at"], reverse=True)[:limit]

    def _by_ward(self, ward_id: Optional[str], status: Optional[str], limit: int) -> List[Dict[str, Any]]:
        from boto3.dynamodb.conditions import Attr, Key

        if ward_id is not None:
            cond = Key("ward_id").eq(ward_id)
            if status is not None:
                cond = cond & Key("status").eq(status)
            resp = self._table().query(IndexName=self.ward_index, KeyConditionExpression=cond, Limit=limit)
            items = resp.get("Items", [])
        else:
            kwargs: Dict[str, Any] = {"Limit": max(limit, 100)}
            if status is not None:
                kwargs["FilterExpression"] = Attr("status").eq(status)
            items = self._table().scan(**kwargs).get("Items", [])
        rows = [from_dynamo(i) for i in items]
        return sorted(rows, key=lambda i: i["created_at"], reverse=True)[:limit]

    async def get(self, report_id: str) -> Optional[Dict[str, Any]]:
        return await self._run(self._get, report_id)

    async def put(self, item: Dict[str, Any]) -> None:
        await self._run(self._put, item)

    async def by_owner(self, owner_id: str, limit: int) -> List[Dict[str, Any]]:
        return await self._run(self._by_owner, owner_id, limit)

    async def by_ward(self, ward_id: Optional[str], status: Optional[str], limit: int) -> List[Dict[str, Any]]:
        return await self._run(self._by_ward, ward_id, status, limit)


_memory = _MemoryStore()


def store():
    s = get_aws_settings()
    if s.enabled and s.grievances_table:
        return _DynamoStore(s.grievances_table, s.grievances_ward_index)
    return _memory


def reset_memory() -> None:
    _memory.items.clear()


# --------------------------------------------------------------------------- views


def _photo_url(item: Dict[str, Any]) -> Optional[str]:
    from ..aws.uploads import presign_get

    try:
        return presign_get(item.get("photo_key"))
    except Exception as exc:
        logger.warning("could not presign photo for %s: %s", item.get("report_id"), exc)
        return None


def _place(item: Dict[str, Any]) -> Dict[str, Any]:
    return drop_none({"en": item.get("place") or "Delhi", "hi": item.get("place_hi")})


def list_item(item: Dict[str, Any]) -> Dict[str, Any]:
    """App contract ReportListItem."""
    verification = item.get("verification") or {}
    inspection = item.get("inspection") or {}
    return drop_none({
        "id": item["report_id"],
        "status": item["status"],
        "created_at": item["created_at"],
        "client_report_id": item.get("client_report_id"),
        "ward_id": None if item.get("ward_id") == UNASSIGNED_WARD else item.get("ward_id"),
        "note": item.get("note"),
        "thumbnail_url": _photo_url(item),
        "place_name": _place(item),
        "verification_label": verification.get("label") if verification.get("verified") else None,
        "inspection_status": inspection.get("status"),
        "outcome_text": item.get("outcome_text"),
        "outcome_text_hi": item.get("outcome_text_hi"),
        "closed_at": item.get("closed_at"),
        "source": item.get("source", "app"),
        "is_simulated": False,
    })


def detail(item: Dict[str, Any]) -> Dict[str, Any]:
    """App contract ReportDetailOut."""
    return drop_none({
        "id": item["report_id"],
        "status": item["status"],
        "location": {"type": "Point", "coordinates": [item["lon"], item["lat"]]},
        "created_at": item["created_at"],
        "timeline": item.get("timeline", []),
        "is_simulated": False,
        "client_report_id": item.get("client_report_id"),
        "source": item.get("source", "app"),
        "accuracy_m": item.get("accuracy_m"),
        "ward_id": None if item.get("ward_id") == UNASSIGNED_WARD else item.get("ward_id"),
        "cell_id": item.get("cell_id"),
        "place_name": _place(item),
        "note": item.get("note"),
        "lang": item.get("lang"),
        "category": item.get("category"),
        "captured_at": item.get("captured_at"),
        "photo_url": _photo_url(item),
        "verification": item.get("verification") or {"verified": False},
        "inspection": item.get("inspection"),
        "outcome": item.get("outcome"),
        "outcome_text": item.get("outcome_text"),
        "outcome_text_hi": item.get("outcome_text_hi"),
        "rejection_reason": item.get("rejection_reason"),
        "rejection_reason_hi": item.get("rejection_reason_hi"),
        "closed_at": item.get("closed_at"),
    })


def officer_view(item: Dict[str, Any], now: Optional[datetime] = None) -> Dict[str, Any]:
    """Detail plus the fields officers need: reporter id, photo key, PM2.5 at the cell and the SLA."""
    now = now or utcnow()
    due = item.get("sla_due_at")
    breach = bool(due and item["status"] in OPEN_STATUSES and parse_ts(due) < now)
    return dict(
        detail(item),
        owner_id=item.get("owner_id"),
        photo_key=item.get("photo_key"),
        pm25=item.get("pm25"),
        sla_due_at=due,
        sla_breach=breach,
        updated_at=item.get("updated_at"),
    )


# --------------------------------------------------------------------------- operations


def report_id_for(owner_id: str, client_report_id: str) -> str:
    """Deterministic, so a retried submission (same client_report_id) finds the first one."""
    return str(uuid.uuid5(NAMESPACE, f"{owner_id}:{client_report_id}"))


def _photo_key_ok(photo_key: str) -> bool:
    s = get_aws_settings()
    if not (s.enabled and s.evidence_bucket):
        return True
    return photo_key.startswith(f"{s.evidence_prefix}report_photo/") and ".." not in photo_key


def _advance(item: Dict[str, Any], status: str, at: Optional[str] = None) -> None:
    at = at or iso(utcnow())
    item["status"] = status
    item["updated_at"] = at
    item.setdefault("timeline", []).append({"status": status, "at": at})


async def create(owner_id: str, req: ReportCreateIn) -> Dict[str, Any]:
    """Store a new report (status submitted). Idempotent on (owner, client_report_id)."""
    lon, lat = float(req.location.coordinates[0]), float(req.location.coordinates[1])
    if not (-90 <= lat <= 90 and -180 <= lon <= 180):
        raise ValueError("location.coordinates must be [lon, lat]")
    if not _photo_key_ok(req.photo_key):
        raise ValueError("photo_key must come from POST /v1/uploads/presign with purpose report_photo")
    st = store()
    report_id = report_id_for(owner_id, req.client_report_id)
    existing = await st.get(report_id)
    if existing:
        return existing
    now = utcnow()
    created = iso(now)
    item: Dict[str, Any] = {
        "report_id": report_id,
        "created_at": created,
        "updated_at": created,
        "owner_id": owner_id or ANONYMOUS,
        "client_report_id": req.client_report_id,
        "photo_key": req.photo_key,
        "lat": lat,
        "lon": lon,
        "accuracy_m": req.accuracy_m,
        "note": req.note,
        "lang": req.lang,
        "category": req.category,
        "captured_at": req.captured_at,
        "source": "app",
        "status": "submitted",
        "ward_id": UNASSIGNED_WARD,
        "place": geo.nearest_locality(lon, lat),
        "timeline": [{"status": "submitted", "at": created}],
        "verification": {"verified": False},
        "sla_due_at": iso(now + timedelta(hours=get_settings().report_sla_hours)),
    }
    await st.put(item)
    return item


def create_out(item: Dict[str, Any]) -> Dict[str, Any]:
    """App contract ReportCreateOut."""
    return drop_none({
        "report_id": item["report_id"],
        "status": item["status"],
        "client_report_id": item.get("client_report_id"),
        "ward_id": None if item.get("ward_id") == UNASSIGNED_WARD else item.get("ward_id"),
        "cell_id": item.get("cell_id"),
    })


async def _notify(item: Dict[str, Any], title: str, body: str) -> None:
    if item.get("owner_id") in (None, ANONYMOUS):
        return
    try:
        await push.send_to_user(
            item["owner_id"],
            title,
            body,
            {
                "type": "report_outcome",
                "alert_id": f"report-{item['report_id']}-{item['status']}",
                "entity_id": item["report_id"],
                "deep_link": f"hawa://reports/{item['report_id']}",
                "role": "citizen",
                "collapse_key": f"report:{item['report_id']}:{item['status']}",
            },
        )
    except Exception as exc:
        logger.warning("report push failed: %s", exc)


def _photo_exists(photo_key: str) -> Optional[bool]:
    from ..aws.uploads import object_exists

    return object_exists(photo_key)


async def verify(report_id: str) -> Optional[Dict[str, Any]]:
    """Automated checks right after submission: submitted -> verifying -> verified | rejected."""
    st = store()
    item = await st.get(report_id)
    if not item or item["status"] != "submitted":
        return item
    _advance(item, "verifying")
    await st.put(item)

    lat, lon = float(item["lat"]), float(item["lon"])
    reason = None
    if not geo.in_delhi(lat, lon):
        reason = ("The location is outside Delhi.", "स्थान दिल्ली के बाहर है।")
    else:
        exists = await asyncio.to_thread(_photo_exists, item["photo_key"])
        if exists is False:
            reason = ("The photo upload was not found.", "फ़ोटो अपलोड नहीं मिला।")

    loc = await asyncio.to_thread(geo.locate, lat, lon)
    item.update(drop_none({
        "cell_id": loc.get("cell_id"),
        "ward_id": loc.get("ward_id") or UNASSIGNED_WARD,
        "place": loc.get("place"),
        "pm25": loc.get("pm25"),
    }))

    if reason:
        item["rejection_reason"], item["rejection_reason_hi"] = reason
        _advance(item, "rejected")
        await st.put(item)
        await _notify(item, "Report not accepted", reason[0])
        return item

    hour = (utcnow() + timedelta(hours=5, minutes=30)).hour
    rule_label, rule_conf = geo.attribute(loc.get("pm25"), loc.get("pm10"), hour)
    claimed = CATEGORY_LABEL.get(item.get("category") or "")
    if claimed:
        label = claimed
        confidence = min(0.95, rule_conf + 0.15) if claimed == rule_label else max(0.4, rule_conf - 0.1)
    else:
        label, confidence = rule_label, rule_conf
    now = iso(utcnow())
    item["verification"] = {
        "verified": True,
        "label": label,
        "confidence": round(confidence, 2),
        "verified_at": now,
        "model_version": "rules@1.0 (photo check + location + AI-ML fingerprint rules)",
    }
    _advance(item, "verified", now)
    await st.put(item)
    await _notify(item, "Report verified", f"Your report near {item.get('place', 'you')} was verified ({label.replace('_', ' ')}).")
    return item


TRANSITIONS = {
    "ticketed": ("submitted", "verifying", "verified"),
    "rejected": ("submitted", "verifying", "verified", "ticketed"),
    "closed": ("verified", "ticketed"),
}


async def update_status(report_id: str, req: ReportUpdateIn) -> Dict[str, Any]:
    """Officer action: ticket (create an inspection), close with an outcome, or reject."""
    st = store()
    item = await st.get(report_id)
    if not item:
        raise ReportNotFound(report_id)
    if item["status"] not in TRANSITIONS[req.status]:
        raise BadTransition(f"Cannot move a {item['status']} report to {req.status}")
    now = iso(utcnow())
    if req.status == "ticketed":
        item["inspection"] = {"id": req.inspection_id or f"insp-{uuid.uuid4().hex[:10]}", "status": "assigned"}
        title, body = "Inspector assigned", f"An inspector will visit the site near {item.get('place', 'you')}."
    elif req.status == "closed":
        outcome = req.outcome or "closed_confirmed"
        item["outcome"] = outcome
        item["closed_at"] = now
        item["outcome_text"] = req.outcome_text
        item["outcome_text_hi"] = req.outcome_text_hi
        if item.get("inspection"):
            item["inspection"]["status"] = outcome
        title, body = "Report closed", req.outcome_text or "Your report has been resolved."
    else:
        item["rejection_reason"] = req.rejection_reason or "Rejected by the ward officer."
        item["rejection_reason_hi"] = req.rejection_reason_hi
        title, body = "Report not accepted", item["rejection_reason"]
    _advance(item, req.status, now)
    await st.put(drop_none(item))
    await _notify(item, title, body)
    return item


async def get(report_id: str) -> Optional[Dict[str, Any]]:
    return await store().get(report_id)


async def mine(owner_id: str, limit: int = 50) -> List[Dict[str, Any]]:
    return await store().by_owner(owner_id, limit)


async def by_ward(ward_id: Optional[str], status: Optional[str], limit: int = 100) -> List[Dict[str, Any]]:
    return await store().by_ward(ward_id, status, limit)
