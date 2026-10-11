"""Alert broadcasts: SNS (email/SMS subscribers) and the FCM topic (app installs), plus the sent-alert log
behind GET /v1/alerts and the citizens' alert-area settings.

Sent alerts are kept in Redis (list alerts:sent, newest first, last 200) or process memory.
"""
from __future__ import annotations

import json
import logging
import uuid
from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel, Field

from ..aws.events import publish_alert
from ..core.redis_store import get_redis, mark_failed
from . import push
from ._util import iso, utcnow

logger = logging.getLogger("hawa_backend.alerts")

SENT_KEY = "alerts:sent"
SUBSCRIPTION_PREFIX = "alerts:subscription:"
MAX_SENT = 200

# Broadcast type -> app AlertKind (push payload `type`)
APP_KIND = {
    "INVERSION_WARNING": "pollutant_warning",
    "POLLUTANT_WARNING": "pollutant_warning",
    "GRAP_STAGE": "grap_outlook",
    "GRAP_OUTLOOK": "grap_outlook",
    "SAFE_WINDOW": "safe_window",
    "PLAN_APPROVED": "route_assignment",
}

DEFAULT_SUBSCRIPTION: Dict[str, Any] = {
    "radius_m": 1000,
    "kinds": ["pollutant_warning", "grap_outlook", "safe_window", "report_outcome"],
}

_memory_sent: List[Dict[str, Any]] = []
_memory_subscriptions: Dict[str, Dict[str, Any]] = {}


def reset() -> None:
    _memory_sent.clear()
    _memory_subscriptions.clear()


class BroadcastIn(BaseModel):
    type: str = Field("POLLUTANT_WARNING", description="INVERSION_WARNING | POLLUTANT_WARNING | GRAP_STAGE | SAFE_WINDOW")
    message: str = Field(..., min_length=3, max_length=1000)
    message_hi: Optional[str] = Field(None, max_length=1000)
    title: Optional[str] = Field(None, max_length=120)
    ward: Optional[str] = Field(None, description="Ward name; omit for all of Delhi")
    window: Optional[str] = Field(None, description="e.g. 06:00 - 09:30 AM")
    expected_pm25: Optional[float] = None
    audience: Literal["Citizens", "School", "Workers", "Drivers"] = "Citizens"
    severity: Literal["info", "warning", "severe"] = "warning"
    channels: List[Literal["sns", "push"]] = Field(default_factory=lambda: ["sns", "push"])


async def _remember(record: Dict[str, Any]) -> None:
    r = await get_redis()
    if r is not None:
        try:
            await r.lpush(SENT_KEY, json.dumps(record, ensure_ascii=False))
            await r.ltrim(SENT_KEY, 0, MAX_SENT - 1)
            return
        except Exception as exc:
            logger.warning("Redis alert log write failed: %s", exc)
            mark_failed()
    _memory_sent.insert(0, record)
    del _memory_sent[MAX_SENT:]


async def sent_alerts() -> List[Dict[str, Any]]:
    r = await get_redis()
    if r is not None:
        try:
            return [json.loads(v) for v in await r.lrange(SENT_KEY, 0, MAX_SENT - 1)]
        except Exception as exc:
            logger.warning("Redis alert log read failed: %s", exc)
            mark_failed()
    return list(_memory_sent)


async def broadcast(req: BroadcastIn, drafted_by: str = "Officer") -> Dict[str, Any]:
    """Publish to SNS and/or the FCM topic; returns the web-console Alert record plus delivery ids."""
    now = utcnow()
    alert_id = f"alt-{uuid.uuid4().hex[:12]}"
    ward = req.ward or "all"
    title = req.title or {
        "INVERSION_WARNING": "Inversion warning",
        "GRAP_STAGE": "GRAP stage update",
        "SAFE_WINDOW": "Safe outdoor window",
        "PLAN_APPROVED": "Dispatch plan approved",
    }.get(req.type.upper(), "Air quality alert")
    if req.ward:
        title = f"{title}: {req.ward}"

    sns_id = None
    if "sns" in req.channels:
        sns_id = await publish_alert(
            {
                "alert_id": alert_id,
                "type": req.type,
                "ward": req.ward,
                "window": req.window,
                "expected_pm25": req.expected_pm25,
                "title": title,
                "message": req.message,
                "message_hi": req.message_hi,
                "sent_at": iso(now),
            },
            type=req.type,
            ward=ward,
            severity=req.severity,
            audience=req.audience,
        )

    push_id = None
    if "push" in req.channels:
        push_id = await push.send_to_topic(
            title,
            req.message,
            {
                "type": APP_KIND.get(req.type.upper(), "pollutant_warning"),
                "alert_id": alert_id,
                "deep_link": f"hawa://alerts/{alert_id}",
                "lang": "en",
                "args": {"ward": req.ward, "window": req.window, "expected_pm25": req.expected_pm25,
                         "message_hi": req.message_hi},
                "collapse_key": alert_id,
            },
        )

    delivered = []
    if "sns" in req.channels:
        delivered.append("SNS sent" if sns_id else "SNS not configured")
    if "push" in req.channels:
        delivered.append("Push sent" if push_id else "Push not configured")
    record: Dict[str, Any] = {
        "id": alert_id,
        "sentAt": iso(now),
        "audience": req.audience,
        "target": req.ward or "All of Delhi",
        "channel": "SMS",
        "lang": "hi+en" if req.message_hi else "en",
        "message": req.message,
        "delivered": " · ".join(delivered) or "Recorded",
        "leadTimeH": None,
        "draftedBy": drafted_by,
        "type": req.type,
        "severity": req.severity,
    }
    if req.message_hi:
        record["messageHi"] = req.message_hi
    await _remember(record)
    return dict(record, snsMessageId=sns_id, fcmMessageName=push_id)


async def alert_on_plan_approval(plan: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """SNS notice (officers/drivers) when a plan is approved; not pushed to citizens."""
    tasks = sum(len(g.get("tasks", [])) for g in plan.get("groups", []))
    window = (plan.get("window") or {}).get("label")
    req = BroadcastIn(
        type="PLAN_APPROVED",
        message=f"Plan {plan['id']} approved for {plan.get('ward', 'Delhi')}: {tasks} tasks"
        + (f", window {window}" if window else "")
        + ".",
        ward=plan.get("ward"),
        window=window,
        audience="Drivers",
        severity="info",
        channels=["sns"],
    )
    try:
        return await broadcast(req, drafted_by="Plan approval")
    except Exception as exc:
        logger.warning("plan approval alert failed: %s", exc)
        return None


# --------------------------------------------------------------------------- citizen alert area


async def get_subscription(user_id: str) -> Dict[str, Any]:
    r = await get_redis()
    if r is not None:
        try:
            raw = await r.get(SUBSCRIPTION_PREFIX + user_id)
            if raw:
                return json.loads(raw)
            return dict(DEFAULT_SUBSCRIPTION)
        except Exception as exc:
            logger.warning("Redis subscription read failed: %s", exc)
            mark_failed()
    return dict(_memory_subscriptions.get(user_id, DEFAULT_SUBSCRIPTION))


async def put_subscription(user_id: str, sub: Dict[str, Any]) -> Dict[str, Any]:
    r = await get_redis()
    if r is not None:
        try:
            await r.set(SUBSCRIPTION_PREFIX + user_id, json.dumps(sub, ensure_ascii=False))
            return sub
        except Exception as exc:
            logger.warning("Redis subscription write failed: %s", exc)
            mark_failed()
    _memory_subscriptions[user_id] = sub
    return sub
