"""Fire-and-forget event publishing: SNS alerts and Kinesis sensor readings."""
import asyncio
import json
import logging
from typing import Any, Dict, Optional

from .clients import get_client
from .settings import get_aws_settings

logger = logging.getLogger("hawa_backend.aws.events")


def _publish(topic_arn: str, message: Dict[str, Any], attributes: Dict[str, str]) -> str:
    resp = get_client("sns").publish(
        TopicArn=topic_arn,
        Message=json.dumps(message, ensure_ascii=False),
        MessageAttributes={k: {"DataType": "String", "StringValue": str(v)} for k, v in attributes.items()},
    )
    return resp["MessageId"]


def _put_record(stream: str, partition_key: str, payload: Dict[str, Any]) -> str:
    resp = get_client("kinesis").put_record(
        StreamName=stream, PartitionKey=partition_key, Data=json.dumps(payload).encode()
    )
    return resp["SequenceNumber"]


async def publish_alert(message: Dict[str, Any], **attributes: str) -> Optional[str]:
    s = get_aws_settings()
    if not (s.enabled and s.alerts_topic_arn):
        return None
    try:
        return await asyncio.to_thread(_publish, s.alerts_topic_arn, message, attributes)
    except Exception as exc:
        logger.warning("alert publish failed: %s", exc)
        return None


async def publish_sensor_reading(device_id: str, payload: Dict[str, Any]) -> Optional[str]:
    s = get_aws_settings()
    if not (s.enabled and s.sensor_stream):
        return None
    try:
        return await asyncio.to_thread(_put_record, s.sensor_stream, device_id, {"device_id": device_id, **payload})
    except Exception as exc:
        logger.warning("sensor publish failed: %s", exc)
        return None
