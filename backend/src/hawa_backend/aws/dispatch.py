"""Start the dispatch workflow (Step Functions) for an approved plan."""
import asyncio
import json
import logging
import re
from typing import Any, Dict, Optional

from .clients import get_client
from .settings import get_aws_settings

logger = logging.getLogger("hawa_backend.aws.dispatch")


def _start(arn: str, plan: Dict[str, Any]) -> str:
    name = re.sub(r"[^A-Za-z0-9_-]", "-", f"plan-{plan['id']}-{plan.get('approvedAt', '')}")[:80]
    payload = {
        "planId": plan["id"],
        "ward": plan.get("ward"),
        "window": plan.get("window"),
        "groups": plan.get("groups", []),
    }
    return get_client("stepfunctions").start_execution(stateMachineArn=arn, name=name, input=json.dumps(payload))["executionArn"]


async def start_dispatch(plan: Dict[str, Any]) -> Optional[str]:
    """Execution ARN of the started run, or None when AWS dispatch is not configured or fails."""
    s = get_aws_settings()
    if not (s.enabled and s.dispatch_state_machine_arn):
        return None
    try:
        return await asyncio.to_thread(_start, s.dispatch_state_machine_arn, plan)
    except Exception as exc:
        logger.warning("dispatch start failed for plan %s: %s", plan.get("id"), exc)
        return None
