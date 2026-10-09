"""Unit tests for Phase 6: Strands multi-agent command room, bilingual alerts, and insights."""
import pytest
from hawa_ml.schemas import AssetSpec, Hotspot, PlanTask, SourceClass, SuspectPin
from hawa_ml.agents.forecaster_agent import forecaster_agent
from hawa_ml.agents.planner_agent import planner_agent
from hawa_ml.agents.auditor_agent import auditor_agent
from hawa_ml.agents.communicator_agent import communicator_agent
from hawa_ml.insights.triggers import insight_trigger_engine
from hawa_ml.insights.narratives import narrative_generator
from hawa_ml.twin.grid import load_grid


def test_forecaster_agent_summary():
    res = forecaster_agent.analyze_forecast("G-052-054", current_pm25=230.0)
    assert "summary" in res
    assert len(res["summary"]) > 20
    assert "grap_stage" in res
    assert len(res["points"]) == 7


def test_planner_agent_proposal():
    assets = [
        AssetSpec(id="SPR-04", type="sprinkler", depot_lat=28.64, depot_lon=77.30, capacity_litres=8000),
    ]
    plan = planner_agent.draft_plan(assets, ward="all", limit_hotspots=5)
    assert plan["plan_id"].startswith("PLAN-")
    assert plan["status"] == "draft"
    assert len(plan["tasks"]) > 0
    assert "planner_reasoning" in plan


def test_auditor_agent_verdicts():
    # 1. Invalid plan: Sprinkler to open burning
    burning_hotspot = Hotspot(
        cell_id="G-BURN-99",
        rank=1,
        exposure_score=18000.0,
        pm25=290.0,
        pm10=310.0,
        cause=SourceClass.OPEN_BURNING,
        cause_confidence=0.88,
        recommended_asset="inspection_team",
    )
    bad_task = PlanTask(
        task_id="TASK-BAD",
        asset_id="SPR-01",
        cell_id="G-BURN-99",
        action="water_sprinkler",
        eta_start="2026-11-12T06:00:00Z",
        eta_end="2026-11-12T07:00:00Z",
        expected_pm_reduction_pct=18.0,
        reason="Bad allocation test",
    )
    verdict, critique = auditor_agent.audit_plan([bad_task], [burning_hotspot])
    assert verdict == "revise"
    assert "CRITICAL VIOLATION" in critique or "reject" in critique.lower()

    # 2. Valid plan: Sprinkler to road dust
    dust_hotspot = Hotspot(
        cell_id="G-DUST-01",
        rank=1,
        exposure_score=15000.0,
        pm25=120.0,
        pm10=420.0,
        cause=SourceClass.ROAD_DUST,
        cause_confidence=0.85,
        recommended_asset="water_sprinkler",
    )
    good_task = PlanTask(
        task_id="TASK-GOOD",
        asset_id="SPR-01",
        cell_id="G-DUST-01",
        action="water_sprinkler",
        eta_start="2026-11-12T06:00:00Z",
        eta_end="2026-11-12T07:00:00Z",
        expected_pm_reduction_pct=18.5,
        reason="Dust suppression at morning peak",
    )
    v_good, crit_good = auditor_agent.audit_plan([good_task], [dust_hotspot])
    assert v_good == "approved"


def test_communicator_agent_bilingual_advisory():
    alert = communicator_agent.draft_school_alert(
        school_name="Amity International School",
        cell_id="G-052-054",
        peak_pm25=265.0,
        safe_window_str="1:30 PM to 3:30 PM",
    )
    assert "english" in alert and len(alert["english"]) > 20
    assert "hindi" in alert and len(alert["hindi"]) > 20
    assert "1:30 PM to 3:30 PM" in alert["safe_window"]


def test_insight_triggers_and_narratives():
    grid = load_grid(500.0).head(20).copy()
    grid["pm25_est"] = 280.0
    grid["primary_land_use"] = "school_cluster"
    grid["schools_nearby_count"] = 4
    grid["population"] = 6000.0
    grid["exposure_score"] = 24000.0

    insights = insight_trigger_engine.scan_cycle_insights(twin_grid=grid)
    assert len(insights) > 0

    first_ins = insights[0]
    narrative = narrative_generator.generate_narrative(first_ins)
    assert "WHAT:" in narrative.narrative_en
    assert "WHERE:" in narrative.narrative_en
    assert "WHY:" in narrative.narrative_en
    assert "WHO:" in narrative.narrative_en
    assert "WHAT TO DO:" in narrative.narrative_en
    assert "EXPECTED EFFECT:" in narrative.narrative_en
    assert len(narrative.narrative_hi) > 10
