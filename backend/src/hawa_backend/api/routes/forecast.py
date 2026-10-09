"""72-hour forecast and GRAP outlook."""
from typing import Optional
from fastapi import APIRouter, Query
from ...aws import get_aws_forecast
from ...core.intel_client import get_intel_client

router = APIRouter(prefix="/v1/forecast", tags=["Forecast"])



async def _forecast(cell_id: Optional[str], ward: Optional[str] = None):
    intel = get_intel_client()
    if cell_id is None:
        return await intel.get_forecast(ward=ward)
    aws_result = await get_aws_forecast(cell_id)
    if aws_result:
        return intel.format_forecast(aws_result, ward)
    return await intel.get_forecast(ward=ward, cell_id=cell_id)


@router.get("")
async def get_forecast(
    ward: Optional[str] = Query(None, description="Optional ward filter"),
):
    return await _forecast(None, ward)


@router.get("/{cell_id}")
async def get_cell_forecast(
    cell_id: str,
    pollutant: Optional[str] = Query("pm25", description="Pollutant: pm25 | pm10"),
    issued_at: Optional[str] = Query(None, description="ISO timestamp of issue time"),
):
    return await _forecast(cell_id)
