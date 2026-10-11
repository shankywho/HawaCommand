# HawaCommand — Shared Contracts

<!-- nav:start -->

**Navigate:** [Project](../README.md) · [Docs hub](README.md) · [Overview](SYSTEM_OVERVIEW.md) · [AWS architecture](AWS_ARCHITECTURE.md) · [AWS guide](AWS_SETUP_GUIDE.md) · [API](backend/API.md) · [Environment](ENVIRONMENT_VARIABLES.md) · **Contracts**

<!-- nav:end -->

> **Status (reconciled 2026-10-10).** The Python source of truth is `backend/contracts/hawa_contracts/` (`ids.py`, `enums.py`, `units.py`, `packets.py`, `envelope.py`, `topics.py`, `redis_keys.py`, `events/*.py`), covered by `backend/contracts/tests/test_contracts.py`. Much of what it declares is not used by running code:
> - No Kafka producers or consumers exist (§5).
> - No database is used by the API (§8).
> - Redis keys are unused (§9).
> - The internal AI-ML surface in §7 (`/internal/v1/simulate`, `/optimize`, `/exposure`, `/models`, `/alerts/draft`, bearer auth) does not exist. The real AI-ML routes are listed in [AI-ML/CONTRACTS.md](../AI-ML/CONTRACTS.md).
> - The AI-ML cell ids are `G-RRR-CCC`, not the `g500-...` form below.
>
> The REST surface actually served is in [backend/API.md](backend/API.md). The web console validates it with zod (`frontend/src/contracts/`, `frontend/scripts/verify_backend_contracts.ts`). The Flutter client is generated from `app_frontend/openapi/openapi.json`, which describes the planned field API; most of its paths are not served yet.


**Every team builds against this file.** It defines the names, IDs, enums, units, packets, events, tables and endpoints that cross a folder boundary. If you need to change something here, open a PR that touches this file **and** the code in `backend/contracts/` (`hawa_contracts`) in the same change, and tag all four leads.

Source: the original proposal (v3) §9 (data model, APIs, algorithms) and §10 (packet format). Context: [SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md).

Contents
1. [Conventions](#1-conventions)
2. [Identifiers](#2-identifiers)
3. [Enums](#3-enums)
4. [Edge → cloud MQTT contracts](#4-edge--cloud-mqtt-contracts)
5. [Kafka event contracts](#5-kafka-event-contracts)
6. [Public REST + WebSocket surface (index)](#6-public-rest--websocket-surface-index)
7. [Internal AI-ML service surface](#7-internal-ai-ml-service-surface)
8. [Database table ownership](#8-database-table-ownership)
9. [Redis key namespaces](#9-redis-key-namespaces)
10. [Air-quality reference tables (AQI, GRAP, thresholds)](#10-air-quality-reference-tables)
11. [Schedules](#11-schedules)
12. [Versioning and change rules](#12-versioning-and-change-rules)

---

## 1. Conventions

| Topic | Rule |
|---|---|
| Time | Stored and transmitted in **UTC**, ISO-8601 with `Z` (`2026-11-12T01:14:30Z`). Displayed in **IST (Asia/Kolkata)**. Schedules in §11 are written in IST. |
| Geometry (wire + storage) | **WGS84, EPSG:4326**. GeoJSON coordinate order is **[lon, lat]**. JSON objects use `{"lat":…, "lon":…}` only in the device packet (as in §10.6). |
| Geometry (computation) | Grid and distance maths in **UTM zone 43N, EPSG:32643** (metres). |
| Particulates | µg/m³ (`pm1`, `pm25`, `pm10`) |
| Gases | ppb (`no2_ppb`, `co_ppb`, `nh3_ppb`); CO₂ in ppm (`co2_ppm`) |
| VOC | BME680 gas resistance in kΩ (`voc_kohm`) — lower = more VOC. Indicative only. |
| Weather | temperature °C (`t`), relative humidity % (`rh`), pressure hPa (`p`), wind speed m/s (`ws`), wind direction degrees **from** (`wd`, meteorological) |
| Speed | km/h (`spd`) |
| Water / power | litres (`litres`), litres per minute (`flow_lpm`), amps (`pump_a`) |
| Exposure | person-hours above threshold (`exposure_ph`) — see §10.4 |
| JSON field style | `snake_case` everywhere (API, events, DB). Exception: the compact device packet in §4 keeps the field names from §10.6 of the proposal. |
| Money | INR, integer paise in storage (`cost_paise`), formatted ₹ in UI |
| Languages | `en`, `hi` (BCP-47). All user-facing alert text exists in both. |
| Simulated data | Every device, asset, reading, intervention, event carries `is_simulated: bool`. UIs **must** show a "Simulated" badge when true. |
| Uncertainty | Every model output carries its uncertainty: `*_var` / `confidence` (twin), `p10/p50/p90` (forecast), `ci_low/ci_high` (impact), `cause_conf` (attribution). Never ship a bare point estimate to a UI. |

---

## 2. Identifiers

| Entity | Format | Example | Notes |
|---|---|---|---|
| Generic entity id | UUIDv7 (string) | `01927f3e-8c1a-7b4e-9f21-3c5d8a0e6b11` | plans, tasks, interventions, impacts, alerts, reports, users, events. Time-ordered → good index locality. |
| Device | `{PREFIX}-{NNNN}` | `HPM-0142` | `HPM` HawaPod-M (mobile), `HPS` HawaPod-S (school sentinel), `HTG` HawaTag (intervention tracker), `HEY` HawaEye (camera). HawaPod-S pairs share a number and add a placement suffix: `HPS-0007-O` (outdoor), `HPS-0007-I` (indoor). |
| Asset (machine / team) | `AST-{TYPE}-{NNNN}` | `AST-SPR-0012` | `SPR` sprinkler, `ASG` anti-smog gun, `SWP` mechanised sweeper, `TEAM` inspection team |
| Vehicle (sensor host) | `VEH-{operator}-{NNNN}` | `VEH-DTC-0457` | bus / e-rickshaw / delivery bike carrying a HawaPod-M |
| 500 m map cell | `g500-{row:03d}-{col:03d}` | `g500-041-077` | row/col from the grid origin (south-west corner of Delhi's bounding box snapped to 500 m in EPSG:32643). Origin stored in `grid_meta`. |
| 1 km planning cell | `g1k-{row:03d}-{col:03d}` | `g1k-020-038` | `g1k.row = floor(g500.row / 2)`, same for col. Forecasts and plans use 1 km cells. |
| Ward | `ward-{code}` | `ward-084` | from the MCD ward boundary file |
| Hotspot | UUIDv7 | | a connected cluster of high-exposure 500 m cells at one twin timestamp |
| Site (construction / unit) | `SITE-{NNNN}` | `SITE-0311` | |
| School | `SCH-{udise_code}` or `SCH-{NNNN}` | `SCH-07050112345` | UDISE code when known |
| Reference station | `REF-{source}-{id}` | `REF-CPCB-site_301` | `CPCB`, `DPCC`, `OAQ` (OpenAQ) |
| Model version | `{model}@{semver}+{git_sha7}` | `forecaster@1.3.0+a1b2c3d` | mirrors the MLflow registry |
| Correlation id | UUIDv7 | | one id per loop run (twin run, plan cycle, dispatch saga); carried in every event, log line and HTTP header `X-Correlation-Id` |
| Request id | UUIDv7 | | per HTTP request; header `X-Request-Id` |

---

## 3. Enums

Canonical definitions live in `backend/contracts/hawa_contracts/enums.py`. Web and Flutter get them from OpenAPI.

```text
DeviceRole        = M | S | TAG | EYE
DevicePlacement   = mobile | outdoor | indoor | vehicle_mounted_tag | roadside
DeviceStatus      = provisioned | active | degraded | offline | retired
TrustBand         = high (≥0.8) | medium (0.5–0.8) | low (<0.5)

Pollutant         = pm1 | pm25 | pm10 | no2 | co | nh3 | voc | co2

CauseLabel        = dust            # road + construction dust (high PM10, low PM2.5/PM10)
                  | traffic         # NO2 + CO co-signal, rush hours, corridors
                  | burning         # sharp PM2.5 + VOC spike, often night, fire point / photo
                  | regional_smoke  # city-wide PM2.5 rise, NW wind, FIRMS fires upwind
                  | mixed
                  | unknown

AssetType         = sprinkler | anti_smog_gun | sweeper | inspection_team
AssetStatus       = available | on_task | off_shift | maintenance | offline

# Cause → which asset types may be assigned (HARD constraint in the optimiser;
# the Auditor agent checks it again in words).
#   dust            → sprinkler, anti_smog_gun, sweeper, inspection_team (site check)
#   traffic         → inspection_team (smoky-vehicle check)  + alerts
#   burning         → inspection_team                          + alerts
#   regional_smoke  → (no machines)                            + alerts / protection only
#   mixed           → per dominant sub-cause
#   unknown         → inspection_team (investigate)            + alerts

GrapStage         = 0 | 1 | 2 | 3 | 4          # 0 = below Stage I (see §10.2)
AqiCategory       = good | satisfactory | moderate | poor | very_poor | severe

PlanMode          = master | replan | spike | manual
PlanStatus        = drafting → draft → approved → dispatched → in_progress → completed
                               ↘ rejected       ↘ partially_completed
                    drafting → failed ;  draft → expired (not approved before first task window)

TaskKind          = spray | sweep | inspect | protect_alert
TaskStatus        = pending → dispatched → acknowledged → en_route → in_progress → done
                    → verifying → verified | inconclusive
                    side exits: skipped (with reason) | cancelled | missed (window passed) | failed

InterventionSource = hawatag | manual | gps_inferred
ImpactMethod       = synthetic_control | diff_in_diff | before_after_naive   # naive is flagged "low evidence"
ImpactVerdict      = effective | no_detectable_effect | inconclusive | adverse

AlertChannel      = push | whatsapp | sms | email | in_app
AlertAudience     = school | citizen | driver | inspector | officer | site_manager
AlertKind         = pollutant_warning | safe_window | route_assignment | inspection_target
                  | grap_outlook | report_outcome | device_health
AlertStatus       = requested → queued → sent → delivered | failed | read

ReportStatus      = submitted → verifying → verified | rejected → ticketed → closed
InspectionStatus  = open → assigned → on_site → closed_confirmed | closed_not_found | closed_unreachable

SiteType          = construction | industrial_unit | waste_site | other
SiteGrade         = A | B | C

IntegrityFlagKind = station_clustering        # cleaning clusters around official stations (anti-gaming, F15)
                  | device_drift | device_tamper | implausible_jump

UserRole          = admin | officer | analyst | inspector | driver | school | site_manager | citizen
                  # "public" = unauthenticated; "service" = machine-to-machine token
                  # A user may hold several roles: JWT carries `role` (active) + `roles[]`;
                  # switch with POST /v1/auth/switch-role. Unknown phone numbers become `citizen` on first OTP verify.

# --- added in contracts v1.1 (merged from area docs) ---
AuditorVerdict      = approve | approve_with_changes | reject
ObjectionSeverity   = blocking | warning | info
ObjectionSource     = auditor_agent | rules
ObjectionResolution = open | auto_applied | accepted | overridden
ImpactStage         = provisional | final
EvidenceLevel       = high | medium | low          # low = naive / manual-source interventions
VerificationStatus  = pending | provisional | verified | inconclusive | skipped
TaskCompletion      = hawatag | manual | gps_inferred
SkipReason          = road_blocked | vehicle_issue | water_empty | unsafe | access_denied | other
InspectionOutcome   = closed_confirmed | closed_not_found | closed_unreachable
ClassroomAdvice     = normal | seal | ventilate
ReportCategory      = burning | dust | other
ReportSource        = app | whatsapp | web
UploadPurpose       = report_photo | inspection_photo | task_photo
ShiftStatus         = scheduled | active | ended
PushPlatform        = android | ios | web
OtpChannel          = sms | whatsapp
AlertKind          += route_changed | task_done_auto
```

TaskStatus ↔ InspectionStatus for `inspect` tasks: `dispatched/acknowledged` ↔ `assigned`, `in_progress` ↔ `on_site`, `done` ↔ `closed_*`. An inspection is closed **only** through `POST /v1/inspections/{id}/close`, which also marks the linked task `done`; `POST /v1/tasks/{id}/evidence` is for photos on spray/sweep tasks.

---

## 4. Edge → cloud MQTT contracts

Broker: Mosquitto (local, username/password per device) · AWS IoT Core (prod, X.509 per device).
All payloads are UTF-8 JSON. QoS 1. The device increments `seq` monotonically per device and **never reuses it** (store-and-forward replays keep the original `seq`).

| Topic | Direction | Publisher | Cadence | Payload |
|---|---|---|---|---|
| `hawa/v1/{deviceId}/telemetry` | up | HPM, HPS, HTG | every 30 s (batched average of 5 s PM / 10 s gas / 1 s GPS samples) | `TelemetryPacket` |
| `hawa/v1/{deviceId}/event` | up | all | immediately | `DeviceEventPacket` (spike, tamper, health, boot) |
| `hawa/v1/{deviceId}/spray` | up | HTG | on pump/flow state change | `SprayPacket` |
| `hawa/v1/{deviceId}/clip` | up | HEY | on flagged detection | `ClipPacket` (metadata; clip itself uploaded to S3 via presigned URL) |
| `hawa/v1/{deviceId}/cmd` | down | cloud | on demand | `DeviceCommand` (config, calibration hint, sampling mode). OTA uses AWS IoT Jobs in prod. |

### 4.1 `TelemetryPacket` (exactly §10.6, plus optional role fields)

```json
{
  "v": 1,
  "dev": "HPM-0142",
  "role": "M",
  "seq": 88214,
  "ts": "2026-11-12T01:14:30Z",
  "gps": { "lat": 28.6331, "lon": 77.2194, "spd": 14.2, "hdop": 0.9 },
  "pm":  { "pm1": 141, "pm25": 212, "pm10": 318 },
  "gas": { "no2_ppb": 61, "co_ppb": 1840 },
  "env": { "t": 17.8, "rh": 82, "p": 1015, "voc_kohm": 38 },
  "flags": ["heater_on"],
  "fw": "1.4.2",
  "batt": 4.02
}
```

Optional fields by role:

| Role | Extra fields |
|---|---|
| `S` | `"placement": "outdoor" \| "indoor"`, `"co2_ppm": 1210` (indoor unit, Senseair S8); `gps` may be omitted (fixed location from registry) |
| `TAG` | `"asset": "AST-SPR-0012"`, `"tag": { "flow_lpm": 38.5, "pump_a": 6.2, "spraying": true, "litres_total": 18234.5 }` |
| `M` | `"imu": { "moving": true, "tamper": false }` |

Validation rules (ingest rejects to DLQ with a reason code):

| Rule | Reason code |
|---|---|
| `v` must be `1` | `unsupported_version` |
| `dev` matches `^(HPM|HPS|HTG|HEY)-\d{4}(-[OI])?$` and is registered | `unknown_device` |
| `ts` within [now − 72 h, now + 2 min] | `stale_or_future` |
| lat ∈ [28.3, 29.0], lon ∈ [76.7, 77.5] (NCR bbox) unless role `S` | `out_of_bounds` |
| 0 ≤ pm1 ≤ pm25 ≤ pm10 ≤ 2000 | `implausible_pm` |
| rh ∈ [0, 100], t ∈ [−5, 55] | `implausible_env` |
| duplicate `(dev, seq)` | dropped silently (counted), not DLQ |

Health `flags` vocabulary: `heater_on`, `warming_up` (MiCS-6814 < 30 min), `fan_stall`, `flatline`, `gps_no_fix`, `sd_replay`, `low_batt`, `high_speed` (> 60 km/h; twin down-weights).

### 4.2 `DeviceEventPacket`

```json
{
  "v": 1, "dev": "HPM-0142", "seq": 88215, "ts": "2026-11-12T01:12:04Z",
  "type": "spike",
  "gps": { "lat": 28.6329, "lon": 77.2201, "spd": 8.1, "hdop": 1.0 },
  "pm": { "pm1": 180, "pm25": 262, "pm10": 301 },
  "gas": { "no2_ppb": 44, "co_ppb": 2210 },
  "env": { "t": 16.9, "rh": 79, "p": 1015, "voc_kohm": 12 },
  "spike": { "pollutant": "pm25", "baseline": 81, "peak": 262, "ratio": 3.2, "window_s": 20, "model": "tinyml-spike@0.3.0" }
}
```

`type` ∈ `spike | tamper | health | boot`. For `tamper`: `"tamper": {"source": "seal_switch" | "imu", "detail": "…"}`. For `health`: `"health": {"flags": [...], "uptime_s": 86400, "sd_queue": 0}`.

### 4.3 `SprayPacket` (HawaTag)

```json
{
  "v": 1, "dev": "HTG-0031", "asset": "AST-SPR-0012", "seq": 5521, "ts": "2026-11-13T00:41:10Z",
  "type": "spray_start",
  "segment_id": "HTG-0031-5521",
  "gps": { "lat": 28.6412, "lon": 77.2095, "spd": 11.0, "hdop": 0.8 },
  "tag": { "flow_lpm": 41.2, "pump_a": 6.4, "litres_total": 18234.5 },
  "pm": { "pm1": 120, "pm25": 188, "pm10": 402 }
}
```

`type` ∈ `spray_start | spray_stop`. `spray_stop` repeats `segment_id` from its start and adds `"litres": 612.3`. Spray is **detected** when flow > 5 lpm **and** pump current > 2 A for ≥ 10 s (smog guns: fan current instead of flow).

---

## 5. Kafka event contracts

### 5.1 Envelope

Every message on every `hawa.*` topic (except `hawa.logs.v1`, which is logifyx Avro) is a JSON envelope:

```json
{
  "event_id": "01927f3e-8c1a-7b4e-9f21-3c5d8a0e6b11",
  "type": "twin.updated",
  "version": 1,
  "source": "intel-worker",
  "occurred_at": "2026-11-12T01:15:00Z",
  "produced_at": "2026-11-12T01:15:02Z",
  "correlation_id": "01927f3e-7000-7aaa-8bbb-000000000001",
  "causation_id": "01927f3e-6fff-7aaa-8bbb-00000000000f",
  "subject": "run:01927f3e-7000-7aaa-8bbb-000000000001",
  "is_simulated": false,
  "data": { }
}
```

Kafka headers: `content-type: application/json`, `hawa-type: <type>`, `hawa-version: <n>`, `traceparent: <W3C trace context>`.
Message **key**: as listed per topic below (guarantees ordering per key).
Delivery: **at-least-once**. Every consumer is idempotent on `event_id`.
The API never produces directly inside a request; it writes to the `outbox_event` table in the same DB transaction and `outbox-relay` publishes.

### 5.2 Topics

Local: 3 partitions (telemetry 6), RF 1. AWS MSK: 12 partitions for telemetry, 6 elsewhere, RF 3.

| Topic | Key | Producer(s) | Consumer group(s) | Retention | `type` values |
|---|---|---|---|---|---|
| `hawa.telemetry.raw.v1` | `device_id` | mqtt-bridge (local) · IoT Rule Kafka action (AWS) | `ingest` | 7 d | raw MQTT payload wrapped: `telemetry.raw`, `device_event.raw`, `spray.raw`, `clip.raw` (data = `{topic, payload, received_at}`) |
| `hawa.telemetry.clean.v1` | `device_id` | ingest-worker | `intel-twin-live`, `api-live`, `archiver` | 3 d | `reading.cleaned` |
| `hawa.telemetry.dlq.v1` | `device_id` | ingest-worker | `ops` | 14 d | `reading.rejected` (data = `{reason, payload}`) |
| `hawa.device.event.v1` | `device_id` | ingest-worker (`device.spike/tamper/health/boot`), intel-worker (`device.calibrated`, `device.trust_changed`) | `intel-spike`, `api-live`, `device-health` | 7 d | `device.spike`, `device.tamper`, `device.health`, `device.boot`, `device.calibrated`, `device.trust_changed` |
| `hawa.intervention.segment.v1` | `asset_id` | ingest-worker | `dispatch`, `intel-verify-scheduler`, `api-live` | 30 d | `spray.started`, `spray.stopped` (paired segment with litres, track, pm before/after) |
| `hawa.external.observation.v1` | `station_id` | feeds-worker | `ingest-calibration`, `intel-twin` | 30 d | `reference.observed` |
| `hawa.external.weather.v1` | `grid_point_id` | feeds-worker | `intel-twin`, `intel-forecast` | 30 d | `weather.observed`, `weather.forecasted` |
| `hawa.external.fire.v1` | `tile_id` | feeds-worker | `intel-attribution` | 30 d | `fire.detected` |
| `hawa.cmd.twin.v1` | `"twin"` | scheduler | `intel-twin` | 1 d | `cmd.twin.rebuild` (data = `{as_of, window_min: 60, advection: true}`) |
| `hawa.cmd.forecast.v1` | `"forecast"` | scheduler | `intel-forecast` | 1 d | `cmd.forecast.run` (data = `{issued_at, horizons: [1..72], master: bool}`) |
| `hawa.cmd.plan.v1` | `ward_id` | scheduler, api (on-demand), intel-worker (`intel-spike`, and `intel-plan` in spike mode on `twin.updated`) | `intel-plan` | 1 d | `cmd.plan.draft` (data = `{plan_id, mode, ward_ids, window_start, window_end, asset_ids?, focus_hotspot_ids?, requested_by}`) |
| `hawa.cmd.verify.v1` | `intervention_id` | scheduler (delayed scan), dispatch-worker | `intel-verify` | 7 d | `cmd.verify.run` (data = `{intervention_id, stage: provisional \| final, requested_by}`; provisional at `end_ts + 2 h`, final at `end_ts + 4 h`, see §10.3) |
| `hawa.cmd.train.v1` | `model` | scheduler | `intel-trainer` | 7 d | `cmd.train.run` (data = `{model: forecaster|fingerprint|calibration|effectiveness|site_score}`) |
| `hawa.cmd.dispatch.v1` | `"dispatch"` | scheduler | `dispatch` | 1 d | `cmd.dispatch.release` (05:30 master-plan release), `cmd.dispatch.sweep` (every minute: timeouts, missed windows, plan expiry, stuck drafts) |
| `hawa.cmd.alert.v1` | `"alert"` | scheduler | `alert-engine` | 1 d | `cmd.alert.school_run` (data = `{phase: draft \| final \| morning, date}`) |
| `hawa.cmd.maintenance.v1` | `"maintenance"` | scheduler | `archiver` | 1 d | `cmd.partitions.maintain`, `cmd.snapshot.freeze` |
| `hawa.cmd.report.v1` | `"report"` | scheduler, api | `evidence-report` (backend), `intel-report` (AI-ML narrative) | 7 d | `cmd.evidence_report.build` (data = `{report_id, period_start, period_end, ward_ids}`) |
| `hawa.evidence.report.v1` | `report_id` | intel-worker | `evidence-report` | 30 d | `evidence_report.narrative_ready` (narrative JSON at `s3://hawa-{env}-reports/evidence/{report_id}/narrative.json`) |
| `hawa.twin.updated.v1` | `"twin"` | intel-worker | `api-cache`, `api-live`, `intel-plan` (spike mode) | 3 d | `twin.updated` (data = `{run_id, as_of, tile_version, cells_updated, bbox, model_version}`) |
| `hawa.hotspot.updated.v1` | `ward_id` | intel-worker | `api-cache`, `api-live`, `alert-engine` | 7 d | `hotspot.updated` (data = ranked list summary + ids) |
| `hawa.forecast.issued.v1` | `"forecast"` | intel-worker | `api-cache`, `alert-engine`, `api-live` | 7 d | `forecast.issued`, `grap.outlook_issued`, `school.safe_window_computed` |
| `hawa.plan.lifecycle.v1` | `plan_id` | intel-worker (drafted/failed), api (edited/approved/rejected), dispatch-worker (dispatched/in_progress/completed) | `api-live`, `dispatch`, `audit` | 30 d | `plan.drafting`, `plan.drafted`, `plan.failed`, `plan.edited`, `plan.approved`, `plan.rejected`, `plan.expired`, `plan.dispatched`, `plan.in_progress`, `plan.completed` |
| `hawa.task.lifecycle.v1` | `plan_id` | dispatch-worker, api (app status updates) | `api-live`, `notifier`, `intel-verify-scheduler`, `audit` | 30 d | `task.dispatched`, `task.acknowledged`, `task.en_route`, `task.in_progress`, `task.done`, `task.skipped`, `task.missed`, `task.cancelled`, `task.verifying`, `task.verified`, `task.inconclusive` |
| `hawa.alert.requested.v1` | `recipient_id` | api, dispatch-worker, alert-engine | `notifier` | 7 d | `alert.requested` (data = `{alert_id, audience, kind, channels[], recipient, lang, title, body, deep_link, expires_at}`) |
| `hawa.alert.delivery.v1` | `alert_id` | notifier | `api-alert-status` | 7 d | `alert.sent`, `alert.delivered`, `alert.failed`, `alert.read` |
| `hawa.impact.verified.v1` | `intervention_id` | intel-worker | `api-cache`, `api-live`, `dispatch` | 90 d | `impact.verified` |
| `hawa.report.lifecycle.v1` | `report_id` | api (submitted), intel-worker (verified/rejected), dispatch-worker (ticketed), api (closed) | `intel-vision`, `dispatch`, `notifier`, `api-live` | 90 d | `report.submitted`, `report.verified`, `report.rejected`, `report.ticketed`, `report.closed` |
| `hawa.integrity.flag.v1` | `subject` | intel-worker | `api-live`, `audit` | 30 d | `integrity.flagged` |
| `hawa.audit.v1` | `actor_id` | all services | `audit-writer` | 365 d | `audit.recorded` (human and agent actions: approve, edit, override, login, device registration) |
| `hawa.dlq.v1` | original key | any consumer after retries | `ops` | 14 d | original envelope + headers `hawa-dlq-topic`, `hawa-dlq-group`, `hawa-dlq-error` |
| `hawa.logs.v1` | service name | **logifyx** Kafka handler (Avro via Schema Registry) | log sink (S3 / OpenSearch via Kafka Connect) | 7 d | logifyx log records |

### 5.3 Key payloads (the `data` field)

`reading.cleaned`
```json
{
  "device_id": "HPM-0142", "seq": 88214, "ts": "2026-11-12T01:14:30Z",
  "lat": 28.6331, "lon": 77.2194, "cell_id": "g500-041-077", "speed_kmh": 14.2,
  "pm25_raw": 212, "pm25": 164.3, "pm10_raw": 318, "pm10": 271.0, "pm1": 118.0,
  "no2_ppb": 61, "co_ppb": 1840, "voc_kohm": 38, "t": 17.8, "rh": 82, "p": 1015,
  "calibration_version": 7, "trust": 0.86, "weight": 0.74, "flags": ["heater_on"],
  "is_simulated": true
}
```

`spray.stopped`
```json
{
  "segment_id": "HTG-0031-5521", "asset_id": "AST-SPR-0012", "device_id": "HTG-0031",
  "task_id": "…uuid…|null", "intervention_id": "…uuid…",
  "start_ts": "2026-11-13T00:41:10Z", "end_ts": "2026-11-13T00:58:40Z",
  "litres": 612.3, "track": { "type": "LineString", "coordinates": [[77.2095, 28.6412], [77.2130, 28.6420]] },
  "cell_ids": ["g500-042-076", "g500-042-077"],
  "pm_before": { "pm25": 188, "pm10": 402 }, "pm_after": { "pm25": 181, "pm10": 331 },
  "is_simulated": true
}
```

`plan.drafted`
```json
{
  "plan_id": "…", "mode": "master", "ward_ids": ["ward-084"], "window_start": "…", "window_end": "…",
  "task_count": 14,
  "expected_exposure_avoided_ph": { "p10": 12900.0, "p50": 18450.0, "p90": 23100.0 },
  "baseline_exposure_avoided_ph": { "p10": 4800.0, "p50": 7120.0, "p90": 9300.0 },
  "auditor_verdict": "approve_with_changes", "objections": 2, "blocking_objections": 0,
  "is_fallback": false, "model_versions": { "optimizer": "…", "planner": "…" }
}
```

`is_fallback = true` means the agents timed out or refused and the plan carries deterministic templated reasons (the pipeline never blocks on an LLM).

`impact.verified`
```json
{
  "impact_id": "…", "intervention_id": "…", "task_id": "…", "cell_id": "g500-042-077",
  "pollutant": "pm10", "effect_pct": -18.2, "ci_low": -26.0, "ci_high": -9.9,
  "duration_min": 90, "method": "synthetic_control", "verdict": "effective",
  "stage": "final", "evidence_level": "high",
  "donor_cells": ["g500-045-070", "g500-039-081"], "placebo_p": 0.04, "model_version": "verifier@1.0.0+a1b2c3d"
}
```

Full Pydantic definitions: `backend/contracts/hawa_contracts/events/*.py`.

---

## 6. Public REST + WebSocket surface (index)

Owned by `backend/`. Full request/response shapes: [backend/API.md](backend/API.md). OpenAPI served at `/openapi.json`; the web and Flutter clients are generated from it.

Base URL: `/v1` (authenticated), `/open/v1` (public, rate-limited). Auth: `Authorization: Bearer <JWT>`.
Errors: RFC 9457 `application/problem+json` → `{type, title, status, detail, instance, code, errors?[]}`.
Pagination: cursor → `?limit=50&cursor=…` → `{items: [...], next_cursor: "…" | null}`.
Headers: `X-Request-Id`, `X-Correlation-Id` (echoed), `Idempotency-Key` accepted on all `POST`s that create or change state.

| Area | Endpoint | Roles | Purpose (§9.3 origin marked ★) |
|---|---|---|---|
| Auth | `POST /v1/auth/login` | officer, admin, analyst | Email + password |
| | `POST /v1/auth/otp/request`, `POST /v1/auth/otp/verify` | driver, inspector, school, site_manager, citizen | Phone OTP |
| | `POST /v1/auth/refresh`, `POST /v1/auth/logout`, `GET /v1/me`, `PUT /v1/me/push-token` | all | Session + FCM token |
| Twin | ★ `GET /v1/twin?bbox=&ts=` | officer+, public (coarse) | Cell values + confidence (GeoJSON) |
| | `GET /v1/twin/tiles/{z}/{x}/{y}.mvt?ts=&v={tile_version}` | officer+ | Vector tiles (PostGIS `ST_AsMVT`); `ts` snaps to the latest run ≤ `ts`; `v` is the cache-buster; response header `X-Twin-As-Of` |
| | `GET /v1/twin/latest`, `GET /v1/twin/runs?from=&to=` | officer+ | Current run pointer `{run_id, as_of, tile_version, model_version, bbox, cells_updated, sim_share}` and run history |
| | `GET /v1/cells/{cell_id}`, `GET /v1/cells/{cell_id}/history?from=&to=` | officer+ | Cell detail and series |
| Hotspots | ★ `GET /v1/hotspots?ward=&limit=` | officer+ | Ranked by exposure, with cause, suspect pin |
| | `GET /v1/hotspots/{id}` | officer+, inspector | Detail + evidence + back-trajectory |
| Forecast | ★ `GET /v1/forecast/{cell_id}` | officer+, school | 72 h P10/P50/P90 + GRAP |
| | `GET /v1/forecast/grid?horizon_h=&issued_at=` | officer+ | Forecast map layer |
| | `GET /v1/grap/outlook?ward=&days=3`, `GET /v1/grap/checklist?ward=&stage=` | officer+ | GRAP Copilot (F6) |
| Plans | ★ `POST /v1/plans/draft` → `202` | officer | Run optimiser + agents (async) |
| | `GET /v1/plans?status=&ward=`, `GET /v1/plans/{id}` | officer+ | List / detail with agent reasons |
| | `PATCH /v1/plans/{id}` | officer | Edit tasks while `draft` |
| | ★ `POST /v1/plans/{id}/simulate` | officer | What-If vs baseline (person-hours avoided) |
| | ★ `POST /v1/plans/{id}/approve`, `POST /v1/plans/{id}/reject` | officer | Human-in-the-loop gate |
| Tasks (app) | `GET /v1/tasks/mine?date=` | driver, inspector | Today's route / targets |
| | `GET /v1/tasks/{id}`, `POST /v1/tasks/{id}/ack`, `POST /v1/tasks/{id}/status` | driver, inspector | Acknowledge, en-route, manual done/skip fallback |
| | `POST /v1/tasks/{id}/evidence` | inspector | Outcome + photos |
| Fleet & devices | `GET /v1/assets`, `GET /v1/assets/{id}`, `GET /v1/fleet/live` | officer+ | Machines + live positions |
| | `GET /v1/devices`, `GET /v1/devices/{id}`, `POST /v1/devices`, `GET /v1/devices/{id}/calibration` | admin, analyst | Registry + calibration history |
| Interventions | `GET /v1/interventions?from=&to=&asset=`, `GET /v1/interventions/{id}` | officer+ | Logged sprays |
| | ★ `GET /v1/interventions/{id}/impact` | officer+ | Verified effect ± CI |
| | `GET /v1/impact/summary?ward=&from=&to=`, `GET /v1/effectiveness?cause=&asset_type=` | officer+ | Library + roll-ups |
| Alerts | `GET /v1/alerts`, `GET /v1/alerts/{id}`, `POST /v1/alerts` | officer+; recipients see their own | Targeted alerts (F16) |
| Schools | `GET /v1/schools/me`, `GET /v1/schools/{id}/safe-window?date=`, `GET /v1/schools/{id}/indoor-outdoor?from=&to=` | school, officer+ | F19 |
| Citizen Eyes | ★ `POST /v1/reports`, `GET /v1/reports/mine`, `GET /v1/reports/{id}` | citizen | F20. **Primary:** JSON after presigned upload `{client_report_id, s3_key, lat, lon, location_accuracy_m, captured_at, category, note}` (Flutter). Multipart with the same field names is also accepted (web). Time field is **`captured_at`**. `client_report_id` is unique → safe offline replay beyond the 24 h Idempotency-Key window. |
| | ★ `POST /v1/reports/webhook/whatsapp`, `GET /v1/reports/webhook/whatsapp` (verify) | Meta (signed) | WhatsApp intake |
| Inspections | `GET /v1/inspections?status=`, `POST /v1/inspections/{id}/close` | officer, inspector | Tickets from reports / spikes |
| Sites | `GET /v1/sites?grade=`, `GET /v1/sites/{id}`, `GET /v1/sites/me` | officer+, site_manager | F9 |
| Integrity & coverage | `GET /v1/integrity/flags`, `GET /v1/coverage/blind-spots` | officer+, analyst | F15, F11 |
| Evidence reports | `GET /v1/evidence-reports`, `POST /v1/evidence-reports`, `GET /v1/evidence-reports/{id}/pdf` | officer+ | F22 |
| Uploads | `POST /v1/uploads/presign` | authenticated | S3 **presigned POST** (policy: 5 min, ≤ 8 MB, JPEG/PNG/HEIC/WebP); body `{purpose: report_photo \| inspection_photo \| task_photo, content_type, size_bytes}` |
| Models | `GET /v1/models` | admin, analyst | Proxies `/internal/v1/models` (the web never calls internal endpoints) |
| Open data | ★ `GET /open/v1/air?bbox=&ts=`, `GET /open/v1/stations`, `GET /open/v1/cells/{cell_id}/history`, `GET /open/v1/methods` | public (Redis rate-limited) | F21 |
| Ops | `GET /healthz`, `GET /readyz`, `GET /metrics` | infra | Probes + Prometheus |

### 6.1 WebSocket

`GET /v1/ws` — authenticate with `Sec-WebSocket-Protocol: bearer, <JWT>` (browser) or `?token=` (Flutter). Messages are JSON.

Client → server: `{"op": "subscribe", "channels": ["twin", "hotspots:ward-084", "plan:<id>"]}`, `{"op": "unsubscribe", ...}`, `{"op": "ping"}`.
Server → client: `{"channel": "twin", "type": "twin.updated", "data": {...}, "ts": "…"}` (same `type` and `data` as the Kafka event, with sensitive fields removed).

| Channel | Who | Fed by |
|---|---|---|
| `twin` | officer+ | `hawa.twin.updated.v1` (client refetches tiles with the new `tile_version`) |
| `hotspots:{ward_id}` | officer+ | `hawa.hotspot.updated.v1` |
| `fleet` | officer+ | Redis GEO updates from `hawa.telemetry.clean.v1` (TAG + vehicle positions), throttled to 1 Hz |
| `devices` | admin, analyst | `hawa.device.event.v1` |
| `plan:{plan_id}` | officer+ | `hawa.plan.lifecycle.v1` + `hawa.task.lifecycle.v1` |
| `tasks:me` | driver, inspector | `hawa.task.lifecycle.v1` filtered to the user's assets |
| `alerts:me` | any authenticated | `hawa.alert.requested.v1` filtered to the user |
| `impact` | officer+ | `hawa.impact.verified.v1` |

---

## 7. Internal AI-ML service surface

Owned by `AI-ML/`. Reachable only on the private network; authenticated with a service token (`Authorization: Bearer <HAWA_INTERNAL_TOKEN>`). Details: [aiml/ARCHITECTURE.md](aiml/ARCHITECTURE.md).

| Endpoint | Caller | Purpose | Latency budget |
|---|---|---|---|
| `POST /internal/v1/simulate` | api (`/v1/plans/{id}/simulate`) | What-If: evaluate a plan and a baseline ("usual routes") against forecast exposure | p95 ≤ 3 s |
| `POST /internal/v1/optimize` | api (plan edits) | Re-run optimiser for an edited plan (greedy or CVRPTW with 5 s cap) | p95 ≤ 6 s |
| `POST /internal/v1/exposure` | api | Exposure score for a set of cells and time range | p95 ≤ 1 s |
| `POST /internal/v1/alerts/draft` | api alert-engine | Communicator drafts en + hi alert text; template fallback on timeout/refusal | p95 ≤ 4 s |
| `GET /internal/v1/models` | api only (exposed to web admin via `GET /v1/models`) | Active model versions + metrics | — |
| `GET /internal/v1/healthz`, `GET /metrics` | infra | Probe, Prometheus | — |

Asynchronous work (twin, attribution, forecast, plan drafting with agents, verification, photo verification, training) is **only** triggered through Kafka `hawa.cmd.*` / lifecycle topics, never through synchronous HTTP.

---

## 8. Database table ownership

One PostgreSQL 16 + PostGIS database, schema `hawa`. **Alembic in `backend/` owns every DDL change.** "Writer" = service allowed to `INSERT/UPDATE`. Everyone may read.

| Table | Purpose | Writer |
|---|---|---|
| `grid_meta`, `cell`, `cell_1k`, `ward` | Grid geometry (500 m / 1 km), wards, population, vulnerability weight, land use | backend seed (built by AI-ML `build_grid` script) |
| `cell_feature` | Static covariates (road density, construction permits, industrial share, green share) | AI-ML (feature build) |
| `poi` | Schools, hospitals, elder-care, markets, bus stops (OSM + registry) | backend seed |
| `school` | School profile, contact, linked HawaPod-S pair | backend |
| `device` | Registry: role, placement, vehicle/asset link, firmware, trust score, current calibration, `is_simulated` | backend (AI-ML updates `trust_score` via `device.trust_changed` event → backend applies) |
| `device_calibration` | Versioned `a, b, c` coefficients per device + fit stats | AI-ML |
| `reading` (partitioned by day) | Cleaned readings (raw + calibrated) | backend ingest-worker |
| `device_event` | Spike / tamper / health / boot | backend ingest-worker |
| `reference_station`, `reference_observation` | CPCB / DPCC / OpenAQ | backend feeds-worker |
| `weather_observation`, `weather_forecast`, `fire_point` | IMD/ERA5/Open-Meteo, NASA FIRMS | backend feeds-worker |
| `twin_run`, `cell_state` | Twin output per cell per run: `pm25_est`, `pm25_var`, `pm10_est`, `pm10_var`, `confidence`, `cause_label`, `cause_conf`, `exposure_ph`, `aqi`, `n_obs` | AI-ML |
| `hotspot` | Ranked clusters with cause, suspect pin, back-trajectory, exposure | AI-ML |
| `forecast_run`, `forecast` | Per 1 km cell, horizon 1–72 h, `p10/p50/p90`, `grap_stage` | AI-ML |
| `grap_outlook` | Per ward per day: stage + probability | AI-ML |
| `school_safe_window` | Per school per day: safe outdoor windows, seal/ventilate advice | AI-ML |
| `asset`, `asset_shift` | Machines and teams, depot, capacity, shifts | backend |
| `plan` | Plan header with `version` (optimistic concurrency, `ETag "v{n}"`). **API inserts** the row in `drafting` in the same transaction as the `cmd.plan.draft` outbox row; **AI-ML** upserts (`ON CONFLICT (id)`) and moves it `drafting` → `draft` / `failed`; **backend** owns every later transition (and emits `plan.failed` with `failure_reason: "timeout"` for drafts stuck > 10 min). A DB trigger stops `hawa_ml` changing plans outside `drafting`. | backend + AI-ML (state-partitioned) |
| `plan_task` | Tasks: asset, planning cell `cell_id` (`g1k`), **`target_cell_ids`** (`g500[]`, where the machine actually works and where impact is measured), kind, ETA window, order, `reason_text` (+ `reason_text_hi`), `expected_effect` `{p10,p50,p90}` | AI-ML inserts/edits while plan is `drafting`; backend updates status after |
| `dispatch_saga` (optional) | Saga state per plan. Default design derives saga state from `plan` / `plan_task` statuses and timestamps; add this table only if that proves insufficient | backend dispatch-worker |
| `asset_usual_route` | "Usual routes" baseline for What-If: `asset_id`, `route_geom`, `service_days`, `start_times`, `cell_ids`, `is_simulated` | backend seed |
| `plan_review` | Agent transcript summary: planner rationale, auditor objections, resolutions, tool calls | AI-ML |
| `plan_simulation` | What-If results (plan vs baseline) | AI-ML |
| `intervention` | Spray segments linked to task/asset, track, litres, pm before/after, `source`, `verify_after`, `verification_status`, `evidence_level` | backend ingest-worker / dispatch-worker; api for `source = manual` |
| `calibration_pair` | Paired device ↔ reference points collected for drive-by calibration | backend ingest-worker (`ingest-calibration`) |
| `impact` | Verified effect per intervention per pollutant | AI-ML |
| `effectiveness_library` | Effect priors by cause × asset type × land use × season × hour band | AI-ML |
| `alert`, `alert_delivery` | Alerts and per-channel delivery status | backend |
| `citizen_report` | Citizen Eyes intake + verification result | backend (AI-ML writes `verification` fields) |
| `inspection` | Tickets for inspectors | backend |
| `site`, `site_score` | Construction / units, A/B/C grade history | backend (`site`), AI-ML (`site_score`) |
| `integrity_flag` | Anti-gaming, drift, tamper flags | AI-ML |
| `coverage_gap` | Blind-spot cells + suggested route/rider | AI-ML |
| `evidence_report` | Weekly report metadata + S3 key | backend (AI-ML supplies narrative) |
| `app_user`, `refresh_token`, `push_token`, `user_ward_scope` | Auth and RBAC | backend |
| `audit_log` | Human + agent actions | backend audit-writer |
| `outbox_event`, `processed_event` | Transactional outbox, consumer idempotency | backend (+ AI-ML uses `processed_event`) |
| `model_version` | Mirror of the MLflow registry (active versions + metrics) | AI-ML |

---

## 9. Redis key namespaces

Prefix every key with `hawa:{env}:` (e.g. `hawa:local:`).

| Pattern | Type | Owner | TTL | Purpose |
|---|---|---|---|---|
| `cache:twin:{tile_version}:{bbox_hash}` | string (JSON) | api | 20 min | `/v1/twin` responses |
| `cache:tile:{tile_version}:{z}:{x}:{y}` | string (MVT bytes) | api | 20 min | vector tiles |
| `cache:hotspots:{ward_id}:{run_id}` | string | api | 20 min | ranked hotspots |
| `cache:forecast:{cell_id}:{issued_at}` | string | api | 75 min | forecast series |
| `cache:plan:{plan_id}:{version}` | string | api | 10 min | plan detail |
| `twin:version` | string (int) | api (from `twin.updated`) | — | current `tile_version`; bump invalidates twin/tile caches |
| `dedupe:pkt:{device_id}:{seq}` | string | ingest-worker | 73 h | packet dedupe (store-and-forward window + 1 h) |
| `dedupe:evt:{group}:{event_id}` | string | every consumer | 24 h | fast idempotency check (DB `processed_event` is the durable one) |
| `live:fleet` | GEO | ingest-worker | — | latest positions of assets and sensor vehicles |
| `live:device:{device_id}` | hash | ingest-worker | 1 h | last seen, last packet summary, flags |
| `rl:{scope}:{subject}:{window}` | string (counter) | api | window | rate limits (open data, OTP, login) |
| `otp:{phone_hash}` | hash | api | 5 min | OTP hash + attempts (key uses a hash of the E.164 number, never the raw number) |
| `jwt:deny:{jti}` | string | api | token TTL | revoked tokens |
| `lock:sched:{job}` | string | scheduler | job interval | single-leader scheduling |
| `lock:plan:{ward_id}` | string | intel-worker | 10 min | one plan draft per ward at a time |
| `ws:{channel}` | pub/sub | api (Kafka → Redis fan-out) | — | WebSocket broadcast across api replicas |
| `ml:feat:{name}:{key}` | string/hash | AI-ML | varies | feature caches (e.g. recent calibrated points) |
| `ml:model:{name}:active` | string | AI-ML | — | active model version pointer |

---

## 10. Air-quality reference tables

### 10.1 Indian National AQI (CPCB) sub-index breakpoints

The official AQI uses 24 h averages for PM. HawaCommand computes an **indicative hourly AQI** from twin values with the same breakpoints and **labels it "indicative"** everywhere. Sub-index is linear within a band.

| AQI band | Category | PM2.5 (µg/m³) | PM10 (µg/m³) | UI colour token |
|---|---|---|---|---|
| 0–50 | good | 0–30 | 0–50 | `aqi.good` |
| 51–100 | satisfactory | 31–60 | 51–100 | `aqi.satisfactory` |
| 101–200 | moderate | 61–90 | 101–250 | `aqi.moderate` |
| 201–300 | poor | 91–120 | 251–350 | `aqi.poor` |
| 301–400 | very_poor | 121–250 | 351–430 | `aqi.very_poor` |
| 401–500 | severe | > 250 | > 430 | `aqi.severe` |



### 10.2 GRAP stages (Delhi-NCR)

| Stage | Trigger (AQI) | Name |
|---|---|---|
| 1 | ≤ 200 | none |
| 2 | 201–300 | Stage I — Poor |
| 3 | 301–400 | Stage II — Very Poor |
| 4 | 401–450 | Stage III — Severe |
| 5 | > 450 | Stage IV — Severe+ |

The GRAP Copilot (F6) maps the P50 forecast (and the probability that P90 crosses a threshold) 24–48 h ahead to a stage, and produces a ward checklist of stage actions **before** formal invocation. The checklist text is config (`backend/src/hawa_backend/config/grap_actions.yaml`), not model output.

### 10.3 Thresholds used across services

| Name | Value | Used by |
|---|---|---|
| `C_SAFE_PM25` | 60 µg/m³ (India 24 h NAAQS) | exposure engine |
| `C_SAFE_PM10` | 100 µg/m³ | exposure engine (dust hotspots) |
| School alert trigger | forecast P50 PM2.5 > 250 µg/m³ in school hours, or GRAP ≥ 3 | alert-engine (Flow C) |
| Spike (edge + cloud) | PM2.5 ≥ 3 × rolling 5-min baseline within 20 s | firmware TinyML, ingest double-check |
| Calibration pairing | device within 200 m of a reference station, speed < 10 km/h, wind ≤ 3 m/s, ≥ 20 paired 1-min points | AI-ML calibration |
| High-speed down-weight | > 60 km/h | twin |
| Spray detected | flow > 5 lpm and pump current > 2 A for ≥ 10 s | ingest (HawaTag) |
| Verification window | effect window fixed in advance: 0–4 h after `end_ts`; donors fitted on the 6 h before `start_ts`. **Provisional** run at `end_ts + 2 h` (0–2 h data, `stage = provisional`), **final** run at `end_ts + 4 h` (`stage = final`). Only final results feed the effectiveness library. The naive before/after fallback can never yield `effective`. | AI-ML verifier |
| Hotspot | cell `exposure_ph` in top 5 % **or** indicative AQI ≥ 301 with confidence ≥ 0.5 | AI-ML |

### 10.4 Exposure formula (§9.4, F12)

```
E(cell, t) = max(0, C(cell, t) − C_safe) × Pop(cell, t) × V(cell) × Δt
```

- `Pop(cell, t)` varies by hour (schools weighted in the morning, markets in the evening; WorldPop 100 m base).
- `V(cell)` = 1.0 residential; higher near schools, hospitals, elder-care (config `vulnerability_weights.yaml`).
- The planner **minimises total forecast E**. Units: µg/m³ · person · h, reported as "person-hours above threshold" with the concentration excess shown alongside.

---

## 11. Schedules

All IST. Implemented by the backend `scheduler` publishing `hawa.cmd.*` events. Cron strings are in the scheduler config.

| Job | Cron (IST) | Emits |
|---|---|---|
| Twin rebuild + attribution | `*/15 * * * *` | `cmd.twin.rebuild` |
| Forecast | `5 * * * *` (master at `0 17 * * *`) | `cmd.forecast.run` |
| Re-plan | `0 8,11,14 * * *` | `cmd.plan.draft` (`mode=replan`) |
| Data freeze snapshot | `0 16 * * *` | internal (S3 snapshot) |
| Master plan | `30 18 * * *` | `cmd.plan.draft` (`mode=master`, window next day 05:30–11:00) |
| School alerts | `0 19 * * *` draft+send, `0 22 * * *` final safe windows | alert-engine run |
| Plan expiry check | `*/10 * * * *` | `plan.expired` for unapproved drafts past their first window |
| Dispatch | `30 5 * * *` | dispatch-worker releases approved master-plan tasks |
| Verification scan | `*/10 * * * *` + batch `0 11 * * *` | `cmd.verify.run` for interventions with `verify_after ≤ now` |
| External feeds | CPCB/OpenAQ `*/15`, weather `0 *`, FIRMS `0 */3` | feeds-worker internal |
| Nightly learn | `0 2 * * *` | `cmd.train.run` × (forecaster, calibration, effectiveness, site_score) |
| Weekly evidence report | `0 7 * * 1` | `cmd.evidence_report.build` |
| Reading partitions | `0 1 * * *` | create next 7 days of partitions, drop > 90 d (archived to S3 first) |

---

## 12. Versioning and change rules

1. **MQTT packets** carry `v`. A breaking change means `v: 2` and a new topic prefix `hawa/v2/…`; ingest supports both for one release.
2. **Kafka topics** carry `.v{major}` in the name; the envelope carries `version`. Additive fields = same version. Removing/renaming a field = new topic `.v2`, dual-publish during migration.
3. **REST** is versioned by path (`/v1`). Additive changes only within `v1`. Deprecations use the `Deprecation` and `Sunset` headers.
4. **DB** changes only via Alembic revisions reviewed by the backend lead; AI-ML contract tests must pass.
5. **Enums** are additive. Clients must treat unknown enum values as `unknown` and render them neutrally, never crash.
6. **Model outputs** always record `model_version`; changing an output's meaning requires a new major model version.

---

## 13. Contracts v1.1: merged additions from the area docs

The four area doc sets proposed additions while being written. The ones below are **accepted**, and the area doc named in the right column holds the detailed spec. Names here win over any older spelling elsewhere.

### 13.1 Decisions on conflicts

| Topic | Decision |
|---|---|
| Report photo time field | `captured_at` (not `taken_at`) |
| Upload mechanism | S3 **presigned POST** (§6) |
| Report create | JSON after presign (primary), multipart accepted; unique `client_report_id` (§6) |
| Plan row creation | API inserts `drafting`; AI-ML upserts and completes (§8). `GET /v1/plans/{id}` never 404s after a `202` |
| Plan/impact granularity | plans on `g1k`, work + impact on `g500` via `plan_task.target_cell_ids` (§8) |
| Verification timing | provisional + final stages (§5.2, §10.3) |
| Inspection close | only `POST /v1/inspections/{id}/close` (§3 note) |
| Multi-role users | `roles[]` in JWT and `GET /v1/me`, `POST /v1/auth/switch-role` |
| Idempotency window | Redis `idem:{user_id}:{key}` 24 h; offline replays beyond that rely on client-generated ids and idempotent state transitions (`already_in_state`, `transition_already_past`) |
| Uncertainty on derived numbers | exposure and plan totals are `{p10, p50, p90}`; `cell_state` and `hotspot` gain `exposure_ph_p10`, `exposure_ph_p90`, `cause_probs` |
| Simulated share | derived tables (`cell_state`, `hotspot`, tiles, forecasts) carry `sim_share` (0–1); UI shows "Simulated" when > 0 |
| Deep links | `hawa://{entity}/{id}[/{sub}]`; the app maps them to routes |
| Git hooks | one manager for the repo: **Husky at the repo root** calls `frontend` lint-staged, `app_frontend/tool/hooks/pre_commit.sh` and Python `pre-commit run` for changed paths |
| Reading uniqueness | `(device_id, seq, ts)`: Postgres needs the partition key in the constraint; dedupe is Redis `dedupe:pkt:` checked before insert and set after commit, plus deterministic UUIDv7 `event_id`s for ingest-derived events |
| Kafka on AWS | **MSK provisioned** (`kafka.t3.small` × 2–3), not Serverless: the IoT Rule Kafka action needs SASL/SCRAM (port 9096), which Serverless lacks. Services use IAM auth. Demo "Tier A" = one EC2 running the compose stack with mqtt-bridge subscribed to IoT Core |
| logifyx → Kafka on AWS | logifyx 2.0.0 has no Kafka security options, so on AWS `hawa.logs.v1` is off and logs go stdout → CloudWatch until logifyx adds producer security kwargs (local/demo keep Kafka logging) |
| Schedules | the backend scheduler emits `cmd.dispatch.sweep` every minute (absorbs plan expiry and the 10-min drafting timeout), `cmd.dispatch.release` at 05:30, `cmd.alert.school_run` at 19:00 / 22:00 (06:30 optional), `cmd.maintenance.*` at 16:00 / 01:00 |
| OTP key | `otp:{phone_hash}` (no raw phone numbers in Redis keys) |
| Open data licence | **open question for the leads** (CC BY 4.0 vs ODbL) |

### 13.2 Additions by area

| Area | Additions | Detailed in |
|---|---|---|
| Plans | `PATCH /v1/plans/{id}` with `{base_version, ops[]}` + `If-Match` (ops `move \| reassign \| retime \| remove \| add \| resolve_objection \| lock`, returns `violations[]`); `GET /v1/plans/{id}/versions`; `POST /v1/plans/{id}/reoptimize`; `GET /v1/plans/{id}/simulation?version=`; approve `{version, note?}`, reject `{version, reason, redraft?}`; 409 codes `plan_version_conflict`, `plan_not_draft`, `unresolved_blocking_objections`; `version` on every `plan.*` event | [backend/API.md](backend/API.md) |
| Impact | `GET /v1/interventions/{id}/impact` returns `series[]{ts, treated, synthetic, synthetic_low, synthetic_high}`, `ci_level`, `spray`, `pre_period{rmse}`, `donors[]{cell_id, weight}`, `stage`, `evidence_level`, `injected_effect_pct` (simulated only); `intervention` gains `verify_after`, `verification_status`, `evidence_level`, `injected_effect_pct` | [aiml/ARCHITECTURE.md](aiml/ARCHITECTURE.md) |
| Map data | `GET /v1/fleet/trails`, `GET /v1/pois?bbox=&kind=`, `GET /v1/wards`, `GET /v1/coverage/summary` | [frontend/ARCHITECTURE.md](frontend/ARCHITECTURE.md) |
| Officer admin | `GET /v1/schools?ward=`, `GET /v1/reports?status=&ward=`, `POST /v1/inspections`, `POST /v1/inspections/{id}/assign`, `GET/POST /v1/users`, `PATCH /v1/users/{id}`, `PUT /v1/users/{id}/ward-scopes`, `POST /v1/alerts/preview` | [backend/API.md](backend/API.md) |
| Field app | shifts `POST /v1/shifts/{id}/start \| end \| locations`; `PATCH /v1/me {lang, notification_prefs}`; `POST /v1/alerts/{id}/ack`; `GET /v1/inspections/{id}` (evidence bundle); `POST /v1/inspections/{id}/on-site`; `GET/PUT /v1/me/alert-subscription`; `DELETE /v1/me/push-token`; OTP `channel: sms \| whatsapp`; `tasks/mine` returns `shift`, `route{route_id, version, geometry, bbox}`, `asset{tag_status, tag_last_seen_at}` and per-stop `sequence, window_start, window_end, place_name{en,hi}, instructions{en,hi}, completion_source` | [app/ARCHITECTURE.md](app/ARCHITECTURE.md) |
| Public | `GET /open/v1/reports/{public_code}` (+ `citizen_report.public_code`); open air items add `dominant_pollutant, confidence, cause_label, cause_conf, aqi_category, is_simulated`; `include_simulated` param | [backend/API.md](backend/API.md) |
| Auth | `GET /v1/auth/jwks.json`; login/refresh body `{access_token, refresh_token, expires_in, token_type, user}`; CORS allows `Authorization, Content-Type, Idempotency-Key, If-Match, X-Request-Id, X-Correlation-Id` and exposes `X-Request-Id, X-Correlation-Id, ETag, Retry-After, X-Twin-As-Of` | [backend/API.md](backend/API.md) |
| WebSocket | server echoes `Sec-WebSocket-Protocol: bearer`; messages carry `event_id` + per-connection `seq`; `sys` channel (`subscribed, unsubscribed, ping, pong, resync, token_expiring, error`); client ops `pong`, `auth`; `fleet.positions` message `{id, kind, asset_type?, device_id?, position:[lon,lat], heading_deg, speed_kmh, status, spraying, ts, is_simulated}`; new channels `forecast`, `plans:{ward_id}`, `alerts`, `reports`, `integrity`; close codes 4400, 4401, 4403, 4408, 4429, 1013 | [backend/API.md](backend/API.md) |
| Events | intel-worker produces `device.calibrated` / `device.trust_changed`; api produces WhatsApp delivery statuses on `hawa.alert.delivery.v1`; `task.updated` on `hawa.task.lifecycle.v1`; `task.verified` carries the impact summary; payloads for `hotspot.updated`, `grap.outlook_issued`, `school.safe_window_computed`, `report.verified/rejected`, `integrity.flagged` | [aiml/ARCHITECTURE.md](aiml/ARCHITECTURE.md) |
| Database | partition `cell_state` and `forecast` by day and `audit_log` by month; sequence `hawa.tile_version_seq`; per-service DB roles (`hawa_api`, `hawa_ingest`, `hawa_feeds`, `hawa_dispatch`, `hawa_notifier`, `hawa_outbox`, `hawa_scheduler`, `hawa_ml`, `hawa_analytics`, `hawa_migrator`); `hawa_ml` writes only AI-ML tables, their columns on `citizen_report`, `processed_event` and `outbox_event` | — |
| Redis | `idem:{user_id}:{key}` (24 h), `lock:cache:{key_hash}`, `cache:open:{endpoint}:{tile_version}:{params_hash}`, `cache:grap:{ward_id}:{issued_at}`, `cache:forecast_grid:…`, `cache:impact_summary:…`, `cache:effectiveness:{query_hash}`, pointers `twin:run_id` / `forecast:issued_at`, pub/sub `ws:user:{user_id}`, `wa:conv:{sha256(wa_id)}` | — |
| IDs | weather point `wx-{source}-{lat:.2f}-{lon:.2f}`, FIRMS tile `firms-{lat0.5}-{lon0.5}`, grid `delhi-{year}-v{n}` | — |
| AI-ML | water-machine hard gate: `P(dust) ≥ 0.5`, `P(burning) + P(regional_smoke) < 0.3`, cell confidence ≥ 0.3; shared `hawa_contracts.quality.reading_weight(trust, speed_kmh, flags)`; simulator ground truth at `s3://hawa-{env}-lake/sim/truth/` (read only by evaluation code); `cmd.train.run` adds `twin_eval`, `verifier_eval` | [aiml/ARCHITECTURE.md](aiml/ARCHITECTURE.md) |
| Errors | canonical code catalogue in [backend/API.md §1.5](backend/API.md); problem `type` = `urn:hawa:problem:<code>`; app-branching codes `otp_invalid, otp_expired, otp_rate_limited, already_in_state, transition_already_past, task_already_done, task_cancelled, inspection_already_closed, upload_expired, media_too_large` | [backend/API.md](backend/API.md) |
| Privacy | the API never returns other users' phone numbers to app roles, not even masked | — |

<!-- footer:start -->

---

[Back to top](#hawacommand--shared-contracts) · [Docs hub](README.md) · [Project README](../README.md)

<!-- footer:end -->
