# AI-ML models

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**AI-ML docs:** [Runbook](../../AI-ML/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · **Models** · [Agents](AGENTS.md) · [Data and training](DATA_AND_TRAINING.md) · [Engine API](../../AI-ML/CONTRACTS.md) · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/twin-Gaussian%20process-F7931E?logo=scikitlearn&logoColor=white" alt="Gaussian process">
<img src="https://img.shields.io/badge/forecast-21%20LightGBM%20quantile%20models-02569B" alt="LightGBM">
<img src="https://img.shields.io/badge/verify-synthetic%20control-8250DF" alt="Synthetic control">
<img src="https://img.shields.io/badge/package-hawa__ml-3776AB?logo=python&logoColor=white" alt="hawa_ml">
</p>

Every model in the closed loop: what it computes, its parameters, where it lives, and how well it does.

---

## The loop, model by model

| Stage | Model | Code | Output |
|---|---|---|---|
| Map | [Digital twin](#1-digital-twin) | `twin/kriging.py`, `twin/advection.py` | PM2.5, PM10, variance, confidence per 500 m cell |
| Attribute | [Source attribution](#2-source-attribution) | `attribution/rules.py`, `backtrajectory.py`, `classifier.py` | Cause + confidence + upwind suspect pin |
| Forecast | [72 h forecaster](#3-72-hour-forecaster) | `forecasting/train.py`, `predict.py`, `features.py` | P10/P50/P90 at 1, 3, 6, 12, 24, 48, 72 h |
| Forecast | [AQI and GRAP](#4-aqi-and-grap) | `forecasting/grap.py` | CPCB AQI, category, CAQM GRAP stage and actions |
| Decide | [Exposure engine](#5-exposure-engine) | `exposure/engine.py` | Hotspots ranked by people exposed |
| Decide | [Dispatch optimiser](#6-dispatch-optimiser) | `optimization/greedy.py` | Cause-matched task list per vehicle |
| Decide | [What-If](#7-what-if) | `optimization/whatif.py` | AI plan vs usual routes |
| Verify | [Causal verifier](#8-causal-verifier) | `causal/synthetic_control.py`, `placebo.py` | Effect % with a 95 % interval and p-value |
| Learn | [Effectiveness library](#9-effectiveness-library) | `causal/effectiveness_library.py` | Expected effect per cause and action |
| Citizen | [Safe window and safe route](#10-citizen-models) | `forecasting/safe_window.py`, `exposure/routing.py` | Safe hours per persona, cleanest route |
| Sensors | [Calibration](#11-sensor-calibration) | `calibration/drive_by.py` | Calibrated PM2.5 + trust score |

All paths are under `AI-ML/src/hawa_ml/`.

---

## 1. Digital twin

- **Method:** scikit-learn Gaussian process regression over station readings, one GP for PM2.5 and one for PM10.
- **Kernel:** `Constant(1.0) × RBF(length_scale = 0.10°, bounds 0.02–0.40) + White(noise = 15, bounds 1–100)`, 2 optimiser restarts.
- **Grid:** 10,600 cells of 500 m over Delhi NCT, with population, schools, hospitals, land use and road density (`twin/grid.py`).
- **Advection:** stations can be shifted downwind by wind speed × elapsed time before fitting (`twin/advection.py`).
- **Output per cell:** `pm25_est`, `pm10_est`, `variance`, `confidence` (0.20–0.98).
- **Inputs at runtime:** live WAQI / OpenAQ stations from the backend, else 5 baseline stations.
- **Caching:** 15 min per process, shared through Redis `grid:pm25:500m:<hour>` ([backend services](../backend/SERVICES.md)).

| Metric (leave-one-station-out, `reports/twin_metrics.json`) | Value |
|---|---|
| GP MAE | 37.82 µg/m³ |
| Nearest-station MAE | 7.40 µg/m³ |
| IDW MAE | 7.05 µg/m³ |
| Stations evaluated | 3 (the committed sample) |

---

## 2. Source attribution

| Cause | Main signals ([`fingerprint_rules.yaml`](../../AI-ML/config/fingerprint_rules.yaml)) | Action | Never send |
|---|---|---|---|
| Road dust | PM2.5/PM10 ≤ 0.45, NO2 ≤ 45 ppb, daytime | Sprinkler, sweeper | — |
| Traffic | Ratio 0.40–0.70, NO2 ≥ 40 ppb, CO ≥ 1.5 ppm, rush hours | Traffic advisory | Sprinkler |
| Open burning | Ratio ≥ 0.70, VOC spike, evening and night | Inspection team | Sprinkler |
| Regional smoke | Ratio ≥ 0.75, NW wind 270–335°, ≥ 20 upwind fires, city-wide PM2.5 ≥ 180 | Protect people | Sprinkler, smog gun |
| Industrial | SO2 ≥ 25 ppb, ratio ≥ 0.50 | Industrial inspection | Sprinkler |
| Unknown | Nothing matches (confidence 0.30) | Monitor | — |

- **Back-trajectory:** reverses wind vectors hour by hour from the hotspot to place an upwind suspect pin.
- **Classifier:** a LightGBM model trained on rule-labelled data (`models/attribution_classifier.txt`); the rules drive runtime decisions. Card: [attribution model card](../../AI-ML/models/attribution_model_card.md).

---

## 3. 72-hour forecaster

- **Models:** 21 LightGBM quantile regressors = 7 horizons × 3 quantiles (α = 0.1, 0.5, 0.9).
- **Hyperparameters:** 75 trees, 31 leaves, learning rate 0.08.
- **Features:** PM2.5 and PM10 lags at 1, 2, 3, 6, 12, 24, 48 h; rolling mean, std and max over 3, 6, 12, 24 h; hour and day cycles; winter flag; weather.
- **Leakage guard:** rolling windows use lagged values only; temporal train/test split (`assert_no_temporal_leakage`).
- **Inference:** `ForecastPredictor.predict_cell_forecast(cell_id, current_pm25)` fills the lag features from the latest reading.
- **Files:** `models/lgb_pm25_{h}h_{p10,p50,p90}.txt`. Card: [forecaster model card](../../AI-ML/models/forecaster_model_card.md).

| Horizon | MAE P50 | Persistence MAE | Skill vs persistence | P10–P90 coverage |
|---|---|---|---|---|
| 1 h | 45.8 | 53.4 | +14.3 % | 77.8 % |
| 3 h | 46.8 | 58.2 | +19.6 % | 82.1 % |
| 6 h | 48.6 | 66.8 | +27.3 % | 85.8 % |
| 12 h | 54.8 | 61.0 | +10.2 % | 81.1 % |
| 24 h | 63.6 | 72.6 | +12.5 % | 77.9 % |
| 48 h | 71.3 | 91.0 | +21.7 % | 74.3 % |
| 72 h | 73.8 | 95.2 | +22.5 % | 75.5 % |

Source: `reports/forecast_metrics.json` (µg/m³). The forecaster beats persistence at every horizon.

---

## 4. AQI and GRAP

- **AQI:** CPCB sub-index breakpoints per pollutant ([`cpcb_breakpoints.yaml`](../../AI-ML/config/cpcb_breakpoints.yaml)); AQI = the highest sub-index.
- **GRAP:** CAQM stages I–IV with mandated actions ([`grap.yaml`](../../AI-ML/config/grap.yaml)).
- **Backend view:** the API derives the stage from PM2.5 thresholds 61 / 121 / 251 / 381 µg/m³ so stage and probability agree.

---

## 5. Exposure engine

```
E = max(0, C − C_safe) × Pop(cell, hour) × V(cell) × dt
```

| Term | Meaning | Source |
|---|---|---|
| `C_safe` | 60 µg/m³ (Indian 24 h standard) | [`weights.yaml`](../../AI-ML/config/weights.yaml) |
| `Pop(cell, hour)` | WorldPop count × diurnal multiplier (school, market, residential curves) | grid + `weights.yaml` |
| `V(cell)` | Vulnerability: hospital 3.0, elderly care 2.8, school 2.5, dense settlement 2.0, … | `weights.yaml` |

- Hotspots are ranked by `E`, then spread so one plume does not fill the list.

---

## 6. Dispatch optimiser

- **Method:** greedy assignment, highest exposure first, nearest compatible vehicle.
- **Compatibility:** sprinklers, smog guns and sweepers only to dust or unknown; inspection teams to burning, industrial, traffic.
- **Constraints:** vehicle speed 22 km/h, 60 min per spray, water tank capacity, shift hours.
- **Expected effect:** each task carries the effectiveness-library estimate for its cause and action.
- **Output:** `PlanTask` list grouped per asset, consumed by the Planner agent and the backend plan routes.

---

## 7. What-If

- Compares the AI plan's person-hours of exposure avoided with a usual-routes baseline.
- Baseline in the prototype: a documented status-quo efficiency of 0.32 of the AI result (`whatif.py`).
- Backend route: `GET /v1/plans/{id}/compare`; console page `/what-if`.

---

## 8. Causal verifier

- **Synthetic control:** donor weights `w ≥ 0`, `Σw = 1`, fitted with SLSQP on the pre-period; effect = treated − synthetic after the spray.
- **Placebo tests:** the same fit run with each donor as a fake treated cell; badly fitted placebos are dropped.
- **Outputs:** mean effect %, empirical 95 % interval, p-value, significance.

| Recovery test (`reports/verifier_metrics.json`) | Value |
|---|---|
| Injected effect | −18.50 % |
| Recovered effect | −18.82 % |
| 95 % interval | −22.24 % to −15.40 % |
| p-value | 0.00 |
| Passed | yes |

---

## 9. Effectiveness library

- Prior effect per `cause:action` (for example `road_dust:water_sprinkler`), updated after each verified intervention.
- Stored in `data/internal/effectiveness_library.json`; served at `/effectiveness-library` and `GET /v1/impact/library`.

---

## 10. Citizen models

| Model | How it works | Backend route |
|---|---|---|
| Safe breath window | 24 h diurnal curve scaled to live PM2.5; safe when below the persona limit: asthma/seniors 100, children 140, runners 160, general 200 µg/m³ | `GET /v1/citizen/safe-window` |
| Safe route | Inhaled dose `D = ∫ C · V_E(mode) dt`; ventilation and speed per mode (walking, cycling, two-wheeler, car) | `POST /v1/citizen/safe-route` |

---

## 11. Sensor calibration

- Drive-by calibration: when a mobile pod passes a reference station, fit a per-device profile.
- Fallback formula: `PM2.5_cal = max(0, 0.85 × raw − 0.15 × RH + 5)`.
- Profiles in `data/internal/calibration_profiles.json`.

---

## Related

- [AI-ML architecture](ARCHITECTURE.md) · [Agents](AGENTS.md) · [Data and training](DATA_AND_TRAINING.md) · [Engine API](../../AI-ML/CONTRACTS.md)

<!-- footer:start -->

---

**Related across the project:** [Twin snapshot in Redis](../backend/SERVICES.md#twin-snapshot) · [Map, forecast and impact pages](../frontend/PAGES.md) · [Citizen air screens](../app/SCREENS.md#citizen-air--report--my-reports--more) · [Forecaster card](../../AI-ML/models/forecaster_model_card.md) · [Attribution card](../../AI-ML/models/attribution_model_card.md) · [SageMaker forecast](../AWS_SETUP_GUIDE.md#16b-sagemaker-or-step-functions-forecast)

[Back to top](#ai-ml-models) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
