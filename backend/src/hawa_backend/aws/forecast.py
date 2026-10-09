"""Forecast via AWS: DynamoDB cache -> Step Functions (Express) or SageMaker endpoint.

The remote side must return the same payload as the AI-ML engine's `/forecast/{cell_id}`
(a dict containing "horizons"). Returns None on any failure so the caller can fall back.
"""
import asyncio
import json
import logging
from typing import Any, Dict, Optional

from .cache import cache_get, cache_set
from .clients import get_client
from .settings import get_aws_settings

logger = logging.getLogger("hawa_backend.aws.forecast")


def _run_state_machine(arn: str, cell_id: str) -> Optional[Dict[str, Any]]:
    resp = get_client("stepfunctions").start_sync_execution(
        stateMachineArn=arn, input=json.dumps({"cell_id": cell_id})
    )
    if resp.get("status") != "SUCCEEDED":
        logger.warning("forecast state machine %s: %s", resp.get("status"), resp.get("cause"))
        return None
    return json.loads(resp["output"])


def _invoke_endpoint(endpoint: str, cell_id: str) -> Dict[str, Any]:
    resp = get_client("sagemaker-runtime").invoke_endpoint(
        EndpointName=endpoint, ContentType="application/json", Body=json.dumps({"cell_id": cell_id})
    )
    return json.loads(resp["Body"].read())


def _compute(cell_id: str) -> Optional[Dict[str, Any]]:
    s = get_aws_settings()
    if s.forecast_state_machine_arn:
        return _run_state_machine(s.forecast_state_machine_arn, cell_id)
    if s.forecast_endpoint:
        return _invoke_endpoint(s.forecast_endpoint, cell_id)
    return None


async def get_aws_forecast(cell_id: str) -> Optional[Dict[str, Any]]:
    s = get_aws_settings()
    if not s.enabled:
        return None
    key = f"forecast:{cell_id}"
    cached = await cache_get(key)
    if cached:
        return cached
    try:
        result = await asyncio.to_thread(_compute, cell_id)
    except Exception as exc:
        logger.warning("AWS forecast failed for %s: %s", cell_id, exc)
        return None
    if not result or "horizons" not in result:
        return None
    await cache_set(key, result)
    return result
