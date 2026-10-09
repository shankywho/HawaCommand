"""Wind back-trajectory calculation for pollution hotspot source localization (F7).

Reverses surface wind vectors hour-by-hour from the detected hotspot coordinate
to pinpoint the upwind suspect emission origin and atmospheric dispersion spread radius.
"""
import math
from typing import Optional, Tuple
from hawa_ml.schemas import SuspectPin


def calculate_upwind_suspect_pin(
    hotspot_lat: float,
    hotspot_lon: float,
    wind_speed_ms: float = 2.5,
    wind_direction_deg: float = 295.0,
    lookback_hours: float = 1.5,
) -> SuspectPin:
    """Calculate the upwind suspect source location and plume uncertainty spread radius."""
    # Wind direction WD is where wind is coming FROM.
    # Moving upwind towards the origin means following WD directly.
    rad = math.radians(wind_direction_deg)

    # Drift distance in meters: distance = speed * time
    drift_distance_m = wind_speed_ms * (lookback_hours * 3600.0)

    # Offset in meters (X is East, Y is North)
    dx_m = drift_distance_m * math.sin(rad)
    dy_m = drift_distance_m * math.cos(rad)

    # Convert to coordinate deltas for Delhi
    # 1 deg lat ≈ 110,852 m; 1 deg lon ≈ 97,710 m
    d_lat = dy_m / 110852.0
    d_lon = dx_m / 97710.0

    suspect_lat = hotspot_lat + d_lat
    suspect_lon = hotspot_lon + d_lon

    # Atmospheric dispersion spread radius (Pasquill-Gifford horizontal dispersion approximation)
    # sigma_y grows with downwind travel distance
    spread_radius_m = max(100.0, 80.0 + 0.08 * drift_distance_m)

    return SuspectPin(
        lat=round(suspect_lat, 5),
        lon=round(suspect_lon, 5),
        distance_m=round(drift_distance_m, 1),
        spread_m=round(spread_radius_m, 1),
    )


if __name__ == "__main__":
    pin = calculate_upwind_suspect_pin(28.6476, 77.3158, wind_speed_ms=3.0, wind_direction_deg=310.0)
    print("Suspect Origin Pin:", pin.model_dump())
