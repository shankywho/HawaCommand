"""Unit tests for Phase 5: Dispatch optimizer, What-If simulation, and Causal Verifier."""
import numpy as np
import pytest

from hawa_ml.schemas import Hotspot, AssetSpec, SourceClass, SuspectPin
from hawa_ml.causal.effectiveness_library import effectiveness_library
from hawa_ml.causal.placebo import verify_injected_intervention_recovery, run_placebo_test
from hawa_ml.optimization.vrp import vrp_optimizer
from hawa_ml.optimization.whatif import whatif_simulator


def test_causal_verifier_recovers_injected_effect():
    """Acceptance test: recovered effect matches known ground-truth within tolerance."""
    res = verify_injected_intervention_recovery()
    assert res["passed"] is True
    assert res["error"] <= 3.5
    assert res["ci_low"] <= res["injected_pct"] <= res["ci_high"]


def test_effectiveness_library_lookup_and_update():
    rec = effectiveness_library.lookup_expected_effect("road_dust", "water_sprinkler")
    assert rec.pm10_reduction_pct > 10.0
    assert rec.duration_minutes >= 60

    old_cut = rec.pm10_reduction_pct
    effectiveness_library.update_from_verification(
        cause="road_dust",
        action="water_sprinkler",
        measured_effect_pct=-20.0,
        duration_min=90,
        ci_low_pct=-25.0,
        ci_high_pct=-15.0,
    )
    rec_updated = effectiveness_library.lookup_expected_effect("road_dust", "water_sprinkler")
    assert rec_updated.sample_count > 1


def test_optimizer_respects_cause_compatibility():
    """Auditing constraint: Sprinklers must NOT be allocated to open burning smoke!"""
    hotspots = [
        Hotspot(
            cell_id="G-BURN-01",
            rank=1,
            exposure_score=25000.0,
            pm25=300.0,
            pm10=320.0,
            cause=SourceClass.OPEN_BURNING,
            cause_confidence=0.88,
            recommended_asset="inspection_team",
            suspect_pin=SuspectPin(lat=28.62, lon=77.21, distance_m=200.0, spread_m=90.0),
        ),
        Hotspot(
            cell_id="G-DUST-02",
            rank=2,
            exposure_score=20000.0,
            pm25=120.0,
            pm10=450.0,
            cause=SourceClass.ROAD_DUST,
            cause_confidence=0.84,
            recommended_asset="water_sprinkler",
            suspect_pin=SuspectPin(lat=28.64, lon=77.30, distance_m=300.0, spread_m=110.0),
        ),
    ]

    assets = [
        AssetSpec(id="SPR-01", type="sprinkler", depot_lat=28.63, depot_lon=77.22, capacity_litres=8000),
        AssetSpec(id="INSP-01", type="inspection_team", depot_lat=28.61, depot_lon=77.20, capacity_litres=0),
    ]

    tasks, total_val = vrp_optimizer.solve_dispatch_plan(hotspots, assets)
    assert len(tasks) == 2
    for t in tasks:
        if t.asset_id == "SPR-01":
            assert t.cell_id == "G-DUST-02", "Sprinkler must only be dispatched to dust, NOT smoke burning!"
        if t.asset_id == "INSP-01":
            assert t.cell_id == "G-BURN-01", "Inspection team must target the open burning hotspot!"


def test_what_if_simulator_proves_exposure_avoidance_gain():
    hotspots = [
        Hotspot(
            cell_id="G-DUST-01",
            rank=1,
            exposure_score=35000.0,
            pm25=140.0,
            pm10=480.0,
            cause=SourceClass.ROAD_DUST,
            cause_confidence=0.85,
            recommended_asset="water_sprinkler",
            suspect_pin=SuspectPin(lat=28.64, lon=77.30, distance_m=300.0, spread_m=110.0),
        )
    ]
    assets = [AssetSpec(id="SPR-01", type="sprinkler", depot_lat=28.63, depot_lon=77.22, capacity_litres=8000)]

    comparison = whatif_simulator.simulate_comparison(hotspots, assets)
    assert comparison["ai_plan"]["person_hours_avoided"] > comparison["usual_fixed_route_baseline"]["person_hours_avoided"]
    assert comparison["comparison"]["gain_percentage"] > 100.0
