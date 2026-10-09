# HawaCommand Data Layer Guide

This directory holds the raw, interim, processed, and external datasets used by the HawaCommand AI-ML Engine.

## Manual Downloads & External Data

### 1. CPCB / DPCC Historical Station Data (`data/external/cpcb/`)
* **Source:** OpenCity Delhi Air Quality Archives / CPCB CCR Portal.
* **Format:** Station CSV files (e.g. `del-punjabi-bagh-dpcc-2024-25.csv`, `del-r-k-puram-dpcc-2024-25.csv`).
* **Granularity:** 15-minute or hourly measurements of PM2.5, PM10, NO2, CO, SO2, O3, Temp, RH, Wind.
* **Status:** Pre-loaded in `data/external/cpcb/`. The ingestion pipeline automatically normalizes units and resamples all records to regular 1-hour intervals.

### 2. WorldPop Population Raster (`data/external/worldpop/`)
* **Source:** WorldPop India 2020 1km Unconstrained Population Count.
* **File:** `ind_ppp_2020_1km_Aggregated.tif`
* **Download URL:** [WorldPop Hub - India 1km Population](https://hub.worldpop.org/geodata/summary?id=24777)
* **Status:** Placed in `data/external/worldloop/` or `data/external/worldpop/`. The engine reads and clips this raster to the Delhi National Capital Territory bounding box.

### 3. OpenAQ Station Metadata (`data/external/stations.csv`)
* Auto-generated dynamically via `scripts/fetch_all.py` using `OPENAQ_API_KEY`.
* If no key is provided, the pipeline loads `data/fixtures/stations_fallback.csv` containing official Delhi CAAQMS stations.

## Directory Structure
* `raw/`: Unprocessed API responses and raw dumps.
* `interim/`: Resampled and cleaned intermediate matrices.
* `processed/`: Final parquet files (e.g. `stations_hourly.parquet`, `grid_covariates.parquet`).
* `cache/`: Local disk HTTP cache with TTL (all authorization headers stripped).
* `fixtures/`: Fallback fixtures for full offline execution (`OFFLINE_MODE=true`).
