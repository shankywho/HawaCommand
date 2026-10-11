"""Live fleet: HawaTag telemetry ingest over HTTP, live positions, nearby search, tracks and a WebSocket
that pushes every ping as it arrives. Storage and fan-out: services/fleet.py."""
import asyncio
import logging
from typing import List, Union

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect

from ...core.identity import require_ingest_key
from ...services import fleet
from ...services._util import iso, utcnow

logger = logging.getLogger("hawa_backend.routes.fleet")

router = APIRouter(tags=["Fleet telemetry"])

MAX_BATCH = 500
HEARTBEAT_SECONDS = 25.0


@router.post("/v1/telemetry/vehicles", status_code=202, dependencies=[Depends(require_ingest_key)])
async def ingest_vehicle_pings(body: Union[fleet.VehiclePing, List[fleet.VehiclePing]]):
    """One ping or a list (max 500). Same payload as the IoT Core topic hawa/vehicles/<asset_id>/telemetry."""
    pings = body if isinstance(body, list) else [body]
    if len(pings) > MAX_BATCH:
        raise HTTPException(status_code=413, detail=f"At most {MAX_BATCH} pings per request")
    stored = await fleet.ingest_many(pings)
    return {"accepted": len(stored), "items": stored}


@router.get("/v1/fleet/live")
async def live_fleet():
    """Vehicles that pinged within HAWA_FLEET_ACTIVE_MINUTES, newest first."""
    items = await fleet.live_fleet()
    return {"asOf": iso(utcnow()), "count": len(items), "items": items}


@router.get("/v1/fleet/nearby")
async def nearby_fleet(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(5.0, gt=0, le=50),
    limit: int = Query(50, ge=1, le=500),
):
    """Active vehicles within radius_km (Redis GEOSEARCH on geo:fleet:active when Redis is configured)."""
    items = await fleet.nearby(lat, lon, radius_km, limit)
    return {"asOf": iso(utcnow()), "count": len(items), "items": items}


@router.get("/v1/fleet/{asset_id}/track")
async def asset_track(asset_id: str, minutes: int = Query(180, ge=1, le=7 * 24 * 60)):
    """Pings of one vehicle over the last `minutes` (DynamoDB fleet table when configured)."""
    items = await fleet.track(asset_id, minutes)
    return {"assetId": asset_id, "minutes": minutes, "count": len(items), "items": items}


@router.websocket("/v1/ws/fleet")
async def fleet_socket(ws: WebSocket):
    """Sends {"type": "snapshot", "items": [...]} then {"type": "ping", "item": {...}} per ping,
    and {"type": "heartbeat"} every 25 s so load balancers keep the connection open."""
    await ws.accept()
    lock = asyncio.Lock()

    async def send(msg):
        async with lock:
            await ws.send_json(msg)

    updates = await fleet.subscribe()  # registered before the snapshot, so no ping falls in between

    async def pump():
        await send({"type": "snapshot", "asOf": iso(utcnow()), "items": await fleet.live_fleet()})
        async for rec in updates:
            await send({"type": "ping", "item": dict(rec, status=fleet.status_of(rec))})

    async def heartbeat():
        while True:
            await asyncio.sleep(HEARTBEAT_SECONDS)
            await send({"type": "heartbeat", "at": iso(utcnow())})

    async def drain():
        while True:
            await ws.receive_text()

    tasks = [asyncio.create_task(t()) for t in (pump, heartbeat, drain)]
    try:
        await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
    except WebSocketDisconnect:
        pass
    finally:
        for t in tasks:
            t.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        await updates.close()
