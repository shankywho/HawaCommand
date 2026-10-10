"""Evidence photo upload slots (pre-signed S3 POST)."""
from typing import Literal

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from ...aws.uploads import UploadRejected, UploadsNotConfigured, presign_upload

router = APIRouter(prefix="/v1/uploads", tags=["Uploads"])


class PresignIn(BaseModel):
    purpose: Literal["report_photo", "inspection_photo", "task_photo"]
    content_type: str
    content_length: int = Field(..., gt=0)
    sha256: str = Field(..., pattern=r"^[0-9a-fA-F]{64}$")


@router.post("/presign")
async def presign(req: PresignIn):
    """Return a pre-signed S3 POST: send `fields` then `file` as multipart form data to `url`."""
    try:
        return await presign_upload(req.purpose, req.content_type, req.content_length, req.sha256.lower())
    except UploadsNotConfigured:
        raise HTTPException(
            status_code=503,
            detail="Uploads are not configured: set HAWA_AWS_ENABLED=true and HAWA_AWS_EVIDENCE_BUCKET in backend/.env",
        )
    except UploadRejected as exc:
        raise HTTPException(status_code=exc.status, detail=exc.detail)
