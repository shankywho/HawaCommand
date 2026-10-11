"""Who is calling: the bearer token's subject, and shared API keys for write endpoints without user auth.

The backend has no sign-in endpoints yet. A token signed with HAWA_JWT_SECRET is verified; any other
JWT (the Flutter app's in-app fake backend issues unsigned ones) is trusted for its `sub` claim only when
HAWA_TRUST_CLIENT_TOKENS is true. That is enough to keep each citizen's reports and push tokens apart,
not to stop a determined caller from impersonating one.
"""
import hmac
from typing import Optional

import jwt
from fastapi import Header, HTTPException, Request

from .config import get_settings

ANONYMOUS = "anonymous"


def caller_id(request: Request) -> str:
    """The `sub` of the bearer token, or "anonymous"."""
    auth = request.headers.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        return ANONYMOUS
    token = auth[7:].strip()
    settings = get_settings()
    try:
        claims = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        return str(claims.get("sub") or ANONYMOUS)
    except jwt.InvalidTokenError:
        pass
    if not settings.trust_client_tokens:
        return ANONYMOUS
    try:
        claims = jwt.decode(token, options={"verify_signature": False})
    except jwt.InvalidTokenError:
        return ANONYMOUS
    sub = claims.get("sub")
    return str(sub) if sub else ANONYMOUS


def _check(expected: Optional[str], given: Optional[str], name: str) -> None:
    if expected is None:
        return
    if not given or not hmac.compare_digest(expected, given):
        raise HTTPException(status_code=401, detail=f"Missing or wrong X-Api-Key ({name})")


def require_admin_key(x_api_key: Optional[str] = Header(None)) -> None:
    """Officer write endpoints: needs X-Api-Key = HAWA_ADMIN_API_KEY when that is set."""
    _check(get_settings().admin_api_key, x_api_key, "HAWA_ADMIN_API_KEY")


def require_ingest_key(x_api_key: Optional[str] = Header(None)) -> None:
    """Telemetry ingest: needs X-Api-Key = HAWA_INGEST_API_KEY (or the admin key) when set."""
    settings = get_settings()
    if settings.admin_api_key and x_api_key and hmac.compare_digest(settings.admin_api_key, x_api_key):
        return
    _check(settings.ingest_api_key, x_api_key, "HAWA_INGEST_API_KEY")
