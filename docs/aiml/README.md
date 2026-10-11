# HawaCommand AI-ML

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**AI-ML docs:** [Runbook](../../AI-ML/README.md) · **Index** · [Architecture](ARCHITECTURE.md) · [Models](MODELS.md) · [Agents](AGENTS.md) · [Data and training](DATA_AND_TRAINING.md) · [Engine API](../../AI-ML/CONTRACTS.md) · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

Index and entry point for everything the `AI-ML/` folder owns: models, optimiser, verifier, agents, and how they are run. These documents describe the code as it exists, and keep the original blueprint as clearly labelled **Planned** target design.

Related: [ARCHITECTURE](ARCHITECTURE.md) · [../../AI-ML/README.md](../../AI-ML/README.md) · [../../AI-ML/CONTRACTS.md](../../AI-ML/CONTRACTS.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. What AI-ML is today

AI-ML is the "Think" and "Decide" layer of HawaCommand (§9.1 of the proposal). In code it is one Python package, `hawa_ml` (`AI-ML/src/hawa_ml/`), plus a FastAPI app (`hawa_ml.api.main:app`), eleven scripts and 38 tests. It runs as a single process with file-based state; there is no Kafka, database, Redis, object store or MLflow. The backend reaches it over HTTP (default `http://localhost:8100`) and, as a fallback, by importing `hawa_ml` in-process.

Status vocabulary used in every AI-ML document: **Implemented** (works as described), **Partial** (works, gap stated), **Stub/Mock** (fixture, hard-coded or synthetic output), **Planned** (not in code).

### 1.1 Implementation status by loop step

| Loop step | Feature | What exists | Status |
|---|---|---|---|
| 1 Sense | F2/F17 fleet, telemetry schema | `TelemetryPacket`; simulator for HawaPod-M (buses), HawaPod-S (schools), HawaTag (sprayers) writing JSONL | Implemented (simulated fleet only) |
| 1 Sense | F3 drive-by calibration | Huber fit `ref = a·raw + b·RH + c`, trust score, JSON profiles; no co-location pairing | Partial |
| 1 Sense | External feeds | CPCB CSVs, OpenAQ stations, Open-Meteo + CAMS, FIRMS, OSM, WorldPop, each with synthetic fallback; only CPCB, OSM and WorldPop feed models | Partial |
| 2 Map | F1 grid | 500 m (10,600 cells) and 1 km (2,650) grids with population, POI distances, vulnerability, synthetic wards | Partial |
| 2 Map | F4 digital twin | sklearn GP (constant x RBF + white noise) on lat/lon with a downwind shift of observations; LOSO evaluation | Implemented (loses to baselines) |
| 3 Attribute | F7 fingerprint | Rule engine from `config/fingerprint_rules.yaml`; weak-label LightGBM classifier trained but unused | Partial |
| 3 Attribute | F7 back-trajectory | Single straight-line upwind pin | Implemented |
| 4 Forecast | F5 72 h forecaster | 21 LightGBM quantile models (7 horizons x P10/P50/P90), metrics vs persistence | Partial (inference ignores cell and history) |
| 4 Forecast | F6 GRAP | CPCB AQI and CAQM stage lookup with mandated actions | Implemented (AQI bug between breakpoints) |
| 4 Forecast | F19 safe window | Fixed diurnal curve with persona thresholds | Stub/Mock |
| 5 Decide | F12 exposure | `max(0, C − 60) × Pop × diurnal × V × dt`, top-N ranking | Implemented (ranking Partial) |
| 5 Decide | F13 optimiser | Greedy cause-compatible dispatch; OR-Tools CVRP not built | Partial |
| 5 Decide | F13 What-If | Baseline fixed at 32 % of the AI plan | Stub/Mock |
| 5 Decide | F14 agents | Forecaster, Planner, Auditor, Communicator as Python classes; Groq or Bedrock only rephrases; template fallback | Partial |
| 6 Act | F16 alerts | English and Hindi template alerts and narratives | Partial |
| 7 Verify | F18 synthetic control + placebo | Algorithm implemented and tested on a seeded synthetic panel; API always returns that panel's result | Implemented (algorithm), Stub/Mock (endpoint) |
| 7 Verify | F18 effectiveness library | JSON running average with 5 priors | Partial |
| Citizen | Safe route, ghost-worker audit | Synthetic route multipliers; hard-coded fleet telemetry | Stub/Mock |
| — | F8, F9, F10, F11, F15, F20, F22, TinyML spike | — | Planned |
| — | Kafka workers, internal service with auth, trainer CLI, MLflow, Postgres/Redis/S3 | — | Planned |

The per-module table, the endpoint list and 18 known defects are in [AI-ML/README.md](../../AI-ML/README.md#1-implementation-status).

## 2. Reading order

| # | Document | Read it when | Lines (approx.) |
|---|---|---|---|
| 1 | [AI-ML/README.md](../../AI-ML/README.md) | First. Install, run, test, endpoints, scripts, Make targets, measured results, known issues | ~330 |
| 2 | [ARCHITECTURE.md](ARCHITECTURE.md) | Runtime as built (process, singletons, flows, state files, failure behaviour) and the Planned event-driven architecture | ~380 |
| 3 | [MODELS.md](MODELS.md) | Every model: twin, attribution, forecaster with metrics, GRAP, exposure, optimiser, What-If, causal verifier | ~230 |
| 4 | [AGENTS.md](AGENTS.md) | Planner, Auditor, Forecaster, Communicator; tools, LLM providers, prompts, insights | ~140 |
| 5 | [DATA_AND_TRAINING.md](DATA_AND_TRAINING.md) | Data sources and fallbacks, datasets, training, runtime state, simulation | ~130 |
| 6 | [AI-ML/CONTRACTS.md](../../AI-ML/CONTRACTS.md) | Exact HTTP request/response shapes, in-process Python API, file formats | ~450 |
| 7 | [DEPLOYMENT.md](DEPLOYMENT.md) | In-process vs separate service, models and data refresh, LLM configuration | ~90 |

## 3. Processes at a glance

| Process | Entry point | Role | Status |
|---|---|---|---|
| AI-ML API | `uvicorn hawa_ml.api.main:app --port 8100` | 13 routes mounted at `/`, `/v1`, `/internal/v1`; no auth | Implemented |
| Operational cycle | `python scripts/run_cycle.py [--loop --interval-sec 10800]` | Simulate, twin, rank, forecast, insights, plan, audit; logs only | Partial |
| Evening master plan | `python -m hawa_ml.pipelines.master_plan` | Cycle plus a school alert | Partial |
| Post-action verification | `python -m hawa_ml.pipelines.verify` | Synthetic injected-effect recovery | Stub/Mock |
| Data and training | `scripts/fetch_all.py`, `build_dataset.py`, `train_all.py` | Fetch or synthesise data, build grids, train 22 boosters | Implemented |
| Fleet simulator | `python -m hawa_ml.simulation.device_sim --mode file --steps 60` | JSONL telemetry | Implemented |
| `intel-worker` (Kafka consumer groups) | `intel-worker --groups ...` | Asynchronous twin, forecast, plan, verify, spike, vision, trainer | Planned |
| `intel-service` (internal FastAPI with token) | `intel-service` | `/internal/v1/simulate`, `/optimize`, `/exposure`, `/models`, `/healthz`, `/alerts/draft` | Planned |
| `hawa-trainer` | `hawa-trainer run --model <m>` | Training, gates, MLflow registry | Planned |
| `hawa_agents` (Strands on Bedrock) | library | Tool-using agents with schema-validated outputs | Planned |

## 4. Quick start (verified 2026-10-10, Python 3.12.3)

```bash
cd AI-ML
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pip install -e ".[dev]"                        # required: make setup does not install hawa_ml
cp .env.example .env                           # optional; everything has a fallback
python scripts/check_env.py                    # masked key and data checklist (read-only)

python -m pytest -q                            # 37 passed, 1 failed on a clean checkout (needs data/processed/stations_hourly.parquet)
OFFLINE_MODE=true python scripts/fetch_all.py  # offline synthetic data, about 1 s
OFFLINE_MODE=true python scripts/build_dataset.py
python -m pytest -q                            # 38 passed once stations_hourly.parquet exists

uvicorn hawa_ml.api.main:app --host 127.0.0.1 --port 8100   # the port the backend expects
```

Do not use `make test` (plain `pytest` cannot import `scripts`) or `make api` (port 8000 collides with the backend). The test suite rewrites four tracked files under `AI-ML/data/`; see [AI-ML/data/README.md](../../AI-ML/data/README.md#2-tracked-files). `scripts/train_all.py` overwrites the committed models with ones trained on whatever data is present (synthetic offline).

## 5. Design rules and how far the code follows them

| Rule (from the blueprint) | Status in code |
|---|---|
| Every output carries uncertainty | Partial: twin variance/confidence, forecast P10/P50/P90, verifier CI; hotspots, plans and What-If have none |
| The optimiser decides, LLM agents explain, a human approves | Implemented in spirit: numbers come from Python and the LLM only rephrases; plans are returned as `draft`, but nothing persists or approves them in AI-ML |
| Cause → asset matrix is a hard constraint (no water on smoke, no trucks for regional smoke) | Implemented in `optimization/greedy.py` (compatibility table, regional smoke and traffic skipped) and checked again by `AuditorAgent` |
| Simulated data is always flagged | Partial: documented in the README; no `is_simulated` field on outputs |
| Verifier demonstrated on injected known effects | Implemented on one seeded synthetic panel; not on simulator twin data |
| Every output carries a `model_version` | Planned |
| AI-ML never runs DDL or writes backend tables | Trivially true (no database access) |
| Never drop the What-If simulator or causal verification (§16) | Both endpoints exist; What-If is Stub/Mock |

## 6. Links

- Proposal (source of truth for intent, no longer in the repository): the original proposal v3, especially §6 (features), §8 (execution flow), §9.4 (algorithms), §12.5 (what is real), §16 (build plan).
- Runbook, endpoints and known issues: [../../AI-ML/README.md](../../AI-ML/README.md)
- Contracts as built: [../../AI-ML/CONTRACTS.md](../../AI-ML/CONTRACTS.md); system-wide target contracts: [../CONTRACTS.md](../CONTRACTS.md)
- Data directory: [../../AI-ML/data/README.md](../../AI-ML/data/README.md); model cards: [forecaster](../../AI-ML/models/forecaster_model_card.md), [attribution](../../AI-ML/models/attribution_model_card.md)
- Whole-system context: [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)
- Sibling teams: [../backend/](../backend/) · [../frontend/](../frontend/) · [../app/README.md](../app/README.md)

<!-- footer:start -->

---

**Related across the project:** [Backend AI-ML bridge](../backend/SERVICES.md#ai-ml-bridge) · [Web pages](../frontend/PAGES.md) · [App screens](../app/SCREENS.md) · [AWS architecture](../AWS_ARCHITECTURE.md)

[Back to top](#hawacommand-ai-ml) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
