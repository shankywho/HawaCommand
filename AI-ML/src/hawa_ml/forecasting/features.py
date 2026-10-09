"""Time-series feature engineering and leakage-free dataset preparation for 72h forecasting.

Features:
- PM2.5 & PM10 Lags: 1, 2, 3, 6, 12, 24, 48 hours
- Rolling statistics: 3h, 6h, 12h, 24h rolling mean, std, max
- Wind components: u = -ws * sin(wd), v = -ws * cos(wd)
- Weather variables: temperature, humidity, wind_speed
- Diurnal & Seasonal cyclics: sin/cos hour, sin/cos month, is_weekend
- Winter / Diwali season flag (Nov-Jan)
- Upwind fire count proxies
"""
from typing import List, Tuple
import pandas as pd
import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("forecast_features")

DEFAULT_HORIZONS = [1, 3, 6, 12, 24, 48, 72]
LAG_HOURS = [1, 2, 3, 6, 12, 24, 48]
ROLLING_WINDOWS = [3, 6, 12, 24]


def assert_no_temporal_leakage(train_df: pd.DataFrame, test_df: pd.DataFrame):
    """Enforce strict temporal ordering: train max timestamp < test min timestamp."""
    train_max = train_df["timestamp"].max()
    test_min = test_df["timestamp"].min()
    assert train_max < test_min, (
        f"Data leakage detected! Train max timestamp ({train_max}) "
        f"must strictly precede test min timestamp ({test_min})."
    )


def engineer_station_features(df: pd.DataFrame) -> pd.DataFrame:
    """Build lag, rolling, cyclic, and meteorological features for a single station series."""
    df = df.sort_values("timestamp").copy()

    # Cyclic encodings
    hours = df["timestamp"].dt.hour.values
    months = df["timestamp"].dt.month.values
    dayofweek = df["timestamp"].dt.dayofweek.values

    df["sin_hour"] = np.sin(2 * np.pi * hours / 24.0)
    df["cos_hour"] = np.cos(2 * np.pi * hours / 24.0)
    df["sin_month"] = np.sin(2 * np.pi * months / 12.0)
    df["cos_month"] = np.cos(2 * np.pi * months / 12.0)
    df["is_weekend"] = (dayofweek >= 5).astype(float)
    # Winter inversion & stubble season flag in Delhi (October 15 to January 31)
    df["is_winter_inversion"] = ((months >= 11) | (months == 1) | ((months == 10) & (df["timestamp"].dt.day >= 15))).astype(float)

    # Wind components
    ws = df["wind_speed"].fillna(2.0).values
    wd_rad = np.radians(df["wind_direction"].fillna(290.0).values)
    df["wind_u"] = -ws * np.sin(wd_rad)
    df["wind_v"] = -ws * np.cos(wd_rad)

    # Fill weather missing values
    df["temp_clean"] = df["temperature"].ffill().bfill().fillna(20.0)
    df["rh_clean"] = df["humidity"].ffill().bfill().fillna(60.0)

    # Lags for PM2.5 and PM10
    for lag in LAG_HOURS:
        df[f"pm25_lag_{lag}h"] = df["pm25"].shift(lag)
        df[f"pm10_lag_{lag}h"] = df["pm10"].shift(lag)

    # Rolling aggregations (computed strictly on lagged values to avoid current-step leakage)
    for w in ROLLING_WINDOWS:
        df[f"pm25_roll_mean_{w}h"] = df["pm25"].shift(1).rolling(w, min_periods=1).mean()
        df[f"pm25_roll_std_{w}h"] = df["pm25"].shift(1).rolling(w, min_periods=1).std().fillna(0.0)
        df[f"pm25_roll_max_{w}h"] = df["pm25"].shift(1).rolling(w, min_periods=1).max()

    # Upwind fire proxy: in winter season with NW wind (wind_u > 0, wind_v < 0), fire impact is elevated
    nw_wind_factor = np.clip((df["wind_u"].values * 0.5 - df["wind_v"].values * 0.5), 0, 5.0)
    df["fire_stubble_proxy"] = df["is_winter_inversion"].values * nw_wind_factor * 15.0

    return df


def prepare_multi_horizon_dataset(
    df_raw: pd.DataFrame, horizons: List[int] = DEFAULT_HORIZONS
) -> Tuple[pd.DataFrame, List[str], List[str]]:
    """Build multi-horizon target dataset with engineered features across all stations."""
    dfs = []
    for sid, group in df_raw.groupby("station_id"):
        feat_df = engineer_station_features(group)
        # Create targets for each horizon
        for h in horizons:
            feat_df[f"target_pm25_{h}h"] = feat_df["pm25"].shift(-h)
            feat_df[f"target_pm10_{h}h"] = feat_df["pm10"].shift(-h)
        dfs.append(feat_df)

    full_df = pd.concat(dfs, ignore_index=True)

    # Define feature column list
    feature_cols = [
        "sin_hour", "cos_hour", "sin_month", "cos_month", "is_weekend", "is_winter_inversion",
        "wind_u", "wind_v", "temp_clean", "rh_clean", "fire_stubble_proxy",
    ]
    for lag in LAG_HOURS:
        feature_cols.append(f"pm25_lag_{lag}h")
        feature_cols.append(f"pm10_lag_{lag}h")
    for w in ROLLING_WINDOWS:
        feature_cols.append(f"pm25_roll_mean_{w}h")
        feature_cols.append(f"pm25_roll_std_{w}h")
        feature_cols.append(f"pm25_roll_max_{w}h")

    target_cols = [f"target_pm25_{h}h" for h in horizons]
    return full_df, feature_cols, target_cols


def temporal_train_test_split(
    df: pd.DataFrame, holdout_days: int = 60
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """Split time-series dataset temporally with the last N days held out."""
    max_ts = df["timestamp"].max()
    split_ts = max_ts - pd.Timedelta(days=holdout_days)

    train_df = df[df["timestamp"] < split_ts].copy()
    test_df = df[df["timestamp"] >= split_ts].copy()

    assert_no_temporal_leakage(train_df, test_df)
    logger.info(
        f"Temporal split complete: Train={len(train_df)} rows ({train_df['timestamp'].min()} to {train_df['timestamp'].max()}), "
        f"Test={len(test_df)} rows ({test_df['timestamp'].min()} to {test_df['timestamp'].max()})"
    )
    return train_df, test_df
