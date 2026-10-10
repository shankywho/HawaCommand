# HawaCommand

An AI command centre that maps, forecasts and ranks Delhi's air pollution hotspots street by street, drafts dispatch plans for the city's anti-pollution machines, and checks whether each intervention worked.

Environmental Hacks 2026 · Bharat Builds Tour · Track 01: Air

---

## Executive Summary

The National Capital Territory (NCT) of Delhi runs 376 anti-smog guns, 266 water sprinklers and 91 mechanised road sweepers. They follow static schedules, and there is no routine way to tell whether a given spray run lowered ground-level particulate matter or whether the wind did it.

HawaCommand is the decision layer for that fleet. It ingests live station data, fits a 500 m digital twin over Delhi (10,600 cells), attributes likely sources, forecasts PM2.5 up to 72 hours ahead with P10/P50/P90 bands, ranks hotspots by human exposure rather than raw AQI, drafts a dispatch plan for officer approval, and verifies interventions with a synthetic-control method.

This is a hackathon build. The pipeline runs end to end, but parts of it run on simulated or hard-coded data. The [Implementation status](#implementation-status) table below says which parts are real.

---

## The Closed-Loop Architecture

```
  [Sense] ───────> [Map] ────────> [Attribute] ───────> [Forecast]
     ▲                                                         │
     │                                                         ▼
 [Verify] <─────── [Act] <──────────────────────────────── [Decide]
     │                                                         │
     └───────────── What Worked Feeds The Next Plan ───────────┘
```

| Stage | Subsystem | What the code does today |
|---|---|---|
| 1. Sense | Ingestion | Backend pulls live Delhi station readings from WAQI, then OpenAQ, then a 5-station baseline (cached 15 min in process). AI-ML ingests CPCB CSVs, OpenAQ station metadata, Open-Meteo weather, NASA FIRMS fires and OSM POIs, each with a synthetic fallback. The sensor fleet (HawaPod-M/S, HawaTag) is simulated. |
| 2. Map | 500 m digital twin | scikit-learn Gaussian Process (constant x RBF + white-noise kernel) over 10,600 cells, with a straight-line wind shift. Each cell carries PM2.5, PM10, variance and a 0.20-0.98 confidence. |
| 3. Attribute | Source fingerprint | Rule engine (`config/fingerprint_rules.yaml`) labels each hotspot road dust, traffic, open burning, regional smoke, industrial or unknown, plus an upwind back-trajectory pin. A LightGBM classifier trained on weak proxy labels exists but is not used at runtime. |
| 4. Forecast | 72 h quantile forecaster | 21 LightGBM quantile models (horizons 1, 3, 6, 12, 24, 48, 72 h x P10/P50/P90), CPCB AQI and CAQM GRAP stage per horizon. |
| 5. Decide | Exposure engine + optimiser | Exposure `E = max(0, C - 60) x population x diurnal multiplier x vulnerability`. A greedy, cause-compatible dispatcher assigns machines (Google OR-Tools is detected but not used). Planner and Auditor agents explain and check the plan; the officer approves in the web console. |
| 6. Act | Field and citizen apps | Flutter app with driver, inspector, school, citizen and site-manager roles. Most field flows run on an in-app fake backend because the backend does not serve the field endpoints yet. |
| 7. Verify | Synthetic control | Constrained donor weights (SLSQP) and in-space placebo tests give an effect with a 95 % interval. It has been validated on a seeded synthetic panel with an injected -18.5 % effect (recovered -18.82 %). |

---

## Implementation status

Status words used in every doc: **Implemented**, **Partial** (works, with a named gap), **Stub/Mock** (fixtures, hard-coded or synthetic data), **Planned** (designed, not in code).

| Area | Status | Notes |
|---|---|---|
| AI-ML HTTP engine (`AI-ML/`, port 8100) | Implemented | 13 routes, mounted at `/`, `/v1` and `/internal/v1`, no auth |
| Digital twin | Partial | The `/twin` route fits on 4 hard-coded points; the backend kriges live WAQI stations in process. Leave-one-station-out MAE (37.8) is worse than nearest-station (7.4) on the 3 committed stations |
| 72 h forecaster | Partial | Models are trained; inference fills every lag feature from one current PM2.5 value and ignores the cell id |
| Exposure ranking, rule attribution, GRAP | Implemented | |
| Dispatch optimiser | Partial | Greedy only; OR-Tools CVRP is Planned |
| What-If vs usual routes | Stub/Mock | Baseline is the AI result x 0.32, so the gain is always 212.5 % |
| Causal verification | Partial | Algorithm works; API always replays the seeded injected-effect test |
| Agents (Forecaster, Planner, Auditor, Communicator) | Partial | Plain Python classes; Groq or Bedrock only rephrases, templates when no key; no Strands SDK |
| Backend API (`backend/`, port 8000) | Partial | 33 operations on 31 paths; plans live in memory; devices, alerts and driver route are fixtures; no auth enforced |
| Database schema and seed | Partial | 23 SQLAlchemy tables, Alembic migration `0001`, idempotent seed (`make db-update db-seed`); the API does not read or write the database yet |
| Kafka, Redis, WebSocket | Planned | Contracts exist; nothing is connected |
| Optional AWS layer | Implemented (off by default) | DynamoDB cache, Step Functions, SageMaker, SNS, Kinesis behind `HAWA_AWS_ENABLED=true` |
| Web console (`frontend/`, port 3000) | Partial | Next.js 15 + MapLibre; runs on built-in mocks when `NEXT_PUBLIC_API_URL` is empty |
| Flutter app (`app_frontend/`) | Partial | Air map, air-near-me and school forecast call the backend; auth, tasks, inspections and reports use the in-app fake backend |
| Safe route ("Safe Air Navigator") | Stub/Mock | Fixed multipliers and synthetic waypoints; the "43 % lower" figure is a literal string, not a computed result |
| Ward scorecards | Stub/Mock | Hard-coded leaderboard |
| Physical sensors | Planned | All device data is simulated |
| CI, Dockerfiles, IaC beyond one CloudFormation template | Planned | No `.github/` workflows |

---

## Repository Structure

```
HawaCommand/
|-- AI-ML/                     # hawa_ml: twin, forecaster, attribution, exposure, optimiser, causal verifier, agents, FastAPI app
|-- backend/                   # hawa_backend FastAPI service + hawa_contracts package (backend/contracts/)
|-- frontend/                  # Next.js 15 officer console, landing page, driver view
|-- app_frontend/              # Flutter app (driver, inspector, school, citizen, site manager)
|-- docs/                      # System overview, contracts, per-discipline docs, AWS runbooks
|-- Makefile                   # install, db-up, db-update, db-seed, aiml-api, backend, frontend
|-- infrastructure/
|   `-- cloudformation/        # hawa-integration.yaml (DynamoDB cache table, SNS topic, Kinesis stream, IAM policy)
|-- HawaCommand_Proposal.pdf   # Original proposal (v3)
|-- LICENSE
`-- README.md
```

---

## Local Development and Setup

### Prerequisites

- [uv](https://docs.astral.sh/uv/) (installs Python 3.11 from `backend/.python-version` if needed)
- Node.js 20 or newer and pnpm
- Docker, only if you want the bundled Postgres (`make db-up`)
- Flutter 3.44.0 (pinned in `app_frontend/.fvmrc`; use `fvm`)

One Python environment, `backend/.venv`, runs both the backend and the AI-ML engine: `backend/pyproject.toml` depends on `hawa-ml` (`../AI-ML`) as an editable path dependency, and `backend/uv.lock` pins everything.

### Make targets (run from the repo root)

| Command | What it runs | Port |
|---|---|---|
| `make install` | `uv sync --extra dev` in `backend/` (backend + AI-ML + contracts), `pnpm install --frozen-lockfile` in `frontend/` | — |
| `make db-up` | `docker compose up -d postgres` (PostGIS 16, user/password/db `hawa`) | 5432 |
| `make db-update` | `uv run alembic upgrade head` in `backend/` | — |
| `make db-seed` | `uv run python -m hawa_backend.db.seed` in `backend/` (idempotent) | — |
| `make aiml-data` | `python -m hawa_ml.twin.grid` in `AI-ML/` (active virtualenv): builds `data/processed/grid_covariates_{500m,1000m}.parquet` once | — |
| `make aiml-api` | `uvicorn hawa_ml.api.main:app --host 0.0.0.0 --port 8100 --reload` from `AI-ML/`, using the active virtualenv (activate `backend/.venv` first). The first start builds `data/processed/` and can take a minute; wait for `Application startup complete` | 0.0.0.0:8100 |
| `make backend` | `uvicorn hawa_backend.api.app:app` from `backend/` | 0.0.0.0:8000 |
| `make frontend` | `pnpm install`, `pnpm build`, `pnpm start` in `frontend/` | 3000 |

Variables you can override: `AIML_HOST`, `AIML_PORT`, `BACKEND_HOST`, `BACKEND_PORT`, `API_URL` (backend URL baked into the web build as `NEXT_PUBLIC_API_URL`), `HAWA_DATABASE_URL`, `UV`, `PNPM`.

### First run

```bash
make install
make db-up            # or point HAWA_DATABASE_URL at an existing Postgres
make db-update
make db-seed
```

Then in three terminals (or tmux panes):

```bash
source backend/.venv/bin/activate && make aiml-api   # 1. AI-ML engine on 0.0.0.0:8100
make backend                                    # 2. backend on 0.0.0.0:8000
make frontend API_URL=http://localhost:8000     # 3. web console on :3000
```

Checks: `curl http://127.0.0.1:8100/health` returns `{"status":"healthy",...}`; `curl http://127.0.0.1:8000/healthz` returns `{"status":"ok"}`; backend OpenAPI UI at `http://127.0.0.1:8000/docs`.

- **Database.** `HAWA_DATABASE_URL` defaults to `postgresql+asyncpg://hawa:hawa@localhost:5432/hawa` (set it in `backend/.env` or on the command line). For a quick demo without Postgres: `make db-update db-seed HAWA_DATABASE_URL=sqlite+aiosqlite:///./hawa.db` (relative to `backend/`; `aiosqlite` comes with `make install`). The API does not read the database yet (plans are in memory, other routes use AI-ML or fixtures); the schema and seed data are there for the persistence work.
- **On a server.** `make aiml-api` listens on `0.0.0.0:8100`. Do not open port 8100 in the security group: only the backend calls the engine, and it has no auth and some GET routes write files. To bind it to localhost instead: `make aiml-api AIML_HOST=127.0.0.1`. Build the web console with the public backend URL: `make frontend API_URL=http://<server-ip>:8000`. `NEXT_PUBLIC_API_URL` is baked in at build time.
- **AI-ML keys** (all optional) live in `AI-ML/.env` (`cp AI-ML/.env.example AI-ML/.env`): `GROQ_API_KEY` or `LLM_PROVIDER=bedrock` for agent text, `OPENAQ_API_KEY`, `NASA_FIRMS_MAP_KEY`, `OFFLINE_MODE=true` to avoid all network calls. The `llm` extra (groq, openai, boto3) is installed through the backend env.
- **Backend settings** live in `backend/.env` (`cp backend/.env.example backend/.env`), read from `backend/` (the Make targets `cd` there). `WAQI_TOKEN` and `OPENAQ_API_KEY` for live stations are read with `os.environ`, not from `.env`: export them in the shell before `make backend`.
- The AI-ML package also has its own `make` targets (`cd AI-ML && make help`); its `make api` uses port 8000, which collides with the backend, so use `make aiml-api` from the root instead.

### Without Make

```bash
# Python env (from backend/)
cd backend && uv sync --extra dev
# or with pip: python3 -m venv .venv && . .venv/bin/activate && pip install -e contracts -e "../AI-ML[llm]" -e ".[dev]"

uv run alembic upgrade head                          # from backend/
uv run python -m hawa_backend.db.seed                # from backend/
uv run uvicorn hawa_backend.api.app:app --host 0.0.0.0 --port 8000          # from backend/
cd ../AI-ML && uv run --project ../backend uvicorn hawa_ml.api.main:app --host 127.0.0.1 --port 8100

cd ../frontend && pnpm install && pnpm build && pnpm start                   # NEXT_PUBLIC_API_URL in .env.local
```

### Flutter app (from `app_frontend/`)

```bash
cd app_frontend
fvm install && fvm flutter pub get
fvm flutter gen-l10n && fvm dart run build_runner build

# Physical Android device over USB: forward the backend port
adb reverse tcp:8000 tcp:8000

fvm flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8000
```

- `USE_FAKE_API` defaults to `true`: login (OTP `123456`), driver, inspector, reports and site screens run on the in-app fake backend. `REAL_FEATURES` (default `air_map,citizen_air,alerts,school_forecast`) always call the backend.
- Default `API_BASE_URL` is `http://10.0.2.2:8000` (Android emulator to host).
- `make run` and `make apk` expect `env/<flavor>.json`, which is not committed; pass `--dart-define` values directly instead.

---

## API Endpoints Reference (backend, port 8000)

| Method | Endpoint | Data source |
|---|---|---|
| `GET` | `/healthz`, `/health`, `/livez`, `/v1/health` | Static `{"status":"ok"}` |
| `GET` | `/readyz` | Always reports database and redis `ok` (not checked) |
| `GET` | `/v1/twin` | AI-ML twin (live WAQI stations kriged in process), fixture fallback |
| `GET` | `/v1/hotspots`, `/v1/hotspots/{cell_id}` | AI-ML exposure ranking, fixture fallback |
| `GET` | `/v1/forecast`, `/v1/forecast/{cell_id}` | AI-ML forecaster |
| `GET` | `/v1/plans`, `/v1/plans/{plan_id}` | In-memory store (seed plan `214` is a fixture) |
| `POST` | `/v1/plans/draft` | AI-ML Planner + Auditor |
| `POST` | `/v1/plans/{plan_id}/approve`, `/request-changes`, `/suggestions/{comment_id}/apply` | In-memory state |
| `GET`, `POST` | `/v1/plans/{plan_id}/compare`, `/v1/plans/{plan_id}/simulate` | AI-ML What-If |
| `GET` | `/v1/devices` | Fixture |
| `GET` | `/v1/impact`, `/v1/impact/library` | Fixture enriched with AI-ML verification; AI-ML effectiveness library |
| `GET`, `POST` | `/v1/impact/{id}/verify`, `/v1/interventions/{id}/verify` | AI-ML causal verifier |
| `GET` | `/v1/alerts` | Fixture |
| `GET` | `/v1/driver/route` | Fixture |
| `POST` | `/v1/citizen/safe-route` | `hawa_ml` in process (heuristic) |
| `GET` | `/v1/citizen/safe-window` | `hawa_ml` in process (fixed diurnal curve) |
| `GET` | `/v1/citizen/live-operations`, `/v1/citizen/wards/leaderboard` | Hard-coded |
| `POST` | `/v1/citizen/reports/missed-machine` | `hawa_ml` IoT auditor (hard-coded fleet telemetry) |
| `GET` | `/open/v1/air` | AI-ML twin cells |

Full request and response shapes: [docs/backend/API.md](docs/backend/API.md). AI-ML engine routes: [AI-ML/README.md](AI-ML/README.md#5-http-api).

---

## Data Sources

| Source | Used by | Status |
|---|---|---|
| WAQI map-bounds API | Backend live stations | Implemented |
| OpenAQ v3 | Backend live stations (fallback); AI-ML station metadata | Implemented |
| CPCB/DPCC CSVs (manual download to `AI-ML/data/external/cpcb/`) | Forecaster training | Implemented; synthetic 60-day data if absent |
| Open-Meteo weather and CAMS | AI-ML `fetch_all.py` | Partial: fetched, not used by any model |
| NASA FIRMS VIIRS fires | AI-ML upwind fire features | Partial: fetched, not used by any model |
| OpenStreetMap Overpass POIs, WorldPop raster | 500 m grid covariates | Implemented, synthetic fallbacks |
| ECMWF ERA5, IMD | none | Planned |
| Sensor fleet (HawaPod-M/S, HawaTag) | AI-ML simulator | Simulated |

---

## Testing and checks

| Component | Command (run from the component folder) | Last result (2026-10-10) |
|---|---|---|
| AI-ML | `python -m pytest -q` (plain `pytest` / `make test` fails to collect `tests/test_phase7_api_pipelines.py`) | 37 passed, 1 failed on a clean checkout (needs `data/processed/stations_hourly.parquet`); 38 passed after `make data && make train` |
| Backend | `uv run pytest -q` (from `backend/`) | 64 passed, 1 failed (`tests/integration/test_end_to_end.py::test_full_mission_air_pipeline` expects `/v1/hotspots` to be simulated) |
| Web | `pnpm typecheck`, `pnpm build` | Both pass; `pnpm lint` fails because no ESLint config is committed (it opens the interactive setup) |
| Flutter | `make lint`, `make test` | Not run (no Flutter SDK on the reviewing machine); two legacy tests import the old package name and will not compile |

The AI-ML suite is not hermetic: it rewrites four tracked JSON files under `AI-ML/data/`. Restore them with `git checkout -- AI-ML/data` after running it.

---

## Known issues (cross-cutting)

Per-component lists with file and line references are in each README.

1. `backend/src/hawa_backend/core/intel_client.py:200` and `:246` contain WAQI and OpenAQ API tokens as hard-coded defaults. Rotate them and remove the defaults.
2. `AI-ML/Makefile` serves the engine on port 8000, the backend's port; the backend expects 8100.
3. The backend's What-If HTTP branch looks for a `delta_gain_pct` key that AI-ML never returns, so it always falls back (`intel_client.py:933`).
4. No route enforces authentication; CORS allows every origin on both Python services.
5. The Flutter app's field endpoints (`/v1/auth/*`, `/v1/tasks*`, `/v1/inspections*`, `/v1/reports*`, `/v1/uploads/presign`, `/v1/ws`) are not served by the backend.
6. The committed PDF report and figures hard-code numbers that the code does not produce (for example an OR-Tools CVRP engine and 99.91 % attribution accuracy measured in-sample against rule-generated labels).

---

## Cloud Integration

The backend has an optional AWS layer (`backend/src/hawa_backend/aws/`, enabled with `HAWA_AWS_ENABLED=true`): DynamoDB twin cache, Step Functions or SageMaker forecast, Step Functions dispatch on plan approval, SNS and Kinesis publishers. `infrastructure/cloudformation/hawa-integration.yaml` provisions the DynamoDB cache table, the SNS alerts topic, the Kinesis sensor stream and an IAM managed policy for the backend; the Step Functions state machines and the SageMaker endpoint are referenced by ARN/name but not created by the template. The web console has an `amplify.yml` for Amplify Hosting. ECS Fargate, ElastiCache, RDS and CI/CD are Planned.

- [docs/AWS_INTEGRATION.md](docs/AWS_INTEGRATION.md)
- [docs/CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md](docs/CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md)

---

## Documentation Index

- [Documentation home](docs/README.md)
- [System Overview](docs/SYSTEM_OVERVIEW.md)
- [Cross-Discipline Contracts](docs/CONTRACTS.md)
- Component runbooks: [AI-ML](AI-ML/README.md) · [Backend](backend/README.md) · [Web](frontend/README.md) · [Flutter app](app_frontend/README.md)
- Per-discipline docs: [docs/aiml/](docs/aiml/README.md) · [docs/backend/](docs/backend/README.md) · [docs/frontend/](docs/frontend/README.md) · [docs/app/](docs/app/README.md)
- [Team Remaining Work and Role Prompts](docs/TEAM_REMAINING_WORK_AND_PROMPTS.md)
- [Proposal](HawaCommand_Proposal.pdf)
