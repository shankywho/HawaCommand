"""Small shared helpers: UTC timestamps, DynamoDB number conversion, distances."""
import json
import math
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Optional


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def iso(dt: datetime) -> str:
    """UTC ISO-8601 with millisecond precision and a Z suffix (sorts correctly as a string)."""
    dt = dt.astimezone(timezone.utc)
    return dt.strftime("%Y-%m-%dT%H:%M:%S.") + f"{dt.microsecond // 1000:03d}Z"


def parse_ts(value: Optional[Any]) -> datetime:
    """Datetime, epoch seconds/milliseconds or ISO string -> aware UTC datetime (now when missing)."""
    if value is None or value == "":
        return utcnow()
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, (int, float, Decimal)):
        seconds = float(value)
        if seconds > 1e12:
            seconds /= 1000.0
        return datetime.fromtimestamp(seconds, tz=timezone.utc)
    text = str(value).strip().replace("Z", "+00:00")
    dt = datetime.fromisoformat(text)
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def to_dynamo(item: dict) -> dict:
    """Floats -> Decimal and drop None values (boto3's DynamoDB resource rejects float)."""
    clean = {k: v for k, v in item.items() if v is not None}
    return json.loads(json.dumps(clean), parse_float=Decimal)


def from_dynamo(item: Any) -> Any:
    """Decimal -> int/float, recursively."""
    if isinstance(item, list):
        return [from_dynamo(v) for v in item]
    if isinstance(item, dict):
        return {k: from_dynamo(v) for k, v in item.items()}
    if isinstance(item, Decimal):
        return int(item) if item == item.to_integral_value() else float(item)
    return item


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def drop_none(d: dict) -> dict:
    return {k: v for k, v in d.items() if v is not None}
