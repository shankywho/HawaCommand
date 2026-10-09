"""Forecaster evaluation metrics: MAE, RMSE, Pinball Loss, and Empirical Coverage."""
from typing import Dict
import numpy as np


def mean_absolute_error(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    mask = ~np.isnan(y_true) & ~np.isnan(y_pred)
    if not np.any(mask):
        return 0.0
    return float(np.mean(np.abs(y_true[mask] - y_pred[mask])))


def root_mean_squared_error(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    mask = ~np.isnan(y_true) & ~np.isnan(y_pred)
    if not np.any(mask):
        return 0.0
    return float(np.sqrt(np.mean((y_true[mask] - y_pred[mask]) ** 2)))


def pinball_loss(y_true: np.ndarray, y_pred: np.ndarray, quantile: float) -> float:
    """Pinball loss for quantile regression."""
    mask = ~np.isnan(y_true) & ~np.isnan(y_pred)
    if not np.any(mask):
        return 0.0
    diff = y_true[mask] - y_pred[mask]
    loss = np.maximum(quantile * diff, (quantile - 1.0) * diff)
    return float(np.mean(loss))


def empirical_coverage(y_true: np.ndarray, p10: np.ndarray, p90: np.ndarray) -> float:
    """Percentage of actual observations falling within the P10-P90 prediction interval (nominal 80%)."""
    mask = ~np.isnan(y_true) & ~np.isnan(p10) & ~np.isnan(p90)
    if not np.any(mask):
        return 0.0
    inside = (y_true[mask] >= p10[mask]) & (y_true[mask] <= p90[mask])
    return float(np.mean(inside) * 100.0)


def compute_forecast_metrics(
    y_true: np.ndarray,
    p10: np.ndarray,
    p50: np.ndarray,
    p90: np.ndarray,
    y_persistence: np.ndarray,
    y_cams: np.ndarray = None,
) -> Dict[str, float]:
    """Compute comprehensive performance and benchmark comparison metrics."""
    mae_model = mean_absolute_error(y_true, p50)
    rmse_model = root_mean_squared_error(y_true, p50)
    mae_pers = mean_absolute_error(y_true, y_persistence)
    coverage = empirical_coverage(y_true, p10, p90)
    pb10 = pinball_loss(y_true, p10, 0.10)
    pb50 = pinball_loss(y_true, p50, 0.50)
    pb90 = pinball_loss(y_true, p90, 0.90)

    # Skill score relative to persistence (positive = beats persistence)
    skill_vs_persistence = float(1.0 - (mae_model / max(mae_pers, 1e-4))) * 100.0

    metrics = {
        "mae_p50": round(mae_model, 2),
        "rmse_p50": round(rmse_model, 2),
        "mae_persistence": round(mae_pers, 2),
        "skill_vs_persistence_pct": round(skill_vs_persistence, 1),
        "coverage_p10_p90_pct": round(coverage, 1),
        "pinball_p10": round(pb10, 2),
        "pinball_p50": round(pb50, 2),
        "pinball_p90": round(pb90, 2),
    }

    if y_cams is not None and len(y_cams) == len(y_true):
        mae_cams = mean_absolute_error(y_true, y_cams)
        skill_vs_cams = float(1.0 - (mae_model / max(mae_cams, 1e-4))) * 100.0
        metrics["mae_cams"] = round(mae_cams, 2)
        metrics["skill_vs_cams_pct"] = round(skill_vs_cams, 1)

    return metrics
