# Backend Context

> **Status (reconciled 2026-10-10).** Product context from the proposal. As built, the backend is one FastAPI process that bridges to AI-ML, serves live WAQI/OpenAQ stations, keeps plans in memory and returns fixtures for devices, alerts and the driver route. Postgres, Kafka, Redis, WebSocket, auth endpoints and workers are Planned. See [docs/backend/README.md](README.md#1-implementation-status).


What the backend must do for HawaCommand and why, taken from the proposal (Proposal v3, 27 Sep 2026) and turned into backend requirements.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [EVENTS](EVENTS.md) · [DATA_MODEL](DATA_MODEL.md) · [API](API.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. The backend in one paragraph

HawaCommand is a closed loop: Sense → Map → Attribute → Forecast → Decide → Act → Verify, running every 3 hours plus an evening master plan (§5). The backend is the loop's **nervous system**. It ingests every packet from the edge and every external feed, stores them, triggers each analytical stage on schedule, serves the results to officers, drivers, schools and citizens, enforces the officer approval gate, turns approved plans into tasks and messages, detects when a machine actually sprayed, and makes sure every intervention reaches the verifier. The analytical stages (calibration fitting, twin, fingerprint, forecast, exposure, optimiser, agents, verifier) live in `AI-ML/` and talk to the backend only through Kafka, the shared database and a small internal REST surface ([CONTRACTS §7](../CONTRACTS.md#7-internal-ai-ml-service-surface)).

## 2. Backend role in each loop step

| Step (§5.1) | What happens | Backend does | AI-ML does | Backend artefacts |
|---|---|---|---|---|
| 1 Sense | Pods on buses and bikes, school sentinels, HawaTags, CPCB/OpenAQ, weather and FIRMS stream in | MQTT bridge, validate, dedupe, **apply** current calibration, cell lookup, store readings, spray segments, feed polling, drive-by **pairing** (F3) | Fits calibration coefficients, trust score | `mqtt-bridge`, `ingest-worker`, `feeds-worker`; `reading`, `device_event`, `intervention`, `reference_observation`, `weather_*`, `fire_point` |
| 2 Map | 500 m twin with a value and a confidence per cell | Schedules `cmd.twin.rebuild` every 15 min; serves GeoJSON and vector tiles; versioned cache; WebSocket `twin` | GP + wind advection → `cell_state` | `scheduler`, `api` (`/v1/twin`, tiles), Redis `twin:version` |
| 3 Attribute | Cause label + upwind suspect pin | Serves hotspots with cause, confidence, suspect pin; pushes `hotspots:{ward_id}` | Fingerprint + back-trajectory → `hotspot` | `/v1/hotspots`, `hawa.hotspot.updated.v1` consumers |
| 4 Forecast | 72 h P10/P50/P90 per 1 km cell, GRAP stage | Schedules hourly + 17:00 master forecast; serves series; GRAP Copilot checklist from config (F6) | LightGBM per horizon → `forecast`, `grap_outlook` | `/v1/forecast/*`, `/v1/grap/*`, `config/grap_actions.yaml` |
| 5 Decide | Exposure-first plan, agents explain and critique, officer approves | Draft request API, What-If proxy with circuit breaker, plan edit and **approval gate**, audit trail | Exposure engine, OR-Tools, Planner + Auditor agents → `plan`, `plan_task`, `plan_review`, `plan_simulation` | `/v1/plans/*`, `hawa.cmd.plan.v1`, `hawa.plan.lifecycle.v1` |
| 6 Act | Drivers get routes, inspectors get targets, schools and citizens get warnings | Dispatch saga, asset assignment, notifier (push / WhatsApp / SMS / in-app), school alert engine (Flow C), inspection tickets | Communicator agent drafts alert wording | `dispatch-worker`, `notifier`, `alert-engine`; `alert`, `alert_delivery`, `inspection` |
| 7 Verify | Tracker logs the spray; synthetic control measures the effect | Spray segment detection and task matching, `intervention` records, `verify_after` scheduling, `cmd.verify.run`, task → `verified`, impact API | Synthetic control → `impact`, effectiveness library | `hawa.intervention.segment.v1`, `hawa.cmd.verify.v1`, `/v1/interventions/{id}/impact` |
| Learn | Nightly retrain, library update, site scores | Schedules `cmd.train.run` at 02:00; weekly evidence report PDF (F22) | Trainer, `effectiveness_library`, `site_score` | `hawa.cmd.train.v1`, `evidence-report` |

## 3. Users and flows the backend serves (§7)

| User | Surface | Backend endpoints and channels ([API.md](API.md)) | Backend guarantees |
|---|---|---|---|
| Ward / district officer (MCD, DPCC) | Web console | `/v1/twin`, `/v1/hotspots`, `/v1/forecast`, `/v1/grap/*`, `/v1/plans/*`, `/v1/interventions/*`, `/v1/impact/summary`, WS `twin`, `hotspots:{ward_id}`, `plan:{id}`, `fleet`, `impact` | Ward-scoped data; one-click approve; every edit and approval audited |
| Admin / analyst | Web console | `/v1/devices/*`, calibration history, `/v1/integrity/flags`, `/v1/coverage/blind-spots`, `/v1/evidence-reports`, WS `devices` | Device registry, trust and calibration visibility |
| Driver / field team | Flutter app, SMS/WhatsApp fallback | `POST /v1/auth/otp/*`, `GET /v1/tasks/mine`, `POST /v1/tasks/{id}/ack`, `/status`, WS `tasks:me`, push | "A clear route and nothing else"; HawaTag confirms the spray automatically; manual fallback only when the tag is missing |
| Inspector | Flutter app | `GET /v1/tasks/mine`, `/v1/hotspots/{id}` (evidence), `POST /v1/tasks/{id}/evidence`, `POST /v1/inspections/{id}/close` | A target (suspect pin + evidence), not an area |
| School principal | Flutter app + WhatsApp | `GET /v1/schools/me`, `/safe-window`, `/indoor-outdoor`, WhatsApp alerts | Alert before the spike with a concrete safe window (Flow C), in Hindi or English |
| Citizen / outdoor worker | Flutter app + WhatsApp, public map | `POST /v1/reports`, WhatsApp webhook, `GET /v1/reports/mine`, `alerts:me` | Photo report → outcome message (Flow D); pollutant-specific advice |
| Site manager | Flutter app (read-only) + web | `GET /v1/sites/me` | Own grade and PM10 trend only |
| Public / researchers | Open data portal | `/open/v1/*` | Rate-limited, calibrated, methods published, simulated data labelled |

### 3.1 Flows as backend sequences

| Flow (§7.1) | Backend path (details in [ARCHITECTURE.md](ARCHITECTURE.md) §5) |
|---|---|
| A. Officer approves tomorrow's plan | 18:30 `cmd.plan.draft` (master) → `plan.drafted` → WS `plan:{id}` → `POST /simulate` (What-If via intel-service) → `PATCH` edits → `POST /approve` (outbox `plan.approved` + audit) → 05:30 release → tasks dispatched → push + SMS |
| B. Driver runs a route | `task.dispatched` → `alert.requested` (route_assignment) → app ack → HawaTag `spray_start` / `spray_stop` → ingest segment → dispatch-worker matches task → `task.in_progress` → `task.done` → `verify_after` → `impact.verified` → `task.verified` |
| C. School protection | 17:00 master forecast → `school.safe_window_computed` → 19:00 `cmd.alert.school_run` → alert-engine applies the trigger rule → `alert.requested` (WhatsApp → SMS) → 22:00 final safe windows |
| D. Citizen Eyes | Presigned upload → `POST /v1/reports` or WhatsApp webhook → `report.submitted` → AI-ML vision + spike match → `report.verified` → inspection ticket (officer one-tap assign) → inspector closes → `report.closed` → citizen outcome message |

## 4. A day in the system (§8), from the backend's point of view

All times IST. Cron strings in [CONTRACTS §11](../CONTRACTS.md#11-schedules); the scheduler runs in `Asia/Kolkata` and stores everything in UTC.

| Time (IST) | Stage | Backend action | Output the backend must make visible |
|---|---|---|---|
| continuous | Ingest | Packets every 30 s per device, spikes immediately → validate, dedupe, calibrate, store, publish | Live pod trails, device health, `live:fleet` |
| every 15 min | Twin + attribution | Publish `cmd.twin.rebuild`; on `twin.updated` bump `twin:version`, pre-warm tiles, push WS | Fresh map (twin age ≤ 20 min) |
| hourly at :05 | Forecast | Publish `cmd.forecast.run` | Forecast series and GRAP outlook |
| 08:00, 11:00, 14:00 | Re-plan | Publish `cmd.plan.draft` (`mode=replan`) per active ward | Draft plans awaiting approval |
| 16:00 | Data freeze | `cmd.snapshot.freeze` → archiver snapshots the last 24 h of readings to S3 Parquet | Reproducible master-plan inputs |
| 17:00 | Master forecast | `cmd.forecast.run` with `master=true` | Tomorrow's 72 h outlook |
| 18:30 | Master plan draft | `cmd.plan.draft` (`mode=master`, window next day 05:30–11:00) | Plan with agent reasons |
| 19:00 | School alerts | `cmd.alert.school_run` (phase `draft`, which also sends) | WhatsApp / push to principals |
| 20:00 | Officer approval | Human action on the console; approval gate enforced | `plan.approved` |
| 22:00 | Final safe windows | `cmd.alert.school_run` (phase `final`) | Final safe window per school |
| 05:30 | Dispatch | `cmd.dispatch.release` → dispatch-worker releases approved master-plan tasks | Routes on driver phones + SMS fallback |
| 06:00–10:00 | Operations | HawaTag segments, task matching, ack and spray timeouts | Tasks auto-marked done |
| 2–4 h after each action; 11:00 batch | Verification | Verify scan publishes `cmd.verify.run` for due interventions | Effect ± CI per intervention |
| 02:00 | Nightly learn | `cmd.train.run` × forecaster, calibration, effectiveness, site_score | New model versions (mirrored in `model_version`) |
| 01:00 | Partitions | `cmd.partitions.maintain` → create the next 7 days of `reading` partitions, archive then drop > 90 d | |
| Monday 07:00 | Evidence report | `cmd.evidence_report.build` → PDF in S3 | Weekly report (F22) |

## 5. Real-time spike path (§8.2) and its budget

| Clock (example) | Event | Backend hop | Budget (backend share) |
|---|---|---|---|
| 06:42:00 | Bus 7 TinyML flags PM2.5 ×3 in 20 s and publishes `hawa/v1/HPM-0007/event` (`type=spike`) immediately | Mosquitto / IoT Core → bridge or IoT Rule → `hawa.telemetry.raw.v1` | ≤ 1 s |
| 06:42:01 | Ingest validates, stores `device_event`, double-checks the spike against the device's recent baseline, publishes `device.spike` (`confirmed_by_cloud`) | ingest-worker | ≤ 2 s p95 |
| 06:42:02 | api-live pushes `devices` and `fleet`; intel-spike (AI-ML) starts the fingerprint | api, Redis pub/sub | ≤ 1 s to connected clients |
| 06:43 | Fingerprint: high PM2.5/PM10, VOC up, no FIRMS fire → "likely open burning" → `hotspot.updated` | api-cache + api-live → WS `hotspots:{ward_id}` | ≤ 2 s after the event |
| 06:44 | Citizen photo 300 m away verified and matched → confidence high | `report.verified` → inspection ticket | ≤ 2 s |
| 06:45 | Planner proposes the nearest inspection team; Auditor confirms a sprinkler would not help smoke → `plan.drafted` (`mode=spike`) → officer taps approve | api approval → dispatch-worker → notifier | approve → inspector push ≤ 10 s |
| 07:10 | Inspector closes the case; the verifier tracks the cell back to baseline | `POST /v1/inspections/{id}/close` → `report.closed` → citizen told the outcome | ≤ 5 s |

End-to-end targets (from `../SYSTEM_OVERVIEW.md` §3.1):

| Target | Budget split |
|---|---|
| **Packet → hotspot on the officer map ≤ 60 s** | bridge 1 s + ingest 2 s + AI-ML live twin/fingerprint ≤ 50 s + api cache/WS 2 s + client tile refetch ≤ 5 s |
| **Spike → draft action ≤ 3 min** | backend transport ≤ 5 s in total; the rest is AI-ML (greedy optimiser + agents with hard timeouts) |

The backend measures both with `hawa_e2e_packet_to_ws_seconds` and `hawa_spike_to_draft_seconds` ([LOGGING_AND_OBSERVABILITY.md](LOGGING_AND_OBSERVABILITY.md) §12).

## 6. Real vs simulated in the demo (§12.5) and the honesty rule

| Component | Status in demo | Backend implication |
|---|---|---|
| CPCB / OpenAQ, weather, FIRMS feeds | Live | feeds-worker polls real APIs; recorded history available as fallback fixtures if the venue network fails (labelled `source=fixture`) |
| IoT pipeline, storage, APIs, map | Live (on AWS for the demo tier) | Same code local and AWS; see [DEPLOYMENT.md](DEPLOYMENT.md) §6.1 |
| HawaPod / HawaTag fleet | Simulated devices publishing real packets over real MQTT, clearly labelled | `hawa-sim` publishes the exact `TelemetryPacket`, `DeviceEventPacket`, `SprayPacket`; one real pod may join |
| Calibration, twin, fingerprint, forecast, exposure | Running on real historical and live reference data | Backend feeds reference observations and pairs readings |
| Optimiser, What-If, agents, approval flow | Running | Approval gate is real; audit trail is real |
| Causal verification | Running on simulated interventions with **injected, known effects** | Simulator's effects config writes ground truth to `simulator/out/ground_truth.jsonl`; e2e test checks the verifier recovers it within its CI |
| WhatsApp / SMS alerts | Live to test numbers | Notifier allowlist `HAWA_NOTIFY_ALLOWLIST`; all other recipients are logged as `dry_run` |

**Honesty rule, as the backend enforces it.**

1. `is_simulated` is set **from the device registry** (`device.is_simulated`), never from anything a packet claims. A simulated device can never produce "real" readings, and a real pod's readings are never marked simulated.
2. It propagates unchanged into `reading`, `device_event`, `intervention`, the `reading.cleaned` / `spray.*` / `device.*` envelopes, `live:device:{id}`, every API response record, and every WebSocket message.
3. **Proposed contract addition (PCA-21):** aggregate or derived outputs carry `simulated_share` (0–1, the fraction of contributing observations from simulated devices) on `twin_run` and in `twin.updated` data. For any derived event, the envelope `is_simulated` is `true` if any contributing input was simulated. Plans, tasks and impacts inherit `is_simulated=true` when their asset, device or intervention is simulated.
4. Assets (machines) seeded for the demo carry `is_simulated=true`. The console and the app must render the "Simulated" badge ([CONTRACTS §1](../CONTRACTS.md#1-conventions)).
5. **Proposed contract addition (PCA-27):** the open data API marks every record with `is_simulated` and a top-level `contains_simulated`. `HAWA_OPEN_INCLUDE_SIMULATED` defaults to `true` in `local`/`demo` (so the demo portal is not empty) and `false` in `pilot`.
6. Demo-only time compression (short verify delay, backfilled history) is controlled by `HAWA_DEMO_MODE` and is shown on the console as "demo-compressed window". The backend never rewrites timestamps of live data to fake a timeline. The only exception is the recorded golden history, which `hawa seed history --shift-to-now` moves to "today", and it is all `is_simulated=true` ([DATA_MODEL.md](DATA_MODEL.md) §18.3).
7. The simulator's injected effect is stored in `intervention.injected_effect_pct` (simulated rows only, DATA_MODEL §9.1) and exposed to admins only, so the verifier's recovery can be checked without showing the answer on the officer console.

## 7. Non-functional requirements

### 7.1 Latency

| Path | Target | Measured by |
|---|---|---|
| Packet → reading row committed (ingest) | p95 ≤ 2 s, p99 ≤ 5 s | `hawa_ingest_latency_seconds` (packet `ts` → commit) |
| Packet → visible on the officer map (trail / WS) | ≤ 10 s; hotspot ≤ 60 s | `hawa_e2e_packet_to_ws_seconds` |
| Spike → draft action | ≤ 3 min | `hawa_spike_to_draft_seconds` |
| Approve → first driver notification sent | ≤ 30 s (immediate plans) | `hawa_dispatch_notify_seconds` |
| `GET /v1/twin/tiles/*` | p95 ≤ 50 ms cached, ≤ 300 ms uncached | `hawa_http_request_duration_seconds` |
| Other read endpoints | p95 ≤ 200 ms | same |
| `POST /v1/plans/{id}/simulate` | p95 ≤ 3.5 s (intel p95 ≤ 3 s + overhead) | same + `hawa_intel_call_seconds` |
| Outbox → Kafka | p95 ≤ 1 s | `hawa_outbox_lag_seconds` |

### 7.2 Throughput and sizing

| Scale | Devices | Packets/s (30 s cadence) | Readings/day | Design check |
|---|---|---|---|---|
| Demo | 50–100 pods + 10 tags | ~2–4 | ~150–300 k | single laptop / single EC2 |
| Campus pilot | ~160 (100 HPM + 40 HPS + 20 HTG) | ~5 | ~0.5 M | one ingest replica |
| MCD zone | ~1,000 | ~35 | ~3 M | 3 ingest replicas, 12 partitions |
| NCR | ~10,000 | ~350 (bursts ×10 on replay) | ~29 M | 12–24 partitions, see [ARCHITECTURE.md](ARCHITECTURE.md) §10 |

Store-and-forward replays after a 4G gap can produce bursts of up to 72 h × 120 packets/h per device. Ingest must drain a 1-device, 72 h backlog (~8,640 packets) in ≤ 2 min without affecting live latency for other devices (keyed partitions + batch inserts).

### 7.3 Availability and recovery

| Item | Hackathon/demo | Pilot target |
|---|---|---|
| API availability | best effort; one node | 99.5 % during operating hours 05:00–22:00 IST |
| Ingest durability | no packet lost after broker ack | same; devices buffer 72 h, Kafka raw retention 7 d |
| RPO (database) | local volume | ≤ 5 min (RDS PITR) |
| RTO | manual restart ≤ 15 min | ≤ 1 h |
| Degraded modes | Redis down → serve from DB; intel-service down → What-If shows last stored simulation; feeds down → last observation + staleness badge | same, alarmed |

### 7.4 Data retention

Full table in [DATA_MODEL.md](DATA_MODEL.md) §19.1. The backend-relevant highlights:

| Data | Hot (Postgres/Redis/Kafka) | Cold | Notes |
|---|---|---|---|
| `reading` | 90 d (daily partitions) | S3 Parquet, 3 y | a verified manifest before any partition drop |
| `intervention`, `impact`, plans, tasks | kept (the evidence base, reviewed yearly) | — | `device_event` 180 d, then Parquet |
| Raw Kafka telemetry | 7 d | optional S3 raw archive (PCA-25) | replay window > 72 h store-and-forward |
| `audit_log` | 365 d (monthly partitions) | Parquet 3 y | insert-only (`app_rw` has no UPDATE/DELETE) |
| Citizen photos | raw: 30 d after the case closes (7 d if rejected); redacted copy: 365 d | none | EXIF stripped on intake; S3 lifecycle rules |
| HawaEye clips (VISION) | 7 d unless attached to an inspection | none | "retained briefly" (§12.4) |
| Driver live position | 1 h (`live:device:*`), fleet GEO pruned | none | not joined to a person in any API |
| OTP | 5 min, hashed | none | |
| App logs | 7 d Kafka / 30 d CloudWatch | none | no PII |

### 7.5 Privacy

- **Driver and inspector location.** HawaTag positions belong to the machine (asset), not the driver. The asset-to-driver link lives only in `asset_shift` for the shift window. APIs expose asset positions to officers only. Logs record `cell_id`, never raw coordinates of assets. The Flutter app sends location only while a shift is active, and only when a task needs it.
- **Citizen and school phone numbers.** Stored once (in `app_user` / `school` contacts), returned only to the owner and to the notifier, masked to the last 4 digits everywhere else (`+91******1234`), never in logs, never in Kafka payloads except `alert.requested.recipient` (which the notifier needs). Redis keys use a hashed phone (PCA-14). The pilot must follow the Digital Personal Data Protection Act, 2023 (consent at signup, purpose limitation, deletion on request).
- **Photos.** Stored in a private bucket, served through short-lived presigned GET URLs, EXIF stripped, never published on open data.
- **HawaEye (VISION).** Only flagged clips, authorised review queue, no faces or plates stored by default (§10.4, §12.4).

### 7.6 Idempotency and ordering

- Device packets are idempotent on `(device_id, seq)`. Redis `dedupe:pkt:{device_id}:{seq}` is the fast path (checked with `MGET` before the insert, set after the commit), and the `reading` primary key `(device_id, seq, ts)` is the durable guarantee ([DATA_MODEL.md](DATA_MODEL.md) §14.2, PCA-12).
- Every Kafka consumer is idempotent on `event_id`: Redis `dedupe:evt:{group}:{event_id}` fast path plus a `processed_event` row in the same DB transaction as the side effects ([EVENTS.md](EVENTS.md) §5.3).
- Every state-changing `POST` accepts `Idempotency-Key` ([CACHING.md](CACHING.md) §9).
- Ordering is per Kafka key (`device_id`, `plan_id`, `asset_id` …). Handlers are state-machine checks, so reordering across topics cannot corrupt state.

### 7.7 Store-and-forward replay (up to 72 h)

- Validation accepts `ts ∈ [now − 72 h, now + 2 min]` ([CONTRACTS §4.1](../CONTRACTS.md#41-telemetrypacket-exactly-106-plus-optional-role-fields)); packets flagged `sd_replay` keep their original `seq` and `ts`.
- Partitions for the last 4 days and the next 7 days always exist.
- Replayed readings are inserted, not merged into the live view: api-live ignores `reading.cleaned` older than 60 s for WebSocket fan-out, but the twin and the verifier see them (late data is valuable for verification).
- Replays never re-trigger spike alerts older than 10 min (they are stored in `device_event` and published with `data.late=true`).

### 7.8 Other

- Time in UTC everywhere; IST only in the scheduler and in rendered text.
- All user-facing text exists in `en` and `hi` (alert templates, GRAP checklist).
- Every model output served carries its uncertainty; the API never returns a bare point estimate ([CONTRACTS §1](../CONTRACTS.md#1-conventions)).

## 8. Risks relevant to the backend (§15 and build risks)

| Risk | Backend mitigation |
|---|---|
| Low-cost sensors drift / read high in humidity | Apply versioned calibration at ingest; record `calibration_version`, `trust`, `weight` on every reading; `device.trust_changed` lowers weight immediately |
| Source attribution is uncertain | API always returns `cause_conf`; cause → asset-type constraint enforced in the approval validator as well as the optimiser |
| Verification confounded by weather | Backend guarantees complete inputs: intervention track, cells, litres, pm before/after, `verify_after`; never marks a task `verified` without an `impact` row |
| LLM agents make a bad call | Hard approval gate; plan edits re-validated server-side (cause/asset constraint, shift windows, capacity); agents cannot call dispatch APIs |
| Privacy (cameras, locations) | §7.5; PII masking in logs; presigned private media |
| Connectivity gaps | 72 h replay acceptance; Kafka raw 7 d; app offline queue with `Idempotency-Key` |
| Gaming (cleaning only near monitors) | Integrity flags are stored and pushed (`hawa.integrity.flag.v1` → WS, audit) |
| Hardware theft or vandalism | `device.tamper` → `device-health` → device `degraded` + officer alert |
| Agencies will not adopt | Open data API and evidence report make results shareable |
| **SMS to Indian numbers needs TRAI DLT registration** (entity + template IDs) | Register early; SNS message attributes for entity/template IDs; WhatsApp test numbers + push as demo fallback |
| **WhatsApp business-initiated messages need pre-approved templates** | Submit `hawa_route_assignment`, `hawa_school_alert`, `hawa_report_outcome` (en/hi) on day 0; test-number sandbox for the demo |
| Bedrock latency blows the 3 min spike budget | Backend does not wait on agents; the greedy optimiser draft is published first (AI-ML), agent notes update the plan later |
| Kafka + Schema Registry + Mosquitto on a laptop is heavy | Compose profiles; default profile is infra only; ~6 GB RAM budget |
| MSK Serverless is incompatible with the IoT Rule Kafka action (IAM only) | PCA-01: MSK provisioned with SASL/SCRAM for the rule, or the bridge against IoT Core in the demo tier |
| Venue network failure during the demo | Local compose fallback with recorded feed fixtures; demo-reset in ≤ 5 min |

## 9. Non-goals (for the backend)

- No ML: the backend never computes the twin, forecasts, exposure, routes, agents or causal effects. It only triggers and serves them.
- No firmware, OTA pipeline or AWS IoT Jobs implementation in the hackathon (spec only, §10.5).
- No HawaEye video processing (F8 is VISION); only `clip` metadata ingest and a presigned upload are specified.
- No power-proxy compliance (F10, VISION).
- No Cognito in the hackathon: a backend-issued JWT with a Cognito-compatible verifier interface.
- No multi-city tenancy and no billing.
- No regulatory values: low-cost sensors are indicative (§12.4). The API labels indicative AQI and never presents readings as legal compliance data. Nothing is used to fine anyone (§15).
- No public write API apart from Citizen Eyes reports.
- No automatic dispatch of fleet or inspectors without officer approval, ever.
