"""Unit tests for Phase 3: Simulator, noise models, drive-by calibration, and digital twin."""
from datetime import datetime, timezone
import json
import numpy as np
import pytest

from hawa_ml.settings import settings
from hawa_ml.simulation.noise_models import SensorNoiseModel
from hawa_ml.simulation.device_sim import FleetSimulator
from hawa_ml.calibration.drive_by import DriveByCalibrator
from hawa_ml.twin.kriging import twin_engine


def test_sensor_noise_and_humidity_growth():
    noise_model = SensorNoiseModel("HPM-TEST-42")
    true_pm25 = 150.0
    true_pm10 = 250.0

    # Low humidity (50%)
    pm25_dry, pm10_dry, flags_dry = noise_model.apply_pm_noise(true_pm25, true_pm10, rh=50.0)
    assert "heater_on" not in flags_dry

    # High humidity (90% winter fog)
    pm25_humid, pm10_humid, flags_humid = noise_model.apply_pm_noise(true_pm25, true_pm10, rh=90.0)
    assert "heater_on" in flags_humid
    # Swelling causes higher observed PM in optical sensors
    assert pm25_humid > pm25_dry * 0.95


def test_fleet_simulator_packet_stream():
    sim = FleetSimulator(n_buses=4, n_schools=2, n_sprinklers=1)
    now = datetime.now(timezone.utc)
    packets = sim.step_simulation(now)
    assert len(packets) >= 6

    # Verify packet format adheres to Proposal §10.6
    for pkt in packets:
        assert pkt.v == 1
        assert pkt.dev != ""
        assert pkt.role in ["M", "S", "TAG"]
        assert pkt.gps.lat > 28.0
        assert pkt.gps.lon > 76.5
        assert pkt.pm.pm25 > 0.0
        assert pkt.env.rh > 0.0


def test_drive_by_calibration_fitting():
    calibrator = DriveByCalibrator()
    true_ref = np.array([120.0, 150.0, 180.0, 210.0, 240.0, 270.0, 300.0, 330.0, 360.0, 390.0])
    rh = np.array([60.0, 65.0, 70.0, 75.0, 80.0, 85.0, 90.0, 85.0, 80.0, 75.0])
    raw = (true_ref - 10.0) / 1.1 + (rh * 0.1)

    prof = calibrator.fit_calibration("HPM-TEST-CALIB", raw, rh, true_ref)
    assert prof.version >= 2
    assert prof.trust_score > 0.5
    cal_val, trust = calibrator.calibrate_reading("HPM-TEST-CALIB", raw[0], rh[0])
    assert abs(cal_val - true_ref[0]) < 25.0


def test_digital_twin_spatial_prediction():
    obs = [
        {"latitude": 28.6315, "longitude": 77.2167, "pm25": 230.0, "pm10": 380.0},
        {"latitude": 28.5672, "longitude": 77.2100, "pm25": 190.0, "pm10": 310.0},
        {"latitude": 28.6740, "longitude": 77.1310, "pm25": 280.0, "pm10": 460.0},
    ]
    grid_res = twin_engine.fit_and_predict(obs, wind_speed_ms=2.0, wind_dir_deg=300.0)
    assert len(grid_res) > 5000
    assert "pm25_est" in grid_res.columns
    assert "variance" in grid_res.columns
    assert "confidence" in grid_res.columns
    assert (grid_res["confidence"] >= 0.20).all()
    assert (grid_res["confidence"] <= 0.99).all()

    report_p = settings.REPORTS_DIR / "twin_metrics.json"
    assert report_p.exists()
