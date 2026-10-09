"""Build processed datasets for HawaCommand AI-ML Engine.

Builds:
1. data/processed/stations_hourly.parquet (Resampled, validated hourly CPCB ground truth)
2. data/processed/grid_covariates_500m.parquet (500m digital twin grid with population & POIs)
3. data/processed/grid_covariates_1km.parquet (1km planning grid for exposure & dispatch)
"""
import sys
from pathlib import Path

# Add src to sys.path
BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE_DIR / "src"))

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.ingestion.cpcb import process_all_cpcb
from hawa_ml.twin.grid import build_delhi_grid

logger = configure_logging("build_dataset")


def build_all_datasets():
    logger.info("=== Starting Dataset Construction Pipeline ===")

    # 1. Process CPCB Historical Ground Truth
    logger.info("[1/3] Normalizing and resampling CPCB station records to hourly...")
    stations_df = process_all_cpcb()
    logger.info(
        f"Hourly station ground truth complete: {len(stations_df)} records across "
        f"{stations_df['station_id'].nunique()} stations. Date range: "
        f"{stations_df['timestamp'].min()} to {stations_df['timestamp'].max()}."
    )

    # 2. Build 500m Digital Twin Grid
    logger.info("[2/3] Constructing 500m map grid with WorldPop & POI covariates...")
    grid_500 = build_delhi_grid(cell_size_m=500.0)
    logger.info(f"500m grid ready: {len(grid_500)} cells.")

    # 3. Build 1km Planning Grid
    logger.info("[3/3] Constructing 1km planning grid...")
    grid_1000 = build_delhi_grid(cell_size_m=1000.0)
    logger.info(f"1km grid ready: {len(grid_1000)} cells.")

    logger.info("=== Dataset Construction Pipeline Finished Successfully ===")


if __name__ == "__main__":
    build_all_datasets()
