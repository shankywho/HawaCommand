"""Communicator Agent: Generates bilingual (English & Hindi) pollutant-specific advisories (F14, F16)."""
from pathlib import Path
from typing import Dict, Optional
from hawa_ml.settings import settings
from hawa_ml.agents.llm_provider import llm_client
from hawa_ml.schemas import Narrative


class CommunicatorAgent:
    def __init__(self):
        prompt_path = settings.BASE_DIR / "src" / "hawa_ml" / "agents" / "prompts" / "communicator.md"
        self.system_prompt = prompt_path.read_text(encoding="utf-8") if prompt_path.exists() else ""

    def draft_school_alert(
        self,
        school_name: str,
        cell_id: str,
        peak_pm25: float,
        dominant_pollutant: str = "PM2.5",
        peak_time_str: str = "8:00 AM Thursday",
        safe_window_str: str = "1:00 PM to 3:30 PM",
    ) -> Dict[str, str]:
        """Generate targeted English and Hindi early warning alerts for school principals."""
        prompt = (
            f"Draft a Japan-style targeted air quality advisory for {school_name} (Cell {cell_id}):\n"
            f"- Forecast Peak: {dominant_pollutant} reaching {peak_pm25:.0f} ug/m3 at {peak_time_str}\n"
            f"- Recommended Actions: Move morning assembly indoors, seal classrooms, run purifiers\n"
            f"- Safe Outdoor Window for PE/Sports: {safe_window_str}\n"
            f"Provide two sections: 1. English Alert, 2. Hindi Alert (हिंदी चेतावनी)."
        )

        llm_out = llm_client.generate(prompt, system_prompt=self.system_prompt)

        # High-quality natural templates for fallback
        en_fallback = (
            f"AIR ADVISORY for {school_name}: {dominant_pollutant} levels are forecasted to spike to "
            f"{peak_pm25:.0f} µg/m³ around {peak_time_str}. Please conduct morning assembly indoors "
            f"and keep classroom windows closed. Safe outdoor activity window: {safe_window_str}."
        )

        hi_fallback = (
            f"{school_name} के लिए वायु गुणवत्ता चेतावनी: {peak_time_str} के आसपास {dominant_pollutant} "
            f"का स्तर {peak_pm25:.0f} µg/m³ तक पहुँचने का अनुमान है। कृपया सुबह की प्रार्थना सभा "
            f"कमरों के अंदर आयोजित करें और खिड़कियाँ बंद रखें। बाहरी खेलकूद के लिए सुरक्षित समय: {safe_window_str}।"
        )

        if llm_out and "हिंदी" in llm_out:
            # Parse sections or return full response
            return {
                "english": en_fallback if len(llm_out) < 40 else llm_out.strip(),
                "hindi": hi_fallback,
                "safe_window": safe_window_str,
            }

        return {
            "english": en_fallback,
            "hindi": hi_fallback,
            "safe_window": safe_window_str,
        }


# Global instance
communicator_agent = CommunicatorAgent()


if __name__ == "__main__":
    alert = communicator_agent.draft_school_alert("Delhi Public School Mathura Road", "G-052-054", 280.0)
    print("English Alert:\n", alert["english"])
    print("\nHindi Alert:\n", alert["hindi"])
