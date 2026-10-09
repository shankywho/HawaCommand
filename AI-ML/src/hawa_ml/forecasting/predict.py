"""Forecaster inference engine for live predictions and GRAP alert outlooks.

Loads trained LightGBM quantile models from models/ and outputs P10/P50/P90 forecasts
coupled with CPCB AQI and CAQM GRAP stage evaluations.
"""
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Dict, List, Optional
import numpy as np
import pandas as pd
import lightgbm as lgb

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.schemas import ForecastPoint
from hawa_ml.forecasting.grap import grap_engine
from hawa_ml.forecasting.features import DEFAULT_HORIZONS

logger = configure_logging("forecast_predict")


class ForecastPredictor:
    def __init__(self):
        self.models_dir = settings.MODELS_DIR
        self._models: Dict[str, lgb.Booster] = {}
        self._load_models()

    def _load_models(self):
        """Pre-load LightGBM booster models from disk."""
        for h in DEFAULT_HORIZONS:
            for q in ["p10", "p50", "p90"]:
                key = f"{h}h_{q}"
                path = self.models_dir / f"lgb_pm25_{h}h_{q}.txt"
                if path.exists():
                    try:
                        self._models[key] = lgb.Booster(model_file=str(path))
                    except Exception as e:
                        logger.warning(f"Failed to load model {key}: {e}")

    def predict_cell_forecast(
        self,
        cell_id: str,
        current_pm25: float = 210.0,
        current_pm10: float = 330.0,
        temp: float = 19.5,
        rh: float = 75.0,
        ws: float = 2.4,
        wd: float = 295.0,
        base_time: Optional[datetime] = None,
    ) -> List[Dict[str, any]]:
        """Generate 72-hour forecast points with P10/P50/P90, AQI, and GRAP stage."""
        if base_time is None:
            base_time = datetime.now(timezone.utc)

        results = []
        for h in DEFAULT_HORIZONS:
            valid_time = base_time + timedelta(hours=h)
            h_hour = valid_time.hour

            # Check if trained models are available
            p10_model = self._models.get(f"{h}h_p10")
            p50_model = self._models.get(f"{h}h_p50")
            p90_model = self._models.get(f"{h}h_p90")

            if p50_model is not None and p10_model is not None and p90_model is not None:
                # Construct feature vector
                sin_h = np.sin(2 * np.pi * h_hour / 24.0)
                cos_h = np.cos(2 * np.pi * h_hour / 24.0)
                sin_m = np.sin(2 * np.pi * valid_time.month / 12.0)
                cos_m = np.cos(2 * np.pi * valid_time.month / 12.0)
                is_wk = 1.0 if valid_time.weekday() >= 5 else 0.0
                is_inv = 1.0 if valid_time.month in [11, 12, 1] else 0.0

                wd_rad = np.radians(wd)
                u = -ws * np.sin(wd_rad)
                v = -ws * np.cos(wd_rad)
                fire_proxy = is_inv * max(0.0, u * 0.5 - v * 0.5) * 15.0

                # Feature array matching feature_cols in features.py
                feats = [
                    sin_h, cos_h, sin_m, cos_m, is_wk, is_inv,
                    u, v, temp, rh, fire_proxy,
                    # Lags [1, 2, 3, 6, 12, 24, 48]
                    current_pm25, current_pm25, current_pm25, current_pm25, current_pm25, current_pm25, current_pm25,
                    current_pm10, current_pm10, current_pm10, current_pm10, current_pm10, current_pm10, current_pm10,
                    # Rolling stats [3, 6, 12, 24]
                    current_pm25, 12.0, current_pm25 * 1.1,
                    current_pm25, 15.0, current_pm25 * 1.15,
                    current_pm25, 20.0, current_pm25 * 1.25,
                    current_pm25, 25.0, current_pm25 * 1.35,
                ]
                X = np.array([feats])
                p10 = float(np.clip(p10_model.predict(X)[0], 10.0, 1500.0))
                p50 = float(np.clip(p50_model.predict(X)[0], 15.0, 1500.0))
                p90 = float(np.clip(p90_model.predict(X)[0], 20.0, 1800.0))
            else:
                # Analytical fallback when models are not yet trained
                diurnal_shift = 35.0 * np.sin((h_hour - 8) * np.pi / 12)
                p50 = float(np.clip(current_pm25 + diurnal_shift + (h * 0.4), 25.0, 650.0))
                uncertainty = 15.0 + (h * 1.2)
                p10 = max(10.0, p50 - uncertainty)
                p90 = p50 + (uncertainty * 1.5)

            p10 = min(p10, p50)
            p90 = max(p90, p50)
            pm10_est = p50 * 1.65

            # Compute AQI and GRAP
            aqi_info = grap_engine.calculate_aqi(pm25=p50, pm10=pm10_est)
            grap_info = grap_engine.evaluate_grap_stage(aqi=aqi_info["aqi"], pm25=p50, pm10=pm10_est)

            results.append({
                "horizon_h": h,
                "valid_time": valid_time.isoformat(),
                "pm25_p10": round(p10, 1),
                "pm25_p50": round(p50, 1),
                "pm25_p90": round(p90, 1),
                "pm10_p50": round(pm10_est, 1),
                "aqi_p50": aqi_info["aqi"],
                "aqi_category": aqi_info["category"],
                "grap_stage": grap_info["stage_name"],
                "grap_stage_number": grap_info["stage_number"],
                "mandated_actions": grap_info["actions"],
            })

        return results


# Global predictor instance
forecaster = ForecastPredictor()


if __name__ == "__main__":
    preds = forecaster.predict_cell_forecast("G-024-032", current_pm25=220.0)
    for p in preds:
        print(f"Horizon +{p['horizon_h']:02d}h -> PM2.5 P50: {p['pm25_p50']} ug/m3 | AQI: {p['aqi_p50']} ({p['grap_stage']})")
