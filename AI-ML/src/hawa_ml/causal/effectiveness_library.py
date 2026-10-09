"""Intervention Effectiveness Library (F18).

Stores empirical, causally-verified intervention outcomes:
(cause x action x conditions) -> effect_pct, duration_minutes, confidence_interval.
Persists across cycles so the Optimizer continuously learns what actually works where.
"""
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Optional
import json

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("effectiveness_library")


@dataclass
class EffectivenessRecord:
    cause: str  # road_dust | open_burning | traffic
    action: str  # water_sprinkler | smog_gun | sweeper | inspection_team
    conditions: str  # daytime_dry | night_humid | any
    pm10_reduction_pct: float
    pm25_reduction_pct: float
    duration_minutes: int
    ci_low_pct: float
    ci_high_pct: float
    sample_count: int = 1
    last_updated: str = ""


# Default prior empirical values from proposal and studies (IIT Delhi / CEEW)
DEFAULT_PRIORS = [
    EffectivenessRecord(
        cause="road_dust",
        action="water_sprinkler",
        conditions="daytime_dry",
        pm10_reduction_pct=18.5,
        pm25_reduction_pct=6.5,
        duration_minutes=90,
        ci_low_pct=13.0,
        ci_high_pct=24.0,
        sample_count=10,
    ),
    EffectivenessRecord(
        cause="road_dust",
        action="smog_gun",
        conditions="daytime_dry",
        pm10_reduction_pct=14.0,
        pm25_reduction_pct=5.0,
        duration_minutes=75,
        ci_low_pct=9.0,
        ci_high_pct=19.0,
        sample_count=8,
    ),
    EffectivenessRecord(
        cause="road_dust",
        action="sweeper",
        conditions="daytime_dry",
        pm10_reduction_pct=22.0,
        pm25_reduction_pct=4.0,
        duration_minutes=120,
        ci_low_pct=16.0,
        ci_high_pct=28.0,
        sample_count=5,
    ),
    EffectivenessRecord(
        cause="open_burning",
        action="inspection_team",
        conditions="night",
        pm10_reduction_pct=65.0,
        pm25_reduction_pct=70.0,
        duration_minutes=240,
        ci_low_pct=50.0,
        ci_high_pct=85.0,
        sample_count=12,
    ),
    EffectivenessRecord(
        cause="traffic",
        action="traffic_advisory",
        conditions="rush_hour",
        pm10_reduction_pct=8.0,
        pm25_reduction_pct=12.0,
        duration_minutes=180,
        ci_low_pct=4.0,
        ci_high_pct=16.0,
        sample_count=6,
    ),
]


class EffectivenessLibrary:
    def __init__(self):
        self.storage_path = settings.DATA_DIR / "internal" / "effectiveness_library.json"
        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        self.records: Dict[str, EffectivenessRecord] = {}
        self._load()

    def _get_key(self, cause: str, action: str) -> str:
        return f"{cause.lower()}:{action.lower()}"

    def _load(self):
        if self.storage_path.exists():
            try:
                with open(self.storage_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self.records = {k: EffectivenessRecord(**v) for k, v in data.items()}
                    return
            except Exception as e:
                logger.warning(f"Could not load library: {e}")

        # Seed with initial priors
        for rec in DEFAULT_PRIORS:
            key = self._get_key(rec.cause, rec.action)
            self.records[key] = rec
        self.save()

    def save(self):
        with open(self.storage_path, "w", encoding="utf-8") as f:
            json.dump({k: asdict(v) for k, v in self.records.items()}, f, indent=2)

    def lookup_expected_effect(self, cause: str, action: str) -> EffectivenessRecord:
        """Query expected reduction effect for an intervention."""
        key = self._get_key(cause, action)
        if key in self.records:
            return self.records[key]

        # Generic fallback
        return EffectivenessRecord(
            cause=cause,
            action=action,
            conditions="any",
            pm10_reduction_pct=12.0,
            pm25_reduction_pct=5.0,
            duration_minutes=60,
            ci_low_pct=5.0,
            ci_high_pct=20.0,
            sample_count=1,
        )

    def update_from_verification(
        self,
        cause: str,
        action: str,
        measured_effect_pct: float,
        duration_min: int,
        ci_low_pct: float,
        ci_high_pct: float,
    ):
        """Bayesian online update of effectiveness library following verified intervention."""
        key = self._get_key(cause, action)
        rec = self.lookup_expected_effect(cause, action)

        # Weighted running average
        n = rec.sample_count
        new_pm10_cut = (rec.pm10_reduction_pct * n + abs(measured_effect_pct)) / (n + 1)
        new_duration = int((rec.duration_minutes * n + duration_min) / (n + 1))

        rec.pm10_reduction_pct = round(new_pm10_cut, 1)
        rec.duration_minutes = new_duration
        rec.ci_low_pct = round(ci_low_pct, 1)
        rec.ci_high_pct = round(ci_high_pct, 1)
        rec.sample_count = n + 1

        self.records[key] = rec
        self.save()
        logger.info(
            f"Updated Effectiveness Library for {key}: expected PM cut = {rec.pm10_reduction_pct}%, "
            f"duration = {rec.duration_minutes} min (N={rec.sample_count})."
        )


# Global instance
effectiveness_library = EffectivenessLibrary()


if __name__ == "__main__":
    eff = effectiveness_library.lookup_expected_effect("road_dust", "water_sprinkler")
    print(f"Road Dust + Water Sprinkler -> Expected cut: {eff.pm10_reduction_pct}%, duration: {eff.duration_minutes} min")
