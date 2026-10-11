"""Firebase Cloud Messaging (HTTP v1 API) and the per-user push-token registry.

Credentials: a Firebase service-account JSON from HAWA_FCM_SERVICE_ACCOUNT_JSON, the file
HAWA_FCM_SERVICE_ACCOUNT_FILE, or the Secrets Manager secret HAWA_AWS_FCM_SECRET_ID (first one set wins).
Without credentials every send is skipped and returns None.

Broadcast alerts go to the topic HAWA_FCM_TOPIC, which every app install subscribes to. Report status
updates go to the reporter's own tokens, registered with PUT /v1/me/push-token and kept in Redis
(hash push:tokens:<user>) or process memory.
"""
from __future__ import annotations

import asyncio
import json
import logging
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx

from ..aws.settings import get_aws_settings
from ..core.config import get_settings
from ..core.redis_store import get_redis, mark_failed
from ._util import iso, utcnow

logger = logging.getLogger("hawa_backend.push")

SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token"
SEND_URL = "https://fcm.googleapis.com/v1/projects/{project}/messages:send"
TOKENS_PREFIX = "push:tokens:"


class _State:
    creds: Optional[Dict[str, Any]] = None
    creds_loaded = False
    access_token: Optional[str] = None
    expires_at = 0.0


_state = _State()
_memory_tokens: Dict[str, Dict[str, Dict[str, Any]]] = {}


def reset() -> None:
    _state.creds, _state.creds_loaded, _state.access_token, _state.expires_at = None, False, None, 0.0
    _memory_tokens.clear()


def _load_credentials() -> Optional[Dict[str, Any]]:
    s = get_settings()
    if s.fcm_service_account_json:
        return json.loads(s.fcm_service_account_json)
    if s.fcm_service_account_file:
        return json.loads(Path(s.fcm_service_account_file).expanduser().read_text(encoding="utf-8"))
    a = get_aws_settings()
    if a.enabled and a.fcm_secret_id:
        from ..aws.secrets import get_secret_json

        return get_secret_json(a.fcm_secret_id)
    return None


def credentials() -> Optional[Dict[str, Any]]:
    if not _state.creds_loaded:
        _state.creds_loaded = True
        try:
            creds = _load_credentials()
            if creds and not all(k in creds for k in ("project_id", "client_email", "private_key")):
                raise ValueError("service-account JSON needs project_id, client_email and private_key")
            _state.creds = creds
        except Exception as exc:
            logger.warning("FCM credentials could not be loaded, push disabled: %s", exc)
            _state.creds = None
    return _state.creds


def configured() -> bool:
    return credentials() is not None


def _fetch_access_token(creds: Dict[str, Any]) -> str:
    """OAuth 2.0 JWT-bearer grant with the service account (RS256 assertion)."""
    import jwt

    now = int(time.time())
    if _state.access_token and _state.expires_at - 60 > now:
        return _state.access_token
    token_uri = creds.get("token_uri") or DEFAULT_TOKEN_URI
    assertion = jwt.encode(
        {"iss": creds["client_email"], "scope": SCOPE, "aud": token_uri, "iat": now, "exp": now + 3600},
        creds["private_key"],
        algorithm="RS256",
        headers={"kid": creds.get("private_key_id")} if creds.get("private_key_id") else None,
    )
    resp = httpx.post(
        token_uri,
        data={"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion},
        timeout=10,
    )
    resp.raise_for_status()
    body = resp.json()
    _state.access_token = body["access_token"]
    _state.expires_at = now + int(body.get("expires_in", 3600))
    return _state.access_token


def _data(payload: Dict[str, Any]) -> Dict[str, str]:
    """FCM data values must be strings."""
    out = {}
    for k, v in payload.items():
        if v is None:
            continue
        out[k] = v if isinstance(v, str) else json.dumps(v, ensure_ascii=False)
    return out


async def send(message: Dict[str, Any]) -> Optional[str]:
    """Send one FCM v1 `message` object. Returns the message name, or None (not configured / failed).

    Raises nothing; an UNREGISTERED token is reported with the return value "unregistered".
    """
    creds = credentials()
    if creds is None:
        return None
    try:
        token = await asyncio.to_thread(_fetch_access_token, creds)
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                SEND_URL.format(project=creds["project_id"]),
                headers={"Authorization": f"Bearer {token}"},
                json={"message": message},
            )
    except Exception as exc:
        logger.warning("FCM send failed: %s", exc)
        return None
    if resp.status_code == 200:
        return resp.json().get("name")
    text = resp.text
    if resp.status_code in (400, 404) and ("UNREGISTERED" in text or "registration-token-not-registered" in text):
        return "unregistered"
    logger.warning("FCM send returned %s: %s", resp.status_code, text[:300])
    return None


def build_message(
    title: str, body: str, data: Dict[str, Any], *, topic: Optional[str] = None, token: Optional[str] = None,
) -> Dict[str, Any]:
    """Data-only message (app ARCHITECTURE §10.3): the app shows its own localized notification from the
    `title`/`body` data fields, in the foreground and from its background handler, so a `notification`
    block here would show twice. High priority so Android wakes the background handler."""
    payload = _data(dict(data, title=title, body=body, sent_at=data.get("sent_at") or iso(utcnow())))
    message: Dict[str, Any] = {"data": payload, "android": {"priority": "high"}}
    if topic:
        message["topic"] = topic
    if token:
        message["token"] = token
    return message


async def send_to_topic(title: str, body: str, data: Dict[str, Any], topic: Optional[str] = None) -> Optional[str]:
    return await send(build_message(title, body, data, topic=topic or get_settings().fcm_topic))


# --------------------------------------------------------------------------- token registry


async def register_token(user_id: str, token: str, platform: str, meta: Dict[str, Any]) -> Dict[str, Any]:
    entry = dict(meta, token=token, platform=platform, last_seen_at=iso(utcnow()))
    r = await get_redis()
    if r is not None:
        try:
            await r.hset(TOKENS_PREFIX + user_id, token, json.dumps(entry))
            await r.expire(TOKENS_PREFIX + user_id, 60 * 24 * 3600)
            return entry
        except Exception as exc:
            logger.warning("Redis push-token write failed: %s", exc)
            mark_failed()
    _memory_tokens.setdefault(user_id, {})[token] = entry
    return entry


async def tokens_for(user_id: str) -> List[str]:
    r = await get_redis()
    if r is not None:
        try:
            return list(await r.hkeys(TOKENS_PREFIX + user_id))
        except Exception as exc:
            logger.warning("Redis push-token read failed: %s", exc)
            mark_failed()
    return list(_memory_tokens.get(user_id, {}))


async def _forget(user_id: str, token: str) -> None:
    r = await get_redis()
    if r is not None:
        try:
            await r.hdel(TOKENS_PREFIX + user_id, token)
        except Exception:
            mark_failed()
    _memory_tokens.get(user_id, {}).pop(token, None)


async def send_to_user(user_id: str, title: str, body: str, data: Dict[str, Any]) -> int:
    """Push to every token the user registered; drops tokens FCM reports as unregistered. Returns sends."""
    if not configured():
        return 0
    sent = 0
    for token in await tokens_for(user_id):
        result = await send(build_message(title, body, data, token=token))
        if result == "unregistered":
            await _forget(user_id, token)
        elif result:
            sent += 1
    return sent
