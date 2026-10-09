"""Forecaster Agent: Interprets 72-hour quantile forecasts and warns of GRAP stage crossings (F14)."""
from pathlib import Path
from typing import Dict, List
from hawa_ml.settings import settings
from hawa_ml.agents.llm_provider import llm_client
from hawa_ml.agents.tools import tool_get_forecast


class ForecasterAgent:
    def __init__(self):
        prompt_path = settings.BASE_DIR / "src" / "hawa_ml" / "agents" / "prompts" / "forecaster.md"
        self.system_prompt = prompt_path.read_text(encoding="utf-8") if prompt_path.exists() else ""

    def analyze_forecast(self, cell_id: str, current_pm25: float = 210.0) -> Dict[str, any]:
        """Fetch forecast from tool and generate executive atmospheric risk summary."""
        forecast_points = tool_get_forecast(cell_id, current_pm25=current_pm25)

        # Identify peak horizon and worst GRAP stage
        peak_point = max(forecast_points, key=lambda x: x["pm25_p50"])
        highest_grap = max(forecast_points, key=lambda x: x["grap_stage_number"])

        prompt = (
            f"Analyze this 72-hour forecast for cell {cell_id}:\n"
            f"- Current PM2.5: {current_pm25} ug/m3\n"
            f"- Forecast Peak: PM2.5 P50={peak_point['pm25_p50']} ug/m3 (P90={peak_point['pm25_p90']}) at +{peak_point['horizon_h']}h\n"
            f"- Triggered GRAP Stage: {highest_grap['grap_stage']} (Stage {highest_grap['grap_stage_number']})\n"
            f"- Mandated Stage Actions: {highest_grap['mandated_actions'][:2]}\n"
            f"Provide a 3-sentence executive risk assessment. Do not change any numbers."
        )

        llm_response = llm_client.generate(prompt, system_prompt=self.system_prompt)
        if not llm_response:
            # Deterministic template fallback
            llm_response = (
                f"Cell {cell_id} is projected to peak at PM2.5 {peak_point['pm25_p50']} µg/m³ "
                f"(P90 {peak_point['pm25_p90']} µg/m³) in +{peak_point['horizon_h']} hours. "
                f"This triggers CAQM {highest_grap['grap_stage']} at an AQI of {peak_point['aqi_p50']}. "
                f"Municipal actions should initiate 24-48h ahead to suppress particulate build-up before morning school hours."
            )

        return {
            "cell_id": cell_id,
            "peak_horizon_h": peak_point["horizon_h"],
            "peak_pm25_p50": peak_point["pm25_p50"],
            "peak_pm25_p90": peak_point["pm25_p90"],
            "grap_stage": highest_grap["grap_stage"],
            "grap_stage_number": highest_grap["grap_stage_number"],
            "mandated_actions": highest_grap["mandated_actions"],
            "summary": llm_response.strip(),
            "points": forecast_points,
            "horizons": forecast_points,
        }



# Global instance
forecaster_agent = ForecasterAgent()
