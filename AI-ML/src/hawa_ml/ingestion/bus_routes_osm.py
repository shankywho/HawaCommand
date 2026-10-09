"""Simulated Delhi transit bus routes derived from OpenStreetMap and major transport corridors.

Used by the mobile sensor simulator (HawaPod-M on DTC and Cluster buses).
No external GTFS files required.
"""
import json
from pathlib import Path
from typing import Dict, List, Tuple
import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("bus_routes")

# Key Delhi Transit Nodes (Terminals, Ring Road Junctions, Major Hubs)
MAJOR_NODES = {
    "kashmiri_gate": (28.6690, 77.2280),
    "anand_vihar_isbt": (28.6500, 77.3150),
    "connaught_place": (28.6315, 77.2167),
    "aiims": (28.5672, 77.2100),
    "dhaula_kuan": (28.5921, 77.1610),
    "punjabi_bagh": (28.6740, 77.1310),
    "dwarka_sec21": (28.5520, 77.0580),
    "rohini_sec14": (28.7150, 77.1250),
    "nehru_place": (28.5490, 77.2520),
    "uttam_nagar": (28.6220, 77.0650),
    "wazirpur": (28.6998, 77.1655),
    "sarai_kale_khan": (28.5890, 77.2580),
    "azadpur": (28.7080, 77.1770),
    "badarpur": (28.4980, 77.3020),
    "narela": (28.8228, 77.1019),
}

# Major Corridor Sequences (Ring Road, Cross-town Arterials)
CORRIDORS = {
    "route_mudrika_ring_road": [
        "kashmiri_gate", "azadpur", "wazirpur", "punjabi_bagh",
        "dhaula_kuan", "aiims", "sarai_kale_khan", "kashmiri_gate",
    ],
    "route_429_anand_vihar_dwarka": [
        "anand_vihar_isbt", "connaught_place", "dhaula_kuan", "uttam_nagar", "dwarka_sec21",
    ],
    "route_534_anand_vihar_nehru_place": [
        "anand_vihar_isbt", "sarai_kale_khan", "nehru_place", "aiims",
    ],
    "route_764_rohini_nehru_place": [
        "rohini_sec14", "punjabi_bagh", "dhaula_kuan", "aiims", "nehru_place",
    ],
    "route_853_uttam_nagar_cp": [
        "uttam_nagar", "punjabi_bagh", "connaught_place",
    ],
    "route_outer_ring_narela_aiims": [
        "narela", "azadpur", "wazirpur", "dhaula_kuan", "aiims",
    ],
}


def interpolate_waypoints(p1: Tuple[float, float], p2: Tuple[float, float], step_m: float = 300.0) -> List[Tuple[float, float]]:
    """Interpolate smooth trajectory between two corridor hubs with minor street jitter."""
    lat1, lon1 = p1
    lat2, lon2 = p2
    # Distance in meters
    d_lat_m = (lat2 - lat1) * 110852.0
    d_lon_m = (lon2 - lon1) * 97710.0
    dist_m = np.sqrt(d_lat_m ** 2 + d_lon_m ** 2)

    n_steps = max(2, int(dist_m / step_m))
    lats = np.linspace(lat1, lat2, n_steps)
    lons = np.linspace(lon1, lon2, n_steps)

    # Add realistic corridor curvature/noise
    pts = []
    for i in range(n_steps):
        jitter_lat = np.sin(i * np.pi / n_steps) * 0.0012 + np.random.normal(0, 0.0003)
        jitter_lon = np.cos(i * np.pi / n_steps) * 0.0012 + np.random.normal(0, 0.0003)
        pts.append((float(lats[i] + jitter_lat), float(lons[i] + jitter_lon)))
    return pts


def generate_bus_routes() -> Dict[str, List[Tuple[float, float]]]:
    """Generate high-resolution waypoint trajectories for Delhi bus routes."""
    routes = {}
    for r_name, nodes in CORRIDORS.items():
        route_pts = []
        for i in range(len(nodes) - 1):
            n1 = MAJOR_NODES[nodes[i]]
            n2 = MAJOR_NODES[nodes[i + 1]]
            segment = interpolate_waypoints(n1, n2, step_m=250.0)
            if route_pts:
                route_pts.extend(segment[1:])
            else:
                route_pts.extend(segment)
        routes[r_name] = route_pts

    out_file = settings.FIXTURES_DIR / "bus_routes_delhi.json"
    settings.FIXTURES_DIR.mkdir(parents=True, exist_ok=True)
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(routes, f, indent=2)
    logger.info(f"Generated {len(routes)} bus routes ({sum(len(v) for v in routes.values())} waypoints) -> {out_file}")
    return routes


def load_bus_routes() -> Dict[str, List[Tuple[float, float]]]:
    """Load bus routes from fixtures or generate dynamically."""
    route_file = settings.FIXTURES_DIR / "bus_routes_delhi.json"
    if route_file.exists():
        with open(route_file, "r", encoding="utf-8") as f:
            return json.load(f)
    return generate_bus_routes()


if __name__ == "__main__":
    r = generate_bus_routes()
    for name, pts in r.items():
        print(f"Route '{name}': {len(pts)} GPS waypoints")
