"""Multimodal data fusion: Combines fixed reference stations, mobile pods, and school sentinels."""
from typing import Dict, List
import pandas as pd
from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.twin.kriging import twin_engine

logger = configure_logging("twin_fusion")


def fuse_and_build_twin(
    telemetry_packets: List[dict],
    reference_stations: pd.DataFrame = None,
    wind_speed_ms: float = 2.5,
    wind_dir_deg: float = 295.0,
) -> pd.DataFrame:
    """Fuse all live observation sources and interpolate 500m digital twin field."""
    obs_points = []

    # 1. Add calibrated mobile & sentinel telemetry
    for pkt in telemetry_packets:
        lat = pkt.get("gps", {}).get("lat")
        lon = pkt.get("gps", {}).get("lon")
        pm25 = pkt.get("pm", {}).get("pm25")
        pm10 = pkt.get("pm", {}).get("pm10")
        if lat and lon and pm25 is not None and pm10 is not None:
            obs_points.append({
                "latitude": float(lat),
                "longitude": float(lon),
                "pm25": float(pm25),
                "pm10": float(pm10),
            })

    # 2. Add latest reference station ground truth
    if reference_stations is not None and not reference_stations.empty:
        latest_stations = (
            reference_stations.sort_values("timestamp")
            .groupby("station_id")
            .last()
            .reset_index()
        )
        for _, row in latest_stations.iterrows():
            lat = row.get("latitude")
            lon = row.get("longitude")
            pm25 = row.get("pm25")
            pm10 = row.get("pm10")
            if pd.notna(lat) and pd.notna(lon) and pd.notna(pm25) and pd.notna(pm10):
                obs_points.append({
                    "latitude": float(lat),
                    "longitude": float(lon),
                    "pm25": float(pm25),
                    "pm10": float(pm10),
                })

    # 3. Fit Kriging digital twin
    twin_grid = twin_engine.fit_and_predict(
        obs_points=obs_points,
        wind_speed_ms=wind_speed_ms,
        wind_dir_deg=wind_dir_deg,
    )
    return twin_grid
