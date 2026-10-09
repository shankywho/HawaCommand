# AI-ML Folder Structure

The complete layout of `AI-ML/`, one line of responsibility per file or package, plus the tooling that keeps it consistent.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [MODELS](MODELS.md) · [AGENTS](AGENTS.md) · [DATA_AND_TRAINING](DATA_AND_TRAINING.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. Tree

Five importable packages live under `src/`: `hawa_ml` (algorithms and I/O), `hawa_agents` (Strands agents), `hawa_intel_service` (internal FastAPI), `hawa_intel_worker` (Kafka consumers) and `hawa_trainer` (training CLI). Dependency direction is strict: `hawa_intel_worker`, `hawa_intel_service`, `hawa_trainer` → `hawa_agents` → `hawa_ml` → `hawa_contracts`. `hawa_ml` never imports the other AI-ML packages (checked by `tests/unit/test_import_boundaries.py`).

```text
AI-ML/
├── pyproject.toml                 # uv project; deps; console scripts; ruff/mypy/pytest config; path dep on ../backend/contracts
├── uv.lock                        # fully pinned lockfile (committed)
├── README.md                      # 10-line pointer to docs/aiml/README.md
├── Dockerfile                     # multi-stage uv build; one image, entrypoint chooses intel-worker | intel-service | hawa-trainer
├── Makefile                       # dev, lint, test, train, data targets (see §4)
├── logifyx.yaml                   # lowest-priority logging defaults (env and configure_logging() override)
├── .env.example                   # every env var with safe placeholders (see §6)
├── .pre-commit-config.yaml        # ruff, ruff-format, mypy, nbstripout, uv-lock check, end-of-file, detect-private-key
├── configs/
│   ├── base.yaml                  # runtime defaults: time zone, bbox, windows, budgets, feature flags (advection, agents)
│   ├── grid.yaml                  # CRS EPSG:32643, cell sizes 500/1000 m, Delhi boundary source, origin snapping
│   ├── calibration.yaml           # pairing rules (CONTRACTS §10.3), Huber epsilon, coefficient bounds, trust weights
│   ├── twin.yaml                  # super-obs slot, kernels and bounds, advection caps, fallback chain, confidence mapping
│   ├── fingerprint_rules.yaml     # v1 rule table thresholds and soft-membership widths per cause
│   ├── trajectory.yaml            # back-trajectory step, horizons per cause, ensemble size, perturbations, candidate priors
│   ├── hotspots.yaml              # top-5 % / AQI ≥ 301 / confidence ≥ 0.5 rules, connectivity, tracking IoU
│   ├── forecaster.yaml            # horizon buckets, quantiles, LightGBM hyperparameters, feature list, conformal window
│   ├── grap_thresholds.yaml       # AQI → stage bands (CONTRACTS §10.2), early-action probability triggers, MC draws
│   ├── vulnerability_weights.yaml # V per population group (residential 1.0; school, hospital, elder-care higher)
│   ├── population_profiles.yaml   # hourly occupancy profiles by POI type and day type
│   ├── cause_asset_matrix.yaml    # CONTRACTS §3 matrix + P-08 confidence gating (hard constraints)
│   ├── optimizer.yaml             # service times, capacities, speeds, time limits per mode, penalties, value scaling
│   ├── effectiveness_priors.yaml  # literature-informed priors per cause × asset type (clearly marked as priors)
│   ├── verifier.yaml              # windows, donor rules, K min/max, spillover buffer, verdict thresholds
│   ├── integrity.yaml             # station-clustering radius and ratios, outlier sigma, drift CUSUM
│   ├── coverage.yaml              # VOI weights, GTFS route matching, suggestion limits
│   ├── site_score.yaml            # component weights and A/B/C cut-offs, minimum data
│   ├── school_window.yaml         # school hours, safe thresholds, seal/ventilate CO₂ and I/O rules
│   ├── vision.yaml                # image limits, match radius/time, decision thresholds
│   ├── advice_matrix.yaml         # pollutant × cause × audience → advice codes (Communicator content source)
│   ├── alert_templates.yaml       # reviewed en/hi fallback templates keyed by advice code
│   ├── alert_limits.yaml          # SMS (GSM-7 / UCS-2), WhatsApp, push length limits per language
│   └── agents.yaml                # per-role model env var names, effort, max_tokens, timeouts, tool budgets
├── src/
│   ├── hawa_ml/
│   │   ├── __init__.py
│   │   ├── config.py              # pydantic-settings Settings (env) + YAML config loader with schema validation
│   │   ├── version.py             # model_version string builder `{model}@{semver}+{git_sha7}`
│   │   ├── cli.py                 # `hawa-ml` utility CLI (inspect run, replay event, export fixtures)
│   │   ├── io/
│   │   │   ├── db.py              # SQLAlchemy 2 Core async engine (asyncpg), sessions, COPY helper, statement timeouts
│   │   │   ├── tables.py          # Core Table objects mirroring the Alembic schema for read and owned-write tables
│   │   │   ├── queries.py         # named read queries (readings window, cell_state series, forecasts, assets)
│   │   │   ├── writers.py         # owned-table writers (bulk cell_state, forecast, impact …) with model_version stamping
│   │   │   ├── s3.py              # boto3 client (MinIO/S3), Parquet read/write via pyarrow, snapshot manifests
│   │   │   ├── kafka.py           # aiokafka producer/consumer factories, envelope (de)serialisation, header propagation
│   │   │   ├── redis.py           # redis.asyncio client, key builders (ml:, lock:plan:, dedupe:evt:), token lock
│   │   │   └── mlflow_registry.py # load champion by alias, register challenger, promote, mirror to model_version
│   │   ├── common/
│   │   │   ├── ids.py             # UUIDv7 generation, id format validators (cell, device, asset, ward)
│   │   │   ├── timeutil.py        # UTC/IST conversion, slot flooring, school-day calendar
│   │   │   ├── geo.py             # pyproj transformers 4326↔32643, distances, bearings, point-in-cell
│   │   │   ├── units.py           # unit constants and conversions (µg/m³, ppb, km/h ↔ m/s)
│   │   │   ├── aqi.py             # CPCB sub-index breakpoints (CONTRACTS §10.1), indicative AQI, GRAP stage
│   │   │   ├── idempotency.py     # processed_event + dedupe:evt: helpers, replay-on-duplicate support
│   │   │   ├── logging.py         # logifyx init, named loggers, ContextLoggerAdapter factory
│   │   │   ├── telemetry.py       # OpenTelemetry setup, Kafka context propagation, span helpers
│   │   │   ├── metrics.py         # Prometheus metric definitions (ARCHITECTURE §9.3)
│   │   │   └── errors.py          # typed errors (DataInsufficient, ModelUnavailable, ConstraintViolation …)
│   │   ├── validation/
│   │   │   └── schemas.py         # pandera schemas for every input frame and output frame
│   │   ├── grid/
│   │   │   ├── build.py           # build 500 m / 1 km grid in EPSG:32643, ids g500-/g1k-, grid_meta
│   │   │   ├── cells.py           # row/col ↔ geometry ↔ id, parent g1k, neighbours
│   │   │   ├── index.py           # fast point → cell lookup (vectorised floor on UTM coords)
│   │   │   ├── features.py        # cell covariates: road density, construction, industrial/green share, distances
│   │   │   └── key_cells.py       # F1 key-cell pre-ranking score
│   │   ├── calibration/
│   │   │   ├── pairing.py         # drive-by pairs: ≤ 200 m, < 10 km/h, wind ≤ 3 m/s, 1-min device means vs reference
│   │   │   ├── fit.py             # Huber regression ref = a·raw + b·RH + c, fleet-prior shrinkage, bounds
│   │   │   ├── drift.py           # coefficient stability, residual CUSUM, device_drift flags
│   │   │   ├── trust.py           # trust score and band (CONTRACTS §3 TrustBand)
│   │   │   └── job.py             # nightly/on-demand calibration job (writes device_calibration, emits events)
│   │   ├── twin/
│   │   │   ├── superobs.py        # weighted cell × 10-min aggregation, noise variance per super-obs, TAG spray exclusion
│   │   │   ├── weights.py         # reading weight curve (P-07) and flag handling
│   │   │   ├── trend.py           # weighted linear trend on cell covariates (regression kriging stage 1)
│   │   │   ├── gp.py              # sklearn GaussianProcessRegressor residual model, heteroscedastic alpha, warm start
│   │   │   ├── kriging.py         # PyKrige ordinary/universal kriging fallback
│   │   │   ├── idw.py             # inverse-distance fallback
│   │   │   ├── advection.py       # wind field interpolation and semi-Lagrangian shift of the background field
│   │   │   ├── confidence.py      # posterior sd → confidence, lognormal back-transform, variance
│   │   │   ├── run.py             # twin pipeline + fallback chain; returns CellState frame and run metrics
│   │   │   └── validate.py        # leave-station-out evaluation vs nearest-station and IDW baselines
│   │   ├── attribution/
│   │   │   ├── features.py        # per-cell and per-hotspot fingerprint features (ratio, gases, VOC index, fires, wind)
│   │   │   ├── rules.py           # v1 soft rule table (§9.4) → class probabilities
│   │   │   ├── classifier.py      # v2 LightGBM multiclass + probability calibration, safe fallback to rules
│   │   │   ├── fingerprint.py     # facade: pick champion (rules or classifier), apply P-08 gating metadata
│   │   │   ├── trajectory.py      # back-trajectory ensemble, suspect scoring against sites/POIs/fires
│   │   │   ├── hotspots.py        # thresholding, connected components / DBSCAN, ranking, hotspot records
│   │   │   └── tracking.py        # hotspot identity across runs (track_id by overlap)
│   │   ├── forecast/
│   │   │   ├── calendar.py        # holidays, Diwali window, stubble season, school days
│   │   │   ├── features.py        # lags, rolling stats, NWP weather, calendar, upwind FIRMS, static covariates
│   │   │   ├── dataset.py         # training matrix builder from the feature store (station and cell targets)
│   │   │   ├── model.py           # 6 horizon buckets × 3 quantiles LightGBM wrapper, save/load
│   │   │   ├── baselines.py       # persistence, seasonal persistence, climatology, no-NWP variant
│   │   │   ├── quantiles.py       # crossing fix (sorting), minimum width, conformal widening
│   │   │   ├── predict.py         # run-time prediction for all g1k cells and horizons
│   │   │   ├── downscale.py       # g1k → g500 ratio downscaling for exposure
│   │   │   └── evaluate.py        # pinball, MAE vs persistence, coverage, CRPS approximation, reports
│   │   ├── grap/
│   │   │   ├── stages.py          # AQI bands → stage (CONTRACTS §10.2)
│   │   │   └── outlook.py         # Monte Carlo daily AQI per ward, stage probabilities, early-action flag
│   │   ├── exposure/
│   │   │   ├── population.py      # WorldPop base + hourly POI profiles → Pop(cell, hour, day_type)
│   │   │   ├── vulnerability.py   # V(cell, t) from population groups and weights
│   │   │   └── engine.py          # E(cell, t) (CONTRACTS §10.4), quantile propagation, totals
│   │   ├── optimizer/
│   │   │   ├── problem.py         # PlanningProblem dataclasses (assets, depots, shifts, nodes, windows)
│   │   │   ├── nodes.py           # candidate service nodes from hotspots, time-window copies, node values
│   │   │   ├── travel.py          # travel-time matrix (haversine × detour / speed; OSRM optional)
│   │   │   ├── constraints.py     # single source of hard constraints; check_plan() used by optimiser, agents, API
│   │   │   ├── cvrptw.py          # OR-Tools routing model: prize-collecting CVRPTW with allowed vehicles
│   │   │   ├── greedy.py          # millisecond greedy insertion fallback
│   │   │   └── solution.py        # routes → tasks (spray/sweep/inspect/protect_alert), ETAs, expected effects
│   │   ├── whatif/
│   │   │   ├── baseline.py        # "usual routes" baseline from asset_usual_route (P-10)
│   │   │   └── simulate.py        # paired Monte Carlo of plan vs baseline, person-hours avoided with uncertainty
│   │   ├── verifier/
│   │   │   ├── windows.py         # pre/post windows per stage (P-02), series extraction at 15-min resolution
│   │   │   ├── donors.py          # donor pool rules: untreated, buffer, land use, pre-trend, weather, data quality
│   │   │   ├── synthetic_control.py # constrained least squares weights (w ≥ 0, Σw = 1), de-meaned, log space
│   │   │   ├── placebo.py         # placebo-in-space, RMSPE ratios, p-value, CI
│   │   │   ├── did.py             # diff-in-diff and naive before/after fallbacks
│   │   │   ├── verdict.py         # verdict rules and evidence level
│   │   │   └── run.py             # verification pipeline returning Impact records
│   │   ├── effectiveness/
│   │   │   ├── strata.py          # cause × asset type × land use × season × hour band keys
│   │   │   ├── priors.py          # prior loading and validation
│   │   │   ├── hierarchical.py    # normal–normal partial pooling up the hierarchy (empirical Bayes)
│   │   │   └── update.py          # incremental update on impact, nightly refit
│   │   ├── integrity/
│   │   │   ├── station_clustering.py # F15 anti-gaming: spray concentration near stations vs exposure, divergence test
│   │   │   ├── outliers.py        # implausible_jump from leave-one-out twin residuals
│   │   │   └── flags.py           # integrity_flag records and events
│   │   ├── coverage/
│   │   │   ├── voi.py             # value of information per cell (variance × people × threshold proximity)
│   │   │   ├── gtfs.py            # GTFS shapes/trips → cells traversed per time window
│   │   │   ├── router.py          # suggest routes, riders and post-spray passes; coverage_gap records
│   │   │   └── road_coverage.py   # KPI: share of pilot road-km observed daily
│   │   ├── sites/
│   │   │   └── score.py           # F9 site compliance score and A/B/C grade
│   │   ├── schools/
│   │   │   └── safe_window.py     # F19 safe windows, seal vs ventilate
│   │   ├── power/
│   │   │   └── proxy.py           # F10 (VISION) interface stub and expected-load check design
│   │   ├── vision/
│   │   │   ├── preprocess.py      # EXIF strip, resize, perceptual hash, format checks
│   │   │   ├── consistency.py     # time/location/duplicate checks
│   │   │   ├── matcher.py         # spike and hotspot matching within radius/time
│   │   │   └── decide.py          # deterministic decision rule combining model output and checks
│   │   ├── reports/
│   │   │   ├── facts.py           # weekly structured facts (hotspots, sources, actions, impact per rupee)
│   │   │   └── number_check.py    # every number in generated text must exist in the facts
│   │   └── eval/
│   │       └── sim_truth.py       # evaluation-only access to simulator ground truth (import-guarded)
│   ├── hawa_agents/
│   │   ├── __init__.py
│   │   ├── llm.py                 # BedrockModel factory per role, stub model, stop-reason normalisation, timeouts
│   │   ├── schemas.py             # Pydantic outputs: ForecastBrief, PlanReview, AuditorVerdict, AlertDraft, PhotoVerification
│   │   ├── context.py             # frozen PlanContext snapshot and read-only views for tools
│   │   ├── orchestrator.py        # deterministic draft pipeline: optimiser → Planner → Auditor → resolve ≤ 2 → revalidate
│   │   ├── fallback.py            # templated reasons, deterministic pre-audit, template alerts
│   │   ├── preaudit.py            # deterministic Auditor rules (water on smoke, regional smoke trucks, …)
│   │   ├── summarise.py           # transcript → plan_review record (deterministic officer summary)
│   │   ├── agents/
│   │   │   ├── forecaster.py      # Forecaster agent builder
│   │   │   ├── planner.py         # Planner agent builder
│   │   │   ├── auditor.py         # Auditor agent builder
│   │   │   ├── communicator.py    # Communicator agent builder + length validators
│   │   │   ├── citizen_eyes.py    # vision verifier builder (image content)
│   │   │   └── narrator.py        # F22 evidence narrative writer
│   │   ├── prompts/
│   │   │   ├── _shared_context.md # shared operating context (cached prefix)
│   │   │   ├── forecaster.md      # role prompt
│   │   │   ├── planner.md         # role prompt
│   │   │   ├── auditor.md         # role prompt
│   │   │   ├── communicator.md    # role prompt + style guide + Hindi glossary
│   │   │   ├── citizen_eyes.md    # role prompt
│   │   │   └── narrator.md        # role prompt
│   │   └── tools/
│   │       ├── read_tools.py      # get_hotspots, get_forecast, get_grap_outlook, get_effectiveness, get_school_windows, get_cell_context, get_plan_candidate, get_station_proximity
│   │       ├── compute_tools.py   # run_optimizer, check_constraints (wrap hawa_ml.optimizer)
│   │       ├── submit_tools.py    # submit_forecast_brief, submit_plan_review, submit_audit, draft_alert, submit_photo_verification
│   │       └── budget.py          # per-agent tool-call budget and call log
│   ├── hawa_intel_service/
│   │   ├── __init__.py
│   │   ├── app.py                 # FastAPI app factory, lifespan (load models, population profiles), middleware
│   │   ├── main.py                # `intel-service` entry point (uvicorn, port 8100)
│   │   ├── auth.py                # bearer HAWA_INTERNAL_TOKEN check (constant-time)
│   │   ├── problems.py            # RFC 9457 problem+json helpers
│   │   ├── deps.py                # DB/Redis/model dependencies
│   │   ├── schemas.py             # request/response models for /internal/v1/*
│   │   └── routes/
│   │       ├── simulate.py        # POST /internal/v1/simulate
│   │       ├── optimize.py        # POST /internal/v1/optimize
│   │       ├── exposure.py        # POST /internal/v1/exposure
│   │       ├── alerts.py          # POST /internal/v1/alerts/draft (P-05)
│   │       ├── models.py          # GET /internal/v1/models
│   │       └── health.py          # GET /internal/v1/healthz, GET /metrics
│   ├── hawa_intel_worker/
│   │   ├── __init__.py
│   │   ├── main.py                # `intel-worker --groups …` entry point, signal handling, graceful drain
│   │   ├── registry.py            # group name → topics, handler, consumer settings
│   │   ├── consumer.py            # base consumer loop: decode, idempotency, retries, DLQ, offsets, spans, metrics
│   │   ├── publisher.py           # outbox writer (P-06) / direct producer with replay-on-duplicate
│   │   ├── executor.py            # process pool for CPU-bound work
│   │   └── handlers/
│   │       ├── twin.py            # intel-twin: cmd.twin.rebuild
│   │       ├── twin_live.py       # intel-twin-live: reading.cleaned → cell aggregates
│   │       ├── attribution.py     # intel-attribution: fire.detected
│   │       ├── forecast.py        # intel-forecast: cmd.forecast.run
│   │       ├── plan.py            # intel-plan: cmd.plan.draft, twin.updated spike detection
│   │       ├── verify.py          # intel-verify: cmd.verify.run
│   │       ├── verify_scheduler.py# intel-verify-scheduler: spray.* and task.* bookkeeping
│   │       ├── spike.py           # intel-spike: device.spike / tamper / health
│   │       ├── vision.py          # intel-vision: report.submitted
│   │       ├── trainer.py         # intel-trainer: cmd.train.run → subprocess
│   │       └── report.py          # intel-report (P-04): cmd.evidence_report.build
│   └── hawa_trainer/
│       ├── __init__.py
│       ├── cli.py                 # `hawa-trainer run|evaluate|promote|snapshot` (Typer)
│       ├── snapshot.py            # freeze training data snapshot + manifest
│       ├── gates.py               # promotion gates per model (DATA_AND_TRAINING §9)
│       ├── registry.py            # MLflow logging conventions, alias moves, model_version mirror, Redis pointer
│       └── jobs/
│           ├── forecaster.py      # train/evaluate forecaster
│           ├── fingerprint.py     # train/evaluate classifier v2 vs rules
│           ├── calibration.py     # fleet calibration run
│           ├── effectiveness.py   # nightly library refit
│           ├── site_score.py      # nightly site scores
│           ├── twin_eval.py       # leave-station-out twin evaluation (P-03)
│           └── verifier_eval.py   # injected-effect recovery suite (P-03)
├── scripts/
│   ├── build_grid.py              # grid + grid_meta + cell/cell_1k seed files (backend seeds them)
│   ├── build_cell_features.py     # cell_feature covariates from OSM, permits, land use
│   ├── fetch_cpcb.py              # CPCB/DPCC historical + recent station data → feature store
│   ├── fetch_openaq.py            # OpenAQ v3 locations and measurements → feature store
│   ├── fetch_firms.py             # NASA FIRMS VIIRS/MODIS area CSV → feature store
│   ├── fetch_weather.py           # Open-Meteo historical/forecast and ERA5 (CDS) → feature store
│   ├── fetch_osm_pois.py          # schools, hospitals, elder-care, markets, bus stops, roads, construction
│   ├── fetch_gtfs.py              # Delhi OTD static GTFS → routes, shapes, trips
│   ├── fetch_wards.py             # MCD ward boundaries → ward seed
│   ├── worldpop_to_cells.py       # WorldPop 100 m raster → population per cell (area-weighted)
│   ├── backfill_twin_history.py   # stations-only twin reanalysis for past days (forecaster lags at demo start)
│   ├── seed_usual_routes.py       # demo usual-route baseline (is_simulated) for What-If (P-10)
│   └── export_fixtures.py         # capture golden fixtures for tests and agent evals
├── notebooks/                     # numbered; outputs stripped by nbstripout; never imported by src
│   ├── 00_data_audit.ipynb
│   ├── 01_grid_population.ipynb
│   ├── 02_calibration.ipynb
│   ├── 03_twin_kriging.ipynb
│   ├── 04_fingerprint_rules.ipynb
│   ├── 05_forecaster.ipynb
│   ├── 06_exposure.ipynb
│   ├── 07_optimizer_whatif.ipynb
│   ├── 08_verifier_injected_effects.ipynb
│   ├── 09_effectiveness_library.ipynb
│   └── 10_agents_eval.ipynb
├── edge/
│   └── tinyml/
│       ├── data.py                # windowing of 1 Hz PM traces, labels (true spike / exhaust / fog / bump)
│       ├── model.py               # tiny 1D-CNN (Keras) with ratio features
│       ├── train_spike.py         # training + evaluation vs the 3× rule
│       ├── export_tflite.py       # full-integer int8 quantisation with representative dataset
│       ├── gen_c_array.py         # .tflite → C array header for ESP-IDF
│       ├── eval_spike.py          # quantised-model evaluation, latency/size report
│       └── out/                   # generated spike_model.tflite, spike_model.h (git-ignored except releases)
└── tests/
    ├── conftest.py                # fixtures: synthetic grid, fields, fleets, frozen PlanContext, stub LLM
    ├── fixtures/                  # small Parquet/JSON fixtures, golden agent scenarios
    ├── unit/                      # pure-function tests per module (calibration, twin, rules, aqi, exposure …)
    ├── property/                  # hypothesis tests: verifier, optimiser/constraints, quantiles, exposure monotonicity
    ├── contract/                  # reflect live DB schema vs tables.py; envelope/payload round-trips with hawa_contracts
    ├── integration/               # docker-compose services: consumer idempotency, end-to-end twin/plan/verify
    └── agents_eval/               # golden scenarios (Bedrock or stub), graders, reports
```

## 2. Package responsibilities

| Package | Owns | Must not |
|---|---|---|
| `hawa_ml` | All numeric algorithms, data access, validation, versioning | Import `hawa_agents`, FastAPI or aiokafka consumer loops; read `sim/truth` outside `hawa_ml.eval` |
| `hawa_agents` | Prompts, tools, orchestration, output schemas, fallbacks | Write to the DB directly; compute numbers the tools did not return |
| `hawa_intel_worker` | Kafka plumbing, idempotency, retries, publishing | Contain algorithm logic (handlers call `hawa_ml`/`hawa_agents`) |
| `hawa_intel_service` | Internal HTTP surface | Trigger asynchronous work (use Kafka) |
| `hawa_trainer` | Training, evaluation, gates, registry | Serve predictions |

## 3. Tooling

| Tool | Purpose | Configuration |
|---|---|---|
| `uv` | Environments, locking, running | `pyproject.toml`, `uv.lock`; `uv sync --all-extras`; path dependency `hawa-contracts = { path = "../backend/contracts", editable = true }` |
| `ruff` | Lint + format (replaces black, isort, flake8) | `[tool.ruff]` line length 100, target py312; rules `E,F,W,I,B,UP,SIM,N,S,PL,RUF,ASYNC,PD,NPY`; `ruff format` |
| `mypy` | Static types | `strict = true` on `src/`, `pydantic.mypy` plugin, `warn_unreachable`; third-party stubs or `ignore_missing_imports` per module (ortools, pykrige, lightgbm) |
| `pytest` | Tests | markers `unit`, `property`, `contract`, `integration`, `eval_agents`, `slow`; `pytest-asyncio` (auto mode); `pytest-cov` (fail under 80 % for `hawa_ml`) |
| `hypothesis` | Property-based tests | profiles `ci` (200 examples) and `dev` (50); deadline 2 s |
| `pandera` | DataFrame validation at every I/O boundary | `hawa_ml/validation/schemas.py`; lazy validation, failures → metric + typed error |
| `pre-commit` | Local gates | ruff, ruff-format, mypy (src only), nbstripout, `uv lock --check`, end-of-file-fixer, detect-private-key |
| Jupyter | Exploration only | notebooks read from the feature store; promote code into `src/` before use |
| `pip-audit` | Vulnerability scan | CI job |

Library versions: Python 3.12; numpy, pandas and/or polars, pyarrow, scikit-learn, PyKrige, LightGBM, SciPy, statsmodels, geopandas, shapely, pyproj, ortools, strands-agents, boto3, mlflow, fastapi, uvicorn, aiokafka, sqlalchemy[asyncio] 2.x, asyncpg, redis (asyncio), pydantic v2, pydantic-settings, pandera, typer, prometheus-client, opentelemetry-sdk + instrumentations, `logifyx[kafka]` 2.x, and `hawa-contracts`. All at the latest stable versions, pinned in `uv.lock`. Edge extras (`tensorflow` for TFLite export) live in an optional `edge` dependency group so the runtime image stays small.

## 4. Makefile targets

| Target | Does |
|---|---|
| `make sync` | `uv sync --all-extras` |
| `make lint` / `make fmt` | `ruff check .` / `ruff format .` |
| `make typecheck` | `mypy src` |
| `make test` | `pytest -m "unit or property"` |
| `make test-contract` | `pytest -m contract` (needs `make up` at repo root) |
| `make test-integration` | `pytest -m integration` |
| `make eval-agents` | `pytest -m eval_agents` (uses `HAWA_LLM_MODE`) |
| `make worker` / `make service` | run `intel-worker --groups all` / `intel-service` |
| `make train MODEL=forecaster` | `hawa-trainer run --model $(MODEL)` |
| `make data` | fetch scripts for the configured date range |
| `make grid` | `scripts/build_grid.py` + `build_cell_features.py` + `worldpop_to_cells.py` |
| `make tinyml` | train, quantise and export the spike model (edge group) |
| `make docker` | build the image |
| `make ci` | lint + typecheck + test + contract (as in CI) |

## 5. `pyproject.toml` sketch

```toml
[project]
name = "hawa-aiml"
version = "0.1.0"
requires-python = ">=3.12,<3.13"
dependencies = [
  "hawa-contracts",
  "numpy", "pandas", "polars", "pyarrow", "scikit-learn", "pykrige", "lightgbm", "scipy", "statsmodels",
  "geopandas", "shapely", "pyproj", "ortools",
  "strands-agents", "boto3", "mlflow",
  "fastapi", "uvicorn[standard]", "aiokafka", "sqlalchemy[asyncio]", "asyncpg", "redis",
  "pydantic", "pydantic-settings", "pandera", "typer", "prometheus-client",
  "opentelemetry-sdk", "opentelemetry-exporter-otlp", "opentelemetry-instrumentation-fastapi",
  "opentelemetry-instrumentation-asyncpg", "opentelemetry-instrumentation-redis", "opentelemetry-instrumentation-botocore",
  "logifyx[kafka]", "pillow", "imagehash", "pyyaml",
]

[project.scripts]
intel-worker = "hawa_intel_worker.main:cli"
intel-service = "hawa_intel_service.main:run"
hawa-trainer = "hawa_trainer.cli:app"
hawa-ml = "hawa_ml.cli:app"

[dependency-groups]
dev = ["pytest", "pytest-asyncio", "pytest-cov", "hypothesis", "ruff", "mypy", "pre-commit", "jupyterlab", "nbstripout", "pip-audit"]
edge = ["tensorflow"]

[tool.uv.sources]
hawa-contracts = { path = "../backend/contracts", editable = true }

[tool.pytest.ini_options]
markers = ["unit", "property", "contract", "integration", "eval_agents", "slow"]
asyncio_mode = "auto"
```

Versions are resolved by `uv lock`; do not hand-pin minor versions in the docs.

## 6. `.env.example`

```dotenv
# --- environment ---
HAWA_ENV=local                         # local | demo | aws
HAWA_TZ=Asia/Kolkata
HAWA_INTERNAL_TOKEN=change-me          # shared with backend api for /internal/v1/*

# --- data stores ---
HAWA_DB_URL=postgresql+asyncpg://hawa_ml:hawa_ml@localhost:5432/hawa
HAWA_REDIS_URL=redis://localhost:6379/0
HAWA_KAFKA_BOOTSTRAP=localhost:9092
HAWA_S3_ENDPOINT=http://localhost:9000  # empty in AWS
HAWA_S3_LAKE_BUCKET=hawa-local-lake
HAWA_S3_MODELS_BUCKET=hawa-local-models
HAWA_S3_AGENTS_BUCKET=hawa-local-agents
MLFLOW_TRACKING_URI=http://localhost:5000

# --- LLM / Bedrock (see AGENTS.md §3) ---
HAWA_LLM_MODE=bedrock                  # bedrock | stub | disabled (deterministic fallback only)
HAWA_BEDROCK_REGION=ap-south-1
AWS_PROFILE=hawa-dev                   # local only; ECS uses the task role
HAWA_LLM_PLANNER_MODEL=anthropic.claude-opus-5        # or the inference-profile id shown in the Bedrock console
HAWA_LLM_AUDITOR_MODEL=anthropic.claude-opus-5
HAWA_LLM_FORECASTER_MODEL=anthropic.claude-opus-5
HAWA_LLM_VISION_MODEL=anthropic.claude-opus-5
HAWA_LLM_NARRATOR_MODEL=anthropic.claude-opus-5
HAWA_LLM_COMMUNICATOR_MODEL=anthropic.claude-haiku-4-5

# --- feature flags ---
HAWA_TWIN_ADVECTION=true
HAWA_AGENTS_ENABLED=true
HAWA_CITIZEN_EYES_ENABLED=true

# --- logging (logifyx) ---
LOG_LEVEL=INFO
LOG_OUTPUT=console
LOG_JSON=true
LOG_MASK=true
LOG_KAFKA_SERVERS=                     # set in demo/aws
LOG_KAFKA_TOPIC=hawa.logs.v1
LOG_SCHEMA_REGISTRY=                   # e.g. http://localhost:8081

# --- tracing ---
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_SERVICE_NAME=intel-worker

# --- external data (scripts only) ---
OPENAQ_API_KEY=
FIRMS_MAP_KEY=
CDS_API_KEY=                           # ERA5 via Copernicus CDS
```

## 7. `Dockerfile`, `logifyx.yaml`

- `Dockerfile`: stage 1 `uv sync --frozen --no-dev` into `/app/.venv` (copies `../backend/contracts` via build context at repo root); stage 2 slim Python 3.12 runtime, non-root user, `ENTRYPOINT ["/app/.venv/bin/python", "-m"]` with `CMD ["hawa_intel_worker.main", "--groups", "all"]`. Compose and ECS override the command for `intel-service` and `hawa-trainer`. LightGBM needs `libgomp1` in the runtime stage.
- `logifyx.yaml`: lowest-priority defaults mirroring the `configure_logging()` kwargs (level INFO, output console, json_mode true, mask true, Kafka topic `hawa.logs.v1`). Confirm the exact key names against the logifyx README before relying on the file; env vars and `configure_logging()` take precedence anyway.
