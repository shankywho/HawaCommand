"""Fleet assets and HawaTag live telemetry."""
from datetime import datetime, timezone
from fastapi import APIRouter
from ...services import fleet
from ..fixtures import get_mock_assets

router = APIRouter(prefix="/v1/devices", tags=["Fleet & Devices"])


@router.get("")
async def list_devices():
    """Vehicles with live telemetry first (services/fleet.py), then the demo fixtures not overridden by them."""
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    live = [fleet.to_asset(r) for r in await fleet.live_fleet()]
    live_ids = {a["id"] for a in live}
    return {
        "asOf": now_iso,
        "simulated": not live,
        "items": live + [a for a in get_mock_assets() if a["id"] not in live_ids],
    }
