"""Liveness and readiness probes."""
from fastapi import APIRouter

from ...aws.settings import get_aws_settings
from ...core.redis_store import get_redis, redis_url
from ...services import push

router = APIRouter(tags=["Health"])


@router.get("/healthz")
@router.get("/health")
@router.get("/livez")
@router.get("/v1/health")
async def healthz():
    return {"status": "ok"}


@router.get("/readyz")
async def readyz():
    """Which optional backends this process is using. Always 200: every one of them has a fallback."""
    aws = get_aws_settings()

    def on(value) -> str:
        return "configured" if aws.enabled and value else "off"

    if not redis_url():
        redis_state = "off (process memory)"
    else:
        redis_state = "ok" if await get_redis() is not None else "unreachable (process memory)"
    return {
        "status": "ready",
        "services": {
            "api": "ok",
            "redis": redis_state,
            "aws": "enabled" if aws.enabled else "disabled",
            "s3_evidence": on(aws.evidence_bucket),
            "dynamodb_grievances": on(aws.grievances_table),
            "dynamodb_fleet": on(aws.fleet_table),
            "kinesis": on(aws.sensor_stream),
            "kinesis_consumer_in_api": "on" if aws.enabled and aws.sensor_stream and aws.kinesis_consumer else "off",
            "sns_alerts": on(aws.alerts_topic_arn),
            "secrets_manager": on(aws.secrets_id),
            "fcm": "configured" if push.configured() else "off",
        },
    }
