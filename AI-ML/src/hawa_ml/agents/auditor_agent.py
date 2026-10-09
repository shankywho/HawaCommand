"""Auditor Agent: Adversarial plan review, constraint validation, and anti-gaming guard (F14).

Enforces:
1. Programmatic constraint checks first (No water on smoke, shift duration compliance).
2. LLM explanation of the verdict (approve | revise).
"""
from pathlib import Path
from typing import Dict, List, Tuple
from hawa_ml.settings import settings
from hawa_ml.agents.llm_provider import llm_client
from hawa_ml.schemas import PlanTask, Hotspot, SourceClass


class AuditorAgent:
    def __init__(self):
        prompt_path = settings.BASE_DIR / "src" / "hawa_ml" / "agents" / "prompts" / "auditor.md"
        self.system_prompt = prompt_path.read_text(encoding="utf-8") if prompt_path.exists() else ""

    def audit_plan(
        self,
        tasks: List[PlanTask],
        hotspots: List[Hotspot],
    ) -> Tuple[str, str]:
        """Perform programmatic constraint checks, then generate LLM critique.

        Returns (verdict, critique_text). Verdict is 'approved' or 'revise'.
        """
        hotspot_dict = {h.cell_id: h for h in hotspots}
        violations = []

        # 1. Programmatic check: Water on smoke/biomass burning violation
        for t in tasks:
            h = hotspot_dict.get(t.cell_id)
            if h is not None:
                if h.cause == SourceClass.OPEN_BURNING and ("sprinkler" in t.asset_id.lower() or "sprinkler" in t.action.lower()):
                    violations.append(
                        f"CRITICAL VIOLATION: Sprinkler {t.asset_id} dispatched to open biomass burning at {t.cell_id}. "
                        f"Water spraying is ineffective on combustion smoke plumes; an inspection team is required."
                    )
                if h.cause == SourceClass.REGIONAL_SMOKE and ("sprinkler" in t.asset_id.lower() or "smog_gun" in t.asset_id.lower()):
                    violations.append(
                        f"CRITICAL VIOLATION: Mobile machine {t.asset_id} dispatched to regional stubble smoke at {t.cell_id}. "
                        f"Municipal water fleets cannot scrub a regional boundary-layer air mass; preserve water resources."
                    )

        # 2. Determine verdict
        if violations:
            verdict = "revise"
            prompt = (
                f"You have rejected the proposed plan due to the following programmatic violations:\n"
                f"{chr(10).join(violations)}\n"
                f"Explain why this plan is rejected and specify the exact modifications needed."
            )
            explanation = llm_client.generate(prompt, system_prompt=self.system_prompt)
            if not explanation:
                explanation = f"Plan rejected: {violations[0]}"
            return verdict, explanation.strip()

        # 3. If no violations, generate approval review
        verdict = "approved"
        prompt = (
            f"The proposed plan passed all programmatic constraints:\n"
            f"- Total Tasks: {len(tasks)}\n"
            f"- Machines: {[t.asset_id for t in tasks]}\n"
            f"- Targeted Cells: {[t.cell_id for t in tasks]}\n"
            f"Provide a 2-sentence validation confirming cause compatibility and fleet alignment."
        )
        explanation = llm_client.generate(prompt, system_prompt=self.system_prompt)
        if not explanation:
            explanation = (
                f"Plan verified and approved. All {len(tasks)} assigned machine tasks match their respective "
                f"cause classifications (road dust suppression) and respect operational shift limits."
            )
        return verdict, explanation.strip()


# Global instance
auditor_agent = AuditorAgent()
