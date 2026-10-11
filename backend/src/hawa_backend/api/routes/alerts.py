"""Multi-channel school, citizen, and worker alerts: the sent-alert log, officer broadcasts (SNS email/SMS
+ FCM push) and SNS subscriptions."""
from datetime import datetime, timezone
from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from ...aws.events import subscribe_alerts
from ...core.identity import require_admin_key
from ...services import alerts as alert_service
from ..fixtures import get_mock_alerts

router = APIRouter(prefix="/v1/alerts", tags=["Alerts"])


@router.get("")
async def list_alerts():
    """Broadcasts sent through this backend (newest first), then the demo fixtures."""
    base = get_mock_alerts()
    sent = await alert_service.sent_alerts()
    items = sent + base["items"]

    def count(audience: str) -> int:
        return sum(1 for i in items if i.get("audience") == audience)

    return {
        "asOf": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "simulated": not sent,
        "counts": {
            "All": len(items),
            "School": count("School"),
            "Citizens": count("Citizens"),
            "Citizen Eyes": count("Citizen Eyes"),
        },
        "items": items,
    }


@router.post("/broadcast", dependencies=[Depends(require_admin_key)])
async def broadcast_alert(req: alert_service.BroadcastIn):
    """Publish an alert to the SNS topic (email/SMS subscribers, filtered by ward) and the FCM topic
    (every app install). Each channel is skipped when it is not configured; see `delivered`."""
    return await alert_service.broadcast(req)


class SubscriberIn(BaseModel):
    protocol: Literal["email", "sms"]
    endpoint: str = Field(..., description="Email address, or phone number in E.164 (+91...)")
    ward: Optional[str] = Field(None, description="Only this ward's alerts (plus city-wide ones); omit for all")


@router.post("/subscribers", dependencies=[Depends(require_admin_key)])
async def add_subscriber(req: SubscriberIn):
    """Subscribe an email address or phone number to the alerts topic. Email subscribers must click the
    confirmation link AWS sends before they receive anything."""
    if req.protocol == "sms" and not req.endpoint.startswith("+"):
        raise HTTPException(status_code=422, detail="Phone numbers must be E.164, e.g. +919812345678")
    try:
        arn = await subscribe_alerts(req.protocol, req.endpoint, req.ward)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"SNS subscribe failed: {exc}")
    if arn is None:
        raise HTTPException(
            status_code=503,
            detail="Alerts are not configured: set HAWA_AWS_ENABLED=true and HAWA_AWS_ALERTS_TOPIC_ARN",
        )
    return {"subscriptionArn": arn, "pendingConfirmation": req.protocol == "email"}


@router.get("/{alert_id}")
async def get_alert(alert_id: str):
    for item in await alert_service.sent_alerts() + get_mock_alerts()["items"]:
        if item["id"] == alert_id:
            return item
    raise HTTPException(status_code=404, detail=f"Alert '{alert_id}' not found")
