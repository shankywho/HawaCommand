# AI-ML data and training

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**AI-ML docs:** [Runbook](../../AI-ML/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · [Models](MODELS.md) · [Agents](AGENTS.md) · **Data and training** · [Engine API](../../AI-ML/CONTRACTS.md) · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/data%20sources-7-0E7C66" alt="7 sources">
<img src="https://img.shields.io/badge/every%20source-has%20a%20fallback-6E7781" alt="Fallbacks">
<img src="https://img.shields.io/badge/training-make%20data%20%26%26%20make%20train-02569B" alt="make train">
</p>

Where the engine's data comes from, how datasets are built, and how models are trained and refreshed.

---

## Data sources

| Source | Module | What it gives | Without a key or network |
|---|---|---|---|
| WAQI | backend `core/intel_client.py` | Live Delhi station AQI, converted to PM2.5 | OpenAQ, then 5 baseline stations |
| OpenAQ v3 | `ingestion/openaq.py` | Station metadata and measurements | `data/fixtures/stations_fallback.csv` |
| CPCB / DPCC | `ingestion/cpcb.py` | 15-minute station history (CSV in `data/external/cpcb/`) | 60 days of synthetic data |
| Open-Meteo + CAMS | `ingestion/openmeteo.py` | 72 h weather and CAMS air quality | Defaults |
| NASA FIRMS VIIRS | `ingestion/firms.py` | Active fires in Punjab, Haryana, NCR; upwind counts | Synthetic fires |
| OpenStreetMap | `ingestion/osm.py`, `bus_routes_osm.py` | Schools, hospitals, markets, land use, bus corridors | Synthetic POIs |
| WorldPop | `ingestion/worldpop.py` | 1 km population raster (2020) | Synthetic density |

- Keys live in `AI-ML/.env`: `OPENAQ_API_KEY`, `NASA_FIRMS_MAP_KEY`; `OFFLINE_MODE=true` turns off every network call.
- Fetch everything once: `python scripts/fetch_all.py`.

---

## Datasets

| Dataset | Built by | Path |
|---|---|---|
| Hourly station series | `scripts/build_dataset.py` step 1 | `data/processed/stations_hourly.parquet` |
| 500 m grid (10,600 cells) with covariates | step 2, `twin/grid.py` | `data/processed/grid_covariates_500m.parquet` |
| 1 km planning grid | step 3 | `data/processed/grid_covariates_1000m.parquet` |
| Demo intervention + simulated telemetry | `scripts/demo_seed.py` | `data/internal/synthetic_data/`, `data/interim/` |

- Grid covariates per cell: population, vulnerability weight, primary land use, road density, distance to schools and hospitals, ward.
- `data/processed/` is generated and not committed; `make aiml-data` rebuilds the grids.

---

## Training

```bash
cd AI-ML
make data     # fetch + build datasets
make train    # 21 forecaster models + attribution classifier + model cards + metrics
```

| Step | Script | Writes |
|---|---|---|
| Forecaster | `scripts/train_all.py` → `forecasting/train.py` | `models/lgb_pm25_*.txt`, `forecaster_model_card.md`, `reports/forecast_metrics.json` |
| Attribution classifier | `scripts/train_all.py` → `attribution/classifier.py` | `models/attribution_classifier.txt`, `attribution_model_card.md` |
| Evaluation | `scripts/eval_metrics.py` | Printed metrics |

- Split: temporal, with a leakage assertion between train and test.
- Baseline: persistence (`forecasting/baselines.py`); skill is reported against it.
- Model files are committed (5.4 MB) and must keep LF line endings.

---

## Runtime state files

| File | Updated by |
|---|---|
| `data/internal/effectiveness_library.json` | Each verified intervention |
| `data/internal/calibration_profiles.json` | Drive-by calibration |
| `data/internal/synthetic_data/known_interventions.json` | Demo seeding |
| `data/fixtures/demo_scenario.json` | Demo seeding |

- Tests and demos rewrite these; restore with `git checkout -- AI-ML/data` before committing.

---

## Simulation

| Piece | Code | Purpose |
|---|---|---|
| Sensor fleet | `simulation/device_sim.py` | HawaPod-M buses, school pods and sprinkler tags producing telemetry packets |
| Noise models | `simulation/noise_models.py` | Humidity swelling, speed pressure drop, per-device drift, exhaust spikes, dropouts |
| Injected interventions | `simulation/interventions.py` | Known-effect sprays to test the causal verifier |
| Ghost-worker auditor | `simulation/audit.py` | Fallback audit for vehicles without live telemetry |

- Live vehicle telemetry for the demo comes from the backend's `hawa simulate-fleet` through IoT Core and Kinesis ([backend services](../backend/SERVICES.md#fleet-telemetry)).

---

## Related

- [AI-ML architecture](ARCHITECTURE.md) · [Models](MODELS.md) · [Agents](AGENTS.md) · [Data folder](../../AI-ML/data/README.md)

<!-- footer:start -->

---

[Back to top](#ai-ml-data-and-training) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
