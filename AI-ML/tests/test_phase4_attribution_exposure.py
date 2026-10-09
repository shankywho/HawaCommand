"""Unit tests for Phase 4: Source attribution, back-trajectory pins, and exposure engine."""
import numpy as np
import pandas as pd
import pytest

from hawa_ml.schemas import SourceClass
from hawa_ml.attribution.rules import rule_attribution
from hawa_ml.attribution.classifier import attribution_classifier
from hawa_ml.attribution.backtrajectory import calculate_upwind_suspect_pin
from hawa_ml.exposure.engine import exposure_engine
from hawa_ml.twin.grid import load_grid


def test_rule_based_attribution_classes():
    # 1. Road dust: Daytime, low PM2.5/PM10 ratio (0.35), high PM10
    src, conf, act = rule_attribution.classify_source(pm25=120.0, pm10=340.0, hour=11)
    assert src == SourceClass.ROAD_DUST
    assert act == "sprinkler"

    # 2. Open biomass burning: Nighttime, high PM2.5/PM10 ratio (0.85), high PM2.5
    src_b, conf_b, act_b = rule_attribution.classify_source(pm25=280.0, pm10=320.0, hour=23, voc_kohm=20.0)
    assert src_b == SourceClass.OPEN_BURNING
    assert act_b == "inspection_team"

    # 3. Traffic exhaust: Rush hour, high NO2
    src_t, conf_t, act_t = rule_attribution.classify_source(pm25=160.0, pm10=280.0, no2_ppb=65.0, hour=9)
    assert src_t == SourceClass.TRAFFIC
    assert act_t == "traffic_advisory"

    # 4. Regional smoke: Upwind fires, NW wind, city-wide PM2.5 spike
    src_r, conf_r, act_r = rule_attribution.classify_source(
        pm25=320.0, pm10=390.0, wind_dir_deg=305.0, upwind_fire_count=45, city_wide_pm25=280.0
    )
    assert src_r == SourceClass.REGIONAL_SMOKE
    assert act_r == "protect_people"


def test_back_trajectory_pin_calculation():
    pin = calculate_upwind_suspect_pin(
        hotspot_lat=28.6476,
        hotspot_lon=77.3158,
        wind_speed_ms=3.0,
        wind_direction_deg=315.0, # North-West
        lookback_hours=2.0,
    )
    assert pin.distance_m > 20000.0  # ~21.6 km
    assert pin.spread_m > 1000.0
    # Traveling North-West from Anand Vihar (28.64, 77.31) means lat increases, lon decreases
    assert pin.lat > 28.6476
    assert pin.lon < 77.3158


def test_exposure_engine_ranks_people_over_empty_cells():
    grid = load_grid(500.0).head(10).copy()

    # Cell 0: High AQI (PM2.5 = 450) but EMPTY industrial yard (Pop = 20, V = 0.4)
    grid.loc[0, "pm25_est"] = 450.0
    grid.loc[0, "population"] = 20.0
    grid.loc[0, "vulnerability_weight"] = 0.4
    grid.loc[0, "primary_land_use"] = "industrial_yard"

    # Cell 1: Moderate-High AQI (PM2.5 = 260) next to schools & hospitals (Pop = 8,000, V = 2.5)
    grid.loc[1, "pm25_est"] = 260.0
    grid.loc[1, "population"] = 8000.0
    grid.loc[1, "vulnerability_weight"] = 2.5
    grid.loc[1, "primary_land_use"] = "school_cluster"

    scored = exposure_engine.compute_exposure_scores(grid, hour=8)

    # Empty industrial cell exposure
    exp_industrial = scored.loc[0, "exposure_score"]
    # School cell exposure
    exp_school = scored.loc[1, "exposure_score"]

    # Fundamental premise of HawaCommand: Rank by exposure avoided, not raw AQI!
    assert exp_school > exp_industrial * 50
