"""Hotspots and Digital Twin query endpoints."""
from typing import Optional
from fastapi import APIRouter, HTTPException, Path, Query
from ...core.intel_client import get_intel_client

router = APIRouter(tags=["Hotspots & Digital Twin"])


@router.get("/v1/hotspots")
async def get_hotspots(
    hour: int = Query(0, ge=-24, le=72, description="Hour relative to now: negative for past, positive for forecast"),
    ward: Optional[str] = Query(None, description="Optional ward filter"),
    threshold: float = Query(250.0, description="PM2.5 threshold for exposure calculation"),
):
    intel = get_intel_client()
    return await intel.get_hotspots(ward=ward, hour=hour, threshold=threshold)


@router.get("/v1/hotspots/{cell_id}")
async def get_hotspot_by_id(cell_id: str = Path(...)):
    intel = get_intel_client()
    hotspots_data = await intel.get_hotspots(limit=50)
    for item in hotspots_data.get("items", []):
        if item.get("cellId") == cell_id:
            return item
    raise HTTPException(status_code=404, detail=f"Hotspot with cellId '{cell_id}' not found")


@router.get("/v1/twin")
async def get_twin(
    bbox: Optional[str] = Query(None, description="Bounding box min_lat,min_lon,max_lat,max_lon"),
    ts: Optional[str] = Query(None, description="ISO timestamp"),
    limit: int = Query(500, le=2000),
):
    intel = get_intel_client()
    return await intel.get_digital_twin(bbox=bbox, ts=ts, limit=limit)


