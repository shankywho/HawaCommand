"""CPCB Air Quality Index (AQI) and CAQM GRAP Stage evaluation.

Calculates:
1. Sub-index per pollutant using linear interpolation across CPCB breakpoints.
2. Overall AQI = max(sub-indices) with dominant pollutant identification.
3. CAQM GRAP (Graded Response Action Plan) stage (Stage 1..4) with official actions.

All thresholds loaded strictly from config/cpcb_breakpoints.yaml and config/grap.yaml.
"""
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import yaml

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("grap")


class GRAPEngine:
    def __init__(self):
        self.cpcb_config = self._load_yaml(settings.CONFIG_DIR / "cpcb_breakpoints.yaml")
        self.grap_config = self._load_yaml(settings.CONFIG_DIR / "grap.yaml")

    @staticmethod
    def _load_yaml(path: Path) -> dict:
        if path.exists():
            with open(path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        return {}

    def calculate_sub_index(self, pollutant: str, concentration: float) -> Optional[float]:
        """Linearly interpolate AQI sub-index for a specific pollutant."""
        if concentration is None or concentration < 0:
            return None

        bps = self.cpcb_config.get("pollutant_breakpoints", {}).get(pollutant.lower(), [])
        if not bps:
            return None

        for bp in bps:
            b_lo = float(bp["b_lo"])
            b_hi = float(bp["b_hi"])
            i_lo = float(bp["i_lo"])
            i_hi = float(bp["i_hi"])

            if b_lo <= concentration <= b_hi:
                sub_index = ((i_hi - i_lo) / (b_hi - b_lo)) * (concentration - b_lo) + i_lo
                return float(sub_index)

        # Cap at maximum scale (500) if above highest bracket
        return 500.0

    def calculate_aqi(self, pm25: float, pm10: Optional[float] = None, no2: Optional[float] = None) -> Dict[str, any]:
        """Compute composite AQI and identify dominant pollutant."""
        sub_indices = {}
        idx_pm25 = self.calculate_sub_index("pm25", pm25)
        if idx_pm25 is not None:
            sub_indices["PM2.5"] = idx_pm25

        if pm10 is not None:
            idx_pm10 = self.calculate_sub_index("pm10", pm10)
            if idx_pm10 is not None:
                sub_indices["PM10"] = idx_pm10

        if no2 is not None:
            idx_no2 = self.calculate_sub_index("no2", no2)
            if idx_no2 is not None:
                sub_indices["NO2"] = idx_no2

        if not sub_indices:
            return {"aqi": 0, "category": "Good", "dominant_pollutant": "None"}

        dominant = max(sub_indices.items(), key=lambda x: x[1])
        aqi_val = int(round(dominant[1]))

        # Find category
        category = "Severe"
        ranges = self.cpcb_config.get("aqi_ranges", [])
        for r in ranges:
            if r["aqi_lo"] <= aqi_val <= r["aqi_hi"]:
                category = r["category"]
                break

        return {
            "aqi": aqi_val,
            "category": category,
            "dominant_pollutant": dominant[0],
            "sub_indices": {k: round(v, 1) for k, v in sub_indices.items()},
        }

    def evaluate_grap_stage(self, aqi: int, pm25: float, pm10: Optional[float] = None) -> Dict[str, any]:
        """Determine GRAP stage (Stage 1 to Stage 4) and associated municipal actions."""
        stages = self.grap_config.get("stages", {})

        # Check from Stage 4 down to Stage 1
        for stage_key in ["stage_4", "stage_3", "stage_2", "stage_1"]:
            stage_info = stages.get(stage_key, {})
            aqi_min = stage_info.get("aqi_min", 9999)
            pm25_min = stage_info.get("pm25_min", 9999)

            if aqi >= aqi_min or pm25 >= pm25_min:
                return {
                    "stage_key": stage_key,
                    "stage_name": stage_info.get("name", "Unknown"),
                    "stage_number": int(stage_key.split("_")[1]),
                    "lead_time_target_hours": stage_info.get("lead_time_target_hours", 24),
                    "actions": stage_info.get("actions", []),
                    "triggered_by": "AQI" if aqi >= aqi_min else "PM2.5",
                }

        return {
            "stage_key": "none",
            "stage_name": "Normal / Moderate",
            "stage_number": 0,
            "lead_time_target_hours": 0,
            "actions": ["Standard continuous ambient surveillance"],
            "triggered_by": "None",
        }


# Singleton instance
grap_engine = GRAPEngine()


if __name__ == "__main__":
    aqi_res = grap_engine.calculate_aqi(pm25=265.0, pm10=410.0)
    grap_res = grap_engine.evaluate_grap_stage(aqi=aqi_res["aqi"], pm25=265.0)
    print("AQI evaluation:", aqi_res)
    print(f"GRAP Stage: {grap_res['stage_name']} (Stage {grap_res['stage_number']})")
    print("Mandated actions:", grap_res["actions"][:2])
