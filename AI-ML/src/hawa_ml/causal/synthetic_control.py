"""Synthetic Control Causal Verification Engine (F18).

Constructs a synthetic counterfactual unit for each intervention by solving:
min_w || Y_treated,pre - Y_donors,pre * w ||^2
subject to w >= 0, sum(w) = 1

Measures the true causal treatment effect (% reduction and absolute ug/m3)
isolated from confounding weather changes and diurnal air mass drift.
"""
from typing import Dict, List, Optional, Tuple
import numpy as np
from scipy.optimize import minimize

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("synthetic_control")


def fit_synthetic_control_weights(
    y_treated_pre: np.ndarray,
    Y_donors_pre: np.ndarray,
) -> np.ndarray:
    """Solve constrained non-negative least squares with sum-to-one constraint.

    y_treated_pre: shape (T_pre,)
    Y_donors_pre: shape (T_pre, N_donors)
    """
    n_donors = Y_donors_pre.shape[1]

    def objective(w):
        y_synth = np.dot(Y_donors_pre, w)
        return np.sum((y_treated_pre - y_synth) ** 2)

    # Initial uniform weights
    w0 = np.ones(n_donors) / n_donors
    # Non-negative bounds [0, 1]
    bounds = [(0.0, 1.0) for _ in range(n_donors)]
    # Equality constraint: sum(w) = 1.0
    constraints = {"type": "eq", "fun": lambda w: np.sum(w) - 1.0}

    res = minimize(objective, w0, method="SLSQP", bounds=bounds, constraints=constraints)
    if res.success:
        return np.clip(res.x, 0.0, 1.0) / np.sum(np.clip(res.x, 0.0, 1.0))
    return w0


def estimate_causal_effect(
    y_treated: np.ndarray,
    Y_donors: np.ndarray,
    pre_window_steps: int = 6,
) -> Dict[str, any]:
    """Estimate counterfactual trajectory, effect size, and effective duration.

    y_treated: (T_total,) where first pre_window_steps are pre-treatment
    Y_donors: (T_total, N_donors)
    """
    T_total = len(y_treated)
    assert T_total > pre_window_steps, "Total observations must exceed pre-window."

    y_pre = y_treated[:pre_window_steps]
    Y_donors_pre = Y_donors[:pre_window_steps, :]

    # Fit synthetic weights
    weights = fit_synthetic_control_weights(y_pre, Y_donors_pre)

    # Predict counterfactual over entire timeline
    y_synthetic = np.dot(Y_donors, weights)

    # Post-treatment evaluation
    y_post_actual = y_treated[pre_window_steps:]
    y_post_synth = y_synthetic[pre_window_steps:]

    diff_post = y_post_actual - y_post_synth

    # Percentage effect: (Actual - Synthetic) / Synthetic * 100%
    mean_synth_post = np.mean(y_post_synth)
    mean_effect_ugm3 = float(np.mean(diff_post))
    mean_effect_pct = float((mean_effect_ugm3 / max(mean_synth_post, 1e-4)) * 100.0)

    # Pre-treatment fit error (Root Mean Squared Prediction Error)
    pre_rmspe = float(np.sqrt(np.mean((y_pre - y_synthetic[:pre_window_steps]) ** 2)))

    # Estimate duration: steps until effect returns within 10% of zero
    duration_steps = len(diff_post)
    for idx, d in enumerate(diff_post):
        if d > -0.05 * mean_synth_post:
            duration_steps = idx + 1
            break
    duration_minutes = duration_steps * 30  # assuming 30-minute intervals

    return {
        "mean_effect_pct": round(mean_effect_pct, 2),
        "mean_effect_ugm3": round(mean_effect_ugm3, 2),
        "duration_minutes": duration_minutes,
        "pre_rmspe": round(pre_rmspe, 2),
        "weights": [round(float(w), 4) for w in weights],
        "y_actual": y_treated.tolist(),
        "y_synthetic": y_synthetic.tolist(),
    }
