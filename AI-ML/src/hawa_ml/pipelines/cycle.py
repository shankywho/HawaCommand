"""3-Hourly Operational Cycle Pipeline.

Sequence:
1. Ingest telemetry from mobile pods & reference stations
2. Calibrate sensor readings using drive-by profiles
3. Rebuild 500m digital twin with wind advection
4. Attribute source fingerprints & back-trajectory suspect pins
5. Predict 72h forecast & evaluate GRAP stage
6. Compute human exposure scores & rank hotspots
7. Scan proactive insight triggers & generate narratives
8. Draft exposure-first fleet dispatch plan
9. Audit plan programmatically & with Auditor Agent
"""
from datetime import datetime, timezone
from typing import Dict, List, Optional
import pandas as pd

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.schemas import AssetSpec, Hotspot, PlanTask
from hawa_ml.simulation.device_sim import FleetSimulator
from hawa_ml.twin.kriging import twin_engine
from hawa_ml.exposure.engine import exposure_engine
from hawa_ml.agents.planner_agent import planner_agent
from hawa_ml.agents.auditor_agent import auditor_agent
from hawa_ml.agents.forecaster_agent import forecaster_agent
from hawa_ml.insights.triggers import insight_trigger_engine
from hawa_ml.insights.narratives import narrative_generator

logger = configure_logging("cycle_pipeline")


def run_3hour_cycle() -> Dict[str, any]:
    """Execute complete 3-hour closed-loop decision cycle."""
    now = datetime.now(timezone.utc)
    logger.info(f"=== Starting HawaCommand 3-Hour Cycle [{now.strftime('%Y-%m-%d %H:%M:%S UTC')}] ===")

    # 1. Sense: Step simulation
    sim = FleetSimulator(n_buses=6, n_schools=2, n_sprinklers=1)
    packets = sim.step_simulation(now)
    logger.info(f"[1/6] Sensed {len(packets)} mobile and sentinel telemetry packets.")

    # 2. Map: Rebuild Digital Twin
    obs_points = [
        {"latitude": p.gps.lat, "longitude": p.gps.lon, "pm25": p.pm.pm25, "pm10": p.pm.pm10}
        for p in packets
    ]
    twin_grid = twin_engine.fit_and_predict(obs_points)
    logger.info(f"[2/6] Rebuilt 500m Digital Twin ({len(twin_grid)} cells updated).")

    # 3. Attribute & Exposure: Rank Hotspots
    twin_grid = exposure_engine.compute_exposure_scores(twin_grid, hour=now.hour)
    hotspots = exposure_engine.get_ranked_hotspots(twin_grid, top_n=8, hour=now.hour)
    logger.info(f"[3/6] Ranked top {len(hotspots)} exposure hotspots (Top cell: {hotspots[0].cell_id}, {hotspots[0].cause.value}).")

    # 4. Forecast & Risk
    top_cell = hotspots[0].cell_id
    forecast_res = forecaster_agent.analyze_forecast(top_cell, current_pm25=hotspots[0].pm25)
    logger.info(f"[4/6] 72h Forecast evaluated for {top_cell}: Peak P50={forecast_res['peak_pm25_p50']} ug/m3 ({forecast_res['grap_stage']}).")

    # 5. Proactive Insights & Narratives
    insights = insight_trigger_engine.scan_cycle_insights(twin_grid, forecast_points=forecast_res["points"])
    narratives = [narrative_generator.generate_narrative(ins) for ins in insights]
    logger.info(f"[5/6] Generated {len(insights)} operational insights and bilingual alerts.")

    # 6. Decide: Multi-Agent Dispatch Plan & Audit
    assets = [
        AssetSpec(id="SPR-04", type="sprinkler", depot_lat=28.6476, depot_lon=77.3000, capacity_litres=10000),
        AssetSpec(id="ASG-02", type="smog_gun", depot_lat=28.6740, depot_lon=77.1310, capacity_litres=8000),
        AssetSpec(id="INSP-01", type="inspection_team", depot_lat=28.6139, depot_lon=77.2090, capacity_litres=0),
    ]
    plan = planner_agent.draft_plan(assets, limit_hotspots=5)
    tasks = [PlanTask(**t) for t in plan["tasks"]]
    verdict, critique = auditor_agent.audit_plan(tasks, hotspots)
    plan["auditor_verdict"] = verdict
    plan["auditor_critique"] = critique
    logger.info(f"[6/6] Plan {plan['plan_id']} formulated ({verdict}): {len(tasks)} tasks avoiding {plan['total_exposure_avoided_person_hours']:.0f} person-hrs.")

    logger.info(f"=== HawaCommand 3-Hour Cycle Completed Successfully ===")
    return {
        "cycle_timestamp": now.isoformat(),
        "sensed_packets_count": len(packets),
        "hotspots_count": len(hotspots),
        "top_hotspot": hotspots[0].model_dump(),
        "forecast_summary": forecast_res["summary"],
        "plan": plan,
        "insights_count": len(insights),
    }


if __name__ == "__main__":
    run_3hour_cycle()
