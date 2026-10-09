# Phase 2: Core Runtime & Security

## Overview
Phase 2 implements the core infrastructure services required across the backend: strongly-typed Pydantic configuration, structured JSON logging with privacy PII masking, contextual asynchronous tracing (`request_id`, `correlation_id`), RFC 9457 Problem Details error handling, cryptographic hashing, and JWT security tokens.

## Artifacts & Components Created

1. **`hawa_backend.core.config`** (`src/hawa_backend/core/config.py`):
   - `Settings` class powered by `pydantic-settings` reading from environment variables with the `HAWA_` prefix.
   - Manages connection strings for PostgreSQL/PostGIS, Redis 7, Kafka KRaft brokers, JWT security parameters, and internal AI-ML service endpoints.
   - Cached configuration provider `get_settings()`.

2. **`hawa_backend.core.context`** (`src/hawa_backend/core/context.py`):
   - Thread-safe, coroutine-safe `RequestContext` via Python `contextvars`.
   - Propagates `request_id`, `correlation_id`, `causation_id`, `user_id`, `role`, and `is_simulated` through asynchronous call graphs.

3. **`hawa_backend.core.logging`** (`src/hawa_backend/core/logging.py`):
   - Structured `JSONFormatter` logging timestamped JSON lines.
   - Automatically enriches log lines with active `request_id` and `correlation_id`.
   - Built-in PII redaction: `mask_phone()` masks central digits of Indian phone numbers (`+9198765****10`) and `mask_token()` masks sensitive auth headers.

4. **`hawa_backend.core.errors`** (`src/hawa_backend/core/errors.py`):
   - Strict adherence to RFC 9457 (Problem Details for HTTP APIs).
   - Domain exception hierarchy:
     - `NotFoundError` (404)
     - `ConflictError` (409)
     - `ValidationError` (422)
     - `ForbiddenError` (403)
     - `UnauthorizedError` (401)
     - `RateLimitedError` (429)
     - `UpstreamServiceError` (503)

5. **`hawa_backend.core.security`** (`src/hawa_backend/core/security.py`):
   - PBKDF2-HMAC-SHA256 password hashing and constant-time verification.
   - JWT creation (`create_access_token()`) and decoding (`verify_access_token()`) carrying user ID, role, allowed wards, and expiration timestamps.
   - Development OTP validation (`dev_otp: 123456`).
   - Webhook HMAC SHA-256 signature verification (`verify_webhook_signature()`).

6. **`hawa_backend.core.clock`** (`src/hawa_backend/core/clock.py`):
   - UTC storage format with `Z` suffix.
   - IST (Asia/Kolkata, UTC + 5:30) presentation layer helpers (`to_ist_label()`).
   - `SystemClock` for production and `FrozenClock` for deterministic testing.

7. **`hawa_backend.cli`** (`src/hawa_backend/cli.py`):
   - Command-line interface with `version`, `config`, and `check` subcommands.

## Testing & Verification
All unit tests in `tests/core/test_core.py` and `contracts/tests/test_contracts.py` were executed:
```bash
PYTHONPATH=src:contracts .venv/bin/pytest tests/core contracts/tests
# 16 passed in 0.20s (100% pass)
```

Verified test cases include:
- Environment variable overrides and settings validation.
- Coroutine-isolated context binding and recovery.
- Sensitive phone number and authorization token masking.
- RFC 9457 ProblemDetail schema compliance.
- Password hashing, verification, and rejection of invalid passwords.
- JWT token issuing, verification, expiration rejection, and ward-scope claims decoding.
- Dev OTP verification and Webhook signature verification.
- Clock UTC-to-IST conversion (10:00 UTC = 15:30 IST).
