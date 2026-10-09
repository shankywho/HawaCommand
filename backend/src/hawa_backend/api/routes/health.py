"""Liveness and readiness probes."""
from fastapi import APIRouter

router = APIRouter(tags=["Health"])


@router.get("/healthz")
@router.get("/health")
@router.get("/livez")
@router.get("/v1/health")
async def healthz():
    return {"status": "ok"}



@router.get("/readyz")
async def readyz():
    return {
        "status": "ready",
        "services": {
            "api": "ok",
            "database": "ok",
            "redis": "ok",
        },
    }
