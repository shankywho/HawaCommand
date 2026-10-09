"""Tool wrappers for Multi-Agent Command Room (F14).

All numbers strictly originate from deterministic models and algorithms.
Agents invoke these tools to obtain verified facts and structured Pydantic data.
"""
from typing import Dict, List, Optional
from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.schemas import Hotspot, AssetSpec, PlanTask
from hawa_ml.forecasting.predict import forecaster
from hawa_ml.forecasting.grap import grap_engine
from hawa_ml.exposure.engine import exposure_engine
from hawa_ml.twin.grid import load_grid
from hawa_ml.optimization.vrp import vrp_optimizer
from hawa_ml.optimization.whatif import whatif_simulator
from hawa_ml.causal.effectiveness_library import effectiveness_library

logger = configure_logging("agent_tools")


def tool_get_forecast(cell_id: str, current_pm25: float = 210.0) -> List[dict]:
    """Retrieve 72-hour P10/P50/P90 forecast and GRAP stages."""
    logger.info(f"[Tool: get_forecast] Querying cell {cell_id}...")
    return forecaster.predict_cell_forecast(cell_id, current_pm25=current_pm25)


def tool_get_hotspots(ward: str = "all", limit: int = 10) -> List[Hotspot]:
    """Retrieve top pollution hotspots ranked by human exposure."""
    logger.info(f"[Tool: get_hotspots] Querying ward '{ward}', limit {limit}...")
    grid = load_grid(500.0)
    return exposure_engine.get_ranked_hotspots(grid, top_n=limit, ward=ward)


def tool_run_optimizer(
    hotspots: List[Hotspot],
    assets: List[AssetSpec],
    shift_hours: float = 4.0,
) -> Dict[str, any]:
    """Run CVRP vehicle routing optimizer to allocate fleet to cause-matched hotspots."""
    logger.info(f"[Tool: run_optimizer] Solving for {len(hotspots)} hotspots and {len(assets)} assets...")
    tasks, avoided_ph = vrp_optimizer.solve_dispatch_plan(hotspots, assets, shift_hours=shift_hours)
    return {
        "tasks": [t.model_dump() for t in tasks],
        "total_exposure_avoided_person_hours": avoided_ph,
    }


def tool_simulate_whatif(
    hotspots: List[Hotspot],
    assets: List[AssetSpec],
    tasks: List[PlanTask],
) -> Dict[str, any]:
    """Simulate person-hours avoided comparison against usual fixed routes baseline."""
    logger.info("[Tool: simulate_whatif] Comparing AI plan vs baseline...")
    return whatif_simulator.simulate_comparison(hotspots, assets, ai_tasks=tasks)


def tool_get_effectiveness(cause: str, action: str) -> dict:
    """Query expected PM reduction percentage and duration from library."""
    rec = effectiveness_library.lookup_expected_effect(cause, action)
    return {
        "pm10_reduction_pct": rec.pm10_reduction_pct,
        "pm25_reduction_pct": rec.pm25_reduction_pct,
        "duration_minutes": rec.duration_minutes,
        "ci_low_pct": rec.ci_low_pct,
        "ci_high_pct": rec.ci_high_pct,
    }
