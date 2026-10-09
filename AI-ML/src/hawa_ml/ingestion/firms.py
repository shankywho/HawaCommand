"""NASA FIRMS (Fire Information for Resource Management System) VIIRS client.

Downloads active fire points across Punjab, Haryana, and Delhi NCR.
Computes upwind sector fire counts and Fire Radiative Power (FRP) at 100km, 300km, and 500km radii.
"""
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Dict, List, Optional
import requests
import pandas as pd
import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.geo import haversine_distance_m

logger = configure_logging("firms")

FIRMS_API_URL = "https://firms.modaps.eosdis.nasa.gov/api/area/csv"
# Bounding box for stubble burning belt (Punjab, Haryana, West UP, Delhi)
BBOX_STUBBLE = [74.0, 28.0, 78.5, 32.5]  # [min_lon, min_lat, max_lon, max_lat]


class FIRMSClient:
    def __init__(self):
        self.map_key = settings.NASA_FIRMS_MAP_KEY
        self.cache_dir = settings.CACHE_DIR / "firms"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.offline = settings.OFFLINE_MODE or not bool(self.map_key)

    def fetch_active_fires(self, days: int = 3) -> pd.DataFrame:
        """Fetch VIIRS active fire detections for the last N days."""
        out_cache = self.cache_dir / f"fires_last_{days}d.parquet"
        if out_cache.exists():
            return pd.read_parquet(out_cache)

        if self.offline:
            logger.warning("[TODO_KEY] NASA_FIRMS_MAP_KEY missing or OFFLINE_MODE=true. Generating synthetic fire points.")
            df = self._generate_synthetic_fires(days=days)
            df.to_parquet(out_cache, index=False)
            return df

        # NASA FIRMS API: /api/area/csv/[MAP_KEY]/[SOURCE]/[BBOX]/[DAY_RANGE]
        bbox_str = f"{BBOX_STUBBLE[0]},{BBOX_STUBBLE[1]},{BBOX_STUBBLE[2]},{BBOX_STUBBLE[3]}"
        url = f"{FIRMS_API_URL}/{self.map_key}/VIIRS_SNPP_NRT/{bbox_str}/{days}"

        try:
            logger.info("Querying NASA FIRMS API for active agricultural fire points...")
            resp = requests.get(url, timeout=20)
            if resp.status_code == 200 and "latitude" in resp.text:
                from io import StringIO
                df = pd.read_csv(StringIO(resp.text))
                df = df.rename(columns={"frp": "frp_mw"})
                df["acq_datetime"] = pd.to_datetime(df["acq_date"] + " " + df["acq_time"].astype(str).str.zfill(4), format="%Y-%m-%d %H%M", utc=True)
                df.to_parquet(out_cache, index=False)
                logger.info(f"Retrieved {len(df)} active fire detections from NASA FIRMS.")
                return df
            else:
                logger.warning(f"NASA FIRMS returned status {resp.status_code}. Using synthetic fires.")
        except Exception as e:
            logger.warning(f"FIRMS connection error: {e}. Using synthetic fires.")

        df = self._generate_synthetic_fires(days=days)
        df.to_parquet(out_cache, index=False)
        return df

    def compute_upwind_fire_features(
        self,
        target_lat: float = 28.6139,
        target_lon: float = 77.2090,
        wind_direction_deg: float = 300.0,
        days: int = 3,
    ) -> Dict[str, float]:
        """Compute fire counts and total FRP in upwind sectors (100km, 300km, 500km)."""
        df_fires = self.fetch_active_fires(days=days)
        if df_fires.empty:
            return {
                "fire_count_upwind_100km": 0.0,
                "fire_count_upwind_300km": 0.0,
                "fire_count_upwind_500km": 0.0,
                "frp_upwind_sum": 0.0,
            }

        # Angle tolerance for upwind cone (±45 degrees)
        # Upwind direction is where wind is coming from
        upwind_deg = (wind_direction_deg) % 360.0

        lat_arr = df_fires["latitude"].values
        lon_arr = df_fires["longitude"].values
        frp_arr = df_fires["frp_mw"].values if "frp_mw" in df_fires.columns else np.ones(len(df_fires)) * 10.0

        # Vectorized distance and bearing
        d_lat = lat_arr - target_lat
        d_lon = lon_arr - target_lon
        # Bearing from target to fire in degrees
        bearing = np.degrees(np.arctan2(d_lon * np.cos(np.radians(target_lat)), d_lat)) % 360.0
        angle_diff = np.abs((bearing - upwind_deg + 180.0) % 360.0 - 180.0)

        # Approximate distance in km
        dist_km = np.sqrt((d_lat * 111.0) ** 2 + (d_lon * 97.7) ** 2)

        upwind_mask = angle_diff <= 45.0
        c100 = int(np.sum(upwind_mask & (dist_km <= 100.0)))
        c300 = int(np.sum(upwind_mask & (dist_km <= 300.0)))
        c500 = int(np.sum(upwind_mask & (dist_km <= 500.0)))
        frp_sum = float(np.sum(frp_arr[upwind_mask & (dist_km <= 500.0)]))

        return {
            "fire_count_upwind_100km": float(c100),
            "fire_count_upwind_300km": float(c300),
            "fire_count_upwind_500km": float(c500),
            "frp_upwind_sum": frp_sum,
        }

    def _generate_synthetic_fires(self, days: int = 3) -> pd.DataFrame:
        """Generate synthetic agricultural stubble fire points in Punjab/Haryana."""
        now = datetime.now(timezone.utc)
        # October-November has heavy stubble burning (post-monsoon paddy harvest)
        is_stubble_season = now.month in [10, 11]
        n_fires = 250 if is_stubble_season else 35

        # Punjab/Haryana cluster: lat [29.5, 31.8], lon [74.5, 76.8]
        lats = np.random.uniform(29.5, 31.8, size=n_fires)
        lons = np.random.uniform(74.5, 76.8, size=n_fires)
        frp = np.random.gamma(shape=2.5, scale=12.0, size=n_fires)

        dates = [now - timedelta(hours=int(h)) for h in np.random.uniform(1, days * 24, size=n_fires)]

        return pd.DataFrame({
            "latitude": lats,
            "longitude": lons,
            "frp_mw": frp,
            "confidence": np.random.choice(["nominal", "high"], size=n_fires),
            "acq_datetime": dates,
        })


if __name__ == "__main__":
    client = FIRMSClient()
    feats = client.compute_upwind_fire_features()
    print("Upwind fire features:", feats)
