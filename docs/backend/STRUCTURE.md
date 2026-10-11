# Backend Structure and Tooling

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Backend docs:** [Runbook](../../backend/README.md) · [Index](README.md) · [Context](CONTEXT.md) · [Architecture](ARCHITECTURE.md) · [API](API.md) · [Data model](DATA_MODEL.md) · [Events](EVENTS.md) · [Caching](CACHING.md) · [Logging](LOGGING_AND_OBSERVABILITY.md) · [Deployment](DEPLOYMENT.md) · **Structure** · [Plan](PLAN.md)

<!-- nav:end -->

The real layout of `backend/` with one line per file, the packaging and test configuration as committed, and the planned layout the blueprint described.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [DATA_MODEL](DATA_MODEL.md) · [API](API.md) · [DEPLOYMENT](DEPLOYMENT.md) · [../CONTRACTS.md](../CONTRACTS.md)

> Status: the tree below is complete as of commit `a33e043` (generated files such as `__pycache__/`, `.pytest_cache/` and `*.egg-info/` omitted). The backend team owns no files at the repository root.

---

## 1. `backend/` tree

```text
backend/
├── .env.example                      # HAWA_* settings with local defaults (no AWS, WAQI or OpenAQ keys)
├── .python-version                   # 3.11
├── alembic.ini                       # Alembic config: script_location=migrations, prepend_sys_path=src; URL from HAWA_DATABASE_URL
├── README.md                         # component quick start, status, known issues
├── docker-compose.yml                # local Postgres 16 + PostGIS 3.4, Redis 7, Kafka 3.8 (KRaft)
├── pyproject.toml                    # project hawa-backend 0.1.0, deps, extras [aws] [dev], script `hawa`, pytest config
├── migrations/
│   ├── env.py                        # async Alembic env; Base.metadata from hawa_backend.db.models; `-x db_url=` override
│   ├── script.py.mako                # revision template
│   └── versions/20261010_0001_initial_schema.py   # all 23 tables and indexes
├── uv.lock                           # uv lockfile (includes alembic and hawa-ml[llm] from ../AI-ML)
├── contracts/                        # installable package hawa-contracts 0.1.0
│   ├── pyproject.toml                # setuptools build; deps pydantic, orjson
│   ├── hawa_contracts/
│   │   ├── __init__.py               # re-exports enums, ids, units, packets, envelope, topics, RedisKeyBuilder
│   │   ├── enums.py                  # 19 StrEnum/IntEnum types + ALLOWED_ASSETS_PER_CAUSE
│   │   ├── ids.py                    # uuid7(), uuid7_deterministic(), id regexes, g500/g1k cell id helpers
│   │   ├── units.py                  # C_SAFE_PM25/PM10, CPCB categories and sub-indices, indicative AQI, GRAP stage
│   │   ├── packets.py                # TelemetryPacket, DeviceEventPacket, SprayPacket, validate_packet(), reason codes
│   │   ├── envelope.py               # EventContext, Envelope[T]
│   │   ├── topics.py                 # Topic (26), ConsumerGroup (12), TopicConfig, ALL_TOPICS
│   │   ├── redis_keys.py             # TTL constants and RedisKeyBuilder (hawa:{env}:… keys)
│   │   ├── py.typed                  # PEP 561 marker
│   │   └── events/
│   │       ├── __init__.py           # EVENT_REGISTRY and @register_event (filled only when submodules are imported)
│   │       ├── alert.py              # alert.requested, alert.delivered
│   │       ├── commands.py           # cmd.twin.rebuild, cmd.forecast.run, cmd.plan.draft, cmd.verify.run, cmd.dispatch.release
│   │       ├── device.py             # device.spike, device.calibrated
│   │       ├── forecast.py           # ForecastPoint; forecast.issued, school.safe_window_computed
│   │       ├── impact.py             # ImpactPoint; impact.verified
│   │       ├── intervention.py       # intervention.spray_started, intervention.spray_stopped
│   │       ├── plan.py               # plan.drafted, plan.approved, plan.dispatched
│   │       ├── task.py               # task.dispatched, task.done, task.verified
│   │       ├── telemetry.py          # reading.cleaned, reading.rejected
│   │       └── twin.py               # twin.updated, hotspot.updated
│   └── tests/
│       └── test_contracts.py         # 8 tests: uuid7, id regexes, cells, AQI/GRAP, cause constraints, packets, envelope, Redis keys
├── src/
│   └── hawa_backend/
│       ├── __init__.py               # __version__ = "0.1.0"
│       ├── cli.py                    # argparse CLI `hawa`: version, config, check
│       ├── api/                      # (no __init__.py)
│       │   ├── app.py                # create_app(): CORS, context middleware, HawaException handler, 11 routers; `app`
│       │   ├── fixtures.py           # demo data: SCHOOLS, RAW_HOTSPOTS (10), forecast, assets, impact + impact_series(), alerts, driver route, pm25_band_label()
│       │   └── routes/               # (no __init__.py)
│       │       ├── alerts.py         # GET /v1/alerts (fixture)
│       │       ├── citizen.py        # /v1/citizen/*: safe-route, safe-window, live-operations, missed-machine, leaderboard (imports hawa_ml)
│       │       ├── devices.py        # GET /v1/devices (fixture)
│       │       ├── driver.py         # GET /v1/driver/route (fixture)
│       │       ├── forecast.py       # GET /v1/forecast, GET /v1/forecast/{cell_id} (AWS, then IntelClient)
│       │       ├── health.py         # /healthz, /health, /livez, /v1/health, /readyz
│       │       ├── hotspots.py       # GET /v1/hotspots, /v1/hotspots/{cell_id}, /v1/twin
│       │       ├── impact.py         # /v1/impact, /v1/impact/library, verify on /v1/impact/* and /v1/interventions/*
│       │       ├── open_data.py      # GET /open/v1/air
│       │       └── plans.py          # /v1/plans*: in-memory store, draft, approve (+ AWS dispatch), request-changes, suggestions, compare/simulate
│       ├── aws/
│       │   ├── __init__.py           # re-exports cache, dispatch, events, forecast, settings helpers
│       │   ├── cache.py              # DynamoDB JSON cache with expiry checked on read
│       │   ├── clients.py            # lazily created, lru-cached boto3 clients and cache table
│       │   ├── dispatch.py           # start_dispatch(): Step Functions StartExecution on approve
│       │   ├── events.py             # publish_alert() (SNS), publish_sensor_reading() (Kinesis)
│       │   ├── forecast.py           # get_aws_forecast(): cache → Step Functions sync or SageMaker endpoint
│       │   └── settings.py           # AwsSettings (HAWA_AWS_*)
│       ├── core/                     # (no __init__.py)
│       │   ├── clock.py              # Clock protocol, SystemClock, FrozenClock, IST helpers
│       │   ├── config.py             # Settings (HAWA_*), get_settings()
│       │   ├── context.py            # RequestContext contextvar, bind_context()
│       │   ├── errors.py             # ProblemDetail (RFC 9457), HawaException and 9 subclasses
│       │   ├── intel_client.py       # IntelClient: AI-ML HTTP → in-process hawa_ml → fixtures; CircuitBreaker; live WAQI/OpenAQ stations
│       │   ├── logging.py            # JSONFormatter, mask_phone(), mask_token(), get_logger()
│       │   ├── places.py             # 41 Delhi localities, nearest_locality(), spread(), name_places()
│       │   └── security.py           # PBKDF2 passwords, JWT create/verify, dev OTP, webhook HMAC
│       ├── db/                       # (no __init__.py)
│       │   ├── base.py               # Base with naming convention, TimestampMixin, SimulatedMixin
│       │   ├── session.py            # async engine/sessionmaker singletons, get_db() dependency (unused by routes)
│       │   ├── seed.py               # idempotent demo-data seed: `python -m hawa_backend.db.seed` / `make db-seed`
│       │   └── models/
│       │       ├── __init__.py       # exports all 23 model classes
│       │       ├── alert.py          # Alert, AlertDelivery
│       │       ├── asset.py          # Asset, AssetShift
│       │       ├── auth.py           # AppUser, RefreshToken, AuditLog
│       │       ├── device.py         # Device, Reading, DeviceEvent
│       │       ├── grid.py           # Ward, Cell500m, School, Site, ReferenceStation
│       │       ├── intervention.py   # Intervention, Impact, EffectivenessLibrary
│       │       ├── outbox.py         # OutboxEvent, ProcessedEvent
│       │       └── plan.py           # Plan, PlanTask, PlanReview
│       └── workers/                  # (no __init__.py)
│           ├── dispatch.py           # DispatchSagaManager: release tasks, match HawaTag sprays
│           ├── ingest.py             # IngestProcessor: dedupe, validate, grid, calibrate, AQI, spike
│           └── simulator.py          # FleetSimulator: telemetry batches and spray packets
└── tests/                            # no conftest.py, no __init__.py (pytest --import-mode=importlib)
    ├── api/
    │   ├── test_all_routes_comprehensive.py  # 8 tests over every console route, incl. 404s and plan lifecycle
    │   └── test_api.py               # 11 tests: probes, hotspots, forecast, plans, devices, impact, alerts, driver, headers, open data
    ├── aws/
    │   └── test_aws_integration.py   # 10 tests with moto: cache, forecast paths, SNS/Kinesis, dispatch, route fallback
    ├── core/
    │   └── test_core.py              # 8 tests: settings, context, masking, problem details, passwords, JWT, OTP/webhook, clock
    ├── db/
    │   └── test_db.py                # 4 tests on in-memory SQLite: grid, device/reading, plan→impact chain, outbox
    ├── integration/
    │   ├── test_aiml_integration.py  # 10 tests: IntelClient methods, circuit breaker, AI-ML app over ASGI
    │   └── test_end_to_end.py        # 1 test: simulator → ingest → DB → saga → outbox → REST (fails, see README)
    └── workers/
        └── test_workers.py           # 5 tests: ingest happy path, dedupe, spike, simulator, saga matching
```

Totals: 65 tests (57 under `tests/`, 8 under `contracts/tests/`).

## 2. Dependency rules as they stand

| Module | Imports | Imported by |
|---|---|---|
| `api/app.py` | `core.config`, `core.context`, `core.errors`, every router | uvicorn, tests |
| `api/routes/*` | `core.intel_client`, `api.fixtures`, `aws`, `hawa_ml` (citizen) | `api/app.py` |
| `core/intel_client.py` | `core.config`, `core.errors`, `core.places`, `api.fixtures`, `httpx`; `hawa_ml` lazily | routes, tests |
| `core/security.py` | `core.config`, `core.errors`, `hawa_contracts.enums`, `jwt` | tests only |
| `core/logging.py` | `core.context` | tests only |
| `db/*` | `core.config`, `sqlalchemy` | tests only |
| `workers/*` | `hawa_contracts` | tests only |
| `aws/*` | `pydantic_settings`; `boto3`/`botocore` lazily | routes, tests |

No import rules are enforced by tooling.

## 3. Tooling

### 3.1 Packaging

| Item | Value |
|---|---|
| Project | `hawa-backend` 0.1.0, `requires-python >= 3.11`, `readme = README.md` |
| Runtime deps | `fastapi>=0.115.0`, `uvicorn>=0.30.0`, `pydantic>=2.8.0`, `pydantic-settings>=2.4.0`, `sqlalchemy>=2.0.30`, `asyncpg>=0.29.0`, `redis>=5.0.0`, `orjson>=3.10.0`, `httpx>=0.27.0`, `pyjwt>=2.8.0`, `greenlet>=3.0.0`, `hawa-contracts` |
| Extra `aws` | `boto3>=1.34.0` |
| Extra `dev` | `pytest>=8.0.0`, `pytest-asyncio>=0.23.0`, `aiosqlite>=0.20.0`, `moto[dynamodb,sns,kinesis]>=5.0.0`, `ruff>=0.5.0`, `mypy>=1.10.0` |
| Path dependencies (`[tool.uv.sources]`) | `hawa-contracts` (`./contracts`), `hawa-ml[llm]` (`../AI-ML`; `api/routes/citizen.py` and `core/intel_client.py` import it) |
| Migrations | `alembic` (`alembic.ini`, `migrations/env.py`, `migrations/script.py.mako`, `migrations/versions/20261010_0001_initial_schema.py`) |
| Seed | `src/hawa_backend/db/seed.py` (`python -m hawa_backend.db.seed`) |
| Declared but unused at runtime | `asyncpg`, `redis`, `orjson`, `greenlet` (needed only once the DB is wired) |
| Console script | `hawa = "hawa_backend.cli:main"` |
| uv source | `hawa-contracts = { path = "contracts", editable = true }` |
| Build backend | none declared (pip falls back to setuptools; uv treats the project as virtual) |
| Contracts package | `contracts/pyproject.toml`: `hawa-contracts` 0.1.0, setuptools build backend, deps `pydantic>=2.8.0`, `orjson>=3.10.0` |

`uv.lock` (lock format version 1, revision 5) pins, among others, fastapi 0.142.2, pydantic 2.13.5, SQLAlchemy 2.1.4, uvicorn 0.54.0, httpx 0.28.1, redis 8.1.0, boto3 1.43.109, moto 5.2.3, pytest 9.1.1. It was regenerated on 2026-10-10 after adding `alembic` and `hawa-ml[llm]`. The verification virtualenv was installed with pip and resolved slightly newer versions (fastapi 0.143.0, pydantic 2.14.0, boto3 1.43.111).

### 3.2 pytest

From `[tool.pytest.ini_options]`:

```toml
minversion = "8.0"
addopts = "-ra -q --import-mode=importlib"
testpaths = ["tests", "contracts/tests"]
pythonpath = ["src", "contracts"]
```

There is no `asyncio_mode` setting; async tests use `@pytest.mark.asyncio` explicitly, and fixtures use `@pytest_asyncio.fixture`. There are no markers (`integration`, `e2e`) and no `conftest.py`.

### 3.3 Lint and types

No `[tool.ruff]`, `[tool.mypy]`, pre-commit configuration or Makefile exists. Results on 2026-10-10 with ruff 0.17.0 are in [README.md](README.md) §7.1, item 5. mypy is installed by the `dev` extra but has no configuration and was not part of verification.

## 4. Planned layout (target design)

> Status: **Planned**. The blueprint's full tree (about 380 lines) is in git history: `git show a33e043:docs/backend/STRUCTURE.md`.

The target adds, under `src/hawa_backend/`: `bootstrap.py` (DI container), `api/routers/`, `api/schemas/`, `api/deps.py`, `api/ws/` (WebSocket hub), `api/middleware/`; `services/` (use cases and state transitions); `db/repositories/`, `db/uow.py`, `db/spatial.py`; `events/` (producer, consumer base class, outbox, relay, serde, MSK auth); `cache/` (client, cached, rate limit, locks); `integrations/` (SMS, WhatsApp, FCM, S3, intel client, feeds, each behind a Protocol with fakes); one package per worker under `workers/` (`ingest`, `feeds`, `scheduler`, `dispatch`, `notifier`, `outbox_relay`, `mqtt_bridge`, `audit_writer`, `alert_engine`, `evidence_report`, `archiver`); plus `backend/simulator/` (`hawa-sim`), `backend/infra/` (CDK), `backend/config/` (GRAP actions, alert templates, reading weights), `backend/docker/` (Dockerfile, Mosquitto config), and repo-root `docker-compose.yml` and `.env.example` (the repo-root `Makefile` and `backend/migrations/` already exist).

Target tooling: a uv workspace (root + contracts + simulator), ruff with banned-import rules for layering, strict mypy, pytest markers `integration` (testcontainers) and `e2e`, pre-commit with gitleaks, and a typer-based `hawa` CLI (`api`, `worker <name>`, `kafka-init`, `seed`, `partitions`, `demo-reset`, `demo-check`, `scheduler trigger`).

<!-- footer:start -->

---

[Back to top](#backend-structure-and-tooling) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
