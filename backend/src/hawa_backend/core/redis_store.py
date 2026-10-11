"""Optional Redis (ElastiCache for Redis/Valkey, or any Redis 6.2+).

HAWA_REDIS_URL unset or empty: callers keep their state in process memory. Set: fleet positions
(`geo:fleet:active`), the 500 m twin snapshot (`grid:pm25:500m:<hour>`), plans, push tokens and broadcast
alerts are shared by every backend process. `rediss://` enables TLS (ElastiCache in-transit encryption).

A failed connection is retried after RETRY_SECONDS; in between, callers get None and use memory.
"""
import logging
import time
from typing import Any, Optional

from .config import get_settings

logger = logging.getLogger("hawa_backend.redis")

RETRY_SECONDS = 30.0
CONNECT_TIMEOUT = 2.0


class _Slot:
    def __init__(self) -> None:
        self.client: Any = None
        self.url: Optional[str] = None
        self.failed_at = -RETRY_SECONDS


_async_slot = _Slot()
_sync_slot = _Slot()


def redis_url() -> Optional[str]:
    return get_settings().redis_url


def _kwargs() -> dict:
    return {
        "decode_responses": True,
        "socket_connect_timeout": CONNECT_TIMEOUT,
        "socket_timeout": CONNECT_TIMEOUT,
        "health_check_interval": 30,
    }


async def get_redis():
    """Async client (redis.asyncio), or None when Redis is not configured or unreachable."""
    url = redis_url()
    if not url:
        return None
    if _async_slot.client is not None and _async_slot.url == url:
        return _async_slot.client
    if time.monotonic() - _async_slot.failed_at < RETRY_SECONDS:
        return None
    import redis.asyncio as aioredis

    client = aioredis.from_url(url, **_kwargs())
    try:
        await client.ping()
    except Exception as exc:
        _async_slot.failed_at = time.monotonic()
        logger.warning("Redis %s unreachable, using process memory for %ss: %s", _redact(url), RETRY_SECONDS, exc)
        try:
            await client.aclose()
        except Exception:
            pass
        return None
    _async_slot.client, _async_slot.url = client, url
    logger.info("Connected to Redis %s", _redact(url))
    return client


def get_sync_redis():
    """Blocking client for sync code paths (the twin snapshot cache), or None."""
    url = redis_url()
    if not url:
        return None
    if _sync_slot.client is not None and _sync_slot.url == url:
        return _sync_slot.client
    if time.monotonic() - _sync_slot.failed_at < RETRY_SECONDS:
        return None
    import redis

    client = redis.Redis.from_url(url, **_kwargs())
    try:
        client.ping()
    except Exception as exc:
        _sync_slot.failed_at = time.monotonic()
        logger.warning("Redis %s unreachable (sync client): %s", _redact(url), exc)
        return None
    _sync_slot.client, _sync_slot.url = client, url
    return client


def mark_failed() -> None:
    """Drop the clients after a command error so the next call reconnects (after RETRY_SECONDS)."""
    for slot in (_async_slot, _sync_slot):
        slot.client = None
        slot.failed_at = time.monotonic()


def reset() -> None:
    for slot in (_async_slot, _sync_slot):
        slot.client, slot.url, slot.failed_at = None, None, -RETRY_SECONDS


def set_clients(async_client: Any = None, sync_client: Any = None, url: str = "redis://test") -> None:
    """Install ready-made clients (tests use fakeredis)."""
    _async_slot.client, _async_slot.url = async_client, url if async_client is not None else None
    _sync_slot.client, _sync_slot.url = sync_client, url if sync_client is not None else None


def _redact(url: str) -> str:
    """Hide the password in redis://user:password@host URLs."""
    if "@" not in url:
        return url
    scheme, rest = url.split("://", 1) if "://" in url else ("redis", url)
    return f"{scheme}://***@{rest.split('@', 1)[1]}"
