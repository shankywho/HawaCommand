# Model Card: HawaCommand 72-Hour Quantile Air Forecaster

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../../docs/README.md) · [Overview](../../docs/SYSTEM_OVERVIEW.md) · [AWS architecture](../../docs/AWS_ARCHITECTURE.md) · [AWS guide](../../docs/AWS_SETUP_GUIDE.md) · [API](../../docs/backend/API.md) · [Environment](../../docs/ENVIRONMENT_VARIABLES.md) · [Contracts](../../docs/CONTRACTS.md)

<!-- nav:end -->

> Status: Implemented (training), Partial (inference; see Intended use). This card describes the committed artifacts `models/lgb_pm25_{1,3,6,12,24,48,72}h_{p10,p50,p90}.txt`. Note: `scripts/train_all.py` regenerates this file from a template in `src/hawa_ml/forecasting/train.py` (`_write_model_card`), which overwrites these notes.

## Model overview
- **Architecture:** 21 independent LightGBM regressors (`LGBMRegressor`, `objective="quantile"`), one per horizon and quantile.
- **Target:** hourly PM2.5 (µg/m³) at `t + h`, raw scale (no log transform).
- **Horizons:** 1h, 3h, 6h, 12h, 24h, 48h, 72h.
- **Quantiles:** 0.10, 0.50 (median), 0.90.
- **Hyperparameters (all models):** `n_estimators=75`, `max_depth=6`, `num_leaves=31`, `learning_rate=0.08`, `random_state=42`, `n_jobs=-1`, no early stopping.
- **Code:** `src/hawa_ml/forecasting/features.py`, `train.py`, `evaluate.py`, `predict.py`.

## Training data
- `data/processed/stations_hourly.parquet` from CPCB/DPCC station CSVs resampled to hourly means (`src/hawa_ml/ingestion/cpcb.py`), or a synthetic 60-day dataset when no CSVs are present.
- When the file has more than 50,000 rows, only `df_raw.tail(45000)` is used. The file is sorted by station then time, so this keeps the last stations alphabetically rather than the most recent hours (known issue 4 in [README §9](../README.md#9-known-issues)).
- The committed artifacts and metrics were produced from real CPCB CSVs that are not in the repository; the row count used is not recorded.

## Features (37, in this order)
sin_hour, cos_hour, sin_month, cos_month, is_weekend, is_winter_inversion, wind_u, wind_v, temp_clean, rh_clean, fire_stubble_proxy, pm25_lag_1h, pm10_lag_1h, pm25_lag_2h, pm10_lag_2h, pm25_lag_3h, pm10_lag_3h, pm25_lag_6h, pm10_lag_6h, pm25_lag_12h, pm10_lag_12h, pm25_lag_24h, pm10_lag_24h, pm25_lag_48h, pm10_lag_48h, pm25_roll_mean_3h, pm25_roll_std_3h, pm25_roll_max_3h, pm25_roll_mean_6h, pm25_roll_std_6h, pm25_roll_max_6h, pm25_roll_mean_12h, pm25_roll_std_12h, pm25_roll_max_12h, pm25_roll_mean_24h, pm25_roll_std_24h, pm25_roll_max_24h

- Calendar features use the timestamp at `t` (the origin), not the valid time.
- `is_winter_inversion` = 1 from 15 October to 31 January.
- `wind_u = -ws·sin(wd)`, `wind_v = -ws·cos(wd)` with missing wind filled as 2.0 m/s from 290°.
- `fire_stubble_proxy = is_winter_inversion × clip(0.5·u − 0.5·v, 0, 5) × 15` (a wind-direction proxy; FIRMS data is not used).
- Rolling statistics are computed on values shifted by one hour.
- The boosters store unnamed features (`Column_0` .. `Column_36`); column order is the contract.

## Validation methodology
- **Split:** one temporal split per run; the last 45 days are the test set (`temporal_train_test_split(holdout_days=45)`), checked by `assert_no_temporal_leakage()` (train max timestamp < test min timestamp). Rows with any missing feature or target are dropped per horizon; a horizon is skipped with fewer than 100 train or 20 test rows.
- **Baseline:** persistence only (`ŷ(t+h) = PM2.5(t)`). `seasonal_naive_forecast` exists but is not evaluated; CAMS is never compared.
- **Metrics:** P50 MAE and RMSE, persistence MAE, skill `1 − MAE/MAE_persistence`, empirical P10-P90 coverage (nominal 80 %), pinball loss per quantile (`src/hawa_ml/forecasting/evaluate.py`).

## Evaluation results (`reports/forecast_metrics.json`)
| Horizon | P50 MAE | P50 RMSE | Persistence MAE | Skill vs persistence | P10-P90 coverage | Pinball P10 / P50 / P90 |
|---|---|---|---|---|---|---|
| **1h** | 45.75 µg/m³ | 68.56 | 53.41 µg/m³ | 14.3% | 77.8% | 9.11 / 22.88 / 12.18 |
| **3h** | 46.81 µg/m³ | 69.13 | 58.19 µg/m³ | 19.6% | 82.1% | 9.24 / 23.41 / 12.98 |
| **6h** | 48.58 µg/m³ | 71.56 | 66.83 µg/m³ | 27.3% | 85.8% | 9.91 / 24.29 / 13.39 |
| **12h** | 54.8 µg/m³ | 79.79 | 61.0 µg/m³ | 10.2% | 81.1% | 10.88 / 27.40 / 17.04 |
| **24h** | 63.55 µg/m³ | 88.28 | 72.6 µg/m³ | 12.5% | 77.9% | 11.49 / 31.77 / 19.05 |
| **48h** | 71.27 µg/m³ | 98.68 | 91.0 µg/m³ | 21.7% | 74.3% | 12.65 / 35.64 / 21.95 |
| **72h** | 73.78 µg/m³ | 103.47 | 95.22 µg/m³ | 22.5% | 75.5% | 12.83 / 36.89 / 22.52 |

No confidence intervals, rolling-origin backtest or per-season breakdown were computed.

## Intended use and how it is served
- `ForecastPredictor.predict_cell_forecast(cell_id, current_pm25, current_pm10=330, temp=19.5, rh=75, ws=2.4, wd=295)` (`src/hawa_ml/forecasting/predict.py`) builds one feature vector per horizon: calendar features at the valid time, the winter flag only for November-January, every PM2.5 lag and rolling mean set to `current_pm25`, every PM10 lag to `current_pm10`, fixed rolling standard deviations (12, 15, 20, 25) and maxima (`current_pm25 × 1.1 .. 1.35`). `cell_id` is not used.
- Predictions are clipped (P10 10-1500, P50 15-1500, P90 20-1800) and re-ordered so P10 ≤ P50 ≤ P90; PM10 is reported as `1.65 × P50`; AQI and GRAP stage come from `src/hawa_ml/forecasting/grap.py`.
- If any of the three boosters for a horizon is missing, an analytical fallback is used: `P50 = clip(current + 35·sin((hour − 8)·π/12) + 0.4·h, 25, 650)`, `P10 = max(10, P50 − (15 + 1.2h))`, `P90 = P50 + 1.5·(15 + 1.2h)`.
- Served by `GET /forecast/{cell_id}` and used by the Forecaster agent, the operational cycle and the backend.

## Limitations
- Station-trained, applied to grid cells without any spatial adaptation.
- Inference does not use real history, weather forecasts or fire data, so live forecasts differ from the evaluated setting.
- Error grows with horizon (MAE 45.75 at 1h to 73.78 at 72h); coverage stays below the nominal 80 % at 1h, 24h, 48h and 72h.
- Retraining on the synthetic offline dataset produces meaningless metrics; check the data source before quoting results.

<!-- footer:start -->

---

**Related across the project:** [Forecaster](../../docs/aiml/MODELS.md#3-72-hour-forecaster) · [Training](../../docs/aiml/DATA_AND_TRAINING.md#training) · [Forecast page](../../docs/frontend/PAGES.md#forecast-72-hours-ahead)

[Back to top](#model-card-hawacommand-72-hour-quantile-air-forecaster) · [Docs hub](../../docs/README.md) · [Project README](../../README.md)

<!-- footer:end -->
