"""Injected physical interventions with known ground-truth causal effects.

Allows the Causal Verifier (F18) to be validated against known mathematical ground truth.
Saves injected effects to data/internal/synthetic_data/known_interventions.json.
"""
from dataclasses import dataclass, asdict
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import json
import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.geo import haversine_distance_m

logger = configure_logging("interventions")


@dataclass
class InjectedIntervention:
    intervention_id: str
    asset_id: str
    action_type: str  # water_sprinkler | smog_gun | sweeper
    lat: float
    lon: float
    cell_id: str
    start_time: str
    end_time: str
    radius_m: float
    true_pm10_reduction_pct: float
    true_pm25_reduction_pct: float
    duration_minutes: int
    decay_half_life_min: float


class InterventionManager:
    def __init__(self):
        self.storage_path = settings.DATA_DIR / "internal" / "synthetic_data" / "known_interventions.json"
        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        self.interventions: List[InjectedIntervention] = []
        self._load()

    def _load(self):
        if self.storage_path.exists():
            try:
                with open(self.storage_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self.interventions = [InjectedIntervention(**d) for d in data]
            except Exception:
                self.interventions = []

    def save(self):
        with open(self.storage_path, "w", encoding="utf-8") as f:
            json.dump([asdict(i) for i in self.interventions], f, indent=2)

    def inject_default_demo_intervention(
        self,
        cell_id: str = "G-052-054",
        lat: float = 28.6476,
        lon: float = 77.3158,
        action: str = "water_sprinkler",
    ) -> InjectedIntervention:
        """Inject a realistic sprinkler spray with 18.5% PM10 reduction for verifier recovery testing."""
        now = datetime.now(timezone.utc)
        start = now - timedelta(hours=2)
        end = start + timedelta(minutes=45)

        interv = InjectedIntervention(
            intervention_id=f"INT-{now.strftime('%Y%m%d%H%M')}",
            asset_id="SPR-04",
            action_type=action,
            lat=lat,
            lon=lon,
            cell_id=cell_id,
            start_time=start.isoformat(),
            end_time=end.isoformat(),
            radius_m=350.0,
            true_pm10_reduction_pct=18.5,
            true_pm25_reduction_pct=6.2,
            duration_minutes=90,
            decay_half_life_min=45.0,
        )
        self.interventions.append(interv)
        self.save()
        logger.info(
            f"Injected intervention {interv.intervention_id}: {interv.true_pm10_reduction_pct}% "
            f"PM10 reduction at {cell_id} for {interv.duration_minutes} min."
        )
        return interv

    def get_attenuation(self, lat: float, lon: float, timestamp: datetime) -> Tuple[float, float]:
        """Calculate active PM2.5 and PM10 attenuation multipliers (1.0 = no effect, 0.8 = 20% cut)."""
        mult_pm25 = 1.0
        mult_pm10 = 1.0

        for interv in self.interventions:
            t_start = datetime.fromisoformat(interv.start_time)
            t_end = datetime.fromisoformat(interv.end_time)

            if timestamp < t_start:
                continue

            dist = haversine_distance_m(lat, lon, interv.lat, interv.lon)
            if dist > interv.radius_m:
                continue

            # Time elapsed since spray began
            elapsed_min = (timestamp - t_start).total_seconds() / 60.0
            if elapsed_min > interv.duration_minutes * 1.5:
                continue

            # Decay factor over time
            decay = 0.5 ** (elapsed_min / interv.decay_half_life_min)
            spatial_factor = max(0.0, 1.0 - (dist / interv.radius_m))

            cut10 = (interv.true_pm10_reduction_pct / 100.0) * decay * spatial_factor
            cut25 = (interv.true_pm25_reduction_pct / 100.0) * decay * spatial_factor

            mult_pm10 *= (1.0 - cut10)
            mult_pm25 *= (1.0 - cut25)

        return float(mult_pm25), float(mult_pm10)
