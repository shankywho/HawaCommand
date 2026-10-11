"""Application configuration management with Pydantic Settings."""
import json
import logging
import os
from functools import lru_cache
from pathlib import Path
from typing import Optional
from pydantic import AliasChoices, Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# backend/ (this file is backend/src/hawa_backend/core/config.py). backend/.env is read whatever the working
# directory is; real environment variables take precedence over it.
BACKEND_DIR = Path(__file__).resolve().parents[3]
ENV_FILE = BACKEND_DIR / ".env"


class Settings(BaseSettings):
    """Canonical application settings loaded from the environment and backend/.env."""
    model_config = SettingsConfigDict(
        env_prefix="HAWA_",
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    env: str = Field("development", description="Environment: development | staging | production")
    debug: bool = Field(False, description="Debug mode")
    host: str = Field("0.0.0.0", description="API listen host")
    port: int = Field(8000, description="API listen port")

    # Database (PostgreSQL 16 + PostGIS)
    database_url: str = Field(
        "postgresql+asyncpg://hawa:hawa@localhost:5432/hawa",
        description="Async database connection string"
    )

    # Redis 6.2+ (ElastiCache / Valkey / local). Unset or empty keeps fleet positions, the twin snapshot,
    # plans, push tokens and broadcast alerts in process memory (core/redis_store.py).
    redis_url: Optional[str] = Field(None, description="redis:// or rediss:// (TLS) connection string")

    # Kafka
    kafka_bootstrap_servers: str = Field("localhost:9092", description="Kafka bootstrap brokers")
    kafka_security: str = Field("plaintext", description="plaintext | iam | scram")

    # Auth & JWT
    jwt_secret: str = Field("supersecret-dev-key-change-in-production-12345", description="JWT HMAC secret")
    jwt_algorithm: str = Field("HS256", description="JWT signing algorithm")
    jwt_expiry_minutes: int = Field(1440, description="JWT lifetime (24 hours)")
    dev_otp: str = Field("123456", description="Static OTP used for local and dev testing")
    # The backend has no sign-in yet; the app signs in against its in-app fake backend, whose tokens are
    # unsigned JWTs. When true, an unverified token's `sub` identifies the caller for "my reports" and push
    # tokens. Tokens signed with jwt_secret are always verified.
    trust_client_tokens: bool = Field(True, description="Accept the sub claim of unverified bearer tokens")
    # Shared keys for write endpoints that have no user auth. Unset leaves the endpoint open (dev only).
    admin_api_key: Optional[str] = Field(None, description="X-Api-Key for officer writes (broadcast, report status)")
    ingest_api_key: Optional[str] = Field(None, description="X-Api-Key for POST /v1/telemetry/vehicles")

    # Live fleet (services/fleet.py)
    fleet_active_minutes: int = Field(15, description="A vehicle with no ping for this long leaves the live fleet")
    # Citizen reports (services/reports.py)
    report_sla_hours: float = Field(3.0, description="Hours to close a report before it counts as an SLA breach")

    # Firebase Cloud Messaging (services/push.py). Credentials: a service-account JSON file, the JSON itself,
    # or the Secrets Manager secret HAWA_AWS_FCM_SECRET_ID. No credentials = push is skipped.
    fcm_service_account_file: Optional[str] = Field(None, description="Path to a Firebase service-account JSON")
    fcm_service_account_json: Optional[str] = Field(None, description="Firebase service-account JSON text")
    fcm_topic: str = Field("hawa-alerts", description="FCM topic every app install subscribes to")

    @field_validator(
        "redis_url", "admin_api_key", "ingest_api_key", "fcm_service_account_file", "fcm_service_account_json",
        mode="before",
    )
    @classmethod
    def _empty_is_none(cls, v):
        return None if isinstance(v, str) and not v.strip() else v

    # AI-ML Service
    aiml_service_url: str = Field("http://localhost:8100", description="Internal AI-ML FastAPI URL")
    aiml_timeout_seconds: float = Field(10.0, description="Timeout for synchronous AI-ML calls")

    # Live station feeds. Read without the HAWA_ prefix (WAQI_TOKEN, OPENAQ_API_KEY) from the environment or
    # backend/.env; the HAWA_-prefixed names also work. Unset or empty disables that source.
    waqi_token: Optional[str] = Field(
        None,
        validation_alias=AliasChoices("WAQI_TOKEN", "HAWA_WAQI_TOKEN"),
        description="WAQI API token for live Delhi stations",
    )
    openaq_api_key: Optional[str] = Field(
        None,
        validation_alias=AliasChoices("OPENAQ_API_KEY", "HAWA_OPENAQ_API_KEY"),
        description="OpenAQ v3 API key, used when WAQI returns fewer than 3 stations",
    )


logger = logging.getLogger("hawa_backend.config")
_secrets_loaded = False


def bootstrap_secrets() -> int:
    """Copy the keys of the JSON secret HAWA_AWS_SECRETS_ID (Secrets Manager) into os.environ, once.

    Precedence: exported environment variables > the secret > backend/.env. Runs before the first
    Settings() is built, so every HAWA_* variable (and WAQI_TOKEN, OPENAQ_API_KEY) can live in the secret.
    Returns the number of variables set; never raises.
    """
    global _secrets_loaded
    if _secrets_loaded:
        return 0
    _secrets_loaded = True
    from ..aws.settings import AwsSettings, get_aws_settings

    aws = AwsSettings()
    if not (aws.enabled and aws.secrets_id):
        return 0
    try:
        from ..aws.secrets import get_secret_json

        values = get_secret_json(aws.secrets_id)
    except Exception as exc:
        logger.warning("could not load secret %s: %s", aws.secrets_id, exc)
        return 0
    count = 0
    for key, value in values.items():
        if key not in os.environ and value is not None:
            os.environ[key] = value if isinstance(value, str) else json.dumps(value)
            count += 1
    get_aws_settings.cache_clear()
    get_settings.cache_clear()
    logger.info("loaded %d settings from Secrets Manager secret %s", count, aws.secrets_id)
    return count


@lru_cache()
def get_settings() -> Settings:
    """Return cached application settings singleton."""
    bootstrap_secrets()
    return Settings()
