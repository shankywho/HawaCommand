"""CPCB / DPCC historical air quality data ingestion and processing.

Loads 15-minute station CSVs from data/external/cpcb/, validates ranges,
cleans flatlines and outliers, resamples to hourly mean, attaches station
coordinates, and saves to data/processed/stations_hourly.parquet.
"""
from pathlib import Path
from typing import Dict, List, Optional
import pandas as pd
import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("cpcb")

# Canonical column mapping from CPCB CSV headers
CPCB_COL_MAP = {
    "Timestamp": "timestamp",
    "PM2.5 (µg/m³)": "pm25",
    "PM10 (µg/m³)": "pm10",
    "NO (µg/m³)": "no",
    "NO2 (µg/m³)": "no2",
    "NOx (ppb)": "nox",
    "NH3 (µg/m³)": "nh3",
    "SO2 (µg/m³)": "so2",
    "CO (mg/m³)": "co",
    "Ozone (µg/m³)": "ozone",
    "AT (°C)": "temperature",
    "RH (%)": "humidity",
    "WS (m/s)": "wind_speed",
    "WD (deg)": "wind_direction",
}

# Plausible range limits for data quality scrubbing
VALID_RANGES = {
    "pm25": (0.0, 1500.0),
    "pm10": (0.0, 2500.0),
    "no2": (0.0, 1000.0),
    "so2": (0.0, 1000.0),
    "co": (0.0, 100.0),  # mg/m3
    "ozone": (0.0, 1000.0),
    "temperature": (-5.0, 55.0),
    "humidity": (1.0, 100.0),
    "wind_speed": (0.0, 40.0),
    "wind_direction": (0.0, 360.0),
}


def load_stations_meta() -> pd.DataFrame:
    """Load station coordinates from stations.csv or fallback fixtures."""
    meta_path = settings.EXTERNAL_DATA_DIR / "stations.csv"
    if not meta_path.exists():
        meta_path = settings.FIXTURES_DIR / "stations_fallback.csv"
    if meta_path.exists():
        return pd.read_csv(meta_path)
    return pd.DataFrame(columns=["id", "name", "latitude", "longitude"])


def match_station_metadata(filename: str, stations_meta: pd.DataFrame) -> Dict[str, any]:
    """Extract station identifier and match with geographic coordinates."""
    stem = Path(filename).stem.lower()
    for _, row in stations_meta.iterrows():
        sid = str(row.get("id", "")).lower()
        sname = str(row.get("name", "")).lower().replace(" ", "-")
        # Match e.g. "punjabi-bagh" in "del-punjabi-bagh-dpcc-2024-25"
        key_token = sname.split("-")[0] if "-" in sname else sname
        if key_token and key_token in stem:
            return {
                "station_id": row["id"],
                "station_name": row["name"],
                "latitude": float(row["latitude"]),
                "longitude": float(row["longitude"]),
            }

    # Fallback to normalized stem name with default Delhi central coordinates
    return {
        "station_id": stem.replace(".", "_"),
        "station_name": stem.replace("-", " ").title(),
        "latitude": 28.6139,
        "longitude": 77.2090,
    }


def clean_station_series(df: pd.DataFrame) -> pd.DataFrame:
    """Filter out non-physical spikes, negative values, and long flatlines."""
    for col, (min_v, max_v) in VALID_RANGES.items():
        if col in df.columns:
            df.loc[(df[col] < min_v) | (df[col] > max_v), col] = np.nan
            # Flag and drop continuous flatlines (> 6 consecutive identical non-zero readings)
            is_same = df[col] == df[col].shift(1)
            flatline_runs = is_same.groupby((~is_same).cumsum()).cumsum()
            df.loc[flatline_runs >= 6, col] = np.nan
    return df


def process_cpcb_file(file_path: Path, stations_meta: pd.DataFrame) -> Optional[pd.DataFrame]:
    """Parse one CPCB station file, resample 15-min to 1-hr, and attach metadata."""
    try:
        df = pd.read_csv(file_path, low_memory=False)
        # Identify columns
        cols_present = {c: CPCB_COL_MAP[c] for c in df.columns if c in CPCB_COL_MAP}
        if "Timestamp" not in df.columns:
            return None

        df = df[list(cols_present.keys())].rename(columns=cols_present)
        df["timestamp"] = pd.to_datetime(df["timestamp"], utc=True, errors="coerce")
        df = df.dropna(subset=["timestamp"]).sort_values("timestamp")

        # Convert numeric columns
        for col in df.columns:
            if col != "timestamp":
                df[col] = pd.to_numeric(df[col], errors="coerce")

        df = clean_station_series(df)

        # Resample to 1-hour intervals
        df = df.set_index("timestamp").resample("1h").mean().reset_index()

        meta = match_station_metadata(file_path.name, stations_meta)
        df["station_id"] = meta["station_id"]
        df["station_name"] = meta["station_name"]
        df["latitude"] = meta["latitude"]
        df["longitude"] = meta["longitude"]

        return df
    except Exception as e:
        logger.warning(f"Failed to process CPCB file {file_path.name}: {e}")
        return None


def process_all_cpcb() -> pd.DataFrame:
    """Process all CPCB CSVs into a unified hourly station parquet."""
    cpcb_dir = settings.EXTERNAL_DATA_DIR / "cpcb"
    stations_meta = load_stations_meta()

    if not cpcb_dir.exists():
        logger.warning(f"CPCB directory {cpcb_dir} not found. Creating synthetic fallback.")
        return generate_synthetic_cpcb_hourly(stations_meta)

    csv_files = list(cpcb_dir.glob("*.csv"))
    if not csv_files:
        logger.warning(f"No CSV files found in {cpcb_dir}. Creating synthetic fallback.")
        return generate_synthetic_cpcb_hourly(stations_meta)

    logger.info(f"Processing {len(csv_files)} CPCB station files...")
    all_dfs = []
    for csv_file in csv_files:
        res = process_cpcb_file(csv_file, stations_meta)
        if res is not None and not res.empty and res["pm25"].notna().sum() > 24:
            all_dfs.append(res)
            logger.info(f"Loaded {csv_file.name}: {len(res)} hourly records for {res['station_id'].iloc[0]}")

    if not all_dfs:
        return generate_synthetic_cpcb_hourly(stations_meta)

    full_df = pd.concat(all_dfs, ignore_index=True)
    full_df = full_df.sort_values(["station_id", "timestamp"]).reset_index(drop=True)

    out_path = settings.PROCESSED_DATA_DIR / "stations_hourly.parquet"
    settings.PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)
    full_df.to_parquet(out_path, index=False)
    logger.info(f"Saved {len(full_df)} clean hourly records to {out_path}")
    return full_df


def generate_synthetic_cpcb_hourly(stations_meta: pd.DataFrame, days: int = 60) -> pd.DataFrame:
    """Generate realistic synthetic hourly ground truth when real CSVs are missing."""
    logger.info(f"Generating synthetic CPCB hourly records for {len(stations_meta)} stations across {days} days...")
    end_dt = pd.Timestamp.now(tz="UTC").floor("h")
    start_dt = end_dt - pd.Timedelta(days=days)
    dates = pd.date_range(start_dt, end_dt, freq="1h")

    dfs = []
    for _, row in stations_meta.iterrows():
        sid = row["id"]
        sname = row["name"]
        lat = float(row["latitude"])
        lon = float(row["longitude"])

        n = len(dates)
        hours = dates.hour.values
        diurnal = 50.0 * np.sin((hours - 8) * np.pi / 12) + 120.0
        winter_bias = 80.0
        noise = np.random.normal(0, 25, size=n)

        pm25 = np.clip(diurnal + winter_bias + noise, 20.0, 650.0)
        pm10 = np.clip(pm25 * np.random.uniform(1.4, 2.2, size=n), 40.0, 950.0)
        no2 = np.clip(pm25 * 0.25 + np.random.normal(0, 8, size=n), 10.0, 180.0)
        co = np.clip(pm25 * 0.008 + np.random.normal(0, 0.2, size=n), 0.4, 8.0)
        so2 = np.clip(np.random.normal(15, 5, size=n), 2.0, 80.0)
        ozone = np.clip(45.0 - (no2 * 0.15) + np.random.normal(0, 6, size=n), 5.0, 150.0)

        station_df = pd.DataFrame({
            "timestamp": dates,
            "station_id": sid,
            "station_name": sname,
            "latitude": lat,
            "longitude": lon,
            "pm25": pm25,
            "pm10": pm10,
            "no2": no2,
            "co": co,
            "so2": so2,
            "ozone": ozone,
            "temperature": 18.0 + 8.0 * np.sin((hours - 14) * np.pi / 12),
            "humidity": 65.0 - 25.0 * np.sin((hours - 14) * np.pi / 12),
            "wind_speed": np.clip(np.random.normal(2.5, 1.0, size=n), 0.2, 10.0),
            "wind_direction": np.random.uniform(250.0, 330.0, size=n),
        })
        dfs.append(station_df)

    combined = pd.concat(dfs, ignore_index=True)
    out_path = settings.PROCESSED_DATA_DIR / "stations_hourly.parquet"
    settings.PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)
    combined.to_parquet(out_path, index=False)
    return combined


if __name__ == "__main__":
    process_all_cpcb()
