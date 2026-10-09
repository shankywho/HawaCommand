"""Lazily created, cached boto3 clients. boto3 is imported on first use so the backend runs without it."""
from functools import lru_cache

from .settings import get_aws_settings


def _config():
    from botocore.config import Config

    return Config(retries={"max_attempts": 3, "mode": "adaptive"}, connect_timeout=3, read_timeout=10)


@lru_cache(maxsize=None)
def get_client(service: str):
    import boto3

    s = get_aws_settings()
    return boto3.client(service, region_name=s.region, endpoint_url=s.endpoint_url, config=_config())


@lru_cache(maxsize=1)
def get_cache_table():
    import boto3

    s = get_aws_settings()
    resource = boto3.resource("dynamodb", region_name=s.region, endpoint_url=s.endpoint_url, config=_config())
    return resource.Table(s.cache_table)


def reset_clients() -> None:
    get_client.cache_clear()
    get_cache_table.cache_clear()
