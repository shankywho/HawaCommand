"""Unit tests for Phase 1: Ingestion, caching, grids, and processed datasets."""
import pandas as pd
import numpy as np
import pytest

from hawa_ml.settings import settings
from hawa_ml.ingestion.openmeteo import OpenMeteoClient
from hawa_ml.ingestion.firms import FIRMSClient
from hawa_ml.ingestion.osm import OSMClient
from hawa_ml.ingestion.bus_routes_osm import load_bus_routes
from hawa_ml.twin.grid import load_grid


def test_processed_stations_hourly_dataset():
    p = settings.PROCESSED_DATA_DIR / "stations_hourly.parquet"
    assert p.exists(), "stations_hourly.parquet must exist"
    df = pd.read_parquet(p)
    assert len(df) > 1000
    expected_cols = ["timestamp", "station_id", "pm25", "pm10", "no2", "latitude", "longitude"]
    for col in expected_cols:
        assert col in df.columns

    # Verify no invalid non-physical negative PM values
    valid_pm25 = df["pm25"].dropna()
    assert (valid_pm25 >= 0).all()
    assert (valid_pm25 <= 1500).all()


def test_spatial_grids_with_covariates():
    grid_500 = load_grid(500.0)
    assert len(grid_500) > 1000
    assert "population" in grid_500.columns
    assert "vulnerability_weight" in grid_500.columns
    assert "nearest_school_dist_m" in grid_500.columns
    assert (grid_500["vulnerability_weight"] >= 0.4).all()
    assert (grid_500["population"] >= 0.0).all()

    grid_1000 = load_grid(1000.0)
    assert len(grid_1000) > 500
    assert (grid_1000["latitude"] >= 28.3).all()
    assert (grid_1000["longitude"] >= 76.8).all()


def test_openmeteo_client_offline_or_online():
    client = OpenMeteoClient()
    weather = client.fetch_weather_forecast(hours=24)
    assert len(weather) == 24
    assert "temperature_2m" in weather.columns
    assert "relative_humidity_2m" in weather.columns
    assert "wind_speed_10m" in weather.columns

    cams = client.fetch_cams_baseline(hours=24)
    assert len(cams) == 24
    assert "cams_pm25" in cams.columns


def test_firms_client_fire_features():
    client = FIRMSClient()
    feats = client.compute_upwind_fire_features(days=3)
    assert "fire_count_upwind_100km" in feats
    assert "fire_count_upwind_500km" in feats
    assert "frp_upwind_sum" in feats
    assert feats["fire_count_upwind_500km"] >= 0


def test_osm_pois_and_bus_routes():
    osm = OSMClient()
    pois = osm.fetch_pois()
    assert len(pois["schools"]) > 0
    assert len(pois["hospitals"]) > 0

    routes = load_bus_routes()
    assert len(routes) >= 4
    for r_name, pts in routes.items():
        assert len(pts) > 10
