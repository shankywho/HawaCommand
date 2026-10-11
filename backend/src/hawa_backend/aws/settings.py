"""AWS integration settings (env prefix HAWA_AWS_). Everything is off unless `enabled`; each service is
also off until its own name/ARN is set, so you can turn them on one at a time."""
from functools import lru_cache
from typing import Optional

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

from ..core.config import ENV_FILE


class AwsSettings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="HAWA_AWS_", env_file=ENV_FILE, extra="ignore")

    enabled: bool = False
    region: str = "ap-south-1"
    endpoint_url: Optional[str] = None

    # Secrets Manager: a JSON secret whose keys are env var names (core/config.py bootstrap_secrets)
    secrets_id: Optional[str] = None

    forecast_state_machine_arn: Optional[str] = None
    forecast_endpoint: Optional[str] = None
    dispatch_state_machine_arn: Optional[str] = None

    cache_table: str = "hawa-cache"
    cache_ttl_seconds: int = 3600

    # SNS topic for alert broadcasts (email/SMS subscribers), aws/events.py
    alerts_topic_arn: Optional[str] = None
    # Publish an alert when an officer approves a plan. Turn off if your dispatch state machine publishes too.
    alert_on_plan_approval: bool = True

    # Kinesis stream for vehicle/sensor telemetry (aws/events.py producer, aws/kinesis_consumer.py consumer)
    sensor_stream: Optional[str] = None
    # Run the Kinesis consumer inside the API process (otherwise run `hawa consume-telemetry` separately)
    kinesis_consumer: bool = False
    # Where a consumer with no checkpoint starts: LATEST or TRIM_HORIZON
    kinesis_start: str = "LATEST"

    # IoT Core data endpoint (Data-ATS), used by `hawa simulate-fleet --target iot`
    iot_endpoint: Optional[str] = None

    # DynamoDB: citizen grievances (services/reports.py) and fleet telemetry (services/fleet.py)
    grievances_table: Optional[str] = None
    grievances_ward_index: str = "WardStatusIndex"
    fleet_table: Optional[str] = None
    fleet_ttl_days: int = 7

    # Secrets Manager secret holding the Firebase service-account JSON (services/push.py)
    fcm_secret_id: Optional[str] = None

    # Evidence photo uploads (pre-signed S3 POST, api/routes/uploads.py)
    evidence_bucket: Optional[str] = None
    evidence_prefix: str = ""
    upload_max_bytes: int = 5 * 1024 * 1024
    presign_ttl_seconds: int = 900
    # Lifetime of the pre-signed GET URLs returned for report photos
    evidence_read_ttl_seconds: int = 3600

    @field_validator(
        "endpoint_url", "secrets_id", "forecast_state_machine_arn", "forecast_endpoint",
        "dispatch_state_machine_arn", "alerts_topic_arn", "sensor_stream", "iot_endpoint",
        "grievances_table", "fleet_table", "fcm_secret_id", "evidence_bucket",
        mode="before",
    )
    @classmethod
    def _empty_is_none(cls, v):
        return None if isinstance(v, str) and not v.strip() else v


@lru_cache()
def get_aws_settings() -> AwsSettings:
    return AwsSettings()
