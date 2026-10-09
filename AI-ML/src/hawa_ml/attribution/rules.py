"""Deterministic rule-based source attribution engine (F7).

Classifies pollution hotspots into:
- road_dust
- traffic
- open_burning
- regional_smoke
- industrial
- unknown

Uses multi-pollutant co-signals (PM2.5/PM10 ratio, NO2, CO, SO2, VOC),
time-of-day diurnal filters, and upwind fire detections from config/fingerprint_rules.yaml.
"""
from pathlib import Path
from typing import Dict, Optional, Tuple
import yaml

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.schemas import SourceClass

logger = configure_logging("attribution_rules")


class RuleBasedAttribution:
    def __init__(self):
        self.rules_path = settings.CONFIG_DIR / "fingerprint_rules.yaml"
        self.rules = self._load_rules()

    def _load_rules(self) -> dict:
        if self.rules_path.exists():
            with open(self.rules_path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f).get("sources", {})
        return {}

    def classify_source(
        self,
        pm25: float,
        pm10: float,
        no2_ppb: float = 35.0,
        co_ppb: float = 1200.0,
        so2_ppb: float = 8.0,
        voc_kohm: float = 45.0,
        hour: int = 10,
        wind_dir_deg: float = 295.0,
        upwind_fire_count: int = 0,
        city_wide_pm25: float = 180.0,
    ) -> Tuple[SourceClass, float, str]:
        """Classify hotspot source and return (SourceClass, confidence, recommended_action)."""
        ratio = pm25 / max(pm10, 1e-4)

        # 1. Regional agricultural smoke (Winter NW wind + massive upwind fire counts + city-wide elevated PM2.5)
        reg_rule = self.rules.get("regional_smoke", {})
        if (
            upwind_fire_count >= reg_rule.get("upwind_fire_count_min", 20)
            and 260.0 <= wind_dir_deg <= 340.0
            and ratio >= reg_rule.get("ratio_pm25_to_pm10_min", 0.70)
            and city_wide_pm25 >= reg_rule.get("city_wide_pm25_elevated_min", 160.0)
        ):
            conf = min(0.92, 0.75 + (upwind_fire_count / 100.0) * 0.15)
            return SourceClass.REGIONAL_SMOKE, round(conf, 2), "protect_people"

        # 2. Local open biomass / garbage burning (High PM2.5/PM10 ratio, nighttime/early morning, VOC spike)
        burn_rule = self.rules.get("open_burning", {})
        burn_hours = burn_rule.get("active_hours", [19, 20, 21, 22, 23, 0, 1, 2, 3, 4, 5, 6, 7])
        if ratio >= burn_rule.get("ratio_pm25_to_pm10_min", 0.68) and hour in burn_hours and pm25 > 180.0:
            conf = 0.82 if voc_kohm < 35.0 else 0.72  # Lower resistance = higher VOC
            return SourceClass.OPEN_BURNING, round(conf, 2), "inspection_team"

        # 3. Road & construction dust (Low PM2.5/PM10 ratio, daytime, high PM10)
        dust_rule = self.rules.get("road_dust", {})
        dust_hours = dust_rule.get("active_hours", list(range(7, 19)))
        if ratio <= dust_rule.get("ratio_pm25_to_pm10_max", 0.48) and hour in dust_hours and pm10 > 250.0:
            conf = min(0.88, 0.70 + (0.50 - ratio) * 0.4)
            return SourceClass.ROAD_DUST, round(conf, 2), "sprinkler"

        # 4. Vehicular traffic exhaust (High NO2 + CO during rush hours)
        traffic_rule = self.rules.get("traffic", {})
        rush_hours = traffic_rule.get("rush_hours", [8, 9, 10, 11, 17, 18, 19, 20, 21])
        if (
            (no2_ppb >= traffic_rule.get("no2_threshold_ppb_min", 40.0) or co_ppb >= 1800.0)
            and hour in rush_hours
            and 0.40 <= ratio <= 0.72
        ):
            conf = 0.75 if no2_ppb >= 55.0 else 0.68
            return SourceClass.TRAFFIC, round(conf, 2), "traffic_advisory"

        # 5. Industrial emissions (Elevated SO2 + industrial hours)
        ind_rule = self.rules.get("industrial", {})
        if so2_ppb >= ind_rule.get("so2_threshold_ppb_min", 25.0) and ratio >= 0.45:
            return SourceClass.INDUSTRIAL, 0.72, "industrial_inspection"

        # Default fallback
        if ratio <= 0.50:
            return SourceClass.ROAD_DUST, 0.55, "sprinkler"
        else:
            return SourceClass.UNKNOWN, 0.40, "monitor"


# Global instance
rule_attribution = RuleBasedAttribution()


if __name__ == "__main__":
    res = rule_attribution.classify_source(pm25=120.0, pm10=380.0, hour=11)
    print("Classified:", res)
    burn_res = rule_attribution.classify_source(pm25=280.0, pm10=320.0, hour=22, voc_kohm=25.0)
    print("Classified (night):", burn_res)
