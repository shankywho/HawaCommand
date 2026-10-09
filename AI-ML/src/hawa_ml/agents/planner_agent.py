"""Planner Agent: Designs exposure-first fleet dispatch proposals (F14)."""
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime, timezone
from hawa_ml.settings import settings
from hawa_ml.agents.llm_provider import llm_client
from hawa_ml.agents.tools import tool_get_hotspots, tool_run_optimizer, tool_simulate_whatif
from hawa_ml.schemas import AssetSpec, Hotspot, PlanTask, PlanDraft


class PlannerAgent:
    def __init__(self):
        prompt_path = settings.BASE_DIR / "src" / "hawa_ml" / "agents" / "prompts" / "planner.md"
        self.system_prompt = prompt_path.read_text(encoding="utf-8") if prompt_path.exists() else ""

    def draft_plan(
        self,
        assets: List[AssetSpec],
        ward: str = "all",
        limit_hotspots: int = 10,
        shift_hours: float = 4.0,
    ) -> Dict[str, any]:
        """Fetch hotspots, run optimizer, and draft plan with reasoning."""
        hotspots = tool_get_hotspots(ward=ward, limit=limit_hotspots)
        opt_res = tool_run_optimizer(hotspots, assets, shift_hours=shift_hours)

        raw_tasks = opt_res["tasks"]
        avoided_ph = opt_res["total_exposure_avoided_person_hours"]

        tasks = [PlanTask(**t) for t in raw_tasks]

        prompt = (
            f"Explain the tactical rationale for this draft dispatch plan:\n"
            f"- Total Hotspots Analyzed: {len(hotspots)}\n"
            f"- Tasks Scheduled: {len(tasks)}\n"
            f"- Total Person-Hours Exposure Avoided: {avoided_ph:.1f}\n"
            f"- Assigned Tasks: {[f'{t.asset_id} to {t.cell_id} ({t.action})' for t in tasks]}\n"
            f"Provide a 2-sentence rationale focusing on why school/hospital clusters were prioritized."
        )

        reasoning = llm_client.generate(prompt, system_prompt=self.system_prompt)
        if not reasoning:
            reasoning = (
                f"Dispatched {len(tasks)} machines targeting {avoided_ph:.0f} person-hours of exposure avoided. "
                f"Fleet routes are prioritized around morning school assembly hours and vulnerable pediatric zones."
            )

        now_str = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M")
        return {
            "plan_id": f"PLAN-{now_str}",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "status": "draft",
            "total_exposure_avoided_person_hours": avoided_ph,
            "tasks": [t.model_dump() for t in tasks],
            "planner_reasoning": reasoning.strip(),
            "hotspots": [h.model_dump() for h in hotspots],
        }


# Global instance
planner_agent = PlannerAgent()
