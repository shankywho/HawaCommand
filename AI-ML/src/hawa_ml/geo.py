"""Geospatial utilities, projections, grid generation, and distance metrics for Delhi."""
import math
from typing import List, Tuple
import numpy as np

# Delhi center approximately 28.6139° N, 77.2090° E
# 1 degree of latitude ≈ 110,852 meters in Delhi
# 1 degree of longitude ≈ 97,710 meters in Delhi (111,320 * cos(28.6°))
LAT_METERS_PER_DEG = 110852.0
LON_METERS_PER_DEG = 97710.0

# Delhi Bounding Box: (min_lat, min_lon, max_lat, max_lon)
DELHI_BBOX = (28.40, 76.84, 28.88, 77.35)


def haversine_distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great circle distance between two points in meters."""
    r = 6371000.0  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return r * c


def latlon_to_meters(lat: float, lon: float, origin_lat: float = 28.40, origin_lon: float = 76.84) -> Tuple[float, float]:
    """Convert Lat/Lon to local Cartesian coordinates (meters X, meters Y) relative to origin."""
    y = (lat - origin_lat) * LAT_METERS_PER_DEG
    x = (lon - origin_lon) * LON_METERS_PER_DEG
    return x, y


def meters_to_latlon(x: float, y: float, origin_lat: float = 28.40, origin_lon: float = 76.84) -> Tuple[float, float]:
    """Convert local Cartesian coordinates (meters X, meters Y) back to Lat/Lon."""
    lat = origin_lat + (y / LAT_METERS_PER_DEG)
    lon = origin_lon + (x / LON_METERS_PER_DEG)
    return lat, lon


def get_cell_id(lat: float, lon: float, cell_size_m: float = 500.0) -> str:
    """Return standard grid cell ID based on meter quantization."""
    x, y = latlon_to_meters(lat, lon)
    col = int(math.floor(x / cell_size_m))
    row = int(math.floor(y / cell_size_m))
    return f"G-{row:03d}-{col:03d}"


def get_cell_centroid(cell_id: str, cell_size_m: float = 500.0) -> Tuple[float, float]:
    """Get the latitude and longitude of the center of a grid cell."""
    parts = cell_id.split("-")
    row = int(parts[1])
    col = int(parts[2])
    x = (col + 0.5) * cell_size_m
    y = (row + 0.5) * cell_size_m
    return meters_to_latlon(x, y)


def get_cell_polygon_coords(cell_id: str, cell_size_m: float = 500.0) -> List[List[float]]:
    """Return GeoJSON polygon coordinates [[lon, lat], ...] for a cell."""
    parts = cell_id.split("-")
    row = int(parts[1])
    col = int(parts[2])
    x0 = col * cell_size_m
    y0 = row * cell_size_m
    x1 = (col + 1) * cell_size_m
    y1 = (row + 1) * cell_size_m

    p1_lat, p1_lon = meters_to_latlon(x0, y0)
    p2_lat, p2_lon = meters_to_latlon(x1, y0)
    p3_lat, p3_lon = meters_to_latlon(x1, y1)
    p4_lat, p4_lon = meters_to_latlon(x0, y1)

    return [
        [p1_lon, p1_lat],
        [p2_lon, p2_lat],
        [p3_lon, p3_lat],
        [p4_lon, p4_lat],
        [p1_lon, p1_lat],
    ]
