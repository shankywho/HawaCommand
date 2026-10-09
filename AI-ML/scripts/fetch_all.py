"""Fetch and cache external datasets from OpenAQ, Open-Meteo, FIRMS, and OpenStreetMap.

Can run completely offline (OFFLINE_MODE=true) or when API keys are missing by using fixtures.
Never leaks secrets to logs or cache files.
"""
import sys
from pathlib import Path

# Add src to sys.path
BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE_DIR / "src"))

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.ingestion.openaq import OpenAQClient
from hawa_ml.ingestion.openmeteo import OpenMeteoClient
from hawa_ml.ingestion.firms import FIRMSClient
from hawa_ml.ingestion.osm import OSMClient
from hawa_ml.ingestion.bus_routes_osm import generate_bus_routes

logger = configure_logging("fetch_all")


def fetch_all_external_data():
    logger.info("=== HawaCommand Data Fetcher Pipeline ===")

    # 1. Stations Metadata
    logger.info("[1/5] Fetching station coordinates (OpenAQ / Fallback)...")
    openaq_client = OpenAQClient()
    stations_df = openaq_client.fetch_delhi_stations()
    logger.info(f"Stations ready: {len(stations_df)} stations.")

    # 2. Open-Meteo Weather Forecast & CAMS
    logger.info("[2/5] Querying Open-Meteo for 72h weather and CAMS baseline...")
    meteo_client = OpenMeteoClient()
    weather_df = meteo_client.fetch_weather_forecast()
    cams_df = meteo_client.fetch_cams_baseline()
    logger.info(f"Weather forecast: {len(weather_df)} hrs, CAMS baseline: {len(cams_df)} hrs.")

    # 3. NASA FIRMS Fire Detections
    logger.info("[3/5] Querying NASA FIRMS for upwind agricultural stubble fires...")
    firms_client = FIRMSClient()
    fires_df = firms_client.fetch_active_fires(days=3)
    fire_feats = firms_client.compute_upwind_fire_features()
    logger.info(f"Active fires: {len(fires_df)} points. Upwind 500km count: {fire_feats['fire_count_upwind_500km']}")

    # 4. OpenStreetMap POIs (Schools, Hospitals, Markets)
    logger.info("[4/5] Fetching infrastructure POIs from OpenStreetMap Overpass...")
    osm_client = OSMClient()
    pois = osm_client.fetch_pois()
    logger.info(f"POIs ready: {len(pois['schools'])} schools, {len(pois['hospitals'])} hospitals, {len(pois['markets'])} markets.")

    # 5. Bus Routes for Fleet Simulator
    logger.info("[5/5] Generating transit bus corridors for mobile sensors...")
    routes = generate_bus_routes()
    logger.info(f"Transit corridors: {len(routes)} routes generated.")

    logger.info("=== All external datasets successfully fetched and cached ===")


if __name__ == "__main__":
    fetch_all_external_data()
