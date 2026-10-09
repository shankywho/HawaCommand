"""Public read-only air data: the current PM2.5 field as ranked 500 m cells."""
from typing import Optional

from fastapi import APIRouter, Query

from ...core.intel_client import get_intel_client

router = APIRouter(prefix="/open/v1", tags=["Open data"])


@router.get("/air")
async def open_air(
    ward: Optional[str] = Query(None, description="Ward filter; omit for all wards"),
    limit: int = Query(50, ge=1, le=200),
):
    data = await get_intel_client().get_hotspots(ward=ward, limit=limit)
    return {
        "asOf": data["asOf"],
        "simulated": data.get("simulated", True),
        "pollutant": "pm25",
        "unit": "ug/m3",
        "cells": [
            {
                "cellId": h["cellId"],
                "ward": h["ward"],
                "lon": h["at"][0],
                "lat": h["at"][1],
                "pm25": h["pm25"],
                "band": h["band"],
                "likelyCause": h["cause"],
                "causeConfidence": h["causeConf"],
            }
            for h in data["items"]
        ],
    }
