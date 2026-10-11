"""AWS Secrets Manager reads: backend settings (core/config.py bootstrap_secrets) and the Firebase
service-account JSON (services/push.py)."""
import json
from functools import lru_cache
from typing import Any, Dict

from .clients import get_client


def get_secret_string(secret_id: str) -> str:
    resp = get_client("secretsmanager").get_secret_value(SecretId=secret_id)
    if "SecretString" in resp:
        return resp["SecretString"]
    return resp["SecretBinary"].decode()


@lru_cache(maxsize=8)
def get_secret_json(secret_id: str) -> Dict[str, Any]:
    """The secret parsed as a JSON object (cached for the life of the process)."""
    value = json.loads(get_secret_string(secret_id))
    if not isinstance(value, dict):
        raise ValueError(f"secret {secret_id} is not a JSON object")
    return value
