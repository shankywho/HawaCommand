"""Unit tests for Phase 2: Forecasting, baselines, evaluation, and GRAP mappings."""
import json
from pathlib import Path
import pytest

from hawa_ml.settings import settings
from hawa_ml.forecasting.grap import grap_engine
from hawa_ml.forecasting.predict import forecaster


def test_cpcb_aqi_and_grap_stages():
    # Good / Moderate range
    res_mod = grap_engine.calculate_aqi(pm25=45.0, pm10=80.0)
    assert res_mod["category"] in ["Satisfactory", "Moderate"]

    # Severe range (>250 PM2.5)
    res_sev = grap_engine.calculate_aqi(pm25=280.0, pm10=420.0)
    assert res_sev["aqi"] >= 400
    assert res_sev["category"] == "Severe"

    # Stage 3 evaluation (>400 AQI or >250 PM2.5)
    grap_sev = grap_engine.evaluate_grap_stage(aqi=res_sev["aqi"], pm25=280.0)
    assert grap_sev["stage_number"] >= 3
    assert len(grap_sev["actions"]) > 0


def test_forecast_metrics_and_persistence_skill():
    metrics_path = settings.REPORTS_DIR / "forecast_metrics.json"
    assert metrics_path.exists(), "forecast_metrics.json must be generated"

    with open(metrics_path, "r", encoding="utf-8") as f:
        metrics = json.load(f)

    for h in ["1h", "3h", "6h", "12h", "24h", "48h", "72h"]:
        assert h in metrics
        m = metrics[h]
        assert m["mae_p50"] > 0
        assert m["skill_vs_persistence_pct"] > 0, f"Model must beat persistence at {h}"
        assert 65.0 <= m["coverage_p10_p90_pct"] <= 95.0


def test_forecaster_live_prediction():
    preds = forecaster.predict_cell_forecast(cell_id="G-024-032", current_pm25=215.0)
    assert len(preds) == 7
    for p in preds:
        assert p["pm25_p10"] <= p["pm25_p50"] <= p["pm25_p90"]
        assert p["aqi_p50"] > 0
        assert p["grap_stage"] != ""
        assert len(p["mandated_actions"]) > 0
