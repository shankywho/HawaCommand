"""AWS integration settings (env prefix HAWA_AWS_). Everything is off unless `enabled`."""
from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict

from ..core.config import ENV_FILE


class AwsSettings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="HAWA_AWS_", env_file=ENV_FILE, extra="ignore")

    enabled: bool = False
    region: str = "ap-south-1"
    endpoint_url: Optional[str] = None

    forecast_state_machine_arn: Optional[str] = None
    forecast_endpoint: Optional[str] = None
    dispatch_state_machine_arn: Optional[str] = None

    cache_table: str = "hawa-cache"
    cache_ttl_seconds: int = 3600

    alerts_topic_arn: Optional[str] = None
    sensor_stream: Optional[str] = None


@lru_cache()
def get_aws_settings() -> AwsSettings:
    return AwsSettings()
