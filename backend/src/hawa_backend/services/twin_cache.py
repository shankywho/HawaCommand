"""Shared 500 m twin snapshot in Redis: key grid:pm25:500m:<YYYYMMDDHH UTC>, TTL 900 s.

The kriged twin (10,600 cells) takes seconds to fit. Each backend process keeps its own copy for 15 min
(core/intel_client.py); with Redis configured the first process to fit it stores it here and the others
load it instead of refitting. Sync, because the twin is built on a sync code path.
"""
import io
import logging
from datetime import datetime, timezone
from typing import Any, Optional

from ..core.redis_store import get_sync_redis, mark_failed

logger = logging.getLogger("hawa_backend.twin_cache")

KEY_PREFIX = "grid:pm25:500m:"
TTL_SECONDS = 900


def snapshot_key(now: Optional[datetime] = None) -> str:
    now = now or datetime.now(timezone.utc)
    return KEY_PREFIX + now.astimezone(timezone.utc).strftime("%Y%m%d%H")


def load_snapshot() -> Optional[Any]:
    """The current hour's twin DataFrame from Redis, or None."""
    r = get_sync_redis()
    if r is None:
        return None
    try:
        raw = r.get(snapshot_key())
    except Exception as exc:
        logger.warning("Redis twin snapshot read failed: %s", exc)
        mark_failed()
        return None
    if not raw:
        return None
    import pandas as pd

    try:
        return pd.read_json(io.StringIO(raw), orient="split", convert_dates=False)
    except Exception as exc:
        logger.warning("Redis twin snapshot is unreadable: %s", exc)
        return None


def save_snapshot(df: Any) -> bool:
    r = get_sync_redis()
    if r is None:
        return False
    try:
        r.set(snapshot_key(), df.to_json(orient="split", index=False), ex=TTL_SECONDS)
        return True
    except Exception as exc:
        logger.warning("Redis twin snapshot write failed: %s", exc)
        mark_failed()
        return False
