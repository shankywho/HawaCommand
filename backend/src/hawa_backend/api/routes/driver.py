"""Driver PWA mobile route view with Hindi-first stop instructions."""
from fastapi import APIRouter, Query
from ..fixtures import get_mock_driver_route

router = APIRouter(prefix="/v1/driver", tags=["Driver PWA"])


@router.get("/route")
async def get_driver_route(asset: str = Query("T-12", description="Assigned asset ID, e.g. T-12")):
    return get_mock_driver_route(asset)
