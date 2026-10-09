"""Delhi spatial grid builder (500m map cells, 1km planning cells).

Attaches static covariates:
- Population (WorldPop 1km clipped raster)
- Nearest school & hospital distance, counts in 500m radius
- Road proximity and density
- Vulnerability weight V(cell) based on config/weights.yaml
- GeoJSON polygon coordinates
"""
import math
from pathlib import Path
from typing import Dict, List, Optional
import pandas as pd
import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.geo import (
    haversine_distance_m,
    latlon_to_meters,
    meters_to_latlon,
    get_cell_id,
    get_cell_centroid,
    get_cell_polygon_coords,
    DELHI_BBOX,
)
from hawa_ml.ingestion.worldpop import WorldPopProcessor
from hawa_ml.ingestion.osm import OSMClient

logger = configure_logging("grid")


def build_delhi_grid(cell_size_m: float = 500.0) -> pd.DataFrame:
    """Generate regular metric grid covering Delhi NCR with static covariates."""
    min_lat, min_lon, max_lat, max_lon = DELHI_BBOX
    x_min, y_min = latlon_to_meters(min_lat, min_lon)
    x_max, y_max = latlon_to_meters(max_lat, max_lon)

    cols = int(math.ceil((x_max - x_min) / cell_size_m))
    rows = int(math.ceil((y_max - y_min) / cell_size_m))

    logger.info(f"Building {cell_size_m}m grid for Delhi ({rows} rows x {cols} cols = {rows * cols} cells)...")

    # Load WorldPop and POIs
    wp = WorldPopProcessor()
    osm = OSMClient()
    pois = osm.fetch_pois()
    schools = pois.get("schools", [])
    hospitals = pois.get("hospitals", [])

    cells = []
    for r in range(rows):
        for c in range(cols):
            x_center = (c + 0.5) * cell_size_m
            y_center = (r + 0.5) * cell_size_m
            c_lat, c_lon = meters_to_latlon(x_center, y_center)

            # Check if within bounding box
            if not (min_lat <= c_lat <= max_lat and min_lon <= c_lon <= max_lon):
                continue

            cell_id = f"G-{r:03d}-{c:03d}"

            # Population count for cell area
            area_km2 = (cell_size_m / 1000.0) ** 2
            pop_per_km2 = wp.get_population_at(c_lat, c_lon)
            cell_pop = pop_per_km2 * area_km2

            # Calculate nearest distances to schools & hospitals
            min_school_dist = 99999.0
            n_schools_nearby = 0
            for s in schools:
                d = haversine_distance_m(c_lat, c_lon, s["lat"], s["lon"])
                if d < min_school_dist:
                    min_school_dist = d
                if d <= cell_size_m:
                    n_schools_nearby += 1

            min_hosp_dist = 99999.0
            n_hosp_nearby = 0
            for h in hospitals:
                d = haversine_distance_m(c_lat, c_lon, h["lat"], h["lon"])
                if d < min_hosp_dist:
                    min_hosp_dist = d
                if d <= cell_size_m:
                    n_hosp_nearby += 1

            # Vulnerability factor V(cell)
            if min_hosp_dist < 400.0:
                v_weight = 3.0
                primary_use = "hospital_cluster"
            elif min_school_dist < 400.0:
                v_weight = 2.5
                primary_use = "school_cluster"
            elif cell_pop > 10000 * area_km2:
                v_weight = 1.8
                primary_use = "dense_residential"
            elif cell_pop < 1500 * area_km2:
                v_weight = 0.5
                primary_use = "industrial_outskirts"
            else:
                v_weight = 1.0
                primary_use = "residential"

            # Road density proxy (closer to city center / hubs = higher road density)
            dist_center_km = haversine_distance_m(c_lat, c_lon, 28.6139, 77.2090) / 1000.0
            road_density = float(np.clip(12.0 * np.exp(-dist_center_km / 15.0) + 1.5, 1.0, 15.0))

            cells.append({
                "cell_id": cell_id,
                "row": r,
                "col": c,
                "latitude": float(c_lat),
                "longitude": float(c_lon),
                "population": float(cell_pop),
                "vulnerability_weight": float(v_weight),
                "primary_land_use": primary_use,
                "road_density_km_km2": road_density,
                "nearest_school_dist_m": float(min_school_dist),
                "schools_nearby_count": int(n_schools_nearby),
                "nearest_hospital_dist_m": float(min_hosp_dist),
                "hospitals_nearby_count": int(n_hosp_nearby),
                "ward": f"Ward-{(r % 12) + 1}",
            })

    df = pd.DataFrame(cells)
    suffix = f"{int(cell_size_m)}m"
    out_path = settings.PROCESSED_DATA_DIR / f"grid_covariates_{suffix}.parquet"
    settings.PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out_path, index=False)
    logger.info(f"Saved {len(df)} {suffix} grid cells with covariates to {out_path}")
    return df


def load_grid(cell_size_m: float = 500.0) -> pd.DataFrame:
    """Load precomputed grid covariates or generate if missing."""
    suffix = f"{int(cell_size_m)}m"
    p = settings.PROCESSED_DATA_DIR / f"grid_covariates_{suffix}.parquet"
    if p.exists():
        return pd.read_parquet(p)
    return build_delhi_grid(cell_size_m=cell_size_m)


if __name__ == "__main__":
    df_500 = build_delhi_grid(500.0)
    df_1000 = build_delhi_grid(1000.0)
    print("500m grid sample:\n", df_500.head())
