"""The caller's push token and alert area (app contract: PUT /v1/me/push-token, GET/PUT /v1/me/alert-subscription)."""
import hashlib
from typing import List, Literal, Optional

from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

from ...core.identity import caller_id
from ...services import alerts, push

router = APIRouter(prefix="/v1/me", tags=["Me"])

AlertKind = Literal[
    "pollutant_warning", "safe_window", "route_assignment", "inspection_target", "grap_outlook",
    "report_outcome", "device_health", "route_changed", "task_done_auto",
]


class PushTokenIn(BaseModel):
    token: str = Field(..., min_length=8, max_length=4096)
    platform: Literal["android", "ios", "web"]
    app_flavor: Optional[str] = None
    app_version: Optional[str] = None
    locale: Optional[str] = None
    device_label: Optional[str] = None


class LatLon(BaseModel):
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)


class LocalizedText(BaseModel):
    en: str
    hi: Optional[str] = None


class QuietHours(BaseModel):
    start: str
    end: str


class AlertSubscription(BaseModel):
    radius_m: int = Field(..., ge=100, le=50000)
    kinds: List[AlertKind]
    home: Optional[LatLon] = None
    place_name: Optional[LocalizedText] = None
    quiet_hours: Optional[QuietHours] = None


@router.put("/push-token")
async def put_push_token(req: PushTokenIn, request: Request):
    """Register this device's FCM token for the caller (report status pushes)."""
    meta = req.model_dump(exclude={"token", "platform"}, exclude_none=True)
    entry = await push.register_token(caller_id(request), req.token, req.platform, meta)
    return {
        "id": hashlib.sha256(req.token.encode()).hexdigest()[:16],
        "platform": req.platform,
        "last_seen_at": entry["last_seen_at"],
    }


@router.get("/alert-subscription")
async def get_alert_subscription(request: Request):
    return await alerts.get_subscription(caller_id(request))


@router.put("/alert-subscription")
async def put_alert_subscription(req: AlertSubscription, request: Request):
    return await alerts.put_subscription(caller_id(request), req.model_dump(exclude_none=True))
