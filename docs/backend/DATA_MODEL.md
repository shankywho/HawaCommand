# HawaCommand Backend — Data Model

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Backend docs:** [Runbook](../../backend/README.md) · [Index](README.md) · [Context](CONTEXT.md) · [Architecture](ARCHITECTURE.md) · [API](API.md) · **Data model** · [Events](EVENTS.md) · [Caching](CACHING.md) · [Logging](LOGGING_AND_OBSERVABILITY.md) · [Deployment](DEPLOYMENT.md) · [Structure](STRUCTURE.md) · [Plan](PLAN.md)

<!-- nav:end -->

The SQLAlchemy 2.0 models in `src/hawa_backend/db/`, table by table and column by column, what the database layer does and does not do today, and the planned schema that the blueprint described.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [API](API.md) · [EVENTS](EVENTS.md) · [DEPLOYMENT](DEPLOYMENT.md) · [../CONTRACTS.md](../CONTRACTS.md) §8

> Status: **Partial**. 23 tables are declared and round-trip on SQLite in tests. Alembic revision `0001` (`backend/migrations/`) creates every table, and `python -m hawa_backend.db.seed` loads demo data; there are no PostGIS columns, and no API code path opens a database session: every API response comes from AI-ML, fixtures or memory.

---

## 1. What exists

| Item | Status | Detail |
|---|---|---|
| ORM models | **Implemented** | 23 tables in `db/models/*.py`, exported from `db/models/__init__.py` |
| Declarative base and mixins | **Implemented** | `db/base.py` |
| Async engine and session factory | **Implemented** | `db/session.py`; never called outside its own module |
| FastAPI dependency `get_db()` | **Implemented**, unused | No route declares it |
| Target database | Configured only | `HAWA_DATABASE_URL`, default `postgresql+asyncpg://hawa:hawa@localhost:5432/hawa`, matching the `postgis/postgis:16-3.4` container in `docker-compose.yml` |
| Schema | — | Tables are created in the default schema (no `schema=` argument, so `public` on Postgres) |
| Alembic migrations | **Implemented** | `backend/alembic.ini`, `backend/migrations/env.py` (async, URL from `HAWA_DATABASE_URL` or `-x db_url=`), revision `migrations/versions/20261010_0001_initial_schema.py` (all 23 tables and indexes, generic SQLAlchemy types, works on Postgres and SQLite). Run `make db-update` or `uv run alembic upgrade head` from `backend/`. `alembic check` reports no drift. |
| Seed data | **Implemented** | `src/hawa_backend/db/seed.py` (`make db-seed`): wards, schools, 25 reference stations, 10,600 grid cells, assets and HawaTag devices, plan `214` with tasks and review, one intervention and impact, 5 effectiveness priors, 2 alerts, 5 demo users. Idempotent by primary key. |
| PostGIS / geometry | **Planned** | The container image has PostGIS, but no model uses a geometry type and `geoalchemy2` is not a dependency. Locations are `lat`/`lon` `FLOAT` columns. |
| Partitioning, DB roles, grants, retention jobs | **Planned** | none |
| Seed data / demo reset | **Planned** | none |
| Tests | **Implemented** | `tests/db/test_db.py` (4 tests) and `tests/integration/test_end_to_end.py` create all tables on `sqlite+aiosqlite:///:memory:` with `Base.metadata.create_all`. No test runs against Postgres. |

## 2. Base, mixins and session

`db/base.py`:

| Element | Definition |
|---|---|
| `Base` | `DeclarativeBase` with `MetaData(naming_convention=CONVENTION)` |
| `CONVENTION` | `ix: ix_%(column_0_label)s`, `uq: uq_%(table_name)s_%(column_0_name)s`, `ck: ck_%(table_name)s_%(constraint_name)s`, `fk: fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s`, `pk: pk_%(table_name)s` |
| `TimestampMixin` | `created_at TIMESTAMPTZ NOT NULL` (Python default `now(UTC)`), `updated_at TIMESTAMPTZ NOT NULL` (default and `onupdate` `now(UTC)`). Defaults are client-side; there are no server defaults. |
| `SimulatedMixin` | `is_simulated BOOLEAN NOT NULL` default `False`, indexed (`ix_<table>_is_simulated`) |

`db/session.py`:

| Function | Behaviour |
|---|---|
| `get_engine(database_url=None)` | Module-level singleton `create_async_engine(url, echo=settings.debug, future=True)`; `connect_args={"check_same_thread": False}` for SQLite URLs; passing a URL replaces the singleton (the old engine is not disposed) |
| `get_sessionmaker(engine=None)` | Singleton `async_sessionmaker(class_=AsyncSession, expire_on_commit=False, autoflush=False)` |
| `get_db()` | Async generator: yields a session, commits on success, rolls back and re-raises on error |

Column nullability follows the `Mapped[...]` annotation: `Mapped[str]` is `NOT NULL` even where only a Python `default=` is given; `Mapped[Optional[...]]` is nullable. Types below are the PostgreSQL DDL that `CreateTable` emits for these models.

## 3. ER overview

```mermaid
erDiagram
  ward ||--o{ cell_500m : "ward_id"
  ward ||--o{ school : "ward_id"
  ward ||--o{ site : "ward_id"
  device ||--o{ reading : "device_id"
  device ||--o{ device_event : "device_id"
  asset ||--o{ asset_shift : "asset_id"
  asset ||--o{ plan_task : "asset_id"
  asset ||--o{ intervention : "asset_id"
  plan ||--o{ plan_task : "plan_id"
  plan ||--o{ plan_review : "plan_id"
  intervention ||--o| impact : "intervention_id (unique)"
  alert ||--o{ alert_delivery : "alert_id"
  app_user ||--o{ refresh_token : "user_id"
```

Tables with no foreign keys: `reference_station`, `effectiveness_library`, `audit_log`, `outbox_event`, `processed_event`. Columns that look like references but have no FK: `asset.ward_id`, `asset.tag_id`, `asset_shift.driver_user_id`, `plan.ward_id`, `plan_task.intervention_id`, `intervention.tag_id`, `intervention.task_id`, `intervention.cell_500m_id`, `reading.cell_500m_id`, `reading.cell_1km_id`. No `relationship()` is declared on any model.

## 4. Tables

`TS` = `TIMESTAMP WITH TIME ZONE`. "Mixins" lists `T` (TimestampMixin: `created_at`, `updated_at`) and `S` (SimulatedMixin: `is_simulated` + index).

### 4.1 Grid and geography (`db/models/grid.py`)

#### `ward` (class `Ward`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `ward_id` | `VARCHAR(64)` | PK | | `pk_ward` |
| `name` | `VARCHAR(128)` | no | | |
| `zone` | `VARCHAR(64)` | no | | |
| `population` | `INTEGER` | no | `0` | |
| `centroid_lat` | `FLOAT` | no | | |
| `centroid_lon` | `FLOAT` | no | | |

#### `cell_500m` (class `Cell500m`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `cell_id` | `VARCHAR(32)` | PK | | e.g. `g500-041-077` |
| `cell_1km_id` | `VARCHAR(32)` | no | | index `ix_cell_500m_cell_1km_id` |
| `ward_id` | `VARCHAR(64)` | yes | | FK `fk_cell_500m_ward_id_ward` → `ward.ward_id`; index `ix_cell_500m_ward_id` |
| `row` | `INTEGER` | no | | |
| `col` | `INTEGER` | no | | |
| `lat` | `FLOAT` | no | | |
| `lon` | `FLOAT` | no | | |
| `population` | `INTEGER` | no | `0` | |
| `is_key_cell` | `BOOLEAN` | no | `False` | |

#### `school` (class `School`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `school_id` | `VARCHAR(64)` | PK | | |
| `name` | `VARCHAR(256)` | no | | |
| `ward_id` | `VARCHAR(64)` | yes | | FK `fk_school_ward_id_ward` → `ward` (not indexed) |
| `lat`, `lon` | `FLOAT` | no | | |
| `assembly_time` | `VARCHAR(16)` | no | `"08:00"` | |
| `contact_phone` | `VARCHAR(32)` | yes | | PII |

#### `site` (class `Site`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `site_id` | `VARCHAR(64)` | PK | | |
| `name` | `VARCHAR(256)` | no | | |
| `ward_id` | `VARCHAR(64)` | yes | | FK `fk_site_ward_id_ward` → `ward` (not indexed) |
| `lat`, `lon` | `FLOAT` | no | | |
| `compliance_grade` | `VARCHAR(8)` | no | `"B"` | |

#### `reference_station` (class `ReferenceStation`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `station_id` | `VARCHAR(64)` | PK | | |
| `name` | `VARCHAR(256)` | no | | |
| `source` | `VARCHAR(32)` | no | `"CPCB"` | CPCB / DPCC / OpenAQ |
| `lat`, `lon` | `FLOAT` | no | | |
| `is_active` | `BOOLEAN` | no | `True` | |

The live WAQI/OpenAQ stations the API uses ([ARCHITECTURE.md](ARCHITECTURE.md) §3.4) are not written to this table.

### 4.2 Devices and readings (`db/models/device.py`)

#### `device` (class `Device`) — mixins: T, S

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `device_id` | `VARCHAR(32)` | PK | | e.g. `HPM-0142` |
| `role` | `VARCHAR(16)` | no | | `M`, `S`, `TAG`, `EYE` (not constrained) |
| `placement` | `VARCHAR(32)` | no | `"mobile"` | |
| `status` | `VARCHAR(32)` | no | `"active"` | |
| `trust_score` | `FLOAT` | no | `1.0` | |
| `current_vehicle_id` | `VARCHAR(64)` | yes | | |
| `calibration_version` | `VARCHAR(32)` | no | `"v1.0.0"` | |

#### `reading` (class `Reading`) — mixins: S only (no `created_at` / `updated_at`)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `reading_id` | `VARCHAR(36)` | PK | | UUIDv7 string |
| `device_id` | `VARCHAR(32)` | no | | FK `fk_reading_device_id_device` → `device`; index `ix_reading_device_id` |
| `seq` | `INTEGER` | no | | |
| `ts` | `TS` | no | | index `ix_reading_ts` |
| `lat`, `lon` | `FLOAT` | no | | |
| `cell_500m_id` | `VARCHAR(32)` | no | | index `ix_reading_cell_500m_id` |
| `cell_1km_id` | `VARCHAR(32)` | no | | index `ix_reading_cell_1km_id` |
| `pm25` | `FLOAT` | no | | calibrated |
| `pm10` | `FLOAT` | yes | | calibrated |
| `pm25_raw` | `FLOAT` | no | | |
| `pm10_raw` | `FLOAT` | yes | | |
| `rh` | `FLOAT` | no | | |
| `t` | `FLOAT` | no | | |
| `speed_kmh` | `FLOAT` | no | `0.0` | |
| `indicative_aqi` | `INTEGER` | no | | |
| `flags` | `JSON` | yes | `list` | annotated `Optional[dict]` |

Constraint: `uq_reading_device_seq_ts UNIQUE (device_id, seq, ts)`. Not partitioned.

#### `device_event` (class `DeviceEvent`) — mixins: S only

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `event_id` | `VARCHAR(36)` | PK | | |
| `device_id` | `VARCHAR(32)` | no | | FK → `device`; index `ix_device_event_device_id` |
| `seq` | `INTEGER` | no | | |
| `ts` | `TS` | no | | index `ix_device_event_ts` |
| `type` | `VARCHAR(32)` | no | | index `ix_device_event_type` |
| `payload` | `JSON` | no | `dict` | |
| `confirmed_by_cloud` | `BOOLEAN` | no | `False` | |

### 4.3 Fleet (`db/models/asset.py`)

#### `asset` (class `Asset`) — mixins: T, S

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `asset_id` | `VARCHAR(32)` | PK | | e.g. `AST-SPR-0012` |
| `kind` | `VARCHAR(32)` | no | | sprinkler / smog_gun / sweeper / inspection |
| `label` | `VARCHAR(128)` | no | | |
| `ward_id` | `VARCHAR(64)` | yes | | no FK |
| `status` | `VARCHAR(32)` | no | `"available"` | |
| `capacity_litres` | `FLOAT` | no | `5000.0` | |
| `tag_id` | `VARCHAR(32)` | yes | | attached HawaTag, no FK |

#### `asset_shift` (class `AssetShift`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `shift_id` | `VARCHAR(36)` | PK | | |
| `asset_id` | `VARCHAR(32)` | no | | FK → `asset`; index `ix_asset_shift_asset_id` |
| `driver_user_id` | `VARCHAR(36)` | no | | index `ix_asset_shift_driver_user_id`; no FK |
| `start_time`, `end_time` | `TS` | no | | |
| `is_active` | `BOOLEAN` | no | `True` | |

### 4.4 Plans (`db/models/plan.py`)

#### `plan` (class `Plan`) — mixins: T, S

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `plan_id` | `VARCHAR(36)` | PK | | |
| `ward_id` | `VARCHAR(64)` | no | | index `ix_plan_ward_id`; no FK |
| `status` | `VARCHAR(32)` | no | `"draft"` | free text (comment lists drafting / draft / approved / done) |
| `window_start`, `window_end` | `TS` | no | | |
| `window_label` | `VARCHAR(64)` | no | | |
| `drafted_by` | `VARCHAR(64)` | no | `"AI-ML Optimizer"` | |
| `approved_by` | `VARCHAR(64)` | yes | | |
| `approved_at` | `TS` | yes | | |
| `approval_note` | `VARCHAR(512)` | yes | | |
| `headline` | `JSON` | no | `dict` | |
| `summary` | `VARCHAR(1024)` | yes | | |
| `reasoning` | `VARCHAR(2048)` | yes | | |
| `checks` | `JSON` | no | `list` | |

#### `plan_task` (class `PlanTask`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `task_id` | `VARCHAR(36)` | PK | | |
| `plan_id` | `VARCHAR(36)` | no | | FK → `plan`; index `ix_plan_task_plan_id` |
| `asset_id` | `VARCHAR(32)` | no | | FK → `asset`; index `ix_plan_task_asset_id` |
| `op` | `VARCHAR(8)` | no | `"add"` | add / del |
| `time_label` | `VARCHAR(32)` | no | | |
| `place` | `VARCHAR(256)` | no | | |
| `action` | `VARCHAR(128)` | yes | | |
| `cause` | `VARCHAR(32)` | yes | | |
| `cause_conf` | `FLOAT` | yes | | |
| `reason` | `VARCHAR(512)` | no | | |
| `status` | `VARCHAR(32)` | no | `"dispatched"` | free text; the e2e test writes `pending` and `approved` |
| `completed_at` | `TS` | yes | | |
| `intervention_id` | `VARCHAR(36)` | yes | | no FK |

#### `plan_review` (class `PlanReview`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `review_id` | `VARCHAR(36)` | PK | | |
| `plan_id` | `VARCHAR(36)` | no | | FK → `plan`; index `ix_plan_review_plan_id` |
| `agent_role` | `VARCHAR(32)` | no | | Planner / Auditor / Forecaster |
| `objections` | `JSON` | no | `list` | |
| `suggestions` | `JSON` | no | `list` | |
| `verdict` | `VARCHAR(32)` | no | `"acceptable"` | |

The in-memory plan objects served by `/v1/plans` (camelCase `groups`, `comments`, `checks`) are not mapped to these tables.

### 4.5 Interventions and impact (`db/models/intervention.py`)

#### `intervention` (class `Intervention`) — mixins: T, S

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `intervention_id` | `VARCHAR(36)` | PK | | |
| `tag_id` | `VARCHAR(32)` | no | | index `ix_intervention_tag_id` |
| `asset_id` | `VARCHAR(32)` | no | | FK → `asset`; index `ix_intervention_asset_id` |
| `task_id` | `VARCHAR(36)` | yes | | no FK |
| `start_ts`, `end_ts` | `TS` | no | | |
| `lat`, `lon` | `FLOAT` | no | | |
| `cell_500m_id` | `VARCHAR(32)` | no | | index `ix_intervention_cell_500m_id` |
| `litres_delivered` | `FLOAT` | no | `0.0` | |
| `flow_avg_lpm` | `FLOAT` | no | `0.0` | |
| `pm25_before`, `pm25_after` | `FLOAT` | yes | | |
| `verification_status` | `VARCHAR(32)` | no | `"pending"` | pending / verified / inconclusive |
| `verify_after` | `TS` | no | | |

#### `impact` (class `Impact`) — mixins: T, S

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `impact_id` | `VARCHAR(36)` | PK | | |
| `intervention_id` | `VARCHAR(36)` | no | | FK → `intervention`; `uq_impact_intervention_id UNIQUE` |
| `pollutant` | `VARCHAR(16)` | no | `"pm25"` | |
| `effect_pct` | `FLOAT` | no | | |
| `ci_low_pct`, `ci_high_pct` | `FLOAT` | no | | |
| `p_value` | `FLOAT` | no | `0.05` | |
| `verdict` | `VARCHAR(32)` | no | `"verified"` | |
| `series` | `JSON` | no | `list` | observed vs synthetic control |

#### `effectiveness_library` (class `EffectivenessLibrary`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `VARCHAR(36)` | PK | | |
| `cause` | `VARCHAR(32)` | no | | |
| `asset_kind` | `VARCHAR(32)` | no | | |
| `sample_size` | `INTEGER` | no | `0` | |
| `effect_pct` | `FLOAT` | no | | |
| `ci_low`, `ci_high` | `FLOAT` | no | | |

### 4.6 Alerts (`db/models/alert.py`)

#### `alert` (class `Alert`) — mixins: T, S

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `alert_id` | `VARCHAR(36)` | PK | | |
| `audience` | `VARCHAR(32)` | no | | School / Citizens / Drivers … |
| `channel` | `VARCHAR(32)` | no | | WhatsApp / SMS / FCM |
| `title` | `VARCHAR(256)` | no | | |
| `body_en`, `body_hi` | `VARCHAR(1024)` | no | | |
| `recipient_phone` | `VARCHAR(32)` | yes | | PII |
| `safe_window` | `VARCHAR(64)` | yes | | |
| `status` | `VARCHAR(32)` | no | `"delivered"` | |

#### `alert_delivery` (class `AlertDelivery`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `delivery_id` | `VARCHAR(36)` | PK | | |
| `alert_id` | `VARCHAR(36)` | no | | FK → `alert`; index `ix_alert_delivery_alert_id` |
| `channel` | `VARCHAR(32)` | no | | |
| `status` | `VARCHAR(32)` | no | `"sent"` | sent / delivered / failed |
| `delivered_at` | `TS` | yes | | |

### 4.7 Auth and audit (`db/models/auth.py`)

#### `app_user` (class `AppUser`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `user_id` | `VARCHAR(36)` | PK | | |
| `phone_e164` | `VARCHAR(32)` | no | | unique index `ix_app_user_phone_e164`; PII |
| `full_name` | `VARCHAR(128)` | no | | |
| `role` | `VARCHAR(32)` | no | | officer / driver / inspector / school |
| `ward_ids` | `JSON` | no | `list` | |
| `hashed_password` | `VARCHAR(256)` | yes | | `salt$hex` from `core.security.hash_password` |
| `is_active` | `BOOLEAN` | no | `True` | |

#### `refresh_token` (class `RefreshToken`) — mixins: T

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `token_id` | `VARCHAR(36)` | PK | | |
| `user_id` | `VARCHAR(36)` | no | | FK → `app_user`; index `ix_refresh_token_user_id` |
| `token_hash` | `VARCHAR(128)` | no | | `uq_refresh_token_token_hash UNIQUE` |
| `expires_at` | `TS` | no | | |
| `revoked` | `BOOLEAN` | no | `False` | |

#### `audit_log` (class `AuditLog`) — no mixins

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `log_id` | `VARCHAR(36)` | PK | | |
| `actor` | `VARCHAR(128)` | no | | index `ix_audit_log_actor` |
| `action` | `VARCHAR(64)` | no | | index `ix_audit_log_action` |
| `subject` | `VARCHAR(128)` | no | | index `ix_audit_log_subject` |
| `details` | `JSON` | no | `dict` | |
| `created_at` | `TS` | no | none (must be supplied) | |

Append-only by intent only; nothing prevents updates.

### 4.8 Outbox and idempotency (`db/models/outbox.py`)

#### `outbox_event` (class `OutboxEvent`) — no mixins

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `event_id` | `VARCHAR(36)` | PK | | |
| `topic` | `VARCHAR(128)` | no | | index `ix_outbox_event_topic`; e.g. `hawa.task.lifecycle.v1` |
| `payload` | `JSON` | no | | the serialised `Envelope` |
| `status` | `VARCHAR(16)` | no | `"pending"` | index `ix_outbox_event_status`; pending / published |
| `created_at` | `TS` | no | none (must be supplied) | |

#### `processed_event` (class `ProcessedEvent`) — no mixins

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `event_id` | `VARCHAR(36)` | PK (1/2) | | composite `pk_processed_event` |
| `consumer_group` | `VARCHAR(64)` | PK (2/2) | | |
| `processed_at` | `TS` | no | | |

No relay reads `outbox_event` and no consumer writes `processed_event` ([EVENTS.md](EVENTS.md) §2).

## 5. Planned schema (target design)

> Status: **Planned**. The pre-implementation data model (about 2 400 lines of DDL, Alembic workflow, partition jobs, grants and seed procedures) is in git history: `git show a33e043:docs/backend/DATA_MODEL.md`. The main differences from what is built:

| Topic | Target design | Built |
|---|---|---|
| Database setup | PostgreSQL 16 + PostGIS 3.4, database and schema `hawa`, UTC, extensions `postgis`, `btree_gist`, `pg_trgm` (optional `pg_partman`, `pg_stat_statements`); group roles `hawa_owner`, `app_rw`, `ml_rw`, `readonly` and one login per service | default schema, no extensions, no roles |
| Ids | Native `uuid` primary keys generated app-side as UUIDv7; `text` + `CHECK` regex for natural keys (devices, assets, cells, wards, schools, sites, stations) | `VARCHAR(36)` strings, no checks |
| Enums | `varchar(32)` + named `CHECK` constraints mirroring `hawa_contracts.enums`, never native `ENUM` | free-text columns |
| Geometry | `geometry(Point/Polygon/LineString, 4326)` with GiST indexes; `ST_AsMVT` vector tiles | `FLOAT` lat/lon |
| Grid | `grid_meta`, `cell` (500 m, with geometry and population), `cell_1k`, `cell_feature`, `poi` | `cell_500m` only |
| Devices | `device` with calibration coefficients, `device_calibration` history | `device` with `calibration_version` only |
| Readings | `reading` partitioned by day, PK `(device_id, seq, ts)`, BRIN on `ts`, 90-day hot retention, archive to S3 Parquet; Redis dedupe in front | single table, UUID PK + unique `(device_id, seq, ts)` |
| External data | `reference_observation`, `weather_observation`, `weather_forecast`, `fire_point` | `reference_station` only |
| AI-ML outputs | `twin_run`, `cell_state` (partitioned), `hotspot`, `forecast_run`, `forecast` (partitioned), `grap_outlook`, `school_safe_window`, `plan_simulation`, `site_score`, `integrity_flag`, `coverage_gap`, `model_version` | none (AI-ML keeps its own data) |
| Plans | `plan` with `ward_ids[]`, `mode`, `version`, `expires_at`; split ownership (AI-ML inserts drafts, backend owns transitions, guarded by triggers); `plan_task` with stop order, windows, geometry, `assigned_user_id`, ack/dispatch timestamps | simple `plan`, `plan_task`, `plan_review` |
| Interventions | `source` (hawatag / manual / gps_inferred), `evidence_level`, `segment_id`, `geom_track`, `cell_ids[]`, `injected_effect_pct` for simulated ground truth | point location only |
| Community | `citizen_report`, `inspection`, `evidence_report` | none |
| Auth | `app_user` with email + argon2id hash, `push_token`, `user_ward_scope`; `audit_log` partitioned by month, INSERT-only grant | phone-keyed `app_user`, `refresh_token`, flat `audit_log` |
| Migrations | Alembic with async `env.py`, numbered baseline revisions, review of autogenerate output, expand/contract for zero downtime, CI check that `alembic check` is clean, AI-ML drift test | none |
| Operations | `hawa seed` (wards, grid, schools, stations, assets, devices, users), `hawa demo-reset` with golden history, `hawa partitions` job, RDS PITR backups | none |

<!-- footer:start -->

---

[Back to top](#hawacommand-backend--data-model) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
