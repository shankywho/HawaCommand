"""Alert and notification lifecycle events."""
from typing import List, Optional
from pydantic import BaseModel
from . import register_event
from ..enums import Audience, Channel, Lang


@register_event("alert.requested", "1.0.0")
class AlertRequested(BaseModel):
    alert_id: str
    audience: Audience
    channels: List[Channel]
    title: str
    body_en: str
    body_hi: str
    recipient_phone_e164: Optional[str] = None
    fcm_token: Optional[str] = None
    safe_window: Optional[str] = None
    is_simulated: bool = False


@register_event("alert.delivered", "1.0.0")
class AlertDelivered(BaseModel):
    alert_id: str
    channel: Channel
    delivered_at: str
