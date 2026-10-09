"""Fleet assets and HawaTag live telemetry."""
from datetime import datetime, timezone
from fastapi import APIRouter
from ..fixtures import get_mock_assets

router = APIRouter(prefix="/v1/devices", tags=["Fleet & Devices"])


@router.get("")
async def list_devices():
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    return {
        "asOf": now_iso,
        "simulated": True,
        "items": get_mock_assets(),
    }
