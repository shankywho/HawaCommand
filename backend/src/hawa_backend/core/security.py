"""Security, cryptographic hashing, and JWT token management."""
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from typing import List, Optional
import jwt
from pydantic import BaseModel, Field
from .config import get_settings
from .errors import UnauthorizedError
from hawa_contracts.enums import UserRole


class TokenPayload(BaseModel):
    """Payload decoded from a verified JWT token."""
    sub: str = Field(..., description="User ID")
    role: UserRole
    ward_ids: List[str] = Field(default_factory=list, description="Allowed ward IDs for scoping")
    exp: int
    iat: int


def hash_password(password: str, salt: Optional[str] = None) -> str:
    """Hash password using PBKDF2-HMAC-SHA256."""
    if not salt:
        salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        iterations=100_000,
    )
    return f"{salt}${key.hex()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against salt$hash string."""
    try:
        salt, key_hex = hashed_password.split("$", 1)
        expected_key = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            salt.encode("utf-8"),
            iterations=100_000,
        )
        return hmac.compare_digest(expected_key.hex(), key_hex)
    except Exception:
        return False


def create_access_token(
    user_id: str,
    role: UserRole,
    ward_ids: Optional[List[str]] = None,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Create a signed JWT access token."""
    settings = get_settings()
    now_utc = datetime.now(timezone.utc)
    if expires_delta:
        expire = now_utc + expires_delta
    else:
        expire = now_utc + timedelta(minutes=settings.jwt_expiry_minutes)

    payload = {
        "sub": user_id,
        "role": str(role.value),
        "ward_ids": ward_ids or [],
        "iat": int(now_utc.timestamp()),
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def verify_access_token(token: str) -> TokenPayload:
    """Verify and decode a JWT access token."""
    settings = get_settings()
    try:
        data = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        return TokenPayload(
            sub=data["sub"],
            role=UserRole(data["role"]),
            ward_ids=data.get("ward_ids", []),
            exp=data["exp"],
            iat=data["iat"],
        )
    except jwt.ExpiredSignatureError:
        raise UnauthorizedError("Token has expired")
    except jwt.InvalidTokenError:
        raise UnauthorizedError("Invalid token")


def verify_otp(phone: str, otp_code: str) -> bool:
    """Verify one-time passcode against dev static or dynamic store."""
    settings = get_settings()
    if settings.env in ("development", "test") and otp_code == settings.dev_otp:
        return True
    return False


def verify_webhook_signature(secret: str, raw_body: bytes, expected_signature: str) -> bool:
    """Verify HMAC SHA-256 signature for incoming webhooks."""
    mac = hmac.new(secret.encode("utf-8"), msg=raw_body, digestmod=hashlib.sha256)
    computed = f"sha256={mac.hexdigest()}"
    return hmac.compare_digest(computed, expected_signature)
