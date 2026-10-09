"""Forecasting baselines: Persistence, Seasonal-Naive, and CAMS."""
from typing import Optional
import numpy as np
import pandas as pd


def persistence_forecast(df: pd.DataFrame, target_col: str, horizon_h: int) -> np.ndarray:
    """Persistence baseline: future value equals the most recent known value."""
    # The last known value at t is pm25 (lag 0)
    return df["pm25"].values


def seasonal_naive_forecast(df: pd.DataFrame, horizon_h: int) -> np.ndarray:
    """Seasonal naive baseline: value from 24 hours prior to forecast target."""
    # 24 hours prior to t+h
    lag_needed = 24 - horizon_h
    if lag_needed > 0:
        return df["pm25"].shift(lag_needed).fillna(df["pm25"]).values
    else:
        # If horizon >= 24, use the multiple of 24
        steps_back = ((horizon_h // 24) + 1) * 24 - horizon_h
        return df["pm25"].shift(steps_back).fillna(df["pm25"]).values
