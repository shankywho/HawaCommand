"""Breath Safe Window: Diurnal atmospheric inversion and outdoor opportunity modeling.

Models Delhi's diurnal boundary layer dynamics:
1. Nocturnal/Morning shallow inversion layer (05:00 - 09:30): traps pollution near the surface.
2. Afternoon solar convective mixing (13:00 - 17:00): boundary layer height deepens 3-4x, diluting PM2.5.
3. Evening nocturnal inversion reformation (18:30 - 23:00): secondary compression.

Provides continuous safe outdoor windows personalized by health vulnerability.
"""
from __future__ import annotations
from typing import Dict, List, Any


PERSONA_THRESHOLDS: Dict[str, Dict[str, Any]] = {
    "asthma_elderly": {
        "max_safe_pm25": 100.0,
        "label": "Asthma / Respiratory / Seniors",
        "description": "High sensitivity; strict particulate thresholds to prevent bronchospasms.",
    },
    "children_school": {
        "max_safe_pm25": 140.0,
        "label": "School Children / Pediatric",
        "description": "Developing lungs; outdoors safe only during convective mixing window.",
    },
    "runners_athletes": {
        "max_safe_pm25": 160.0,
        "label": "Runners & Outdoor Fitness",
        "description": "Elevated minute ventilation (30-40 L/min); avoid morning peak inversion.",
    },
    "general": {
        "max_safe_pm25": 200.0,
        "label": "General Public",
        "description": "Standard precautionary standard under CPCB GRAP guidelines.",
    },
}


class SafeWindowCalculator:
    """Calculates diurnal air quality timeline and personalized safe windows."""

    def __init__(self, baseline_pm25: float = 260.0):
        self.baseline_pm25 = baseline_pm25

    def compute_daily_window(
        self,
        lat: float = 28.6139,
        lon: float = 77.2090,
        persona: str = "general",
    ) -> Dict[str, Any]:
        """Generate a 24-hour diurnal curve and identify the optimal safe outdoor window."""
        persona_key = persona.lower() if persona.lower() in PERSONA_THRESHOLDS else "general"
        config = PERSONA_THRESHOLDS[persona_key]
        threshold = config["max_safe_pm25"]

        # Diurnal multipliers reflecting winter Delhi inversion
        # Hour 0 to 23
        multipliers = [
            1.15, 1.20, 1.25, 1.30, 1.38, 1.45,  # 00:00 - 05:00
            1.55, 1.62, 1.58, 1.40, 1.15, 0.95,  # 06:00 - 11:00 (Morning inversion peak)
            0.78, 0.65, 0.58, 0.60, 0.68, 0.82,  # 12:00 - 17:00 (Afternoon convective dilution window)
            1.05, 1.22, 1.30, 1.28, 1.20, 1.15,  # 18:00 - 23:00 (Evening traffic + cooling inversion)
        ]

        hours_data = []
        safe_hours = []

        for h, mult in enumerate(multipliers):
            est_pm25 = round(self.baseline_pm25 * mult, 1)
            is_safe = est_pm25 <= threshold
            
            if est_pm25 <= 60:
                band = "Good"
                color = "#1E8A4C"
            elif est_pm25 <= 120:
                band = "Moderate"
                color = "#B8920A"
            elif est_pm25 <= 250:
                band = "Poor"
                color = "#D0690E"
            elif est_pm25 <= 350:
                band = "Very Poor"
                color = "#C02A2A"
            else:
                band = "Severe"
                color = "#7F1D3A"

            hour_str = f"{h:02d}:00"
            hours_data.append({
                "hour": h,
                "time_label": hour_str,
                "pm25": est_pm25,
                "band": band,
                "color": color,
                "is_safe": is_safe,
                "inversion_risk": "HIGH" if h in [5, 6, 7, 8, 9] else ("MODERATE" if h in [19, 20, 21] else "LOW"),
            })

            if is_safe:
                safe_hours.append(h)

        # Find continuous safe window in the afternoon
        if safe_hours:
            best_start = safe_hours[0]
            best_end = safe_hours[-1] + 1
            # Filter specifically around the solar convective window (12:00 - 18:00)
            solar_window = [h for h in safe_hours if 12 <= h <= 18]
            if solar_window:
                start_h = solar_window[0]
                end_h = solar_window[-1] + 1
                recommended_window = f"{start_h:02d}:00 - {end_h:02d}:00"
                min_pm25 = min(hours_data[h]["pm25"] for h in solar_window)
            else:
                recommended_window = f"{best_start:02d}:00 - {best_end:02d}:00"
                min_pm25 = min(hours_data[h]["pm25"] for h in safe_hours)
            has_window = True
        else:
            # Fallback to the lowest hour of the day
            lowest_h = min(range(24), key=lambda i: hours_data[i]["pm25"])
            recommended_window = f"{lowest_h:02d}:00 - {lowest_h+2:02d}:00"
            min_pm25 = hours_data[lowest_h]["pm25"]
            has_window = False

        return {
            "persona": persona_key,
            "persona_label": config["label"],
            "threshold_pm25": threshold,
            "has_safe_window": has_window,
            "recommended_window": recommended_window,
            "lowest_pm25": min_pm25,
            "danger_window": "06:00 - 09:30",
            "peak_pm25": max(item["pm25"] for item in hours_data),
            "recommendation": (
                f"Air is safest between {recommended_window} when solar thermal heating dilutes ground particulates. "
                f"Avoid outdoor exertion from 06:00 - 09:30 AM during morning cold inversion."
            ),
            "timeline": hours_data,
        }


safe_window_calculator = SafeWindowCalculator()
