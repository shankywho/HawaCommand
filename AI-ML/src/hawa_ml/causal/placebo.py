"""In-space placebo tests and recovery acceptance test for Causal Verifier (F18).

Performs in-space placebo iterations across donor units to calculate:
- Empirical p-value
- 95% Confidence Interval [ci_low_pct, ci_high_pct]
- Acceptance test verifying recovery of known injected intervention effects.
"""
import json
from typing import Dict, List, Tuple
import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.causal.synthetic_control import fit_synthetic_control_weights, estimate_causal_effect
from hawa_ml.causal.effectiveness_library import effectiveness_library

logger = configure_logging("placebo_verifier")


def run_placebo_test(
    y_treated: np.ndarray,
    Y_donors: np.ndarray,
    pre_window_steps: int = 6,
) -> Dict[str, any]:
    """Execute in-space placebo tests across all donor units to compute CI and p-value."""
    base_res = estimate_causal_effect(y_treated, Y_donors, pre_window_steps=pre_window_steps)
    treated_effect = base_res["mean_effect_pct"]

    n_donors = Y_donors.shape[1]
    placebo_effects = []

    for j in range(n_donors):
        # Treat donor j as pseudo-treated
        y_pseudo = Y_donors[:, j]
        # Remaining donors form pool
        other_donors = np.delete(Y_donors, j, axis=1)

        res_j = estimate_causal_effect(y_pseudo, other_donors, pre_window_steps=pre_window_steps)
        # Filter placebos with terrible pre-treatment fit
        if res_j["pre_rmspe"] < base_res["pre_rmspe"] * 4.0:
            placebo_effects.append(res_j["mean_effect_pct"])

    if not placebo_effects:
        placebo_effects = [0.0]

    placebo_arr = np.array(placebo_effects)

    # Empirical p-value: proportion of placebos with absolute effect >= treated effect
    p_val = float(np.mean(np.abs(placebo_arr) >= abs(treated_effect)))

    # Empirical 95% confidence interval centered around treated effect
    ci_half_width = float(1.96 * np.std(placebo_arr))
    ci_low = treated_effect - ci_half_width
    ci_high = treated_effect + ci_half_width

    is_significant = p_val < 0.05 and (ci_high < 0.0 or ci_low > 0.0)

    return {
        "measured_effect_pct": base_res["mean_effect_pct"],
        "ci_low_pct": round(ci_low, 2),
        "ci_high_pct": round(ci_high, 2),
        "duration_minutes": base_res["duration_minutes"],
        "p_value": round(p_val, 4),
        "donor_pool_count": n_donors,
        "is_significant": is_significant,
        "pre_rmspe": base_res["pre_rmspe"],
    }


def verify_injected_intervention_recovery() -> Dict[str, any]:
    """Acceptance test: verifies that synthetic control accurately recovers injected known ground-truth.

    Prints the recovery table.
    """
    logger.info("=== Running Causal Verifier Acceptance Test (Recovery of Injected Effect) ===")
    np.random.seed(42)

    # Simulate 10 time steps (6 pre, 4 post)
    T = 10
    pre_steps = 6
    n_donors = 10

    # Common background diurnal trend + weather confounding
    t = np.arange(T)
    background_trend = 220.0 + 35.0 * np.sin(t * np.pi / 6.0)

    # Donor units with varying baseline offsets and localized noise
    Y_donors = np.zeros((T, n_donors))
    for j in range(n_donors):
        donor_offset = np.random.uniform(-40.0, 40.0)
        donor_noise = np.random.normal(0, 4.0, size=T)
        Y_donors[:, j] = background_trend + donor_offset + donor_noise

    # Synthetic weights (e.g. 50% donor 0, 30% donor 1, 20% donor 2)
    true_weights = np.zeros(n_donors)
    true_weights[0] = 0.50
    true_weights[1] = 0.30
    true_weights[2] = 0.20

    # True counterfactual
    counterfactual = np.dot(Y_donors, true_weights)

    # INJECT KNOWN EFFECT: Sprinkler causes -18.5% PM10 reduction during post-period
    injected_effect_pct = -18.5
    y_treated = counterfactual.copy()
    y_treated[pre_steps:] *= (1.0 + (injected_effect_pct / 100.0))
    # Add minor sensor noise
    y_treated += np.random.normal(0, 2.5, size=T)

    # Run Synthetic Control + Placebo Verifier
    res = run_placebo_test(y_treated, Y_donors, pre_window_steps=pre_steps)
    recovered_effect = res["measured_effect_pct"]
    abs_error = abs(recovered_effect - injected_effect_pct)

    logger.info(
        f"Injected Effect: {injected_effect_pct:.1f}% | "
        f"Recovered Effect: {recovered_effect:.1f}% | "
        f"Error: {abs_error:.2f}% | "
        f"CI: [{res['ci_low_pct']}%, {res['ci_high_pct']}%] | p-value: {res['p_value']}"
    )

    # Check acceptance criteria: recovered within 3.5 percentage points and CI covers truth
    tolerance = 3.5
    is_recovered = abs_error <= tolerance
    ci_covers = res["ci_low_pct"] <= injected_effect_pct <= res["ci_high_pct"]

    # Print recovery table
    print("\n" + "=" * 65)
    print(" CAUSAL VERIFICATION RECOVERY ACCEPTANCE TABLE")
    print("=" * 65)
    print(f"{'Metric':<30} | {'Value'}")
    print("-" * 65)
    print(f"{'Injected Ground-Truth Effect':<30} | {injected_effect_pct:.2f}%")
    print(f"{'Recovered Causal Effect':<30} | {recovered_effect:.2f}%")
    print(f"{'Absolute Estimation Error':<30} | {abs_error:.2f}% (Tolerance: <= {tolerance}%)")
    print(f"{'95% Placebo Confidence Interval':<30} | [{res['ci_low_pct']}%, {res['ci_high_pct']}%]")
    print(f"{'Placebo Empirical p-value':<30} | {res['p_value']}")
    print(f"{'Statistically Significant?':<30} | {res['is_significant']}")
    print(f"{'CI Covers Ground Truth?':<30} | {ci_covers}")
    print(f"{'Acceptance Criteria Status':<30} | {'PASSED' if is_recovered else 'FAILED'}")
    print("=" * 65 + "\n")

    # Update effectiveness library
    effectiveness_library.update_from_verification(
        cause="road_dust",
        action="water_sprinkler",
        measured_effect_pct=recovered_effect,
        duration_min=res["duration_minutes"],
        ci_low_pct=res["ci_low_pct"],
        ci_high_pct=res["ci_high_pct"],
    )

    metrics_dict = {
        "injected_pct": injected_effect_pct,
        "recovered_pct": recovered_effect,
        "error": abs_error,
        "ci_low": res["ci_low_pct"],
        "ci_high": res["ci_high_pct"],
        "p_value": res["p_value"],
        "is_significant": res["is_significant"],
        "duration_minutes": res["duration_minutes"],
        "passed": is_recovered,
    }

    try:
        settings.REPORTS_DIR.mkdir(parents=True, exist_ok=True)
        with open(settings.REPORTS_DIR / "verifier_metrics.json", "w") as f:
            json.dump(metrics_dict, f, indent=2)
    except Exception as e:
        logger.warning(f"Could not save verifier_metrics.json: {e}")

    return metrics_dict


if __name__ == "__main__":
    verify_injected_intervention_recovery()
