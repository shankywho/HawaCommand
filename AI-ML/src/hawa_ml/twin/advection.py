"""Wind-driven spatial advection for pollution fields.

Shifts the interpolated pollution field downwind based on IMD/ERA5 surface wind vectors:
dx = ws * sin(wd_rad) * dt
dy = ws * cos(wd_rad) * dt
"""
from typing import Tuple
import numpy as np


def shift_coordinates_downwind(
    lat: float,
    lon: float,
    wind_speed_ms: float,
    wind_direction_deg: float,
    elapsed_seconds: float = 3600.0,
) -> Tuple[float, float]:
    """Calculate downwind shifted coordinates after elapsed time."""
    # Wind direction is where wind is coming from, so downwind drift is (wd + 180) % 360
    downwind_deg = (wind_direction_deg + 180.0) % 360.0
    rad = np.radians(downwind_deg)

    # Drift distance in meters
    drift_m = wind_speed_ms * elapsed_seconds

    dx_m = drift_m * np.sin(rad)
    dy_m = drift_m * np.cos(rad)

    # Approximate coordinate offset (Delhi: ~110.8km lat, ~97.7km lon per deg)
    d_lat = dy_m / 110852.0
    d_lon = dx_m / 97710.0

    return lat + d_lat, lon + d_lon
