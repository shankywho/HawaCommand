# Backend data stores

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Backend docs:** [Runbook](../../backend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · [API](API.md) · [Services](SERVICES.md) · **Data stores** · [Testing](TESTING.md) · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/DynamoDB-2%20tables-4053D6?logo=amazondynamodb&logoColor=white" alt="DynamoDB">
<img src="https://img.shields.io/badge/ElastiCache-Valkey%20%2F%20Redis-DC382D?logo=redis&logoColor=white" alt="Redis">
<img src="https://img.shields.io/badge/S3-evidence-569A31?logo=amazons3&logoColor=white" alt="S3">
<img src="https://img.shields.io/badge/SQL-23%20tables%20(schema%20ready)-336791?logo=postgresql&logoColor=white" alt="SQL">
</p>

Every place the backend keeps data, with keys, item shapes and expiry.

| Store | Holds | Without it |
|---|---|---|
| [DynamoDB](#dynamodb) | Citizen reports, fleet telemetry history, forecast cache | Process memory |
| [ElastiCache](#elasticache-redis) | Live fleet, twin snapshot, plans, alerts, push tokens, checkpoints | Process memory |
| [S3](#s3) | Citizen and inspection photos | Uploads return `503` |
| [SQL](#sql-schema) | 23-table schema and seed for the next persistence step | Not used by the API |

---

## DynamoDB

### `hawa-citizen-grievances`

| Key | Type | Notes |
|---|---|---|
| `report_id` (partition) | S | UUIDv5 of caller + `client_report_id` |
| `created_at` (sort) | S | ISO-8601 UTC with ms |
| GSI `WardStatusIndex` | `ward_id` + `status` | Officer list by ward and status |
| GSI `OwnerIndex` | `owner_id` + `created_at` | "My reports"; without it the backend scans |

Other attributes: `owner_id`, `client_report_id`, `photo_key`, `lat`, `lon`, `accuracy_m`, `note`, `lang`, `category`, `captured_at`, `source`, `status`, `cell_id`, `place`, `pm25`, `timeline[]`, `verification{}`, `inspection{}`, `outcome`, `outcome_text`, `rejection_reason`, `closed_at`, `sla_due_at`, `updated_at`.

- `status` ∈ `submitted`, `verifying`, `verified`, `rejected`, `ticketed`, `closed`.
- `ward_id` is `unassigned` until verification sets it.
- Point-in-time recovery on.

### `hawa-fleet-telemetry`

| Key | Type | Notes |
|---|---|---|
| `asset_id` (partition) | S | e.g. `SPR-04` |
| `timestamp` (sort) | S | ISO-8601 UTC with ms |
| `ttl_epoch` | N | TTL attribute: ping time + 7 days |

Other attributes: `epoch`, `lat`, `lon`, `speed_kmh`, `pump_flow_lpm`, `heading_deg`, `litres_cum`, `pm25`, `pm10`, `kind`, `tag_id`, `seq`, `source`, `area`.

### `hawa-cache` (optional)

- Key `pk` (`forecast:<cell_id>`), attributes `value` (JSON) and `ttl`; caches SageMaker or Step Functions forecasts.

---

## ElastiCache (Redis)

| Key | Type | Written by | TTL |
|---|---|---|---|
| `geo:fleet:active` | GEO (sorted set) | each ping | pruned after 15 min idle |
| `fleet:lastseen` | sorted set (epoch) | each ping | pruned after 15 min idle |
| `fleet:latest:<asset_id>` | string (JSON) | each ping | 24 h |
| `fleet:pings` | pub/sub channel | each ping | — |
| `grid:pm25:500m:<YYYYMMDDHH>` | string (JSON split frame) | first twin fit in the hour | 900 s |
| `plans:active` | hash (plan id → JSON) | plan routes | — |
| `alerts:sent` | list (newest first, 200) | broadcasts | — |
| `alerts:subscription:<user>` | string (JSON) | `PUT /v1/me/alert-subscription` | — |
| `push:tokens:<user>` | hash (token → JSON) | `PUT /v1/me/push-token` | 60 days |
| `kinesis:checkpoint:<stream>:<shard>` | string (sequence number) | Kinesis consumer | 7 days |

- URL: `HAWA_REDIS_URL` (`redis://` or `rediss://`); a failed connection is retried every 30 s, memory is used in between.
- Check by hand: `GEOSEARCH geo:fleet:active FROMLONLAT 77.3158 28.6476 BYRADIUS 5 KM WITHDIST`.

---

## S3

| Item | Value |
|---|---|
| Bucket | `hawa-citizen-evidence-prod` (private) |
| Key | `{HAWA_AWS_EVIDENCE_PREFIX}{purpose}/YYYY/MM/DD/{uuid}.{ext}` |
| Purposes | `report_photo`, `inspection_photo`, `task_photo` |
| Upload | Pre-signed POST, pins content type, SHA-256 metadata and size (≤ 5 MB) |
| Read | Pre-signed GET, 1 h |
| Health check object | `healthcheck/aws-check.txt` |

---

## SQL schema

The schema is ready for moving state into PostgreSQL; the API does not open a session yet.

| Group | Tables |
|---|---|
| Geography | `ward`, `cell_500m`, `school`, `site`, `reference_station` |
| Devices | `device`, `reading`, `device_event` |
| Fleet | `asset`, `asset_shift` |
| Plans | `plan`, `plan_task`, `plan_review` |
| Impact | `intervention`, `impact`, `effectiveness_library` |
| Alerts | `alert`, `alert_delivery` |
| Users | `app_user`, `refresh_token` |
| Events | `outbox_event`, `processed_event`, `audit_log` |

- Migrations: Alembic revision `0001` (`backend/migrations/`); `make db-update db-seed` on PostgreSQL 16 or SQLite.
- Models: `backend/src/hawa_backend/db/models/`.

---

## Related

- [Services](SERVICES.md) · [Backend architecture](ARCHITECTURE.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [Contracts](../CONTRACTS.md)

<!-- footer:start -->

---

[Back to top](#backend-data-stores) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
