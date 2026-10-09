"""Application configuration management with Pydantic Settings."""
from functools import lru_cache
from typing import Optional
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Canonical application settings loaded from environment and .env."""
    model_config = SettingsConfigDict(
        env_prefix="HAWA_",
        env_file=".env",
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


@lru_cache()
def get_settings() -> Settings:
    """Return cached application settings singleton."""
    return Settings()
