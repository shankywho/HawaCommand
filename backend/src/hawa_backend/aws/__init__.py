"""Optional AWS integration (DynamoDB cache, Step Functions/SageMaker forecast, SNS, Kinesis)."""
from .cache import cache_get, cache_set
from .dispatch import start_dispatch
from .events import publish_alert, publish_sensor_reading
from .forecast import get_aws_forecast
from .settings import AwsSettings, get_aws_settings

__all__ = [
    "AwsSettings",
    "cache_get",
    "cache_set",
    "get_aws_forecast",
    "get_aws_settings",
    "publish_alert",
    "start_dispatch",
    "publish_sensor_reading",
]
