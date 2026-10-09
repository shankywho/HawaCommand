"""Train all machine learning models in the HawaCommand pipeline.

Trains:
1. 72-hour LightGBM Quantile Forecaster (P10, P50, P90)
2. Multi-class Source Attribution Classifier (Weak Supervision)
"""
import sys
from pathlib import Path
import pandas as pd

# Add src to sys.path
BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE_DIR / "src"))

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.forecasting.train import train_forecast_models
from hawa_ml.attribution.classifier import attribution_classifier

logger = configure_logging("train_all")


def train_all_models():
    logger.info("=== Starting Master Training Pipeline ===")

    # 1. Train 72h Forecaster Models
    logger.info("[1/2] Training LightGBM 72h quantile forecasters...")
    forecast_metrics = train_forecast_models()
    logger.info("Forecaster training complete.")

    # 2. Train Attribution Classifier
    logger.info("[2/2] Training source attribution classifier...")
    data_path = settings.PROCESSED_DATA_DIR / "stations_hourly.parquet"
    if data_path.exists():
        df_hourly = pd.read_parquet(data_path)
        attribution_classifier.train(df_hourly)
        logger.info("Attribution classifier training complete.")
    else:
        logger.warning(f"{data_path} not found. Skipping attribution training.")

    logger.info("=== All models successfully trained and persisted to models/ ===")


if __name__ == "__main__":
    train_all_models()
