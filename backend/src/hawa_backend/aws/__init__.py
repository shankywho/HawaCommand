"""Optional AWS integration: S3 evidence uploads, DynamoDB cache, Step Functions/SageMaker forecast and dispatch,
SNS alerts, Kinesis telemetry (producer here, consumer in kinesis_consumer.py), Secrets Manager (secrets.py).
The DynamoDB grievance and fleet stores live in ../services/."""
from .cache import cache_get, cache_set
from .dispatch import start_dispatch
from .events import publish_alert, publish_sensor_reading, subscribe_alerts
from .forecast import get_aws_forecast
from .settings import AwsSettings, get_aws_settings
from .uploads import presign_upload

__all__ = [
    "AwsSettings",
    "cache_get",
    "cache_set",
    "get_aws_forecast",
    "get_aws_settings",
    "publish_alert",
    "start_dispatch",
    "publish_sensor_reading",
    "presign_upload",
    "subscribe_alerts",
]
