# HawaCommand Backend

The FastAPI service that the web console and the Flutter app talk to. Today it is a single process that turns AI-ML output (over HTTP, in process, or from fixtures) into the frontends' camelCase contract, keeps plan state in memory, pulls live Delhi station data from WAQI/OpenAQ, and can optionally call AWS. It also ships the shared `hawa_contracts` package (`contracts/`).

The event-driven, Postgres/Kafka/Redis design in [`docs/backend/`](../docs/backend/README.md) is the target; parts not built are labelled **Planned** there.

--- 

## Implementation status

| Area | Status |
|---|---|
| FastAPI app, wildcard CORS, `x-request-id` / `x-correlation-id` echo | Implemented |
| AI-ML bridge with circuit breaker (`core/intel_client.py`) | Implemented |
| Live stations: WAQI, then OpenAQ, then 5 baseline stations, 15 min in-process cache | Implemented |
| Twin, hotspots, forecast, open air data | Implemented (AI-ML backed, fixture fallback) |
| Plans (draft, approve, request changes, apply suggestion, compare) | Partial (in-memory only) |
| Impact and effectiveness library | Partial |
| Citizen routes | Partial (two are hard-coded) |
| Devices, alerts, driver route | Stub/Mock (fixtures) |
| `/readyz` | Stub/Mock (always `ok`) |
| RFC 9457 errors, JWT/OTP helpers, JSON logging | Partial (code exists, not wired into routes) |
| SQLAlchemy models (23 tables), Alembic migration, seed script | Partial (migrate and seed work on Postgres and SQLite; the API never opens a session) |
| Ingest, simulator, dispatch saga workers | Partial (classes with unit tests, not connected) |
| Optional AWS layer (`aws/`) | Implemented, off unless `HAWA_AWS_ENABLED=true` |
| Kafka, Redis, PostGIS geometry, WebSocket, auth endpoints, DB-backed routes | Planned |

Details: [docs/backend/README.md](../docs/backend/README.md).

---

## Quick Start

Run everything from `backend/`.

### 1. Install

From the repo root, `make install` does this for you. Manually, from `backend/`:

```bash
cd backend
uv sync --extra dev          # creates backend/.venv from uv.lock (backend + contracts + AI-ML + alembic)
# optional AWS extras: uv sync --extra dev --extra aws
```

`pyproject.toml` declares `hawa-contracts` (`./contracts`) and `hawa-ml[llm]` (`../AI-ML`) as editable path dependencies in `[tool.uv.sources]`, so one environment runs both the backend and the AI-ML engine. Without uv: `python3 -m venv .venv && . .venv/bin/activate && pip install -e contracts -e "../AI-ML[llm]" -e ".[dev]"`.

### 2. Configure (optional)

```bash
cp .env.example .env
```

Settings use the `HAWA_` prefix and read `backend/.env` by absolute path (`core/config.py` `ENV_FILE`, also used by `aws/settings.py`), so the working directory does not matter; real environment variables override the file.

| Variable | Default | Used today |
|---|---|---|
| `HAWA_ENV`, `HAWA_DEBUG`, `HAWA_HOST`, `HAWA_PORT` | `development`, `false`, `0.0.0.0`, `8000` | `hawa config` only |
| `HAWA_AIML_SERVICE_URL` | `http://localhost:8100` | Yes |
| `HAWA_AIML_TIMEOUT_SECONDS` | `10.0` | Yes |
| `HAWA_DATABASE_URL` | `postgresql+asyncpg://hawa:hawa@localhost:5432/hawa` | Alembic (`migrations/env.py`) and the seed script; the API does not use it yet |
| `HAWA_REDIS_URL`, `HAWA_KAFKA_BOOTSTRAP_SERVERS`, `HAWA_KAFKA_SECURITY` | Redis/Kafka on localhost | No (Planned) |
| `HAWA_JWT_SECRET`, `HAWA_JWT_ALGORITHM`, `HAWA_JWT_EXPIRY_MINUTES`, `HAWA_DEV_OTP` | dev values | Helpers only |
| `HAWA_AWS_*` (`aws/settings.py`) | AWS off | Optional AWS layer, see [docs/AWS_INTEGRATION.md](../docs/AWS_INTEGRATION.md) |
| `WAQI_TOKEN`, `OPENAQ_API_KEY` (aliases `HAWA_WAQI_TOKEN`, `HAWA_OPENAQ_API_KEY`) | unset | Yes: live stations (`Settings.waqi_token` / `openaq_api_key`); unset or empty skips that source, and with neither the backend uses 5 baseline stations |

### 2a. Database: migrate and seed

```bash
make db-up        # from the repo root: Postgres via docker compose (optional)
make db-update    # = cd backend && uv run alembic upgrade head
make db-seed      # = cd backend && uv run python -m hawa_backend.db.seed
```

- `alembic.ini` and `migrations/` (async `env.py`, revision `0001_initial_schema`) create all 23 tables from `src/hawa_backend/db/models/`. The URL comes from `HAWA_DATABASE_URL`; `uv run alembic -x db_url=<url> upgrade head` overrides it. New migration after a model change: `uv run alembic revision --autogenerate -m "<message>"`, then `uv run alembic check`.
- `src/hawa_backend/db/seed.py` inserts demo rows and skips any primary key that already exists, so it is safe to re-run. It loads: 7 wards, 3 schools, 25 reference stations (`AI-ML/data/fixtures/stations_fallback.csv`), 10,600 500 m grid cells (AI-ML grid geometry, ids `G-RRR-CCC`), 2 assets and their HawaTag devices, seed plan `214` with 2 tasks and 1 Auditor review, 1 intervention with its verified impact, 5 effectiveness-library priors, 2 alerts and 5 demo users (the Flutter app's demo phone numbers).
- SQLite works for a quick demo: `HAWA_DATABASE_URL=sqlite+aiosqlite:///./hawa.db`.
- The API does not read or write the database yet; plans are still held in memory.

### 3. Start the API server (port 8000)

Start the AI-ML engine first on port 8100 (`make aiml-api` from the repo root), then:

```bash
make backend      # from the repo root, or from backend/:
uv run uvicorn hawa_backend.api.app:app --host 0.0.0.0 --port 8000
```

- Health: `curl http://127.0.0.1:8000/healthz` returns `{"status":"ok"}`
- OpenAPI UI: `http://127.0.0.1:8000/docs`

Postgres, Redis and Kafka are not required. If AI-ML is not running, the backend calls `hawa_ml` in process, then falls back to fixtures.

`docker compose up -d` (from `backend/`) starts PostGIS 16, Redis 7 and Kafka 3.8 for future work; the backend does not connect to them yet.

### 4. Run the tests

```bash
uv run pytest -q
```

Last result (2026-10-10, Python 3.12): **64 passed, 1 failed**. The failure is `tests/integration/test_end_to_end.py::test_full_mission_air_pipeline`, which expects `/v1/hotspots` to return `"simulated": true` while the route now serves live data. Without `hawa_ml` installed, 4 test modules fail to import.

| Test file | Covers |
|---|---|
| `contracts/tests/test_contracts.py` | Enums, ids, units, packets, envelope, topics, Redis keys, events |
| `tests/core/test_core.py` | Settings, logging masking, errors, security helpers, clock |
| `tests/db/test_db.py` | SQLAlchemy models on SQLite (`aiosqlite`) |
| `tests/api/test_api.py`, `tests/api/test_all_routes_comprehensive.py` | Every registered route through ASGI |
| `tests/workers/test_workers.py` | Ingest dedupe and calibration, simulator, dispatch saga |
| `tests/aws/test_aws_integration.py` | AWS layer with `moto` |
| `tests/integration/test_aiml_integration.py`, `tests/integration/test_end_to_end.py` | Backend to AI-ML bridge, end-to-end mission flow |

### 5. CLI

```bash
python -m hawa_backend.cli config    # or: hawa config
```

Subcommands: `version`, `config`, `check`.

### 6. Make targets (repo root)

`make install`, `make db-up`, `make db-update`, `make db-seed`, `make aiml-api`, `make backend`, `make frontend`: see the [root README](../README.md#make-targets-run-from-the-repo-root).

---

## API surface

34 operations on 32 paths. Full shapes in [docs/backend/API.md](../docs/backend/API.md).

| Method | Path | Source |
|---|---|---|
| GET | `/healthz`, `/health`, `/livez`, `/v1/health`, `/readyz` | Static |
| GET | `/v1/twin`, `/v1/hotspots`, `/v1/hotspots/{cell_id}`, `/v1/forecast`, `/v1/forecast/{cell_id}` | AI-ML |
| GET | `/v1/plans`, `/v1/plans/{plan_id}` | In-memory |
| POST | `/v1/plans/draft`, `/v1/plans/{plan_id}/approve`, `/v1/plans/{plan_id}/request-changes`, `/v1/plans/{plan_id}/suggestions/{comment_id}/apply` | AI-ML + in-memory |
| GET, POST | `/v1/plans/{plan_id}/compare`, `/v1/plans/{plan_id}/simulate` | AI-ML What-If |
| GET | `/v1/devices`, `/v1/alerts`, `/v1/driver/route` | Fixtures |
| GET | `/v1/impact`, `/v1/impact/library` | Fixture + AI-ML |
| GET, POST | `/v1/impact/{id}/verify`, `/v1/interventions/{id}/verify` | AI-ML |
| POST | `/v1/citizen/safe-route`, `/v1/citizen/reports/missed-machine` | `hawa_ml` in process |
| GET | `/v1/citizen/safe-window` | `hawa_ml` in process |
| GET | `/v1/citizen/live-operations`, `/v1/citizen/wards/leaderboard` | Hard-coded |
| GET | `/open/v1/air` | AI-ML twin |
| POST | `/v1/uploads/presign` | AWS S3 pre-signed POST (needs `HAWA_AWS_ENABLED`, `HAWA_AWS_EVIDENCE_BUCKET`) |

---

## Known issues

1. The What-If HTTP branch requires a `delta_gain_pct` key that AI-ML never returns, so it always falls back to the in-process path (`intel_client.py:933`, `:977`).
2. `/readyz` reports database and redis `ok` without checking them (`api/routes/health.py`).
3. No route enforces a JWT; CORS is `*` with credentials.
4. `HawaException` handlers exist but no route raises them, so clients get FastAPI's default error bodies.
5. `tests/integration/test_end_to_end.py::test_full_mission_air_pipeline` fails (see above).
6. Plan state is lost on restart (in-process dict).

---

## Further reading

- [PHASES.md](PHASES.md): build phases and their status
- [docs/PHASE_1_FOUNDATION.md](docs/PHASE_1_FOUNDATION.md) to [docs/PHASE_5_WORKERS_AND_SIMULATOR.md](docs/PHASE_5_WORKERS_AND_SIMULATOR.md)
- [docs/backend/](../docs/backend/README.md): architecture, API, data model, events, caching, logging, deployment
- [docs/CONTRACTS.md](../docs/CONTRACTS.md), [docs/AWS_INTEGRATION.md](../docs/AWS_INTEGRATION.md)
