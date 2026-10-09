# Model Card: HawaCommand 72-Hour Quantile Air Forecaster

## Model Overview
- **Architecture:** LightGBM Gradient Boosted Decision Trees with Quantile Objectives (P10, P50, P90).
- **Target Horizons:** 1h, 3h, 6h, 12h, 24h, 48h, 72h.
- **Quantiles:** 0.10, 0.50 (Median), 0.90.
- **Training Ground Truth:** Historical CPCB/DPCC Delhi continuous monitoring stations (15-min resampled to hourly).

## Validation Methodology
- **Split Strategy:** Strict temporal split with held-out validation on the final 45 days. **Zero future information leakage.**
- **Benchmark Baselines:** Persistence ($\hat{y}_{t+h} = y_t$), Seasonal-Naive, and Copernicus CAMS forecast.

## Evaluation Results
| Horizon | Model MAE (P50) | Persistence MAE | Skill vs Persistence | P10-P90 Coverage |
|---|---|---|---|---|
| **1h** | 45.75 µg/m³ | 53.41 µg/m³ | 14.3% | 77.8% |
| **3h** | 46.81 µg/m³ | 58.19 µg/m³ | 19.6% | 82.1% |
| **6h** | 48.58 µg/m³ | 66.83 µg/m³ | 27.3% | 85.8% |
| **12h** | 54.8 µg/m³ | 61.0 µg/m³ | 10.2% | 81.1% |
| **24h** | 63.55 µg/m³ | 72.6 µg/m³ | 12.5% | 77.9% |
| **48h** | 71.27 µg/m³ | 91.0 µg/m³ | 21.7% | 74.3% |
| **72h** | 73.78 µg/m³ | 95.22 µg/m³ | 22.5% | 75.5% |

## Engineered Feature Columns (37)
sin_hour, cos_hour, sin_month, cos_month, is_weekend, is_winter_inversion, wind_u, wind_v, temp_clean, rh_clean, fire_stubble_proxy, pm25_lag_1h, pm10_lag_1h, pm25_lag_2h, pm10_lag_2h, pm25_lag_3h, pm10_lag_3h, pm25_lag_6h, pm10_lag_6h, pm25_lag_12h, pm10_lag_12h, pm25_lag_24h, pm10_lag_24h, pm25_lag_48h, pm10_lag_48h, pm25_roll_mean_3h, pm25_roll_std_3h, pm25_roll_max_3h, pm25_roll_mean_6h, pm25_roll_std_6h, pm25_roll_max_6h, pm25_roll_mean_12h, pm25_roll_std_12h, pm25_roll_max_12h, pm25_roll_mean_24h, pm25_roll_std_24h, pm25_roll_max_24h

## Limitations
- Performance degradation at 72h horizon due to meteorological divergence.
- Heavy reliance on low-level surface wind vectors and winter boundary-layer inversion proxies.
