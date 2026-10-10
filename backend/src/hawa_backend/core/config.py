"""Application configuration management with Pydantic Settings."""
from functools import lru_cache
from pathlib import Path
from typing import Optional
from pydantic import AliasChoices, Field
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

    # Redis 7
    redis_url: str = Field("redis://localhost:6379/0", description="Redis connection string")

    # Kafka
    kafka_bootstrap_servers: str = Field("localhost:9092", description="Kafka bootstrap brokers")
    kafka_security: str = Field("plaintext", description="plaintext | iam | scram")

    # Auth & JWT
    jwt_secret: str = Field("supersecret-dev-key-change-in-production-12345", description="JWT HMAC secret")
    jwt_algorithm: str = Field("HS256", description="JWT signing algorithm")
    jwt_expiry_minutes: int = Field(1440, description="JWT lifetime (24 hours)")
    dev_otp: str = Field("123456", description="Static OTP used for local and dev testing")

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


@lru_cache()
def get_settings() -> Settings:
    """Return cached application settings singleton."""
    return Settings()
