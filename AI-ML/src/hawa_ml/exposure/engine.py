"""Exposure Engine: Human-centric pollution prioritization (F12).

Formula:
E(cell, t) = max(0, C - C_safe) * Pop(cell, t) * V(cell) * dt

Ranks pollution hotspots not by raw AQI numbers, but by person-hours of harmful exposure,
weighting school morning assemblies, outdoor workers, and hospital clusters.
Vectorized implementation using NumPy.
"""
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional
import numpy as np
import pandas as pd
import yaml

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.schemas import Hotspot, SourceClass, SuspectPin
from hawa_ml.attribution.rules import rule_attribution
from hawa_ml.attribution.backtrajectory import calculate_upwind_suspect_pin

logger = configure_logging("exposure_engine")


class ExposureEngine:
    def __init__(self):
        self.weights_path = settings.CONFIG_DIR / "weights.yaml"
        self.config = self._load_config()
        self.c_safe_pm25 = float(self.config.get("thresholds", {}).get("c_safe_pm25", 60.0))
        self.diurnal_multipliers = self.config.get("diurnal_population_multipliers", {})

    def _load_config(self) -> dict:
        if self.weights_path.exists():
            with open(self.weights_path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        return {}

    def compute_exposure_scores(
        self,
        grid_df: pd.DataFrame,
        hour: int = 8,
        dt_hours: float = 1.0,
    ) -> pd.DataFrame:
        """Vectorized computation of human exposure score E across all grid cells."""
        df = grid_df.copy()

        # Concentration above safe standard
        pm25_vals = df["pm25_est"].values if "pm25_est" in df.columns else np.full(len(df), 180.0)
        excess_c = np.maximum(0.0, pm25_vals - self.c_safe_pm25)

        # Base population
        base_pop = df["population"].values if "population" in df.columns else np.full(len(df), 2500.0)

        # Diurnal multipliers
        mult_school = float(self.diurnal_multipliers.get("school", {}).get(hour, 1.0))
        mult_market = float(self.diurnal_multipliers.get("market", {}).get(hour, 1.0))
        mult_res = float(self.diurnal_multipliers.get("residential", {}).get(hour, 1.0))

        land_use = df["primary_land_use"].values if "primary_land_use" in df.columns else np.array(["residential"] * len(df))
        diurnal_factors = np.where(
            land_use == "school_cluster",
            mult_school,
            np.where(land_use == "dense_residential", mult_market, mult_res),
        )

        pop_dynamic = base_pop * diurnal_factors

        # Vulnerability weights V(cell)
        v_weights = df["vulnerability_weight"].values if "vulnerability_weight" in df.columns else np.ones(len(df))

        # Vectorized formula: E = Excess * Pop * V * dt
        exposure_scores = excess_c * pop_dynamic * v_weights * dt_hours
        df["exposure_score"] = np.round(exposure_scores, 1)

        return df

    def get_ranked_hotspots(
        self,
        twin_grid_df: pd.DataFrame,
        top_n: int = 15,
        hour: int = 8,
        ward: Optional[str] = None,
        wind_speed_ms: float = 2.5,
        wind_dir_deg: float = 295.0,
    ) -> List[Hotspot]:
        """Rank hotspots by exposure and attach source attribution and back-trajectory pins."""
        scored_df = self.compute_exposure_scores(twin_grid_df, hour=hour)

        if ward and ward.lower() != "all":
            matched = scored_df[scored_df["ward"].str.lower() == ward.lower()]
            if not matched.empty:
                scored_df = matched

        # Filter cells with meaningful excess and rank
        top_cells = scored_df.sort_values("exposure_score", ascending=False).head(top_n)

        hotspots = []
        rank = 1
        for _, row in top_cells.iterrows():
            pm25 = float(row.get("pm25_est", 180.0))
            pm10 = float(row.get("pm10_est", 280.0))
            lat = float(row["latitude"])
            lon = float(row["longitude"])

            # Source attribution
            source_cls, conf, action = rule_attribution.classify_source(
                pm25=pm25,
                pm10=pm10,
                hour=hour,
                wind_dir_deg=wind_dir_deg,
            )

            # Upwind back-trajectory pin
            suspect_pin = calculate_upwind_suspect_pin(
                hotspot_lat=lat,
                hotspot_lon=lon,
                wind_speed_ms=wind_speed_ms,
                wind_direction_deg=wind_dir_deg,
            )

            hotspots.append(
                Hotspot(
                    cell_id=row["cell_id"],
                    rank=rank,
                    exposure_score=float(row["exposure_score"]),
                    pm25=pm25,
                    pm10=pm10,
                    cause=source_cls,
                    cause_confidence=conf,
                    recommended_asset=action,
                    suspect_pin=suspect_pin,
                    ward=row.get("ward"),
                )
            )
            rank += 1

        return hotspots


# Global instance
exposure_engine = ExposureEngine()


if __name__ == "__main__":
    from hawa_ml.twin.grid import load_grid
    grid = load_grid(500.0)
    grid["pm25_est"] = np.random.uniform(100.0, 320.0, size=len(grid))
    grid["pm10_est"] = grid["pm25_est"] * 1.6
    spots = exposure_engine.get_ranked_hotspots(grid, top_n=5)
    for s in spots:
        print(f"Rank {s.rank}: {s.cell_id} | Exposure: {s.exposure_score:.0f} person-hrs | Cause: {s.cause.value} -> Asset: {s.recommended_asset}")
