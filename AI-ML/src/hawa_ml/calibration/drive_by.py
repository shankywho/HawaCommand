"""Drive-by dynamic sensor self-calibration against reference CAAQMS stations (F3).

When a mobile sensor (bus/rickshaw) passes within 200m of a reference station at low speed (<30 km/h),
pairs of readings are collected.
A robust linear model ref = a * raw + b * RH + c is fitted using HuberRegressor.
Tracks per-device calibration coefficients, versioning, and trust_score.
"""
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import json
import numpy as np
import pandas as pd
from sklearn.linear_model import HuberRegressor

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.geo import haversine_distance_m

logger = configure_logging("calibration")


@dataclass
class DeviceCalibrationProfile:
    dev_id: str
    slope_a: float = 1.0
    rh_coef_b: float = 0.0
    offset_c: float = 0.0
    trust_score: float = 1.0
    version: int = 1
    last_calibrated: str = ""
    mae_before: float = 0.0
    mae_after: float = 0.0
    r2_after: float = 0.0
    co_location_samples: int = 0


class DriveByCalibrator:
    def __init__(self):
        self.profile_path = settings.DATA_DIR / "internal" / "calibration_profiles.json"
        self.profile_path.parent.mkdir(parents=True, exist_ok=True)
        self.profiles: Dict[str, DeviceCalibrationProfile] = {}
        self._load_profiles()

    def _load_profiles(self):
        if self.profile_path.exists():
            try:
                with open(self.profile_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self.profiles = {k: DeviceCalibrationProfile(**v) for k, v in data.items()}
            except Exception as e:
                logger.warning(f"Failed to load calibration profiles: {e}")

    def save_profiles(self):
        with open(self.profile_path, "w", encoding="utf-8") as f:
            json.dump({k: asdict(v) for k, v in self.profiles.items()}, f, indent=2)

    def get_or_create_profile(self, dev_id: str) -> DeviceCalibrationProfile:
        if dev_id not in self.profiles:
            self.profiles[dev_id] = DeviceCalibrationProfile(
                dev_id=dev_id,
                last_calibrated=datetime.now(timezone.utc).isoformat(),
            )
        return self.profiles[dev_id]

    def fit_calibration(
        self,
        dev_id: str,
        raw_pm25: np.ndarray,
        rh_values: np.ndarray,
        ref_pm25: np.ndarray,
    ) -> DeviceCalibrationProfile:
        """Fit ref = a * raw + b * RH + c using robust Huber regression."""
        prof = self.get_or_create_profile(dev_id)

        mask = ~np.isnan(raw_pm25) & ~np.isnan(rh_values) & ~np.isnan(ref_pm25)
        raw_clean = raw_pm25[mask]
        rh_clean = rh_values[mask]
        ref_clean = ref_pm25[mask]

        if len(raw_clean) < 8:
            logger.info(f"Insufficient co-location samples ({len(raw_clean)}) for device {dev_id}. Keeping current fit.")
            return prof

        # MAE before calibration
        mae_before = float(np.mean(np.abs(ref_clean - raw_clean)))

        # Feature matrix: [raw, RH]
        X = np.column_stack([raw_clean, rh_clean])
        y = ref_clean

        huber = HuberRegressor(epsilon=1.35, max_iter=200)
        huber.fit(X, y)

        slope_a = float(huber.coef_[0])
        rh_b = float(huber.coef_[1])
        offset_c = float(huber.intercept_)

        pred_calibrated = huber.predict(X)
        mae_after = float(np.mean(np.abs(ref_clean - pred_calibrated)))

        ss_tot = np.sum((ref_clean - np.mean(ref_clean)) ** 2)
        ss_res = np.sum((ref_clean - pred_calibrated) ** 2)
        r2 = float(1.0 - (ss_res / max(ss_tot, 1e-4)))

        # Trust score decays if calibration slope drifts drastically away from 1.0 (drift detection)
        slope_drift = abs(slope_a - 1.0)
        new_trust = float(np.clip(1.0 - slope_drift * 0.8, 0.2, 1.0))

        prof.slope_a = round(slope_a, 4)
        prof.rh_coef_b = round(rh_b, 4)
        prof.offset_c = round(offset_c, 2)
        prof.mae_before = round(mae_before, 2)
        prof.mae_after = round(mae_after, 2)
        prof.r2_after = round(r2, 3)
        prof.trust_score = round(new_trust, 2)
        prof.version += 1
        prof.co_location_samples = len(raw_clean)
        prof.last_calibrated = datetime.now(timezone.utc).isoformat()

        self.save_profiles()
        logger.info(
            f"Calibrated {dev_id} v{prof.version}: ref = {slope_a:.3f}*raw + ({rh_b:.3f})*RH + {offset_c:.2f} | "
            f"MAE: {mae_before:.1f} -> {mae_after:.1f} ug/m3 | Trust: {new_trust}"
        )
        return prof

    def calibrate_reading(self, dev_id: str, raw_pm25: float, rh: float) -> Tuple[float, float]:
        """Apply active calibration curve to a single live telemetry reading."""
        prof = self.get_or_create_profile(dev_id)
        calibrated = prof.slope_a * raw_pm25 + prof.rh_coef_b * rh + prof.offset_c
        calibrated = max(0.0, float(calibrated))
        return calibrated, prof.trust_score

    def calibrate_batch(self, df_telemetry: pd.DataFrame) -> pd.DataFrame:
        """Batch calibrate a stream of telemetry packets."""
        calibrated_pm25 = []
        trust_scores = []
        for _, row in df_telemetry.iterrows():
            dev_id = str(row["dev_id"])
            raw = float(row["pm25"])
            rh = float(row.get("rh", 60.0))
            cal, trust = self.calibrate_reading(dev_id, raw, rh)
            calibrated_pm25.append(cal)
            trust_scores.append(trust)

        df_telemetry["pm25_calibrated"] = calibrated_pm25
        df_telemetry["trust_score"] = trust_scores
        return df_telemetry


# Global calibrator instance
drive_by_calibrator = DriveByCalibrator()


if __name__ == "__main__":
    calibrator = DriveByCalibrator()
    # Test fitting on synthetic co-located readings
    true_ref = np.random.uniform(100.0, 300.0, size=50)
    rh = np.random.uniform(50.0, 90.0, size=50)
    # Sensor has 1.15 gain, +15 offset, and RH swelling
    raw_obs = (true_ref - 15.0) / 1.15 + (rh * 0.12)
    p = calibrator.fit_calibration("HPM-TEST-01", raw_obs, rh, true_ref)
    print(f"Profile: a={p.slope_a}, b={p.rh_coef_b}, c={p.offset_c}, MAE: {p.mae_before} -> {p.mae_after}")
