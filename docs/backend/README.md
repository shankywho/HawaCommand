# HawaCommand Backend — Documentation Index

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Backend docs:** [Runbook](../../backend/README.md) · **Index** · [Architecture](ARCHITECTURE.md) · [API](API.md) · [Services](SERVICES.md) · [Data stores](DATA_STORES.md) · [Testing](TESTING.md) · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

Entry point for everything under `backend/`: what the backend does today, what is still only designed, which document to read for what, how to run and test it, and the defects that are known.

Related: [ARCHITECTURE](ARCHITECTURE.md) · [API](API.md) · [DEPLOYMENT](DEPLOYMENT.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../../backend/README.md](../../backend/README.md)

---

## 1. Implementation status

Status vocabulary used in every backend document: **Implemented** (works as described), **Partial** (works, with the named gap), **Stub/Mock** (returns fixtures or hard-coded data), **Planned** (designed in these docs, not in the code).

| Area | Status | What exists in code | Where |
|---|---|---|---|
| FastAPI app, CORS, request-context middleware | **Implemented** | One ASGI app, 50 operations on 45 paths plus WebSocket `/v1/ws/fleet`, wildcard CORS | `src/hawa_backend/api/app.py` |
| AI-ML bridge (`IntelClient`) | **Implemented** | HTTP to the AI-ML service, then in-process `hawa_ml`, then fixtures; in-memory circuit breaker | `src/hawa_backend/core/intel_client.py` |
| Live station ingestion | **Implemented** | WAQI map-bounds API, then OpenAQ v3 locations, then 5 baseline stations; cached 15 min in process | `IntelClient._fetch_live_stations` |
| Hotspots, twin, forecast, open air data | **Implemented** | Served from AI-ML (live WAQI data kriged in-process when the HTTP service is down), fixture fallback | `api/routes/hotspots.py`, `forecast.py`, `open_data.py` |
| Plans (list, draft, approve, request changes, apply suggestion, compare) | **Partial** | Drafts come from the AI-ML planner; state in Redis (`plans:active`) or an in-process dict; seed plan `214` is a fixture; approval can start Step Functions and publish to SNS | `api/routes/plans.py` |
| Causal impact and effectiveness library | **Partial** | Fixture intervention enriched with an AI-ML verification; library from AI-ML | `api/routes/impact.py` |
| Citizen endpoints | **Partial** | Safe route and safe window call `hawa_ml` in process; live operations and the missed-machine audit use live telemetry; ward leaderboard is hard-coded |
| Citizen reports (Citizen Eyes) | **Implemented** | `/v1/reports*`: DynamoDB grievances or memory, automated verification, officer ticket/close, FCM push | `services/reports.py`, `api/routes/reports.py` |
| Live fleet telemetry | **Implemented** | HTTP ingest, Kinesis consumer, Redis GEO, DynamoDB tracks, `/v1/fleet/*`, WebSocket | `services/fleet.py`, `aws/kinesis_consumer.py`, `api/routes/fleet.py` |
| Alerts and push | **Implemented** | SNS broadcast and subscribers, FCM HTTP v1, push tokens, alert areas | `services/alerts.py`, `services/push.py`, `api/routes/alerts.py`, `me.py` | `api/routes/citizen.py` |
| Devices, alerts list | **Implemented** | Live telemetry and sent broadcasts first, then fixtures | `api/routes/devices.py`, `alerts.py` |
| Driver route | **Stub/Mock** | Fixture from `api/fixtures.py` | `api/routes/driver.py` |
| Health probes | **Implemented** | `/readyz` pings Redis and lists which AWS services and FCM are configured | `api/routes/health.py` |
| RFC 9457 errors | **Partial** | Model, exception classes and handler exist; no route raises them, so clients get FastAPI's default error bodies | `core/errors.py` |
| Auth (JWT, OTP, password hashing, webhook HMAC) | **Partial** | Helper functions only; no auth endpoints; no route enforces a token | `core/security.py` |
| Structured JSON logging with PII masking | **Partial** | Formatter and masking helpers exist; nothing in `src/` uses `get_logger` | `core/logging.py` |
| Optional AWS layer | **Implemented** | S3, DynamoDB (grievances, fleet, cache), Kinesis producer and consumer, SNS, Secrets Manager, Step Functions and SageMaker forecast, Step Functions dispatch; off unless `HAWA_AWS_ENABLED=true` ([AWS architecture](../AWS_ARCHITECTURE.md)) | `src/hawa_backend/aws/` |
| `hawa_contracts` package | **Implemented** | Enums, ids, units, packets, envelope, 26 topics, 12 consumer groups, Redis key builder, 24 event models | `backend/contracts/` |
| SQLAlchemy models, migrations, seed | **Partial** | 23 tables; Alembic revision `0001` (`alembic.ini`, `migrations/`); idempotent seed (`db/seed.py`); verified on Postgres 16 and SQLite; the API never opens a session | `src/hawa_backend/db/`, `migrations/` |
| Ingest, simulator, dispatch saga | **Partial** | Plain Python classes, unit-tested; not connected to MQTT, Kafka or the database | `src/hawa_backend/workers/` |
| CLI `hawa` | **Implemented** | `version`, `config`, `check`, `aws-check`, `simulate-fleet`, `consume-telemetry` | `src/hawa_backend/cli.py` |
| Local infrastructure | **Implemented** | `docker-compose.yml` with PostGIS 16, Redis 7, Kafka 3.8 (KRaft); the backend uses the Redis when `HAWA_REDIS_URL` points at it | `backend/docker-compose.yml` |
| PostGIS geometry, partitions | **Planned** | none (Alembic itself is Implemented) | — |
| Kafka producers and consumers, outbox relay | **Planned** | Topic names and event models only | — |
| Redis live state | **Implemented** | Fleet geo index, twin snapshot, plans, push tokens, alert log, pub/sub, Kinesis checkpoints | `core/redis_store.py` |
| Redis rate limits, idempotency keys, OTP store | **Planned** | Key builders only | — |
| WebSocket `/v1/ws/fleet` | **Implemented** | Snapshot then every ping; task-event socket `/v1/ws` is Planned | `api/routes/fleet.py`, [API.md](API.md) |
| Auth endpoints, RBAC, ward scoping | **Planned** | none | [API.md](API.md) §6 |
| Scheduler, notifier, feeds-worker, alert-engine, MQTT bridge, other workers | **Planned** | none | [ARCHITECTURE.md](ARCHITECTURE.md) §8 |
| Metrics, tracing, dashboards | **Planned** | none | — |
| Dockerfile, image build, IaC | **Implemented** | `backend/Dockerfile` (build from the repo root); `.github/workflows/backend-image.yml` pushes it to ECR (manual trigger); CloudFormation `hawa-integration.yaml`, `hawa-redis.yaml`, `hawa-ecs.yaml` in `infrastructure/cloudformation/`. Test CI and CDK are Planned | [DEPLOYMENT.md](DEPLOYMENT.md), [AWS integration guide](../AWS_SETUP_GUIDE.md) |

In one sentence: today the backend is a single FastAPI process that serves the web console and the Flutter app by translating AI-ML output (live, in-process or fixture) into the frontend's camelCase contract, keeps plan, fleet and alert state in Redis or memory, stores citizen reports and telemetry in DynamoDB, and talks to S3, Kinesis and SNS. The event-driven, database-backed design in the rest of these documents is the target, and is labelled **Planned** wherever it appears.

## 2. Documents

| File | What it covers | Read when |
|---|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | The one running process, module layering, the hotspot/forecast fallback chain, the circuit breaker, live station ingestion, plan flow, security and resilience as built, then the target process architecture | Before changing any code |
| [API.md](API.md) | Every registered route with parameters, real response examples, status codes and data source; errors, CORS, headers, auth; planned endpoints listed separately | Before touching routes or clients |
| [SERVICES.md](SERVICES.md) | Citizen reports, fleet telemetry, alerts, push, twin snapshot, AI-ML bridge, plans: lifecycles and fallbacks | Before changing a feature |
| [DATA_STORES.md](DATA_STORES.md) | DynamoDB items, Redis keys, S3 layout, SQL schema | Before touching storage |
| [TESTING.md](TESTING.md) | Test suites, moto and fakeredis, live AWS checks | Before a PR |
| [DEPLOYMENT.md](DEPLOYMENT.md) | EC2 + PM2 (live), the Docker image, ECS Fargate, configuration and operations | When running or shipping |

The code is organised by layer under `backend/src/hawa_backend/`.

## 3. Reading order

**Humans:** this README → [SERVICES.md](SERVICES.md) → [API.md](API.md) → [ARCHITECTURE.md](ARCHITECTURE.md) → [DATA_STORES.md](DATA_STORES.md) → [DEPLOYMENT.md](DEPLOYMENT.md).

**AI coding agents:** treat the code and this README's status table as the truth; treat `../CONTRACTS.md` as binding for names that already exist in `hawa_contracts`. Do not assume any **Planned** item exists.

**Frontend and app developers:** [API.md](API.md). Responses use the camelCase shapes in `frontend/src/lib/api.ts`, not the snake_case shapes in the planned spec.

**AI-ML developers:** [ARCHITECTURE.md](ARCHITECTURE.md) §4 (exactly which `hawa_ml` symbols and HTTP paths the backend uses) and `backend/contracts/`.

## 4. Quick start (verified)

Prerequisites: [uv](https://docs.astral.sh/uv/) (Python 3.11 from `.python-version`). Docker is optional: it is only needed for `make db-up` (Postgres); nothing in the running API connects to Postgres, Redis or Kafka yet.

From the repo root (see the [root README](../../README.md#commands)):

```bash
make install       # cd backend && uv sync --extra dev   (backend + contracts + AI-ML + alembic)
make db-up         # optional: Postgres via backend/docker-compose.yml
make db-update     # cd backend && uv run alembic upgrade head
make db-seed       # cd backend && uv run python -m hawa_backend.db.seed
make aiml-api      # AI-ML engine on 0.0.0.0:8100 with --reload (activate backend/.venv first)
make backend       # uvicorn hawa_backend.api.app:app on 0.0.0.0:8000
# OpenAPI UI: http://localhost:8000/docs   ReDoc: /redoc   schema: /openapi.json
```

`backend/pyproject.toml` declares `hawa-contracts` (`./contracts`) and `hawa-ml[llm]` (`../AI-ML`) as editable path dependencies (`[tool.uv.sources]`), so `uv sync` produces one environment for both the backend and the AI-ML engine. Without uv: `python3 -m venv .venv && . .venv/bin/activate && pip install -e contracts -e "../AI-ML[llm]" -e ".[dev,aws]"`.

The AI-ML engine is optional: without it the backend calls `hawa_ml` in process, then falls back to fixtures. AI-ML's own `make api` binds port 8000 (collides with the backend); use `make aiml-api` from the root.

CLI:

```bash
hawa --help            # or: python -m hawa_backend.cli --help
hawa version           # HawaCommand Backend v0.1.0
hawa config            # prints env, debug, database URL, redis URL, kafka brokers
hawa check             # [OK] Configuration validated successfully.
```

Tests (from `backend/`; `pyproject.toml` already sets `pythonpath = ["src", "contracts"]` and both test paths):

```bash
uv run pytest -q -W ignore
```

Result on 2026-10-10: **65 tests, 64 passed, 1 failed** (`tests/integration/test_end_to_end.py::test_full_mission_air_pipeline`, Known issue 2). The suite needs no Docker; database tests use in-memory SQLite and AWS tests use moto.

## 5. Services and ports (local)

| Service | Port | Started by | Used by the backend today |
|---|---|---|---|
| Backend API (`hawa_backend.api.app:app`) | 8000 (`HAWA_PORT` is informational; uvicorn's `--port` decides) | `uvicorn` by hand | — |
| AI-ML service (`hawa_ml.api.main:app`) | expected at 8100 (`HAWA_AIML_SERVICE_URL`) | `uvicorn` by hand | Yes, over HTTP when reachable; otherwise in process |
| PostgreSQL 16 + PostGIS 3.4 (`hawa-postgres`) | 5432 | `docker compose up -d` in `backend/` | No |
| Redis 7 (`hawa-redis`) | 6379 | same | No |
| Kafka 3.8 KRaft (`hawa-kafka`) | 9092 host, 29092 in-network, 9093 controller | same | No |
| WAQI (`api.waqi.info`) and OpenAQ (`api.openaq.org`) | HTTPS | — | Yes, for live station readings |
| AWS (DynamoDB, Step Functions, SageMaker, SNS, Kinesis) | — | — | Only with `HAWA_AWS_ENABLED=true` |

The web console (`frontend/`, `NEXT_PUBLIC_API_URL=http://localhost:8000`) and the Flutter app (`app_frontend/`, `HAWA_API_URL`, default `http://10.0.2.2:8000`) call the backend.

## 6. Request path in one line

Client → `GET /v1/hotspots` → `IntelClient.get_hotspots` → AI-ML `GET {HAWA_AIML_SERVICE_URL}/hotspots` (circuit breaker) → else in-process `hawa_ml` exposure engine on a twin kriged from live WAQI stations → else `api/fixtures.py` → reshaped to the frontend contract with readable place names (`core/places.py`). Details in [ARCHITECTURE.md](ARCHITECTURE.md) §3.

## 7. Known issues

Defects found while reconciling these documents with the code (verified 2026-10-10 at commit `a33e043`). Paths are relative to `backend/` unless they start with another top-level directory. None of them are fixed here.

### 7.1 Build, packaging and tests

1. **AI-ML dependency (fixed).** `src/hawa_backend/api/routes/citizen.py:7-9` imports `hawa_ml` at module level. `pyproject.toml` now declares `hawa-ml[llm]` as an editable path dependency on `../AI-ML`, so `uv sync` installs it. A venv built by hand without `../AI-ML` still cannot import the app.
2. **Failing end-to-end test.** `tests/integration/test_end_to_end.py:321` asserts `GET /v1/hotspots` returns `"simulated": true`. When the AI-ML HTTP service is not running and `hawa_ml` is installed (the normal test setup), `IntelClient.get_hotspots` takes the in-process path, which sets `"simulated": False` (`src/hawa_backend/core/intel_client.py:494`). The HTTP path (`:425`) and the fixture path (`:514`) set `True`. The test passes only when the AI-ML service is reachable or `hawa_ml` is absent.
3. **Packaging.** `pyproject.toml` has no `[build-system]`, so `uv.lock:682` records `hawa-backend` as a virtual project: `uv sync` installs the dependencies but not `hawa_backend` or the `hawa` script (`pip install -e .` does work, with setuptools' default backend). `api/`, `api/routes/`, `core/`, `db/` and `workers/` have no `__init__.py` (implicit namespace packages).
4. **Stale lock.** `uv.lock:704` locks `moto` with only the `dynamodb` extra while `pyproject.toml:30` asks for `moto[dynamodb,sns,kinesis]`; `uv lock --check` will report the lock as out of date.
5. **Lint.** No ruff or mypy configuration exists. `ruff check src` with ruff 0.17.0 defaults reports 357 findings; with the classic `--select E4,E7,E9,F` set, `src contracts tests` report 96 (93 unused imports, 2 unused variables, 1 multiple-imports line).

### 7.2 Data honesty and consistency

6. **`simulated` flag is inconsistent.** Hotspots from AI-ML over HTTP are labelled `simulated: true` (`core/intel_client.py:425`) although AI-ML computes them from the same live feeds, while the in-process path says `false` (`:494`). The twin fallback returns fixture hotspots labelled `simulated: false` (`:334-340`).
7. **Ward vocabularies do not match.** The live path uses AI-ML ward names (`Ward-1`, `Ward-3`, …), fixtures use zone names (`West`, `North West`, `East Delhi` …), the seed plan uses `ward-084`. A `?ward=` value that matches nothing on the live path silently falls back to fixtures (`core/intel_client.py:420-421, 489-490, 506-510`); for example `GET /v1/forecast?ward=North West` returns a fixture-based Stage IV outlook.
8. **Cell id vocabularies do not match.** Ingest produces `g500-062-052` style ids (`workers/ingest.py:17-19, 36-42`, using a 0.0045° step for both latitude and longitude), AI-ML returns `G-050-072`, fixtures use slugs (`ghazipur`) and `g500-041-077`, and `IntelClient` defaults to `C-2863-7721` (`core/intel_client.py:1037`). `GET /v1/hotspots/{cell_id}` only finds ids from whichever source answered.
9. **Effectiveness library confidence intervals.** When a record's reduction is positive, the effect is negated but the CI is not (`core/intel_client.py:1115-1124, 1140-1149`); observed: `effectPct -14.0` with `ci [9.0, 19.0]`. Every non-dust cause is labelled `Burning`.
10. **OpenAQ fallback invents values.** Every OpenAQ location is given `pm25 78.0`, `pm10 135.0` (`core/intel_client.py:256-262`); only the coordinates are real.

### 7.3 API behaviour

11. **Draft id collisions.** The AI-ML planner names plans `PLAN-YYYYMMDD-HHMM` (`AI-ML/src/hawa_ml/agents/planner_agent.py:47-50`) and `api/routes/plans.py:141-142` stores drafts by that id, so two drafts in the same minute overwrite each other (observed with `ward-084` then `All wards`).
12. **Plans have no lifecycle rules or persistence.** State is the module dict `_ACTIVE_PLANS` (`api/routes/plans.py:27`), lost on restart and not shared between workers. Approve and request-changes work from any status (`:146-166`); applying an unknown comment id returns 200 (`:169-175`); compare/simulate do not check that the plan exists (`:178-183`).
13. **RFC 9457 is not what clients receive.** The `HawaException` handler (`api/app.py:58-66`) is never triggered: 404s are `HTTPException` with `{"detail": "..."}` (`api/routes/hotspots.py:26`, `api/routes/plans.py:116`) and 422s are FastAPI's default `{"detail": [...]}`. `AimlUnavailableError` and `AimlTimeoutError` are imported (`core/intel_client.py:26`) but never raised; AI-ML failures degrade silently to fallbacks.
14. **No authentication.** Every route is anonymous; `core/security.py` is not used by any route. CORS is `allow_origins=["*"]` with `allow_credentials=True` (`api/app.py:36-42`), so Starlette reflects any `Origin` with credentials allowed.
15. **Readiness lies.** `/readyz` returns `database: ok` and `redis: ok` without contacting either (`api/routes/health.py:16-25`).
16. **Ids not echoed.** `X-Request-Id` / `X-Correlation-Id` are echoed only when the client sent them (`api/app.py:52-55`); generated ids are never returned.
17. **Ignored parameters.** `GET /v1/forecast/{cell_id}` ignores `pollutant` and `issued_at` (`api/routes/forecast.py:28-34`). `IntelClient.draft_plan` ignores `windowStart` and always labels the window `Thu 06:00 – 10:00` (`core/intel_client.py:695-709, 755, 909`). `verify_intervention` ignores `cell_id`, `asset` and `action` (`:1034-1041`). `simulate_plan` posts empty `hotspots`/`assets` and returns hard-coded rows (`:931-959`).
18. **Plan formatting heuristics.** `_format_drafted_plan` labels every task whose action lacks "dust"/"sprink" as cause `Traffic`, fixes `causeConf` at 0.82, and flags the second task `auditor` regardless of content (`core/intel_client.py:818-819, 838, 842-843`).
19. **Blocking I/O in async handlers.** WAQI and OpenAQ are fetched with blocking `urllib.request.urlopen` (5 s timeout each, `core/intel_client.py:208, 251`) and the GP twin is fitted synchronously (`:281-293`) inside async route handlers; the first `/v1/hotspots` after a cache expiry took about 3 s and blocks the event loop meanwhile.
20. **Shared mutable state in citizen routes.** `safe_route_optimizer.default_bg_pm25` and `safe_window_calculator.baseline_pm25` are module-level `hawa_ml` singletons overwritten on every request (`api/routes/citizen.py:42, 65`). `/v1/citizen/live-operations` returns a fixed `as_of` of `2026-10-08T03:00:00Z` (`:118`).
21. **Secrets in git history.** WAQI and OpenAQ API keys were hard-coded in `core/intel_client.py` in commit `fec1f58`. They are no longer in the code (`core/config.py` defaults are `None`; set `WAQI_TOKEN` / `OPENAQ_API_KEY` in `backend/.env`), but they remain in history and should be revoked.

### 7.4 Not wired

22. **Workers are library code only.** `workers/ingest.py`, `simulator.py`, `dispatch.py` are not run by any process or CLI command. The dedupe set grows without bound (`workers/ingest.py:27`), the spike baseline is a caller-supplied default of 80 (`:63`), `confirmed_by_cloud` is always `True` (`:134`), and the saga matches the first open task for an asset with no location or time check (`workers/dispatch.py:46-49`).
23. **Unused settings and helpers.** `HAWA_KAFKA_*`, `HAWA_HOST`, `HAWA_PORT` are read but nothing connects or binds with them; `db/session.get_db` is never used by a route; `core/logging.get_logger` is never called. (`HAWA_REDIS_URL`, `aws.publish_alert` and `aws.publish_sensor_reading` are used since 2026-10-11.)
24. **Context default is shared.** `_CURRENT_CONTEXT` defaults to one module-level `RequestContext()` (`core/context.py:19`, ruff B039), so code running outside a request shares one request id.

### 7.5 Cross-component mismatches

25. **AI-ML port.** The backend expects AI-ML on 8100 (`core/config.py:42`, `.env.example:26`) but `AI-ML/Makefile:35` and `AI-ML/src/hawa_ml/api/main.py:45` start it on 8000, the backend's own port.
26. **Flutter app expects endpoints that do not exist.** `/v1/auth/*` (`app_frontend/lib/core/network/api_paths.dart:3`) and the WebSocket `/v1/ws` (`app_frontend/lib/app/env.dart:11`) are **Planned** here.

<!-- footer:start -->

---

[Back to top](#hawacommand-backend--documentation-index) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
