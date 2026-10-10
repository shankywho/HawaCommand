"""Pre-signed S3 POST uploads for evidence photos (Citizen Eyes reports, inspection and task photos).

The client asks for an upload slot, then POSTs the file straight to S3 as multipart form data
(the returned `fields` first, then `file`). The POST policy pins the object key, the content type
and a size range, so the bucket stays private and the backend never handles the bytes.
"""
import asyncio
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict

from .clients import get_s3_client
from .settings import get_aws_settings

CONTENT_TYPE_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/heic": ".heic",
}


class UploadsNotConfigured(Exception):
    """HAWA_AWS_ENABLED is off or HAWA_AWS_EVIDENCE_BUCKET is not set."""


class UploadRejected(Exception):
    def __init__(self, status: int, detail: str):
        super().__init__(detail)
        self.status = status
        self.detail = detail


def _object_key(prefix: str, purpose: str, content_type: str, now: datetime) -> str:
    return f"{prefix}{purpose}/{now:%Y/%m/%d}/{uuid.uuid4().hex}{CONTENT_TYPE_EXTENSIONS[content_type]}"


def _presign(bucket: str, key: str, content_type: str, sha256: str, max_bytes: int, ttl: int) -> Dict[str, Any]:
    fields = {"Content-Type": content_type, "x-amz-meta-sha256": sha256}
    conditions = [
        {"Content-Type": content_type},
        {"x-amz-meta-sha256": sha256},
        ["content-length-range", 1, max_bytes],
    ]
    return get_s3_client().generate_presigned_post(
        Bucket=bucket, Key=key, Fields=fields, Conditions=conditions, ExpiresIn=ttl
    )


async def presign_upload(purpose: str, content_type: str, content_length: int, sha256: str) -> Dict[str, Any]:
    """Upload slot in the PresignOut shape of app_frontend/openapi/openapi.json."""
    s = get_aws_settings()
    if not (s.enabled and s.evidence_bucket):
        raise UploadsNotConfigured()
    if content_type not in CONTENT_TYPE_EXTENSIONS:
        raise UploadRejected(415, f"Unsupported content type '{content_type}'; use one of {sorted(CONTENT_TYPE_EXTENSIONS)}")
    if content_length > s.upload_max_bytes:
        raise UploadRejected(413, f"File is {content_length} bytes; the limit is {s.upload_max_bytes} bytes")

    now = datetime.now(timezone.utc)
    key = _object_key(s.evidence_prefix, purpose, content_type, now)
    post = await asyncio.to_thread(
        _presign, s.evidence_bucket, key, content_type, sha256, s.upload_max_bytes, s.presign_ttl_seconds
    )
    expires_at = now + timedelta(seconds=s.presign_ttl_seconds)
    return {
        "key": key,
        "url": post["url"],
        "method": "POST",
        "expires_at": expires_at.isoformat().replace("+00:00", "Z"),
        "fields": post["fields"],
        "headers": None,
        "max_bytes": s.upload_max_bytes,
    }
