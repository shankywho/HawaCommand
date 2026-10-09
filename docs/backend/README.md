# HawaCommand Backend — Documentation Index

Entry point for everything under `backend/`: what the backend owns, which document to read for what, and how to get the golden path running locally.

Related: [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [DATA_MODEL](DATA_MODEL.md) · [API](API.md) · [EVENTS](EVENTS.md) · [CACHING](CACHING.md) · [LOGGING_AND_OBSERVABILITY](LOGGING_AND_OBSERVABILITY.md) · [DEPLOYMENT](DEPLOYMENT.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. What the backend owns

The backend (`backend/`, Python 3.12, FastAPI + asyncio) is the **plumbing and the command surface** of the closed loop (§5). It does not compute the twin, forecasts, plans or causal effects; those belong to AI-ML. The backend moves data between loop stages, stores it, serves it, and turns approved decisions into real-world actions.

| Area | Backend responsibility | Key artefacts |
|---|---|---|
| Edge ingest | MQTT to Kafka bridge, packet validation, dedupe, calibration apply, cell lookup, readings storage, HawaTag spray segments | `mqtt-bridge`, `ingest-worker`, `reading`, `device_event`, `intervention` |
| External feeds | CPCB / OpenAQ, Open-Meteo (IMD/ERA5 proxy), NASA FIRMS polling and normalisation | `feeds-worker`, `reference_observation`, `weather_*`, `fire_point` |
| Orchestration | Cron in IST that publishes `hawa.cmd.*` commands; dispatch saga (approve → notify → await spray → verify) | `scheduler`, `dispatch-worker` |
| Command surface | REST + WebSocket for the officer console, the Flutter field and community app, and the open data portal | `api` ([API.md](API.md)) |
| Human-in-the-loop gate | Nothing dispatches without officer approval (F14) | `POST /v1/plans/{id}/approve` |
| Delivery | Push (FCM), WhatsApp Cloud API, SMS (SNS), in-app | `notifier`, `alert-engine` |
| Schema | Alembic owns **every** DDL change for the shared `hawa` schema, including AI-ML-owned tables | `backend/alembic/` ([DATA_MODEL.md](DATA_MODEL.md)) |
| Contracts | `hawa_contracts` Python package: enums, packets, envelopes, topics, Redis key builders | `backend/contracts/` |
| Local stack | Root `docker-compose.yml`, `.env.example`, `Makefile` | repo root (owned by the backend team) |
| Infra | AWS CDK (Python) for the pilot | `backend/infra/` |
| Device simulator | Virtual HawaPod/HawaTag fleet publishing the exact firmware packet | `backend/simulator/` |

## 2. Documents

| File | What it covers | Read when |
|---|---|---|
| [CONTEXT.md](CONTEXT.md) | Backend role per loop step, users and flows, the day timeline, spike path, real vs simulated, non-functional requirements, risks, non-goals | First, always |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Processes, layering, sequence diagrams (ingest, saga, WebSocket, Citizen Eyes, school alerts, What-If), auth/RBAC overview, security, resilience, performance, scaling | Before writing any code |
| [STRUCTURE.md](STRUCTURE.md) | Full `backend/` tree with one line per file, tooling (uv, ruff, mypy, pytest, pre-commit, Makefile) | When creating files or packages |
| [DATA_MODEL.md](DATA_MODEL.md) | Postgres/PostGIS schema, SQLAlchemy models, Alembic workflow, partitions | Before touching tables or migrations |
| [API.md](API.md) | Full REST and WebSocket spec, auth, RBAC details, errors, pagination | Before touching routers or clients |
| [EVENTS.md](EVENTS.md) | Kafka: setup, topic bootstrap, envelope/serde, producer/consumer design, outbox, consumer group map, saga choreography, replay, DLQ, lag | Before writing a producer or consumer |
| [CACHING.md](CACHING.md) | Redis: keys and TTLs, versioned cache-aside, stampede protection, rate limiting, OTP, idempotency, locks, pub/sub, GEO, failure modes | Before adding any Redis usage |
| [LOGGING_AND_OBSERVABILITY.md](LOGGING_AND_OBSERVABILITY.md) | logifyx setup and policy, PII rules, audit vs app log, OpenTelemetry, Prometheus metrics, Grafana, alerts, probes | Before adding logs, metrics or spans |
| [DEPLOYMENT.md](DEPLOYMENT.md) | docker-compose services, `.env.example` catalogue, Makefile, demo-reset, AWS CDK stacks, CI/CD, backups, secrets, cost | When running, shipping or demoing |
| [PLAN.md](PLAN.md) | Hour-by-hour hackathon plan for the backend lead, milestones with acceptance criteria, dependencies, cut rules, risks, post-hackathon phases | At kickoff and at every checkpoint |

## 3. Reading order

**Humans (backend lead and reviewers):** `../SYSTEM_OVERVIEW.md` → `../CONTRACTS.md` → CONTEXT → ARCHITECTURE → EVENTS → DATA_MODEL → API → CACHING → LOGGING_AND_OBSERVABILITY → STRUCTURE → DEPLOYMENT → PLAN.

**AI coding agents:** treat `../CONTRACTS.md` as binding and do not invent topic names, table names, Redis keys or enums.

**Frontend and app developers:** API.md (endpoints, auth, WebSocket) and `../CONTRACTS.md` §6. You never read Kafka.

**AI-ML developers:** EVENTS.md §4, §7 (envelope, consumer groups), DATA_MODEL.md (tables you own), CACHING.md §2 (`ml:*`, `lock:plan:*`, `dedupe:evt:*`), and `backend/contracts/`.

## 4. Quick start (local, golden path)

Prerequisites: Docker Desktop (8 GB RAM allocated), `uv` (latest stable), `make` (optional), Git Bash or WSL on Windows.

```bash
# from the repo root
cp .env.example .env                     # host-oriented defaults; compose overrides hostnames inside containers
docker compose up -d                     # infra only (default profile): postgres, redis, kafka, schema-registry,
                                         # kafka-ui, mosquitto, minio (+ minio-init)
cd backend
uv sync                                  # creates .venv from uv.lock (workspace: root + contracts + simulator)
uv run alembic upgrade head              # schema hawa, PostGIS, all tables, first reading partitions
uv run hawa kafka-init                   # creates every topic from hawa_contracts.topics (idempotent)
uv run hawa seed                         # = hawa seed all: wards, grid, POIs, schools, stations, assets, devices, sites, users (DATA_MODEL §18)
uv run hawa api                          # terminal 1: http://localhost:8000/docs
uv run hawa worker mqtt-bridge           # terminal 2: Mosquitto -> hawa.telemetry.raw.v1
uv run hawa worker ingest                # terminal 3: raw -> reading + hawa.telemetry.clean.v1
uv run hawa worker outbox-relay          # terminal 4: outbox_event -> Kafka
uv run hawa-sim run --devices 50 --tags 10 --scenario golden   # terminal 5: virtual fleet over real MQTT
```

Check that it works:

```bash
docker compose exec postgres psql -U hawa -d hawa \
  -c "select count(*), max(ts), bool_and(is_simulated) from hawa.reading where ts > now() - interval '5 minutes';"
curl -s localhost:8000/readyz | jq
open http://localhost:8080               # Kafka UI: watch hawa.telemetry.clean.v1
```

Tests:

```bash
uv run pytest -m "not integration and not e2e"   # unit + contract, < 30 s, no Docker needed
uv run pytest -m integration                     # testcontainers: PostGIS, Redis, Kafka
uv run pytest -m e2e                             # golden path against the running compose stack
```

The whole stack in containers, with AI-ML, web and observability: `make up && make migrate && make seed && make sim`. See [DEPLOYMENT.md](DEPLOYMENT.md) §3 for all Makefile targets and §5.2 for `make demo-reset`.

## 5. Services and ports (local)

Host ports. Inside the compose network, services use service names (for example `postgres:5432`, `kafka:19092`).

| Service | Owner | Host port(s) | Profile | Notes |
|---|---|---|---|---|
| postgres (PostGIS 16-3.4) | backend | 5432 | default | DB `hawa`, schema `hawa`; DB `mlflow` for MLflow |
| redis 7 | backend | 6379 | default | `maxmemory-policy volatile-lru` |
| kafka (Apache Kafka, KRaft) | backend | 9092 (host listener) | default | internal listener `kafka:19092`, controller 9093 |
| schema-registry | backend | 8081 | default | only for logifyx Avro on `hawa.logs.v1` |
| kafka-ui | backend | 8080 | default | topics, groups, lag, message browser |
| mosquitto 2 | backend | 1883 | default | username/password per device, ACL by topic |
| minio (S3) | backend | 9000 (API), 9001 (console) | default | buckets `hawa-local-lake`, `-media`, `-reports`, `-models` |
| api | backend | 8000 | app | REST `/v1`, `/open/v1`, WebSocket `/v1/ws`, `/healthz`, `/readyz`, `/metrics` |
| ingest-worker | backend | 9101 | app | ops port: `/healthz` `/readyz` `/metrics` |
| feeds-worker | backend | 9102 | app | |
| scheduler | backend | 9103 | app | |
| dispatch-worker | backend | 9104 | app | |
| notifier | backend | 9105 | app | |
| outbox-relay | backend | 9106 | app | |
| mqtt-bridge | backend | 9107 | app | local and demo only |
| audit-writer | backend | 9108 | app | |
| alert-engine | backend | 9109 | app | |
| evidence-report | backend | 9110 | app | |
| archiver | backend | 9111 | app | |
| simulator | backend | 9112 | sim | virtual fleet |
| intel-service | AI-ML | 8100 | ml | internal only (`/internal/v1/*`) |
| intel-worker | AI-ML | 9120 | ml | |
| mlflow | AI-ML | 5000 | ml | |
| web (Next.js) | frontend | 3000 | web | |
| jaeger | backend | 16686 (UI), 4317/4318 (OTLP) | obs | |
| prometheus | backend | 9090 | obs | |
| grafana | backend | 3001 | obs | golden-path dashboard |
| kafka-exporter, redis-exporter, postgres-exporter | backend | 9308, 9121, 9187 | obs | |

Every backend worker listens on container port 9100 for its ops endpoints. The host ports above are the defaults when a worker runs on the host with `uv run hawa worker <name>`.

## 6. Golden path in one line

`hawa-sim` → Mosquitto → `mqtt-bridge` → `hawa.telemetry.raw.v1` → `ingest-worker` → `reading` + `hawa.telemetry.clean.v1` → `scheduler` `cmd.twin.rebuild` → intel-worker → `twin.updated` → `api` cache + WebSocket → officer drafts plan → intel-worker `plan.drafted` → officer approves → `dispatch-worker` → `notifier` (push + SMS to a test phone) → simulated HawaTag `spray.stopped` → task `done` → `cmd.verify.run` → `impact.verified` → `/console/impact`. Details in [ARCHITECTURE.md](ARCHITECTURE.md) §5 and `../SYSTEM_OVERVIEW.md` §10.

## 7. Proposed contract additions (summary)

The backend docs define a few items that `../CONTRACTS.md` does not yet contain. Each is marked **Proposed contract addition (PCA-nn)** where it is used. The lead merges them into CONTRACTS.md and `hawa_contracts` in one PR.

| ID | Summary | Defined in |
|---|---|---|
| PCA-01 | AWS streaming uses **MSK provisioned** (SASL/SCRAM for the IoT Rule, IAM for services), not MSK Serverless | DEPLOYMENT §6.3 |
| PCA-02 | Raw ingress accepts an envelope (bridge) or a bare packet plus headers (IoT Rule). The raw `is_simulated` is advisory only | EVENTS §3.3 |
| PCA-03 | Topic `hawa.cmd.dispatch.v1` (`cmd.dispatch.release`, `cmd.dispatch.sweep`) | EVENTS §8 |
| PCA-04 | Topic `hawa.cmd.alert.v1` (`cmd.alert.school_run`) | EVENTS §8 |
| PCA-05 | Topic `hawa.cmd.maintenance.v1` (`cmd.partitions.maintain`, `cmd.snapshot.freeze`) | EVENTS §8 |
| PCA-06 | Group `dispatch` also on `hawa.task.lifecycle.v1`; group `api-live` also on `hawa.alert.requested.v1` | EVENTS §7 |
| PCA-07 | intel-worker produces `device.calibrated` / `device.trust_changed`; api produces `alert.delivered` / `alert.read` | EVENTS §7 |
| PCA-08 | Event types `plan.partially_completed` and `task.failed` | EVENTS §9 |
| PCA-09 | Schedule changes: every-minute dispatch sweep, command topics for release, school run and maintenance | EVENTS §8 |
| PCA-10 | Extra DLQ headers (`hawa-dlq-partition`, `-offset`, `-attempts`, `-failed-at`, `-error-type`) | EVENTS §5.4 |
| PCA-11 | Deterministic UUIDv7 `event_id` for ingest-derived events | EVENTS §3.4 |
| PCA-12 | CONTRACTS wording: `reading` uniqueness is `(device_id, seq, ts)` (the partition key is required; DATA_MODEL already uses it as the PK) | ARCHITECTURE §5.1 |
| PCA-13 | Redis keys `idem:*`, `lock:cache:*`, `cache:open:*`, `cache:grap:*`, `ws:user:*`, and `rl` scope names | CACHING §2.2 |
| PCA-14 | Hash phone numbers in Redis keys (`otp:{phone_hash}`) | CACHING §8 |
| PCA-15 | Table `calibration_pair` (drive-by pairing), written by group `ingest-calibration` | ARCHITECTURE §5.1 |
| PCA-16 | `intervention.verify_requested_at`, `verify_attempts`, `flags`. Saga state is derived (no `dispatch_saga` table), and the scheduler writes `verification_status` + `verify_*` | ARCHITECTURE §5.2, EVENTS §9–10 |
| PCA-17 | `inspection.proposed_asset_id` + `POST /v1/inspections/{id}/assign` (officer approval for Citizen Eyes) | ARCHITECTURE §5.4 |
| PCA-18 | Internal `POST /internal/v1/narrative` for the evidence report | ARCHITECTURE §4 |
| PCA-19 | `device.spike` data fields `confirmed_by_cloud` (same name as the `device_event` column) and `late` | ARCHITECTURE §5.1 |
| PCA-20 | `alert.requested` data field `delivery: first_success \| all` | ARCHITECTURE §5.5 |
| PCA-21 | `simulated_share` on `twin_run` / `twin.updated`. A derived event's `is_simulated` is true if any input was simulated | CONTEXT §6 |
| PCA-22 | Tile URLs carry `?v={tile_version}`, with ETag and immutable caching | CACHING §4 |
| PCA-23 | Every worker exposes `/healthz`, `/readyz`, `/metrics` on container port 9100 | LOGGING_AND_OBSERVABILITY §15 |
| PCA-24 | logifyx needs a Kafka security passthrough before `hawa.logs.v1` can run on MSK | LOGGING_AND_OBSERVABILITY §2.4 |
| PCA-25 | Optional group `archiver-raw` for a raw S3 archive | EVENTS §7 |
| PCA-26 | Group hosting: `device-health` runs in alert-engine; `audit` and `audit-writer` both run in audit-writer | EVENTS §7 |
| PCA-27 | Open-data simulated policy `HAWA_OPEN_INCLUDE_SIMULATED` | CONTEXT §6 |
| PCA-28 | DB login users for the processes DATA_MODEL §20.5 doesn't list: `hawa_alerts` (alert-engine), `hawa_audit` (audit-writer), `hawa_reports` (evidence-report), all members of `app_rw`. The archiver's partition job uses the owner login | DEPLOYMENT §2.2–2.3 |
| PCA-29 | `intervention` writers include the **api** (manual fallback, API.md §7). CONTRACTS §8 and DATA_MODEL §9.1 name only ingest/dispatch | ARCHITECTURE §5.2 |

Where these documents overlap with [DATA_MODEL.md](DATA_MODEL.md) (schema, roles, grants, partitions, seed, demo reset, retention) or [API.md](API.md) (endpoints, error codes, auth, rate limits, idempotency, HTTP caching), **those two are authoritative**, and the docs here have been aligned to them.
