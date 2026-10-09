"""Unit tests for hawa_backend core runtime modules."""
import pytest
from datetime import datetime, timezone, timedelta
from hawa_backend.core.config import get_settings
from hawa_backend.core.context import bind_context, get_current_context
from hawa_backend.core.logging import mask_phone, mask_token
from hawa_backend.core.errors import (
    NotFoundError,
    ValidationError,
    ConflictError,
    UnauthorizedError,
)
from hawa_backend.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    verify_access_token,
    verify_otp,
    verify_webhook_signature,
)
from hawa_backend.core.clock import (
    SystemClock,
    FrozenClock,
    to_utc_iso,
    to_ist_label,
)
from hawa_contracts.enums import UserRole


def test_settings_load():
    settings = get_settings()
    assert settings.env in ("development", "staging", "production", "test")
    assert settings.jwt_secret is not None
    assert settings.dev_otp == "123456"


def test_request_context():
    ctx = bind_context(user_id="usr-123", role="officer", is_simulated=True)
    current = get_current_context()
    assert current.user_id == "usr-123"
    assert current.role == "officer"
    assert current.is_simulated is True
    assert current.request_id is not None
    assert current.correlation_id is not None


def test_pii_masking():
    # Test phone masking
    phone_msg = "Alert dispatched to +919876543210 for Ward 84"
    masked = mask_phone(phone_msg)
    assert "+919876543210" not in masked
    assert "****" in masked

    # Test token masking
    token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abcdef"
    masked_tok = mask_token(token)
    assert masked_tok.startswith("eyJh")
    assert masked_tok.endswith("cdef")


def test_problem_details():
    err = NotFoundError("Plan", "01927f3e-8c1a-7b4e-9f21-3c5d8a0e6b11")
    problem = err.to_problem(instance="/v1/plans/01927f3e-8c1a-7b4e-9f21-3c5d8a0e6b11")
    assert problem.status == 404
    assert problem.code == "not_found"
    assert "Plan" in problem.detail
    assert problem.instance == "/v1/plans/01927f3e-8c1a-7b4e-9f21-3c5d8a0e6b11"


def test_password_hashing():
    raw = "OfficerSecurePass2026!"
    hashed = hash_password(raw)
    assert hashed != raw
    assert "$" in hashed
    assert verify_password(raw, hashed) is True
    assert verify_password("WrongPassword", hashed) is False


def test_jwt_lifecycle():
    token = create_access_token(
        user_id="usr-officer-01",
        role=UserRole.OFFICER,
        ward_ids=["ward-084", "ward-085"],
    )
    decoded = verify_access_token(token)
    assert decoded.sub == "usr-officer-01"
    assert decoded.role == UserRole.OFFICER
    assert decoded.ward_ids == ["ward-084", "ward-085"]

    # Expired token test
    expired_token = create_access_token(
        user_id="usr-driver-02",
        role=UserRole.DRIVER,
        expires_delta=timedelta(seconds=-10),
    )
    with pytest.raises(UnauthorizedError):
        verify_access_token(expired_token)


def test_otp_and_webhook():
    assert verify_otp("+919876543210", "123456") is True
    assert verify_otp("+919876543210", "000000") is False

    secret = "test-webhook-secret"
    body = b'{"event": "spray.stopped"}'
    import hmac, hashlib
    expected_sig = "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    assert verify_webhook_signature(secret, body, expected_sig) is True
    assert verify_webhook_signature(secret, body, "sha256=invalid") is False


def test_clock_and_time():
    frozen_dt = datetime(2026, 11, 12, 10, 0, 0, tzinfo=timezone.utc)
    clock = FrozenClock(frozen_dt)
    assert clock.now_utc() == frozen_dt
    
    # 10:00 UTC is 15:30 IST
    ist_time = clock.now_ist()
    assert ist_time.hour == 15
    assert ist_time.minute == 30

    assert to_utc_iso(frozen_dt) == "2026-11-12T10:00:00Z"
    assert "15:30 IST" in to_ist_label(frozen_dt)
