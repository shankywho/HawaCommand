"""DynamoDB-backed JSON cache. Expiry is checked on read because DynamoDB TTL deletion is lazy."""
import asyncio
import json
import logging
import time
from typing import Any, Optional

from .clients import get_cache_table
from .settings import get_aws_settings

logger = logging.getLogger("hawa_backend.aws.cache")


def _get(key: str) -> Optional[Any]:
    item = get_cache_table().get_item(Key={"pk": key}).get("Item")
    if not item or int(item["ttl"]) <= time.time():
        return None
    return json.loads(item["value"])


def _set(key: str, value: Any, ttl_seconds: int) -> None:
    get_cache_table().put_item(
        Item={"pk": key, "value": json.dumps(value), "ttl": int(time.time()) + ttl_seconds}
    )


async def cache_get(key: str) -> Optional[Any]:
    try:
        return await asyncio.to_thread(_get, key)
    except Exception as exc:
        logger.warning("cache read failed for %s: %s", key, exc)
        return None


async def cache_set(key: str, value: Any, ttl_seconds: Optional[int] = None) -> bool:
    try:
        await asyncio.to_thread(_set, key, value, ttl_seconds or get_aws_settings().cache_ttl_seconds)
        return True
    except Exception as exc:
        logger.warning("cache write failed for %s: %s", key, exc)
        return False
