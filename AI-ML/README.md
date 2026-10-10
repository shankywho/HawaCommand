# HawaCommand AI-ML Engine

The Python package `hawa_ml` that holds HawaCommand's predictive, spatial, exposure, dispatch and causal-verification logic, plus a FastAPI app that serves it over HTTP. HawaCommand (Environmental Hacks 2026, Air Track) aims to close Delhi's anti-pollution loop: Sense, Map, Attribute, Forecast, Decide, Act, Verify.

This README is the runbook: what is built, how to install, configure, run and test it, every endpoint, script and Make target, and the known defects. Design documents live in [`docs/aiml/`](../docs/aiml/README.md); the HTTP and in-process contracts are in [CONTRACTS.md](CONTRACTS.md); the data layout is in [data/README.md](data/README.md).

---

## 1. Implementation status

Status vocabulary used in all AI-ML docs: **Implemented** (works as described), **Partial** (works, with the gap stated), **Stub/Mock** (returns fixtures, hard-coded or synthetic data), **Planned** (not in code).

| Area | Code | Status | Notes |
|---|---|---|---|
| Settings, `.env` loading, secret masking | `settings.py`, `logging_conf.py` | Partial | `.env` loading, `mask_secret()` and log scrubbing work; `LOG_LEVEL` is read but never applied (§9, issue 12) |
| Telemetry packet schema (Proposal §10.6) | `schemas.py` `TelemetryPacket` | Implemented | Pydantic validation with physical ranges |
| 500 m and 1 km grid with covariates | `twin/grid.py`, `geo.py` | Partial | 10,600 cells at 500 m, 2,650 at 1 km; wards are synthetic labels `Ward-1`..`Ward-12` (row mod 12), not MCD boundaries |
| CPCB/DPCC CSV ingestion | `ingestion/cpcb.py` | Implemented | Needs manually placed CSVs in `data/external/cpcb/`; otherwise writes a synthetic 60-day dataset |
| OpenAQ station metadata | `ingestion/openaq.py` | Partial | Station locations only; no measurement download |
| Open-Meteo weather and CAMS | `ingestion/openmeteo.py` | Partial | Fetched by `fetch_all.py` but not consumed by any model; JSON cache writes are broken (issue 6) |
| NASA FIRMS fires | `ingestion/firms.py` | Partial | Fetch and upwind counts work; no model or endpoint uses them |
| OSM POIs, WorldPop, bus corridors | `ingestion/osm.py`, `worldpop.py`, `bus_routes_osm.py` | Implemented | Each has a synthetic fallback; bus routes are 6 synthetic corridors between 15 hubs, not GTFS |
| Fleet simulator (HawaPod-M/S, HawaTag) | `simulation/` | Implemented | File (JSONL) mode; `--mode mqtt` is a Stub/Mock that only writes the file |
| Drive-by calibration | `calibration/drive_by.py` | Partial | Huber fit and per-reading correction work; co-location pairing (200 m, < 30 km/h) is not implemented, fits are only run by tests |
| Digital twin (GP kriging + wind shift) | `twin/kriging.py`, `twin/advection.py` | Implemented | LOSO evaluation loses to nearest-station and IDW baselines (§7) |
| Multi-source fusion | `twin/fusion.py` | Implemented | Not called by any route, pipeline or script |
| Rule-based source attribution | `attribution/rules.py` | Implemented | Used by the exposure engine for every hotspot |
| LightGBM attribution classifier | `attribution/classifier.py` | Partial | Trained on weak proxy labels; not used by any runtime path |
| Back-trajectory suspect pin | `attribution/backtrajectory.py` | Implemented | Single straight-line trajectory, fixed default wind |
| 72 h quantile forecaster, training | `forecasting/train.py`, `features.py` | Implemented | 7 horizons x P10/P50/P90 = 21 LightGBM models; training subset bug (issue 4) |
| 72 h quantile forecaster, inference | `forecasting/predict.py` | Partial | `cell_id` is ignored; every lag and rolling feature is filled from one `current_pm25` value; weather inputs are fixed defaults |
| CPCB AQI and CAQM GRAP stage | `forecasting/grap.py` | Implemented | Fractional concentrations between breakpoints return AQI 500 (issue 1) |
| Safe outdoor window | `forecasting/safe_window.py` | Stub/Mock | Fixed 24-hour multiplier curve times a baseline; not driven by the forecaster |
| Safe route (inhaled dose) | `exposure/routing.py` | Stub/Mock | Route geometry and PM levels are synthetic multiples of a background value; no road graph, no twin lookup |
| Exposure engine | `exposure/engine.py` | Implemented | `E = max(0, C - 60) x Pop x diurnal multiplier x V x dt` |
| Hotspot ranking | `exposure/engine.py` `get_ranked_hotspots` | Partial | Top-N cells by exposure; no clustering, tracking or forecast look-ahead |
| Dispatch optimiser | `optimization/greedy.py`, `vrp.py` | Partial | Greedy cause-compatible allocation is Implemented; OR-Tools CVRP is Planned (`vrp.py` detects OR-Tools but always runs greedy) |
| What-If vs usual routes | `optimization/whatif.py` | Stub/Mock | Baseline is the AI result times a constant 0.32, so the gain is always 212.5 % |
| Synthetic control + placebo | `causal/synthetic_control.py`, `placebo.py` | Implemented | Algorithm only; validated on one seeded synthetic panel |
| Intervention verification (API, pipeline) | `api/routes.py`, `pipelines/verify.py` | Stub/Mock | Always re-runs the seeded injected-effect test; the intervention id is ignored |
| Effectiveness library | `causal/effectiveness_library.py` | Partial | JSON-persisted running average; key mismatch means verified results never reach the optimiser (issue 2) |
| IoT "ghost worker" auditor | `simulation/audit.py` | Stub/Mock | Hard-coded `FLEET_TELEMETRY` for 3 assets |
| Insight triggers and narratives | `insights/` | Partial | 4 of the 7 documented triggers exist; narratives are templates (no LLM call) |
| Agents (Forecaster, Planner, Auditor, Communicator) | `agents/` | Partial | Plain Python classes; LLM (Groq or Bedrock) only rephrases; deterministic templates when no key; no tool-calling, no output validation |
| Operational cycle, evening master plan | `pipelines/cycle.py`, `master_plan.py` | Partial | Sensing is simulated; the planner re-ranks hotspots from a constant PM field instead of the cycle's twin (issue 7) |
| HTTP API | `api/main.py`, `api/routes.py` | Implemented | 13 routes, mounted at `/`, `/v1` and `/internal/v1`; no authentication; CORS `*` |
| Kafka workers, Postgres/Redis/S3/MLflow, trainer CLI, internal `/simulate` `/optimize` `/exposure` `/models` `/alerts/draft` | — | Planned | Target design in [docs/aiml/ARCHITECTURE.md](../docs/aiml/ARCHITECTURE.md) |
| Citizen Eyes, anti-gaming guard, coverage router, site score, TinyML spike, HawaEye, evidence narrative, power proxy, MQTT ingest | — | Planned | Target designs in [docs/aiml/MODELS.md](../docs/aiml/MODELS.md) |

The physical sensor fleet does not exist; all mobile, school-sentinel and HawaTag data is produced by `simulation/device_sim.py`. Causal verification has only been demonstrated on a seeded synthetic panel with a known injected effect.

---

## 2. Install

Requires Python 3.11 or newer (`pyproject.toml`); verified with Python 3.12.3. Run everything from the `AI-ML/` directory.

```bash
cd AI-ML
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt     # runtime + pytest + groq/openai clients
pip install -e ".[dev]"             # installs hawa_ml itself (required, see note)
```

Install `hawa_ml` in editable mode. `make setup` only installs `requirements.txt`, so its own import check, `make api`, `uvicorn` and `scripts/eval_metrics.py` fail with `ModuleNotFoundError: No module named 'hawa_ml'` until `pip install -e .` has been run (the package lives in `src/`). A non-editable install is not supported: `settings.BASE_DIR` is computed from the source location and `config/`, `models/`, `data/` and `agents/prompts/` are not packaged.

Optional extras that are not declared anywhere: `boto3` (Bedrock LLM provider), `ortools` (detected but unused), `matplotlib` (`scripts/generate_report_assets.py`), `reportlab` (the two PDF scripts).

### Dependencies

| File | Packages |
|---|---|
| `pyproject.toml` `dependencies` | pydantic>=2.7.0, pydantic-settings>=2.2.0, requests>=2.31.0, pandas>=2.2.0, numpy>=1.26.0, pyarrow>=15.0.0, scikit-learn>=1.4.0, scipy>=1.12.0, lightgbm>=4.3.0, pyyaml>=6.0.1, pillow>=10.0.0, fastapi>=0.110.0, uvicorn>=0.28.0 |
| `pyproject.toml` `[dev]` | pytest>=8.0.0, pytest-asyncio>=0.23.0, httpx>=0.27.0 |
| `requirements.txt` (adds) | urllib3>=2.0.0, shapely>=2.0.0 (unused), groq>=0.5.0, openai>=1.20.0, python-dotenv>=1.0.1 |

---

## 3. Configure

All settings come from environment variables or `AI-ML/.env` (pydantic-settings, `settings.py`). Copy `.env.example` to `.env`; every key is optional. With no `.env` the engine runs: LLM text falls back to templates, OpenAQ and FIRMS fall back to fixtures and synthetic data. Open-Meteo and the Overpass API need no key and are called over the network unless `OFFLINE_MODE=true`.

| Variable | Default | Read by | Effect |
|---|---|---|---|
| `OFFLINE_MODE` | `false` | `llm_provider.py`, `ingestion/openaq.py`, `openmeteo.py`, `osm.py`, `firms.py` | `true` forces the template LLM client and synthetic or fixture data for every external source |
| `LLM_PROVIDER` | `groq` | `agents/llm_provider.py` | `groq` or `bedrock`; anything else gives template text |
| `GROQ_API_KEY` | unset | `agents/llm_provider.py` | Enables `GroqLLMClient` (model `openai/gpt-oss-120b`, temperature 0.2, max_tokens 600) when `LLM_PROVIDER=groq` |
| `BEDROCK_MODEL_ID` | `anthropic.claude-3-5-sonnet-20241022-v2:0` | `agents/llm_provider.py` | Bedrock model when `LLM_PROVIDER=bedrock` (needs `boto3`, max_tokens 800, temperature 0.2) |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | unset | `agents/llm_provider.py` | Passed to `boto3.Session`; unset uses the default AWS credential chain |
| `AWS_REGION` | `ap-south-1` | `agents/llm_provider.py` | Bedrock runtime region |
| `OPENAQ_API_KEY` | unset | `ingestion/openaq.py` | Live OpenAQ v3 `/locations` query for Delhi stations; else `data/fixtures/stations_fallback.csv` |
| `NASA_FIRMS_MAP_KEY` | unset | `ingestion/firms.py` | Live VIIRS S-NPP NRT fire points; else synthetic Punjab/Haryana fires |
| `WAQI_TOKEN`, `CDS_API_KEY`, `DATA_GOV_IN_API_KEY` | unset | `scripts/check_env.py` only | Declared and reported, not used by any ingestion code |
| `LOG_LEVEL` | `INFO` | `scripts/check_env.py` only | Printed, never applied to the logger |

`.env.example` lists all of the above. `.gitignore` excludes `.env`, `.env.*` (except `.env.example`), `*.pem`, `*.key`, `**/*credentials*`, `**/*secret*`, `.cdsapirc`, `data/cache|external|raw|interim|processed/`, virtualenvs, caches and `*.egg-info/`.

YAML configuration in `config/` (read at import time):

| File | Loaded by | Contents |
|---|---|---|
| `cpcb_breakpoints.yaml` | `forecasting/grap.py` | IND-AQI category ranges; PM2.5, PM10, NO2, CO breakpoints |
| `grap.yaml` | `forecasting/grap.py` | Stage 1-4 AQI and PM2.5 minimums, lead times, mandated actions |
| `fingerprint_rules.yaml` | `attribution/rules.py` | Per-cause ratio, gas and hour thresholds |
| `weights.yaml` | `exposure/engine.py` | `c_safe_pm25: 60`; diurnal population multipliers for `school`, `market`, `residential` (its `vulnerability_weights` block is not read) |
| `settings.yaml` | nothing | Descriptive parameters only; no code loads it |

---

## 4. Run

### 4.1 HTTP API

```bash
uvicorn hawa_ml.api.main:app --host 127.0.0.1 --port 8100
```

Port 8100 is what the backend expects (`HAWA_AIML_SERVICE_URL=http://localhost:8100` in `backend/.env.example`). `make api` and `python -m hawa_ml.api.main` use port 8000 with `--reload`, which collides with the backend API on 8000. OpenAPI docs: `http://localhost:8100/docs`. First import loads 21 forecaster boosters and the attribution booster, and builds `data/processed/grid_covariates_500m.parquet` if it is missing (about 2 s offline).

### 4.2 Make targets

| Target | Runs | Status |
|---|---|---|
| `make help` | Prints the target list (omits `clean`) | Implemented |
| `make setup` | `pip install -r requirements.txt`, then `python -c "import hawa_ml.settings"` | Partial: the import check fails unless `pip install -e .` was run first |
| `make env-check` | `python scripts/check_env.py` | Implemented |
| `make data` | `scripts/fetch_all.py` then `scripts/build_dataset.py` | Implemented; rewrites the tracked `data/fixtures/bus_routes_delhi.json` with new random jitter |
| `make train` | `scripts/train_all.py` | Implemented; overwrites the tracked `models/*.txt`, model cards and `reports/forecast_metrics.json` |
| `make demo` | `scripts/demo_seed.py` then `scripts/run_cycle.py --once` | Implemented; mutates tracked files (§9 issue 3) |
| `make test` | `pytest -v tests/` | Partial: collection error `ModuleNotFoundError: No module named 'scripts'` in `tests/test_phase7_api_pipelines.py`; use `python -m pytest` |
| `make api` | `uvicorn hawa_ml.api.main:app --host 0.0.0.0 --port 8000 --reload` | Partial: wrong port for the backend; needs the editable install |
| `make clean` | Deletes `__pycache__` and `.pytest_cache` directories | Implemented |

### 4.3 Scripts (`scripts/`)

Scripts that call `sys.path.insert(0, "src")` work without the editable install; run them from `AI-ML/`.

| Script | Does | Writes | Status |
|---|---|---|---|
| `check_env.py` | Masked key checklist, presence of `data/external/cpcb/*.csv` and the WorldPop GeoTIFF, mode summary | nothing | Implemented (reports `BEDROCK_MODEL_ID` as PRESENT because it has a default) |
| `fetch_all.py` | OpenAQ stations, Open-Meteo 72 h weather + CAMS, FIRMS 3-day fires + upwind counts, OSM POIs, bus corridors | `data/external/stations.csv`, `data/cache/{openaq,openmeteo,firms,osm}/`, `data/fixtures/bus_routes_delhi.json` | Implemented |
| `build_dataset.py` | CPCB CSVs to hourly parquet (synthetic if absent); 500 m and 1 km grids | `data/processed/stations_hourly.parquet`, `grid_covariates_500m.parquet`, `grid_covariates_1000m.parquet` | Implemented |
| `train_all.py` | Forecaster (21 models) and attribution classifier | `models/lgb_pm25_*.txt`, `models/attribution_classifier.txt`, both model cards, `reports/forecast_metrics.json` | Implemented |
| `demo_seed.py` | Injects a known sprinkler intervention, writes 40 simulator steps, writes the demo scenario JSON | `data/internal/synthetic_data/known_interventions.json` (append), `data/interim/simulated_telemetry.jsonl`, `data/fixtures/demo_scenario.json` | Implemented |
| `run_cycle.py` | One 3-hour cycle (`--once`, default) or a loop (`--loop --interval-sec 10800`) | nothing beyond logs | Partial (`--once` is a no-op flag; see §1) |
| `eval_metrics.py` | Prints attribution accuracy/precision/recall/F1 and forecaster "PM2.5 >= 150" alert metrics on the last 20 % of `stations_hourly.parquet` | nothing | Partial: needs the editable install; evaluates in-sample (issue 9) |
| `generate_report_assets.py` | Draws `reports/figures/fig1..fig8_*.png` | `reports/figures/` (relative to the working directory) | Stub/Mock: every number is hard-coded; figs 2, 6, 7, 8 are illustrative; needs `matplotlib` |
| `generate_ai_ml_report_pdf.py` | Builds the evaluation whitepaper PDF | `reports/HawaCommand_AI_ML_Model_Evaluation_Report.pdf` | Stub/Mock: hard-coded text and tables, several claims contradict the code (issue 10); needs `reportlab` |
| `generate_citizen_app_pdf.py` | Builds the HawaCitizen product blueprint PDF | `docs/HawaCitizen_App_Comprehensive_Blueprint.pdf` relative to the working directory (the committed copy is at the repo root `docs/`) | Stub/Mock (product spec text); needs `reportlab` |

### 4.4 Module entry points

`python -m <module>` from `AI-ML/` (editable install) runs a small demo or job:

| Module | Action |
|---|---|
| `hawa_ml.api.main` | Uvicorn on 0.0.0.0:8000 with reload |
| `hawa_ml.pipelines.cycle` | `run_3hour_cycle()` |
| `hawa_ml.pipelines.master_plan` | `run_evening_master_plan()` (cycle + school alert) |
| `hawa_ml.pipelines.verify` | `run_post_action_verification()` (synthetic recovery test; mutates the library) |
| `hawa_ml.simulation.device_sim` | `--mode file\|mqtt --steps 60 --out data/interim/simulated_telemetry.jsonl` |
| `hawa_ml.twin.kriging` | Leave-one-station-out evaluation, writes `reports/twin_metrics.json` |
| `hawa_ml.forecasting.train` | Forecaster training only |
| `hawa_ml.attribution.classifier` | Trains the classifier if `stations_hourly.parquet` exists, prints one prediction |
| `hawa_ml.causal.placebo` | Injected-effect recovery test (writes `reports/verifier_metrics.json`, updates the library) |
| `hawa_ml.twin.grid` | Rebuilds both grids |
| `hawa_ml.ingestion.{cpcb,openaq,openmeteo,firms,osm,worldpop,bus_routes_osm}` | Run one ingestion step |
| `hawa_ml.forecasting.{predict,grap}`, `hawa_ml.exposure.engine`, `hawa_ml.optimization.vrp`, `hawa_ml.attribution.{rules,backtrajectory}`, `hawa_ml.calibration.drive_by`, `hawa_ml.causal.effectiveness_library`, `hawa_ml.agents.communicator_agent` | Print a sample result |

---

## 5. HTTP API

`api/main.py` mounts one router three times: at `/`, at `/v1` and at `/internal/v1`, so every path below also exists under both prefixes (39 operations). There is no authentication and CORS allows every origin. Full request and response schemas with examples: [CONTRACTS.md](CONTRACTS.md).

| Method | Path | Parameters / body | Response | Status |
|---|---|---|---|---|
| GET | `/health`, `/healthz` | — | `{status, service, timestamp, offline_mode, llm_provider, models{...}}` (model names are fixed strings) | Implemented |
| GET | `/twin` | `bbox=min_lat,min_lon,max_lat,max_lon` (malformed values ignored), `ts` (echoed), `limit` (default 500, max 2000) | `{timestamp, total_cells, returned_cells, cells[]}`; each cell has the grid covariates plus `pm25_est`, `pm10_est`, `variance`, `confidence` | Partial: GP fitted on 4 hard-coded observations on every call |
| GET | `/forecast/{cell_id}` | `pm25` (default 210.0) | `{cell_id, peak_horizon_h, peak_pm25_p50, peak_pm25_p90, grap_stage, grap_stage_number, mandated_actions[], summary, points[7], horizons[7]}` | Partial: `cell_id` only echoed; result depends on `pm25` and the clock |
| GET | `/hotspots` | `ward` (default `all`; unknown wards fall back to all), `limit` (default 10, max 50), `hour` (0-23, default 8) | `Hotspot[]` | Partial: PM field is synthetic (`210 + 1.5 x row`, PM10 = 1.6 x PM2.5), so every hotspot is `unknown` / `monitor` |
| POST | `/plans/draft` | `{ward="all", limit_hotspots=10, shift_hours=4.0, assets: AssetSpec[]}` (body required; empty `assets` uses SPR-04, ASG-02, INSP-01) | `{plan_id, created_at, status, total_exposure_avoided_person_hours, tasks: PlanTask[], planner_reasoning, hotspots: Hotspot[], auditor_verdict, auditor_critique}` | Partial: hotspots use constant PM2.5 180 / PM10 280; nothing is stored |
| POST | `/plans/{plan_id}/simulate` | `{hotspots: Hotspot[], assets: AssetSpec[]}` (body required, may be `{}`) | `{ai_plan{...}, usual_fixed_route_baseline{...}, comparison{delta_person_hours_avoided, gain_percentage, summary}, plan_id}` | Stub/Mock: `plan_id` not looked up; gain is always 212.5 % |
| POST | `/interventions/{intervention_id}/verify` | — | `{intervention_id, method, measured_effect_pct, ci_low_pct, ci_high_pct, duration_minutes, status, acceptance_check_passed}` | Stub/Mock: always -18.82 % [-22.24, -15.40]; `duration_minutes` fixed at 90 |
| GET, POST | `/interventions/{intervention_id}/impact` | — | same as `/verify` | Stub/Mock (the GET also writes files) |
| GET | `/insights` | `since` (ignored) | `{count, insights: [{insight: Insight, narrative: Narrative}]}` | Stub/Mock: computed on 20 cells forced to PM2.5 265, school cluster |
| POST | `/ingest/telemetry` | `TelemetryPacket` or `TelemetryPacket[]` | `{ingested_count, records: [{dev, seq, raw_pm25, calibrated_pm25, trust_score, status}]}` | Partial: calibrates each reading; nothing is stored or forwarded |
| GET | `/effectiveness-library`, `/effectiveness` | — | `{records: EffectivenessRecord[]}` | Implemented |

`verify`, `impact` (GET and POST) and `/plans/*` have side effects: each verification call increments `sample_count` in `data/internal/effectiveness_library.json` and rewrites `reports/verifier_metrics.json`.

---

## 6. Test

```bash
cd AI-ML
python -m pytest -q          # not plain `pytest`, see make test above
```

`python -m pytest` puts `AI-ML/` on `sys.path`, which `tests/test_phase7_api_pipelines.py` needs for `from scripts.demo_seed import seed_demo_scenario`; `pyproject.toml` adds `src` via `[tool.pytest.ini_options] pythonpath`.

| File | Tests | Covers |
|---|---|---|
| `tests/test_phase0_scaffold.py` | 4 | `mask_secret`, log scrubbing, `TelemetryPacket`, haversine and cell ids |
| `tests/test_phase1_data.py` | 5 | `stations_hourly.parquet` contents, grids, Open-Meteo, FIRMS features, OSM POIs and bus routes |
| `tests/test_phase2_forecast.py` | 3 | AQI/GRAP mapping, `reports/forecast_metrics.json` beats persistence, live prediction ordering |
| `tests/test_phase3_twin_sim.py` | 4 | Humidity noise, simulator packets, Huber calibration, twin prediction |
| `tests/test_phase4_attribution_exposure.py` | 3 | Four rule classes, back-trajectory direction, exposure ranks people over empty cells |
| `tests/test_phase5_optimization_causal.py` | 4 | Injected-effect recovery, library update, cause compatibility, What-If gain > 100 % |
| `tests/test_phase6_agents_insights.py` | 5 | Forecaster, Planner, Auditor (water-on-smoke rejected), Communicator, insights + narratives |
| `tests/test_phase7_api_pipelines.py` | 10 | Every HTTP route through `TestClient`, demo seed + one cycle |

Results obtained on 2026-10-10 (Python 3.12.3):

| Run | Result |
|---|---|
| `pytest -v tests/` (what `make test` runs) | Collection error in `tests/test_phase7_api_pipelines.py`: `ModuleNotFoundError: No module named 'scripts'` |
| `python -m pytest -q -W ignore` on a clean checkout | 37 passed, 1 failed in 6.5 s: `test_phase1_data.py::test_processed_stations_hourly_dataset` needs the gitignored `data/processed/stations_hourly.parquet` |
| Same, after `OFFLINE_MODE=true python scripts/fetch_all.py && python scripts/build_dataset.py && python scripts/train_all.py` (about 13 s, synthetic data) | 38 passed in 2.0 s |

The suite is not hermetic. Each run rewrites four tracked files (`data/fixtures/demo_scenario.json`, `data/internal/calibration_profiles.json`, `data/internal/effectiveness_library.json`, `data/internal/synthetic_data/known_interventions.json`) plus the ignored `data/interim/simulated_telemetry.jsonl`, and with `OFFLINE_MODE=false` it calls the Open-Meteo API. Run it in a scratch copy, or restore those files with `git checkout -- AI-ML/data` afterwards.

---

## 7. Measured results

All numbers below are copied from the committed `reports/*.json`. None are produced by an LLM. The `reports/figures/` PNGs and the PDF report are drawn from hard-coded values, not read from these files.

### 7.1 Forecaster (`reports/forecast_metrics.json`)

Single temporal split: last 45 days held out (`train.py`), on the rows selected by `df_raw.tail(45000)` when the dataset exceeds 50,000 rows (issue 4). Baseline is persistence only.

| Horizon | P50 MAE | P50 RMSE | Persistence MAE | Skill vs persistence | P10-P90 coverage | Pinball P10 / P50 / P90 |
|---|---|---|---|---|---|---|
| 1h | 45.75 | 68.56 | 53.41 | 14.3 % | 77.8 % | 9.11 / 22.88 / 12.18 |
| 3h | 46.81 | 69.13 | 58.19 | 19.6 % | 82.1 % | 9.24 / 23.41 / 12.98 |
| 6h | 48.58 | 71.56 | 66.83 | 27.3 % | 85.8 % | 9.91 / 24.29 / 13.39 |
| 12h | 54.80 | 79.79 | 61.00 | 10.2 % | 81.1 % | 10.88 / 27.40 / 17.04 |
| 24h | 63.55 | 88.28 | 72.60 | 12.5 % | 77.9 % | 11.49 / 31.77 / 19.05 |
| 48h | 71.27 | 98.68 | 91.00 | 21.7 % | 74.3 % | 12.65 / 35.64 / 21.95 |
| 72h | 73.78 | 103.47 | 95.22 | 22.5 % | 75.5 % | 12.83 / 36.89 / 22.52 |

MAE, RMSE and pinball loss in µg/m³. Nominal P10-P90 coverage is 80 %.

### 7.2 Digital twin (`reports/twin_metrics.json`)

Leave-one-station-out on station-mean PM2.5 (`python -m hawa_ml.twin.kriging`):

| Metric | Value |
|---|---|
| GP kriging MAE / RMSE | 37.82 / 38.44 µg/m³ |
| Nearest-station baseline MAE | 7.4 µg/m³ |
| IDW baseline MAE | 7.05 µg/m³ |
| Skill vs nearest station | -411.2 % |
| Stations evaluated | 3 |

The GP is worse than both baselines. The 10,600-cell coverage is a property of the grid, not an accuracy result. When fewer than 3 stations are available the code writes fixed placeholder metrics instead (`kriging.py` `_default_validation_metrics`).

### 7.3 Causal verifier (`reports/verifier_metrics.json`)

`verify_injected_intervention_recovery()`: 10 donors, 6 pre and 4 post steps, numpy seed 42, a -18.5 % effect injected into a counterfactual built from three donors.

| Metric | Value |
|---|---|
| Injected / recovered effect | -18.5 % / -18.82 % |
| Absolute error (tolerance 3.5) | 0.32 percentage points, `passed: true` |
| 95 % placebo interval | [-22.24 %, -15.40 %] |
| Placebo p-value | 0.0, `is_significant: true` |
| Duration estimate | 120 min (the API reports a fixed 90) |

---

## 8. Integration with other components

| Caller | How | What it uses |
|---|---|---|
| Backend `IntelClient` (`backend/src/hawa_backend/core/intel_client.py`) | HTTP to `HAWA_AIML_SERVICE_URL` (default `http://localhost:8100`), no prefix | `GET /health`, `GET /twin`, `GET /hotspots`, `GET /forecast/{cell_id}`, `POST /plans/draft`, `POST /plans/{id}/simulate`, `POST /interventions/{id}/verify`, `GET /effectiveness-library` |
| Backend `IntelClient` fallback | In-process import when HTTP fails (circuit breaker) | `hawa_ml.api.deps`: `get_twin_engine`, `get_exposure_engine`, `get_forecaster`, `get_grid`, `get_whatif_simulator`, `get_effectiveness_library`, `forecaster_agent`, `planner_agent`, `auditor_agent`, `drive_by_calibrator`; `hawa_ml.schemas`: `AssetSpec`, `PlanTask`, `Hotspot`; `hawa_ml.causal.placebo.verify_injected_intervention_recovery` |
| Backend citizen routes (`backend/src/hawa_backend/api/routes/citizen.py`) | In-process import at module load (lines 7-9) | `hawa_ml.exposure.routing.safe_route_optimizer`, `hawa_ml.forecasting.safe_window.safe_window_calculator`, `hawa_ml.simulation.audit.iot_auditor`, `FLEET_TELEMETRY` |
| Backend integration tests | `from hawa_ml.api.main import app` over ASGI | `/health`, `/hotspots`, `/forecast/{id}`, `/interventions/{id}/verify` |

These imports make the listed symbols a de-facto public Python API; see [CONTRACTS.md §4](CONTRACTS.md#4-in-process-python-api-used-by-the-backend). The backend must have `hawa_ml` importable (`pip install -e ../AI-ML`), although `backend/pyproject.toml` does not declare it. In-process calls read and write the same `AI-ML/data/` files as the API.

Mismatches found: the backend's What-If HTTP branch requires a `delta_gain_pct` key that AI-ML never returns, so the HTTP result is discarded and the in-process fallback reports its 42.0 default (`intel_client.py:933`, `:977`); `make api` uses port 8000, which collides with the backend; `docs/CONTRACTS.md` §7 describes `/internal/v1/simulate`, `/optimize`, `/exposure`, `/models` and `/alerts/draft` with bearer-token auth, none of which exist (the real `/internal/v1/*` is an unauthenticated mirror of the routes above); cell ids are `G-RRR-CCC`, not the `g500-RRR-CCC` / `C-2863-7721` forms used in the contracts and backend defaults.

---

## 9. Known issues

Defects found while documenting. Nothing here has been fixed.

1. **AQI is 500 between integer breakpoints.** `GRAPEngine.calculate_sub_index` matches `b_lo <= c <= b_hi` and returns 500 when no bracket matches (`src/hawa_ml/forecasting/grap.py:41-52`). The breakpoints in `config/cpcb_breakpoints.yaml` leave gaps (30-31, 60-61, 90-91, 120-121, 250-251), so PM2.5 = 60.5 gives AQI 500, category Severe and GRAP Stage 4. Forecast values are rounded to 0.1, so this happens in normal use.
2. **Verified effects never reach the optimiser.** Rule attribution recommends `"sprinkler"` (`src/hawa_ml/attribution/rules.py:75`, `:95`) and the greedy optimiser looks up `effectiveness_library.lookup_expected_effect(cause, recommended_asset)` (`src/hawa_ml/optimization/greedy.py:64`), but the library key that verification updates is `road_dust:water_sprinkler` (`src/hawa_ml/causal/placebo.py:144`). Real dispatches get the generic 12 % / 5 % fallback.
3. **Tests, demo seeding and API calls mutate tracked files.** `data/fixtures/demo_scenario.json` (`scripts/demo_seed.py:107`), `data/internal/calibration_profiles.json` (`src/hawa_ml/calibration/drive_by.py:122`), `data/internal/effectiveness_library.json` (`src/hawa_ml/causal/effectiveness_library.py:166`, called from `placebo.py:144` on every verification, including `GET /interventions/{id}/impact`), `data/internal/synthetic_data/known_interventions.json` (`src/hawa_ml/simulation/interventions.py:85`, appends one record per seed). `make data` rewrites `data/fixtures/bus_routes_delhi.json` (unseeded jitter, `src/hawa_ml/ingestion/bus_routes_osm.py:75-76`) and `make train` rewrites `models/` and `reports/forecast_metrics.json`. The backend's in-process fallback and its integration tests write the same files.
4. **Forecaster trains on the wrong subset.** `df_raw.tail(45000)` (`src/hawa_ml/forecasting/train.py:37-39`) runs on data sorted by `["station_id", "timestamp"]` (`src/hawa_ml/ingestion/cpcb.py:158`), so it keeps the last stations alphabetically, not the latest hours. The docstring says a 60-day hold-out and a CAMS comparison; the code uses 45 days (`train.py:45`) and persistence only.
5. **Forecast inference ignores the cell and history.** `ForecastPredictor.predict_cell_forecast` fills all 14 lag features and the rolling means/maxima from the single `current_pm25` argument with fixed standard deviations, and uses fixed weather defaults (`src/hawa_ml/forecasting/predict.py:40-90`). The winter flag differs from training (Nov-Jan vs 15 Oct-Jan; `predict.py:72`, `features.py:51`).
6. **Open-Meteo cache files are truncated.** `_set_cache` dumps records holding pandas `Timestamp` objects; `json.dump` raises after writing `[{"timestamp": ` and the exception is swallowed (`src/hawa_ml/ingestion/openmeteo.py:48-54`, callers `:91`, `:130`). The cache never hits, so every online call goes to the network, including during tests.
7. **The planner ignores the live twin.** `tool_get_hotspots` ranks `load_grid(500.0)`, which has no `pm25_est`, so every cell defaults to PM2.5 180 / PM10 280 (`src/hawa_ml/agents/tools.py:27-31`, `src/hawa_ml/exposure/engine.py:49`, `:101`). In `run_3hour_cycle` the auditor then checks the plan against a different hotspot list (`src/hawa_ml/pipelines/cycle.py:72-74`). With these defaults every hotspot classifies as `unknown`, and sprinklers and smog guns are dispatched to unknown causes.
8. **What-If is a constant ratio.** The baseline is `ai_person_hours_avoided * 0.32` (`src/hawa_ml/optimization/whatif.py:35-36`), so `gain_percentage` is 212.5 % for any input. `schools_ai` has an operator-precedence error and effectively counts hotspots with `rank <= 3` (`whatif.py:31`).
9. **`eval_metrics.py` is in-sample.** The classifier is trained on the full dataset (`train_all.py`) and then scored on the last 20 % of the same rows against labels produced by the same rules (`scripts/eval_metrics.py:16-36`; training at `scripts/train_all.py:36`), so the 99.91 % figures in the PDF measure rule recovery, not attribution accuracy. The script also lacks the `sys.path` insert the other scripts have.
10. **Report assets contradict the code.** `scripts/generate_report_assets.py` and `scripts/generate_ai_ml_report_pdf.py` hard-code their numbers and claim an OR-Tools CVRP engine, a 140,352-row training set, anisotropic advection, a calibrator MAE drop from 42.6 to 9.4, latency figures and endpoints (`/attribution`, `/exposure/hotspots`, `/causal/verify`) that do not exist in the code.
11. **`make test` and `make setup` fail as written.** `Makefile:32` runs plain `pytest` (issue in §6); `make setup` never installs `hawa_ml`, so its check at `Makefile:15` fails.
12. **Logging configuration misuse.** Every module calls `configure_logging("<module name>")`, but the parameter is a level (`src/hawa_ml/logging_conf.py:36-38`), so all modules share the `hawa_ml` logger at INFO and `LOG_LEVEL` is never applied.
13. **Bedrock provider cannot load as declared.** `BedrockLLMClient` imports `boto3` (`src/hawa_ml/agents/llm_provider.py:53`), which is in neither `pyproject.toml` nor `requirements.txt`; the import error is caught and template text is returned. `groq` and `openai` are only in `requirements.txt`.
14. **Effectiveness CI sign convention is mixed.** Priors store positive intervals for positive reductions (`src/hawa_ml/causal/effectiveness_library.py:41`); updates overwrite them with the verifier's negative intervals (`:161-162`) next to a positive `pm10_reduction_pct`.
15. **Auditor approval text is hard-coded.** The approved-plan fallback always says the tasks match "road dust suppression" (`src/hawa_ml/agents/auditor_agent.py:72`), even when every task targets `unknown`.
16. **Simulator details.** `SensorNoiseModel` seeds from Python `hash(dev_id)` (`src/hawa_ml/simulation/noise_models.py:17`), which changes per process, so device biases are not repeatable; ambient curves use the UTC hour as local time (`src/hawa_ml/simulation/device_sim.py:75-79`); `n_schools` and `n_sprinklers` are ignored (`device_sim.py:32`).
17. **Unused declared surface.** `config/settings.yaml`, `WAQI_TOKEN`, `CDS_API_KEY`, `DATA_GOV_IN_API_KEY`, `ARCHIVE_URL` (`openmeteo.py:28`), `seasonal_naive_forecast`, `fuse_and_build_twin`, `calibrate_batch`, `tool_get_effectiveness` and `tool_simulate_whatif` are defined but not used by any runtime path.
18. **Subpackages have no `__init__.py`.** Only `src/hawa_ml/__init__.py` exists; the subpackages are implicit namespace packages. The editable install works; packaging for distribution is untested.

---

## 10. Further reading

| Document | Contents |
|---|---|
| [docs/aiml/README.md](../docs/aiml/README.md) | Documentation index and status summary |
| [docs/aiml/CONTEXT.md](../docs/aiml/CONTEXT.md) | Problem, loop, features and honesty rules |
| [docs/aiml/ARCHITECTURE.md](../docs/aiml/ARCHITECTURE.md) | Runtime architecture as built, target architecture (Planned) |
| [docs/aiml/STRUCTURE.md](../docs/aiml/STRUCTURE.md) | File-by-file tree |
| [docs/aiml/MODELS.md](../docs/aiml/MODELS.md) | Every algorithm as implemented, with target designs |
| [docs/aiml/AGENTS.md](../docs/aiml/AGENTS.md) | Agents, LLM providers, runtime prompts |
| [docs/aiml/DATA_AND_TRAINING.md](../docs/aiml/DATA_AND_TRAINING.md) | Data sources, dataset build, training and evaluation |
| [docs/aiml/PLAN.md](../docs/aiml/PLAN.md) | Milestone status and remaining work |
| [models/forecaster_model_card.md](models/forecaster_model_card.md), [models/attribution_model_card.md](models/attribution_model_card.md) | Model cards |
