# Backend Structure and Tooling

The full `backend/` folder tree with one line of responsibility per file or package, plus the tooling: uv workspace, ruff, mypy, import contracts, pytest, pre-commit, the `hawa` CLI and the Makefile.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [EVENTS](EVENTS.md) · [CACHING](CACHING.md) · [LOGGING_AND_OBSERVABILITY](LOGGING_AND_OBSERVABILITY.md) · [DATA_MODEL](DATA_MODEL.md) · [API](API.md) · [DEPLOYMENT](DEPLOYMENT.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. Repo-root files owned by the backend team

| File | Purpose |
|---|---|
| `docker-compose.yml` | the whole local stack (infra, backend, AI-ML, web, observability) with profiles ([DEPLOYMENT.md](DEPLOYMENT.md) §2) |
| `.env.example` | canonical variable catalogue for every service ([DEPLOYMENT.md](DEPLOYMENT.md) §4) |
| `Makefile` | `up`, `down`, `logs`, `migrate`, `seed`, `sim`, `demo-reset`, `lint`, `test`, `fmt` and more (§4.7) |
| `.github/workflows/backend.yml` | backend CI/CD with path filters `backend/**`, `docs/CONTRACTS.md` ([DEPLOYMENT.md](DEPLOYMENT.md) §8) |

Other teams send changes to these files as PRs reviewed by the backend lead.

## 2. `backend/` tree

```text
backend/
├── pyproject.toml                    # root project `hawa-backend`; uv workspace (members: contracts, simulator); console script `hawa`; ruff/mypy/pytest/import-linter config
├── uv.lock                           # single lockfile for the workspace (committed; CI runs `uv lock --check`)
├── .python-version                   # 3.12
├── alembic.ini                       # script_location=alembic; URL read from HAWA_MIGRATOR_DATABASE_URL in env.py
├── logifyx.yaml                      # logifyx baseline defaults (mask, topic, compatibility, rotation); see LOGGING_AND_OBSERVABILITY §2.2
├── .env.example                      # pointer to the repo-root .env.example plus backend-only test overrides
├── .pre-commit-config.yaml           # hooks (§4.5)
├── openapi/openapi.v1.json           # exported OpenAPI, diffed with `oasdiff breaking` in CI (API.md §1.10)
│
├── alembic/
│   ├── env.py                        # async env (asyncpg, run_sync); target_metadata = Base.metadata; schema `hawa`; include_object skips
│   │                                 #   child partitions `reading_p%` and PostGIS/topology tables; GeoAlchemy2 alembic_helpers (render_item, writer)
│   ├── helpers.py                    # op helpers: create_extension, create_partitioned_table, grant_table_privileges(role, tables), updated_at trigger
│   ├── script.py.mako                # revision template (imports geoalchemy2, sqlalchemy.dialects.postgresql)
│   └── versions/                     # `YYYYMMDD_HHMM_<slug>.py`; baseline = schema, PostGIS, all tables, grants (DATA_MODEL.md owns the content)
│
├── contracts/                        # installable package `hawa-contracts` (import `hawa_contracts`), shared with AI-ML as a uv path dependency
│   ├── pyproject.toml                # minimal deps: pydantic, uuid6, orjson (no FastAPI, no SQLAlchemy)
│   ├── hawa_contracts/
│   │   ├── __init__.py               # package version, re-exports
│   │   ├── py.typed                  # PEP 561 marker
│   │   ├── enums.py                  # every enum in CONTRACTS §3 as StrEnum/IntEnum; lenient parser mapping unknown values to `unknown`
│   │   ├── ids.py                    # id regexes (device, asset, vehicle, cell, ward, school, site, station), uuid7(), uuid7_deterministic(),
│   │   │                             #   g500 <-> g1k helpers, correlation-id helpers
│   │   ├── units.py                  # units, thresholds (CONTRACTS §10.3), AQI breakpoints + indicative AQI, GRAP stage mapping, C_SAFE values
│   │   ├── packets.py                # TelemetryPacket, DeviceEventPacket, SprayPacket, ClipPacket, DeviceCommand; validation rules + reason codes
│   │   ├── envelope.py               # Envelope[T], EventContext, header names (hawa-type, hawa-version, traceparent, DLQ headers)
│   │   ├── topics.py                 # TopicSpec registry for every topic (CONTRACTS §5.2 + PCA-03..05), Group enum (all consumer groups)
│   │   ├── redis_keys.py             # key builders with `hawa:{env}:` prefix, TTL constants, protected-key list (CONTRACTS §9 + PCA-13)
│   │   ├── schemas/                  # generated JSON Schemas for packets and events (`hawa contracts export`), committed for diffing
│   │   └── events/
│   │       ├── __init__.py           # REGISTRY {(type, version): model}; @event(type, version) decorator
│   │       ├── telemetry.py          # TelemetryRaw, ReadingCleaned, ReadingRejected
│   │       ├── device.py             # DeviceSpike (confirmed_by_cloud, late), DeviceTamper, DeviceHealth, DeviceBoot, DeviceCalibrated, DeviceTrustChanged
│   │       ├── intervention.py       # SprayStarted, SprayStopped
│   │       ├── external.py           # ReferenceObserved, WeatherObserved, WeatherForecasted, FireDetected
│   │       ├── commands.py           # CmdTwinRebuild, CmdForecastRun, CmdPlanDraft, CmdVerifyRun, CmdTrainRun, CmdEvidenceReportBuild,
│   │       │                         #   CmdDispatchRelease, CmdDispatchSweep, CmdAlertSchoolRun, CmdPartitionsMaintain, CmdSnapshotFreeze, CmdRetentionPurge
│   │       ├── twin.py               # TwinUpdated (tile_version, run_id, simulated_share), HotspotUpdated
│   │       ├── forecast.py           # ForecastIssued, GrapOutlookIssued, SchoolSafeWindowComputed
│   │       ├── plan.py               # PlanDrafting, PlanDrafted, PlanFailed, PlanEdited, PlanApproved, PlanRejected, PlanExpired,
│   │       │                         #   PlanDispatched, PlanInProgress, PlanCompleted, PlanPartiallyCompleted
│   │       ├── task.py               # TaskDispatched ... TaskInconclusive, TaskFailed (data.source for done)
│   │       ├── alert.py              # AlertRequested (channels, delivery), AlertSent, AlertDelivered, AlertFailed, AlertRead
│   │       ├── impact.py             # ImpactVerified
│   │       ├── report.py             # ReportSubmitted, ReportVerified, ReportRejected, ReportTicketed, ReportClosed
│   │       ├── integrity.py          # IntegrityFlagged
│   │       └── audit.py              # AuditRecorded
│   └── tests/                        # round-trips, JSON Schema snapshot diff, parity with CONTRACTS.md tables
│
├── src/hawa_backend/
│   ├── __init__.py                   # __version__ (git sha injected at build)
│   ├── bootstrap.py                  # Container: settings, engine/sessionmaker, UoW factory, Redis, producer, integrations, clock, metrics
│   ├── cli.py                        # typer app `hawa` (§5)
│   │
│   ├── core/
│   │   ├── config.py                 # Settings (pydantic-settings, env prefix HAWA_, nested groups: db, redis, kafka, mqtt, s3, auth, notify,
│   │   │                             #   feeds, dispatch, sched, log, otel); get_settings() cached; validation refuses unsafe prod combos
│   │   ├── logging.py                # logifyx setup (profiles, env-override rule), third-party routing, HawaLogger proxy, get_logger, flush_logs
│   │   ├── context.py                # contextvars: RequestContext (request_id, correlation_id, causation_id, user_id, role, ward_ids, event_id,
│   │   │                             #   topic, partition, offset, consumer_group, is_simulated); bind(), current(), log_fields()
│   │   ├── pii.py                    # mask_phone, mask_email, mask_token, hash_ip, redact_headers, PiiFilter
│   │   ├── security.py               # argon2id hashing, JWT issue/verify (TokenVerifier protocol: LocalJwtVerifier, CognitoJwtVerifier),
│   │   │                             #   OTP HMAC, webhook signature verify (X-Hub-Signature-256), constant-time compares
│   │   ├── ids.py                    # uuid7 wrappers (re-export hawa_contracts.ids) + UUID validation for headers
│   │   ├── errors.py                 # error hierarchy (NotFound, Conflict, Forbidden, UnprocessableEntity, RateLimited, Unavailable…),
│   │   │                             #   RFC 9457 problem+json rendering, code registry
│   │   ├── telemetry.py              # OpenTelemetry setup (FastAPI, SQLAlchemy, Redis, httpx, aiokafka propagation), X-Ray id generator on AWS
│   │   ├── metrics.py                # Prometheus registry and every hawa_* metric definition (LOGGING_AND_OBSERVABILITY §12)
│   │   ├── resilience.py             # CircuitBreaker, tenacity retry presets, bulkhead semaphores, timeout helpers
│   │   ├── lifecycle.py              # signal handling, ordered shutdown hooks (consumers → producer → pools → logifyx flush)
│   │   ├── opsserver.py              # tiny Starlette app for worker /healthz /readyz /metrics on port 9100 (PCA-23)
│   │   └── clock.py                  # Clock protocol: SystemClock (UTC), FrozenClock (tests); IST helpers for rendering and cron
│   │
│   ├── db/
│   │   ├── base.py                   # DeclarativeBase (schema hawa, constraint naming convention), mixins (timestamps, is_simulated, version)
│   │   ├── session.py                # async engine (asyncpg, orjson codec, pool, statement_timeout, hide_parameters), sessionmaker
│   │   ├── uow.py                    # UnitOfWork: session + repositories + outbox writer; commit/rollback; get_for_update helpers
│   │   ├── spatial.py                # GridIndex (lat/lon -> g500 via pyproj EPSG:32643 + grid_meta), bbox parsing, TILE_SQL, GeoJSON helpers
│   │   ├── partitions.py             # partitioned tables (reading, cell_state, forecast, audit_log): create ahead, Parquet export +
│   │   │                             #   verified manifest, DETACH CONCURRENTLY, drop, cell_state thinning, row retention (DATA_MODEL §14, §19)
│   │   ├── models/                   # SQLAlchemy 2.0 typed models for ALL tables (Alembic owns DDL for AI-ML tables too; see DATA_MODEL.md)
│   │   │   ├── grid.py               # grid_meta, cell, cell_1k, ward, cell_feature (AI-ML writes)
│   │   │   ├── poi.py                # poi
│   │   │   ├── school.py             # school
│   │   │   ├── device.py             # device, device_calibration (AI-ML writes), device_event, calibration_pair (PCA-15)
│   │   │   ├── reading.py            # reading (partitioned by day)
│   │   │   ├── reference.py          # reference_station, reference_observation
│   │   │   ├── weather.py            # weather_observation, weather_forecast, fire_point
│   │   │   ├── twin.py               # twin_run, cell_state, hotspot (AI-ML writes)
│   │   │   ├── forecast.py           # forecast_run, forecast, grap_outlook, school_safe_window (AI-ML writes)
│   │   │   ├── asset.py              # asset, asset_shift
│   │   │   ├── plan.py               # plan, plan_task, plan_review, plan_simulation
│   │   │   ├── intervention.py       # intervention, impact (AI-ML), effectiveness_library (AI-ML)
│   │   │   ├── alert.py              # alert, alert_delivery
│   │   │   ├── report.py             # citizen_report, inspection
│   │   │   ├── site.py               # site, site_score (AI-ML)
│   │   │   ├── integrity.py          # integrity_flag, coverage_gap (AI-ML)
│   │   │   ├── evidence.py           # evidence_report
│   │   │   ├── auth.py               # app_user, refresh_token, push_token, user_ward_scope
│   │   │   ├── audit.py              # audit_log
│   │   │   ├── outbox.py             # outbox_event, processed_event
│   │   │   └── model_version.py      # model_version (AI-ML)
│   │   └── repositories/             # one per aggregate; ward-scoped queries take a Scope; no business rules
│   │       ├── base.py               # generic get/list with keyset pagination, get_for_update
│   │       ├── devices.py            # registry lookups (cached by callers), last_seen, status/trust updates
│   │       ├── readings.py           # bulk insert ON CONFLICT DO NOTHING RETURNING, latest per device, history queries
│   │       ├── calibration.py        # current calibration per device, calibration_pair upserts
│   │       ├── grid.py               # cells, wards, grid_meta
│   │       ├── twin.py               # latest run, cell states by bbox, tile rendering (ST_AsMVT)
│   │       ├── hotspots.py           # ranked hotspots by ward/run
│   │       ├── forecasts.py          # series per cell, grid layer, GRAP outlook, safe windows
│   │       ├── plans.py              # plan + tasks + review + simulations; version checks
│   │       ├── tasks.py              # tasks by asset/shift, transitions, overdue queries for the sweep
│   │       ├── interventions.py      # open/close segments, matching candidates, verify scan claim
│   │       ├── impacts.py            # impact per intervention, summaries, effectiveness library reads
│   │       ├── assets.py             # assets, shifts, availability, current driver for an asset
│   │       ├── alerts.py             # alert + alert_delivery claim/update, per-recipient listing
│   │       ├── reports.py            # citizen_report, inspection
│   │       ├── schools.py, sites.py  # school profiles, site + scores
│   │       ├── reference.py          # stations, observations upserts
│   │       ├── weather.py            # weather + fire upserts
│   │       ├── users.py              # users, refresh tokens (rotation, reuse detection), push tokens, ward scopes
│   │       ├── evidence.py           # evidence_report rows
│   │       ├── integrity.py          # flags, coverage gaps (read)
│   │       ├── audit.py              # audit_log insert, history queries
│   │       ├── outbox.py             # outbox rows (writer side), relay batch claim, purge
│   │       └── processed_events.py   # claim(group, event_id), purge
│   │
│   ├── cache/
│   │   ├── client.py                 # redis.asyncio client factory, *_safe helpers with breaker + fallback
│   │   ├── keys.py                   # thin wrapper over hawa_contracts.redis_keys with the process env
│   │   ├── cached.py                 # cache-aside get_or_fill with versioned keys, single-flight, early refresh
│   │   ├── pointers.py               # twin:version, twin:run_id, forecast:issued_at read/write + DB fallback
│   │   ├── rate_limit.py             # sliding-window Lua limiter + in-process fallback; FastAPI dependency factory
│   │   ├── locks.py                  # token locks: acquire, release (compare-and-delete), renew
│   │   ├── idempotency.py            # Idempotency-Key store (idem:*) and FastAPI dependency
│   │   ├── otp.py                    # OTP hash store and attempt counting
│   │   ├── denylist.py               # jwt:deny:*
│   │   ├── live.py                   # live:fleet GEO + live:device hashes, prune, GEOSEARCH
│   │   ├── pubsub.py                 # ws:* publish + PSUBSCRIBE reader; inv:device invalidation channel
│   │   └── lua/                      # sliding_window.lua, release.lua, renew.lua
│   │
│   ├── events/
│   │   ├── producer.py               # AIOKafkaProducer wrapper (acks=all, idempotence, lz4), publish/publish_many, header injection
│   │   ├── consumer.py               # KafkaConsumerBase: manual commits, retries + backoff, DLQ, idempotency modes, rebalance listener
│   │   ├── outbox.py                 # Outbox writer used through the UoW (envelope build, traceparent capture)
│   │   ├── relay.py                  # relay_once / relay_forever (FOR UPDATE SKIP LOCKED, publish, mark sent, optional shard)
│   │   ├── admin.py                  # topic bootstrap/check from hawa_contracts.topics (hawa kafka-init)
│   │   ├── serde.py                  # orjson encode/decode, REGISTRY routing, PoisonMessage/UnknownType
│   │   ├── dlq.py                    # dead-letter publish with headers; list/replay helpers for the CLI
│   │   ├── msk_auth.py               # MSK IAM token provider (aws-msk-iam-sasl-signer-python), kafka_security()
│   │   └── tracing.py                # consumer/producer span helpers, traceparent inject/extract
│   │
│   ├── api/
│   │   ├── main.py                   # create_app(): lifespan (logging, tracing, container, consumers, pubsub reader), middleware order,
│   │   │                             #   routers, exception handlers, OpenAPI metadata
│   │   ├── deps.py                   # container, current_principal, require_roles(...), scope, if_match_or_body_version, pagination, rate_limit, idempotency, services
│   │   ├── middleware/
│   │   │   ├── request_context.py    # request/correlation ids, one logifyx line per request, http metrics (pure ASGI)
│   │   │   ├── body_limit.py         # 1 MB JSON cap
│   │   │   ├── security_headers.py   # HSTS, nosniff, referrer policy, no-store on auth
│   │   │   └── draining.py           # 503 on /readyz and new requests during shutdown
│   │   ├── routers/                  # one per area in CONTRACTS §6
│   │   │   ├── auth.py               # /v1/auth/*, /v1/me, /v1/me/push-token
│   │   │   ├── twin.py               # /v1/twin, /v1/twin/tiles/{z}/{x}/{y}.mvt, /v1/cells/*
│   │   │   ├── hotspots.py           # /v1/hotspots*
│   │   │   ├── forecast.py           # /v1/forecast/*, /v1/grap/*
│   │   │   ├── plans.py              # /v1/plans* (draft, list, detail, patch, simulate, approve, reject)
│   │   │   ├── tasks.py              # /v1/tasks/* (mine, detail, ack, status, evidence)
│   │   │   ├── fleet.py              # /v1/assets*, /v1/fleet/live
│   │   │   ├── devices.py            # /v1/devices*, calibration history
│   │   │   ├── interventions.py      # /v1/interventions*, /v1/impact/summary, /v1/effectiveness
│   │   │   ├── alerts.py             # /v1/alerts*
│   │   │   ├── schools.py            # /v1/schools/*
│   │   │   ├── reports.py            # /v1/reports*, WhatsApp webhook GET/POST
│   │   │   ├── inspections.py        # /v1/inspections* (+ assign, PCA-17)
│   │   │   ├── sites.py              # /v1/sites*
│   │   │   ├── integrity.py          # /v1/integrity/flags, /v1/coverage/blind-spots
│   │   │   ├── evidence_reports.py   # /v1/evidence-reports*
│   │   │   ├── uploads.py            # /v1/uploads/presign
│   │   │   ├── open_data.py          # /open/v1/*
│   │   │   └── ops.py                # /healthz, /readyz, /metrics
│   │   ├── schemas/                  # request/response models per area (common.py: Page[T], Problem, GeoJSON types; one module per router)
│   │   ├── consumers/                # Kafka consumers hosted in the api process
│   │   │   ├── live.py               # group api-live -> Redis ws:* (sensitive-field stripping, 1 Hz fleet batching, recipient resolution)
│   │   │   ├── cache.py              # group api-cache -> pre-warm tiles, pointers, invalidation
│   │   │   └── alert_status.py       # group api-alert-status -> alert.status roll-up
│   │   └── ws/
│   │       ├── gateway.py            # /v1/ws endpoint: auth, subscribe/unsubscribe/ping ops, close codes
│   │       ├── hub.py                # per-replica connection registry, bounded queues, coalescing
│   │       ├── channels.py           # channel names, parsing, ACL (role + ward scope)
│   │       └── messages.py           # frame models, sensitive-field filters per channel
│   │
│   ├── services/                     # domain use cases; framework-free; used by routers, workers and CLI
│   │   ├── auth_service.py           # login, OTP request/verify, refresh rotation, logout, push token
│   │   ├── twin_service.py           # twin GeoJSON, tiles, cell detail/history (versioned cache)
│   │   ├── hotspot_service.py        # ranked hotspots, detail with evidence
│   │   ├── forecast_service.py       # series, grid layer
│   │   ├── grap_service.py           # outlook + checklist from config/grap_actions.yaml
│   │   ├── plan_service.py           # draft request, edit (+ optimize), simulate (What-If), approve/reject gate, constraints
│   │   ├── constraints.py            # cause -> asset type (CONTRACTS §3), shift windows, capacity; shared by approve and edit
│   │   ├── task_service.py           # app task views and transitions (ack, en_route, manual done/skip, evidence)
│   │   ├── dispatch_service.py       # saga steps used by the dispatch worker: release, assign, match, timeouts, verify scheduling
│   │   ├── fleet_service.py          # assets, live fleet
│   │   ├── device_service.py         # registry, provisioning, calibration history, health/trust application
│   │   ├── intervention_service.py   # interventions, impact read models, summaries, effectiveness
│   │   ├── alert_service.py          # alert creation (+ outbox), recipient resolution, templates, allowlist policy
│   │   ├── school_service.py         # school profile, safe window, indoor/outdoor series
│   │   ├── report_service.py         # Citizen Eyes intake (app + WhatsApp), EXIF strip, ticketing, closing
│   │   ├── inspection_service.py     # inspection assign/close
│   │   ├── site_service.py           # sites and grades
│   │   ├── evidence_service.py       # weekly report assembly, narrative call, render orchestration
│   │   ├── upload_service.py         # presigned POST policy, post-upload verification
│   │   ├── open_data_service.py      # public air/stations/history/methods with simulated-data policy (PCA-27)
│   │   ├── feeds_service.py          # normalise + upsert external observations (+ outbox)
│   │   └── audit_service.py          # AuditRecorded builders
│   │
│   ├── workers/
│   │   ├── runner.py                 # common worker main: setup logging/tracing, container, ops server, TaskGroup, graceful shutdown
│   │   ├── ingest/
│   │   │   ├── main.py               # group ingest (+ ingest-calibration) wiring
│   │   │   ├── decode.py             # envelope vs bare-packet raw decoding (PCA-02)
│   │   │   ├── validate.py           # CONTRACTS §4.1 rules -> reason codes
│   │   │   ├── registry_cache.py     # in-process device registry + inv:device invalidation
│   │   │   ├── calibrate.py          # apply device.cal_* from the registry cache (a·raw + b·rh + c), calibration_version, weight
│   │   │   ├── pipeline.py           # batch: MGET dedupe -> calibrate -> cell -> insert + commit -> live -> publish -> SET dedupe (DATA_MODEL §14.2)
│   │   │   ├── spray.py              # segment assembly, detection rule double-check, track building
│   │   │   ├── spikes.py             # cloud confirmation, late-spike handling
│   │   │   └── pairing.py            # group ingest-calibration: calibration_pair rows
│   │   ├── feeds/
│   │   │   ├── main.py               # internal APScheduler with lock:sched:{job}
│   │   │   └── jobs.py               # cpcb, openaq, openmeteo, firms jobs + backfill
│   │   ├── scheduler/
│   │   │   ├── main.py               # AsyncIOScheduler (Asia/Kolkata), job registration from config/schedules.yaml
│   │   │   ├── jobs.py               # command builders per job (EVENTS §8)
│   │   │   └── verify_scan.py        # claim due interventions + outbox cmd.verify.run in one transaction
│   │   ├── dispatch/
│   │   │   ├── main.py               # group dispatch wiring
│   │   │   ├── handlers.py           # plan.approved/rejected, release, sweep, spray.*, app task updates, impact.verified, report.verified
│   │   │   ├── transitions.py        # allowed TaskStatus/PlanStatus transitions (the approval gate lives here)
│   │   │   ├── matching.py           # spray segment <-> task matching (asset, cell buffer, time window)
│   │   │   ├── sweep.py              # expiry, release, ack escalation, missed, open segments, verification exhaustion, late matching
│   │   │   └── inspections.py        # Citizen Eyes ticketing + nearest team proposal (GEOSEARCH)
│   │   ├── notifier/
│   │   │   ├── main.py               # group notifier wiring
│   │   │   ├── router.py             # channel fallback chain, delivery mode (PCA-20), claim row per (alert_id, channel, attempt) (DATA_MODEL §10.2)
│   │   │   ├── render.py             # Jinja2 templates en/hi per kind x channel; WhatsApp template parameter mapping
│   │   │   ├── policy.py             # allowlist (non-prod), dry-run, per-recipient throttle, escalation cancellation
│   │   │   └── providers.py          # adapters over integrations.sns / whatsapp / fcm / log
│   │   ├── outbox_relay/main.py      # relay_forever with shard config
│   │   ├── mqtt_bridge/
│   │   │   ├── main.py               # aiomqtt client (Mosquitto or IoT Core TLS), shared subscription hawa/v1/+/+
│   │   │   └── bridge.py             # wrap to envelope, produce to hawa.telemetry.raw.v1, ack after produce
│   │   ├── audit_writer/main.py      # groups audit-writer + audit -> audit_log
│   │   ├── alert_engine/
│   │   │   ├── main.py               # groups alert-engine + device-health wiring
│   │   │   ├── school_alerts.py      # Flow C runs (draft/final/morning), slot validation, idempotent per (school, date, phase)
│   │   │   ├── hotspot_alerts.py     # pollutant-specific citizen warnings (F16), officer notifications
│   │   │   ├── grap_alerts.py        # GRAP outlook alerts to officers
│   │   │   └── device_health.py      # tamper/health -> device status + alerts; trust_changed -> trust_score
│   │   ├── evidence_report/
│   │   │   ├── main.py               # group evidence-report wiring
│   │   │   ├── builder.py            # data aggregation for the week (hotspots, causes, actions, impact per rupee)
│   │   │   ├── render.py             # WeasyPrint HTML -> PDF in a process pool
│   │   │   └── templates/            # report.html.j2, styles.css, fonts (Noto incl. Devanagari)
│   │   └── archiver/
│   │       ├── main.py               # groups archiver (+ archiver-raw optional) wiring
│   │       ├── parquet_writer.py     # batch clean readings to S3 Parquet (pyarrow), offset-keyed file names
│   │       ├── partitions.py         # cmd.partitions.maintain -> `hawa partitions` with the owner login (DATA_MODEL §14.3)
│   │       └── snapshot.py           # cmd.snapshot.freeze (16:00 data freeze)
│   │
│   ├── integrations/
│   │   ├── base.py                   # Protocols: SmsSender, WhatsAppClient, PushSender, ObjectStore, IntelClient, FeedClient; ProviderResult
│   │   ├── sns.py                    # Amazon SNS SMS (DLT entity/template attributes), via asyncio.to_thread
│   │   ├── whatsapp.py               # WhatsApp Cloud API over httpx: templates, media download, status parsing, signature verify
│   │   ├── fcm.py                    # firebase-admin messaging (thread pool), token invalidation handling
│   │   ├── s3.py                     # boto3 S3: presigned POST/GET, put/get/head/delete (MinIO endpoint locally)
│   │   ├── cpcb.py                   # CPCB/DPCC real-time AQ (data.gov.in API), normalisation to reference.observed
│   │   ├── openaq.py                 # OpenAQ v3 (X-API-Key), locations + latest measurements for the NCR bbox
│   │   ├── openmeteo.py              # Open-Meteo current + 72 h hourly forecast on the NCR grid (IMD/ERA5 proxy)
│   │   ├── firms.py                  # NASA FIRMS area CSV (VIIRS/MODIS NRT) for NCR + upwind region
│   │   ├── intel_client.py           # httpx client to AI-ML intel-service: timeouts, breaker, bulkhead, header propagation
│   │   ├── log_providers.py          # "log" implementations of SMS/WhatsApp/push (masked line, no send)
│   │   └── fakes.py                  # in-memory fakes for tests (record calls, scripted failures)
│   │
│   ├── seeding/                      # loaders used by `hawa seed <target>` and `hawa demo-reset` (DATA_MODEL §18; data in backend/seed/)
│   │   ├── wards.py, grid.py, pois.py, schools.py, stations.py, assets.py, devices.py, sites.py, users.py, shifts.py, history.py
│   │   └── demo.py                   # golden-path reset orchestration (DEPLOYMENT §5.2)
│   │
│   └── config/
│       ├── grap_actions.yaml         # GRAP stage checklists per agency (en/hi), CONTRACTS §10.2
│       ├── schedules.yaml            # scheduler jobs, cron (IST), locks, enabled flags (EVENTS §8)
│       ├── reading_weights.yaml      # ingest weight coefficients (speed, flags, hdop)
│       ├── dispatch.yaml             # saga timeouts and matching buffers (overridable by env)
│       └── alert_templates/
│           ├── en/                   # {kind}.{channel}.j2 for route_assignment, inspection_target, safe_window, pollutant_warning,
│           │                         #   grap_outlook, report_outcome, device_health
│           ├── hi/                   # same set in Hindi
│           └── whatsapp_templates.yaml  # mapping kind -> registered WhatsApp template name + parameter order
│
├── simulator/                        # workspace member `hawa-simulator` (import hawa_simulator), console script `hawa-sim`
│   ├── pyproject.toml                # deps: hawa-contracts, aiomqtt, numpy, shapely, pyproj, httpx, typer, pyyaml
│   ├── hawa_simulator/
│   │   ├── cli.py                    # run, backfill, provision, scenarios, verify-effects
│   │   ├── config.py                 # SimSettings (HAWA_SIM_*)
│   │   ├── clock.py                  # real-time and backfill clocks (packet ts never > now + 2 min)
│   │   ├── routes/
│   │   │   ├── gtfs.py               # GTFS shapes/trips/stop_times -> bus polylines + headways
│   │   │   ├── osm.py                # e-rickshaw/bike walks on a pre-extracted OSM road GeoJSON
│   │   │   └── vehicles.py           # kinematics: speed profiles, stops, dwell, ignition off
│   │   ├── field/
│   │   │   ├── background.py         # background from live/recorded reference observations + diurnal cycle
│   │   │   ├── sources.py            # road dust, construction sites, burning events, traffic corridors, regional smoke
│   │   │   ├── plume.py              # plume-lite dispersion + wind advection
│   │   │   └── field.py              # PollutionField.sample(lat, lon, t) -> true concentrations + met
│   │   ├── sensors/
│   │   │   ├── pms5003.py            # optical PM: noise, humidity over-read, drift, fan stall, flatline
│   │   │   ├── mics6814.py           # gas: 30 min warm-up, cross-sensitivity, heat drift
│   │   │   ├── bme680.py             # t/rh/p/VOC resistance
│   │   │   └── gps.py                # jitter, hdop, no-fix zones
│   │   ├── devices/
│   │   │   ├── base.py               # persistent seq per device, 30 s batching, flags, battery
│   │   │   ├── pod_m.py              # HawaPod-M + TinyML spike emulation
│   │   │   ├── pod_s.py              # HawaPod-S outdoor/indoor pair with infiltration and CO2
│   │   │   └── tag.py                # HawaTag flow/pump behaviour, spray_start/stop, litres
│   │   ├── drivers.py                # simulated drivers using the real API (login, tasks:me, ack, drive, spray)
│   │   ├── effects.py                # injected known effects + ground truth writer
│   │   ├── store_forward.py          # connectivity gaps and ordered replay (sd_replay, original seq/ts)
│   │   ├── publisher.py              # aiomqtt publisher (Mosquitto or IoT Core X.509), QoS 1
│   │   └── scenarios/                # golden.yaml, effects.yaml, stress.yaml
│   └── tests/                        # packet validity vs hawa_contracts, seeded determinism, effect math
│
├── seed/                             # inputs for `hawa seed` (layout per DATA_MODEL §18.1); the grid is read from AI-ML/data/grid/<grid_id>/
│   ├── wards.geojson                 # MCD ward boundaries
│   ├── pois.geojson                  # OSM schools, hospitals, elder care, markets, bus stops
│   ├── schools.csv                   # pilot schools (UDISE), principals, HawaPod-S pairs
│   ├── sites.geojson                 # SITE-0301 … SITE-0325
│   ├── demo_fleet.yaml               # AST-* machines and teams (is_simulated)
│   ├── demo_devices.yaml             # HPM/HPS/HTG registry incl. the one real pod HPM-0900 (is_simulated=false)
│   ├── demo_users.yaml               # demo users per role (passwords from env)
│   ├── routes/dtc_routes.geojson     # GTFS-derived bus routes for the simulator
│   ├── golden/                       # golden-path history (*.parquet) + state.yaml for demo-reset
│   ├── fixtures/demo/                # recorded CPCB/OpenAQ/FIRMS/weather for HAWA_FEEDS_MODE=fixture (labelled source=fixture)
│   └── fixtures/test/                # 10 x 10 mini grid + minimal registry for integration tests
│
├── infra/                            # AWS CDK (Python), separate uv project (own pyproject + uv.lock), not a workspace member
│   ├── pyproject.toml, uv.lock, cdk.json
│   ├── app.py                        # instantiates stacks per env from config/{env}.yaml
│   ├── config/                       # demo.yaml, pilot.yaml (sizes, counts, domains, feature flags)
│   ├── hawa_infra/
│   │   ├── stacks/                   # network, data, streaming, iot, compute, ai, messaging, observability, web (DEPLOYMENT §6.2)
│   │   └── constructs/               # hawa_service.py (Fargate svc + ADOT sidecar + alarms), one_off_task.py, iot_rule_kafka.py
│   └── tests/                        # synth assertions + cdk-nag
│
├── docker/
│   ├── Dockerfile                    # multi-stage (uv builder -> python:3.12-slim), WeasyPrint libs, Noto fonts, non-root uid 10001
│   ├── entrypoint.sh                 # api | worker <name> | migrate | kafka-init | seed | sim | demo-reset
│   └── local/
│       ├── mosquitto/                # mosquitto.conf, acl, passwd (generated by `hawa devices mqtt-passwd`)
│       ├── postgres/init.sql         # database mlflow + login users per DATA_MODEL §1.2/§20.5 (hawa_migrator, hawa_api, hawa_ingest, …, hawa_ml);
│       │                             #   group roles hawa_owner/app_rw/ml_rw/readonly come from migration 0001
│       ├── prometheus/               # prometheus.yml, rules/*.yml (EVENTS §12, LOGGING_AND_OBSERVABILITY §14)
│       ├── grafana/                  # provisioning/{datasources,dashboards}, dashboards/golden_path.json and others
│       └── minio/init.sh             # buckets hawa-local-{lake,media,reports,models} + lifecycle rules
│
└── tests/
    ├── conftest.py                   # HAWA_ENV=test settings, FrozenClock, markers, logifyx_records fixture
    ├── factories.py                  # polyfactory builders for packets, envelopes, ORM rows
    ├── fakes/                        # InMemoryProducer, FakeIntel, fake providers (re-export integrations.fakes)
    ├── unit/                         # pure logic: validation, calibration, cells, transitions (approval gate), matching, sweep,
    │                                 #   rate-limit math, idempotency, problem+json, templates, PII masking
    ├── integration/                  # testcontainers PostGIS 16-3.4, Redis 7, Kafka (KRaft): migrations, ingest pipeline, consumer base,
    │                                 #   outbox relay, dispatch saga, tiles, rate limiting Lua, WebSocket fan-out
    ├── contract/                     # OpenAPI snapshot, event JSON Schema snapshots, CONTRACTS.md parity
    ├── db/                           # test_grants.py (ownership matrix), partitions, plan guard triggers (DATA_MODEL §16.8, §17.7)
    └── e2e/                          # golden path against the running compose stack (sim -> reading -> twin -> plan -> approve -> notify -> spray -> impact)
```

## 3. Dependency and layering rules

- **Layering** ([ARCHITECTURE.md](ARCHITECTURE.md) §3.1): routers and workers call services; services use the UoW, cache and integration Protocols; repositories touch SQLAlchemy; `core` depends on nothing internal.
- **Enforced** with import-linter (`lint-imports`, run in pre-commit and CI):

```toml
[tool.importlinter]
root_packages = ["hawa_backend"]
include_external_packages = true

[[tool.importlinter.contracts]]
name = "API never touches persistence, brokers or providers directly"
type = "forbidden"
source_modules = ["hawa_backend.api.routers", "hawa_backend.api.ws", "hawa_backend.api.schemas"]
forbidden_modules = ["hawa_backend.db.models", "hawa_backend.db.repositories", "hawa_backend.integrations", "sqlalchemy", "aiokafka"]
allow_indirect_imports = true

[[tool.importlinter.contracts]]
name = "Services are framework-free"
type = "forbidden"
source_modules = ["hawa_backend.services"]
forbidden_modules = ["fastapi", "starlette", "aiokafka", "hawa_backend.api", "hawa_backend.workers"]

[[tool.importlinter.contracts]]
name = "Workers do not import the API"
type = "forbidden"
source_modules = ["hawa_backend.workers"]
forbidden_modules = ["hawa_backend.api"]

[[tool.importlinter.contracts]]
name = "Core is the bottom layer"
type = "forbidden"
source_modules = ["hawa_backend.core"]
forbidden_modules = ["hawa_backend.api", "hawa_backend.services", "hawa_backend.workers", "hawa_backend.db",
                     "hawa_backend.events", "hawa_backend.cache", "hawa_backend.integrations"]
```

- `hawa_contracts` depends only on pydantic, uuid6 and orjson. It must stay installable by AI-ML without pulling FastAPI or SQLAlchemy.

## 4. Tooling

### 4.1 uv workspace

```toml
# backend/pyproject.toml (excerpt): versions resolved and pinned in uv.lock
[project]
name = "hawa-backend"
requires-python = ">=3.12,<3.13"
dependencies = [
  "hawa-contracts",
  "fastapi", "uvicorn[standard]", "pydantic>=2", "pydantic-settings", "python-multipart",
  "sqlalchemy[asyncio]>=2", "asyncpg", "geoalchemy2", "alembic", "shapely", "pyproj",
  "redis>=5", "aiokafka[lz4]", "aws-msk-iam-sasl-signer-python", "aiomqtt", "apscheduler>=3.10,<4",
  "httpx", "tenacity", "orjson", "uuid6", "argon2-cffi", "pyjwt[crypto]",
  "boto3", "firebase-admin", "weasyprint", "jinja2", "pillow", "pyarrow", "pyyaml", "typer",
  "opentelemetry-sdk", "opentelemetry-exporter-otlp", "opentelemetry-instrumentation-fastapi",
  "opentelemetry-instrumentation-sqlalchemy", "opentelemetry-instrumentation-redis",
  "opentelemetry-instrumentation-httpx", "opentelemetry-sdk-extension-aws",
  "prometheus-client", "logifyx[kafka]",
]

[project.scripts]
hawa = "hawa_backend.cli:app"

[dependency-groups]
dev = [
  "pytest", "pytest-asyncio", "pytest-cov", "pytest-xdist", "testcontainers[postgres,redis,kafka]",
  "polyfactory", "respx", "time-machine", "fakeredis[lua]",
  "ruff", "mypy", "import-linter", "pre-commit", "pip-audit",
  "types-pyyaml", "boto3-stubs[s3,sns]", "asyncpg-stubs",
]

[tool.uv.workspace]
members = ["contracts", "simulator"]

[tool.uv.sources]
hawa-contracts = { workspace = true }
hawa-simulator = { workspace = true }

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/hawa_backend"]
```

AI-ML consumes the contracts with `hawa-contracts = { path = "../backend/contracts", editable = true }` in its own `pyproject.toml`.

Common commands: `uv sync` (all groups), `uv sync --no-dev` (images), `uv add <pkg>`, `uv lock --upgrade-package <pkg>`, `uv run <cmd>`.

### 4.2 ruff (lint + format)

```toml
[tool.ruff]
target-version = "py312"
line-length = 110
src = ["src", "contracts", "simulator", "tests"]

[tool.ruff.format]
quote-style = "double"
docstring-code-format = true

[tool.ruff.lint]
select = [
  "E", "W",     # pycodestyle
  "F",          # pyflakes
  "I",          # isort
  "N",          # pep8-naming
  "UP",         # pyupgrade (3.12 syntax)
  "B",          # bugbear
  "A",          # builtins shadowing
  "C4",         # comprehensions
  "DTZ",        # timezone-aware datetimes only (UTC rule)
  "T10", "T20", # no debugger, no print
  "S",          # bandit security
  "ASYNC",      # blocking calls in async code
  "BLE",        # blind except
  "G", "LOG",   # logging format rules (no f-strings in log calls)
  "PT",         # pytest style
  "RET", "SIM", "PIE", "RSE", "FLY", "FURB", "PERF",
  "TID",        # tidy imports + banned APIs
  "TC",         # type-checking-only imports (formerly TCH)
  "ARG",        # unused arguments
  "PTH",        # pathlib
  "ERA",        # commented-out code
  "PL",         # pylint subset
  "TRY",        # exception anti-patterns
  "FAST",       # FastAPI-specific rules
  "RUF",        # ruff-specific
]
ignore = ["PLR0913", "TRY003", "PLR2004"]    # FastAPI deps have many params; messages on exceptions are fine; constants in tests

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101", "ARG", "PLR2004", "S105", "S106"]
"alembic/versions/**" = ["E501", "ERA001"]
"src/hawa_backend/core/logging.py" = ["TID251"]      # the one place allowed to touch stdlib logging.getLogger

[tool.ruff.lint.flake8-tidy-imports.banned-api]
"logging.getLogger".msg = "Use hawa_backend.core.logging.get_logger (logifyx)."
"logging.basicConfig".msg = "Logging is configured once by core.logging.setup_logging()."
"datetime.datetime.utcnow".msg = "Use core.clock (timezone-aware UTC)."
"time.sleep".msg = "Use await asyncio.sleep()."
"requests".msg = "Use httpx.AsyncClient."
"kafka".msg = "Use aiokafka."
"confluent_kafka".msg = "Use aiokafka."
"pickle".msg = "Never pickle; use orjson."
```

### 4.3 mypy (strict)

```toml
[tool.mypy]
python_version = "3.12"
strict = true
plugins = ["pydantic.mypy"]
mypy_path = ["src", "contracts", "simulator"]
warn_unreachable = true
enable_error_code = ["ignore-without-code", "redundant-expr", "truthy-bool", "possibly-undefined"]

[tool.pydantic-mypy]
init_forbid_extra = true
init_typed = true
warn_required_dynamic_aliases = true

[[tool.mypy.overrides]]
# only libraries that ship without type information; keep this list short
module = ["weasyprint.*", "firebase_admin.*", "geoalchemy2.*", "shapely.*", "pyproj.*", "apscheduler.*",
          "aws_msk_iam_sasl_signer.*", "logifyx.*", "testcontainers.*"]
ignore_missing_imports = true
```

SQLAlchemy 2.0 typed models (`Mapped[...]`) need no plugin. `# type: ignore` must carry an error code.

### 4.4 pytest

```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "session"
testpaths = ["tests", "contracts/tests", "simulator/tests"]
addopts = "-ra --strict-markers --strict-config -m 'not e2e'"
markers = [
  "integration: needs Docker (testcontainers PostGIS/Redis/Kafka)",
  "e2e: needs the running docker compose stack",
  "slow: > 5 s",
]
filterwarnings = ["error::RuntimeWarning"]   # a never-awaited coroutine fails the test
```

- **Unit** (default run, no Docker, < 30 s): fakes plus `fakeredis[lua]` for Lua scripts.
- **Integration** (`-m integration`): session-scoped containers `postgis/postgis:16-3.4`, `redis:7`, and Kafka in KRaft mode (testcontainers `KafkaContainer` with KRaft, or a generic `apache/kafka` container). Fixtures run `alembic upgrade head` and `hawa kafka-init`. Each test uses a unique topic prefix or truncates tables.
- **Contract**: `openapi.json` snapshot (breaking-change diff), event JSON Schema snapshots, parity between `hawa_contracts` and the tables in `../CONTRACTS.md`, and DB grants against [CONTRACTS §8](../CONTRACTS.md#8-database-table-ownership).
- **E2E** (`-m e2e`): the golden path against `make up`, with a timeout per step.
- Coverage target: ≥ 80 % on `services/`, `workers/dispatch/`, `workers/ingest/`, `events/`, and 100 % on `workers/dispatch/transitions.py` (the approval gate).

### 4.5 pre-commit

```yaml
# backend/.pre-commit-config.yaml (hook revisions pinned by `pre-commit autoupdate`)
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks: [trailing-whitespace, end-of-file-fixer, check-yaml, check-toml, check-json,
            check-merge-conflict, detect-private-key, {id: check-added-large-files, args: ["--maxkb=500"]},
            {id: no-commit-to-branch, args: ["--branch", "main"]}]
  - repo: https://github.com/astral-sh/ruff-pre-commit
    hooks: [{id: ruff, args: ["--fix"]}, {id: ruff-format}]
  - repo: https://github.com/gitleaks/gitleaks
    hooks: [gitleaks]
  - repo: https://github.com/compilerla/conventional-pre-commit
    hooks: [{id: conventional-pre-commit, stages: [commit-msg]}]
  - repo: local
    hooks:
      - {id: mypy, name: mypy, entry: uv run mypy src contracts simulator, language: system, pass_filenames: false, types: [python]}
      - {id: import-linter, name: lint-imports, entry: uv run lint-imports, language: system, pass_filenames: false, types: [python]}
      - {id: uv-lock, name: uv lock --check, entry: uv lock --check, language: system, pass_filenames: false, files: pyproject\.toml$}
      - {id: contracts-schemas, name: contract schemas up to date, entry: uv run hawa contracts export --check, language: system, pass_filenames: false, files: ^contracts/}
```

### 4.6 `hawa` CLI (typer)

| Command | Purpose |
|---|---|
| `hawa api [--host] [--port] [--reload]` | run Uvicorn (uvloop, httptools, `access_log=False`, `--proxy-headers`) |
| `hawa worker <name>` | `ingest`, `feeds`, `scheduler`, `dispatch`, `notifier`, `outbox-relay`, `mqtt-bridge`, `audit-writer`, `alert-engine`, `evidence-report`, `archiver` |
| `hawa seed [all\|<target>] [--env local\|demo] [--dry-run]` | idempotent upserts per target (DATA_MODEL §18.1); no target means `all` |
| `hawa demo-reset [--yes] [--backfill-hours N] [--recreate-topics]` | golden-path reset (DATA_MODEL §18.3, [DEPLOYMENT.md](DEPLOYMENT.md) §5.2); refuses outside `local`/`demo` |
| `hawa demo-check` | prints golden-path readiness (twin fresh, hotspots, forecast, allowlisted phone, WS reachable) |
| `hawa kafka-init [--profile] [--dry-run] [--check] [--grow-partitions]` | topic bootstrap ([EVENTS.md](EVENTS.md) §4.2) |
| `hawa partitions [--table reading\|cell_state\|forecast\|audit_log\|all] [--ahead-days 7] [--dry-run]` | create, archive, drop partitions + row retention (DATA_MODEL §14.3, §19.1) |
| `hawa scheduler trigger <job> [--force]` | fire a scheduled job now |
| `hawa dlq list\|show\|replay [--group] [--topic] [--reason] [--since]` | DLQ tooling ([EVENTS.md](EVENTS.md) §11) |
| `hawa events tail <topic> [--type] [--pretty]` | debugging consumer (group `ops`, never commits) |
| `hawa feeds backfill --source --from --to` | external feed backfill |
| `hawa archive rebuild --date` | rebuild a day of Parquet from Postgres |
| `hawa users create --role --email\|--phone [--wards]` | create users (admin bootstrap) |
| `hawa devices provision --count --role [--simulated] [--aws]` / `hawa devices mqtt-passwd` | registry + Mosquitto credentials, or IoT Core things + certs |
| `hawa contracts export [--check]` | write/check JSON Schemas and the OpenAPI snapshot |
| `hawa-sim run\|backfill\|provision\|verify-effects` | simulator (separate console script) |

### 4.7 Makefile targets (repo root)

| Target | Does |
|---|---|
| `make up` | `docker compose --profile all up -d --build` (infra + backend + AI-ML + web + obs) |
| `make infra` | `docker compose up -d` (default profile: infra only, for host development) |
| `make down` | `docker compose --profile all down` |
| `make clean` | `down -v` (drops volumes) |
| `make logs [s=api]` | `docker compose logs -f --tail=200 $(s)` |
| `make ps` | service status |
| `make migrate` | `alembic upgrade head` in the `migrate` one-off container (or `uv run` with `HOST=1`) |
| `make kafka-init` | topic bootstrap |
| `make seed` | `hawa seed` |
| `make sim` | start the simulator profile (`--scenario golden`) |
| `make demo-reset` | stop sim + scheduler → `hawa demo-reset --yes` → start them again |
| `make fmt` | `ruff format` + `ruff check --fix` |
| `make lint` | `ruff check`, `ruff format --check`, `mypy`, `lint-imports`, `uv lock --check` |
| `make test` | unit + contract; `make test-int` integration; `make e2e` golden path |
| `make openapi` | export `openapi.json` and regenerate the web and Flutter clients (calls the frontend/app generators) |

The Makefile source is in [DEPLOYMENT.md](DEPLOYMENT.md) §3.
