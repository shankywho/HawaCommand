# Backend Build Plan

> **Status (2026-10-10).** Built: phases 1-5 as code plus unit tests (`backend/PHASES.md`), the AI-ML bridge with circuit breaker, live stations, 33 API operations, the optional AWS layer. Test run: 64 passed, 1 failed. Not built: persistence (the API never opens a DB session, no Alembic), Kafka producers and consumers, Redis, WebSocket, auth endpoints and enforcement, the field API the Flutter app expects, scheduler, notifier, Dockerfile, CI. Prioritised next steps: [TEAM_REMAINING_WORK_AND_PROMPTS.md](../TEAM_REMAINING_WORK_AND_PROMPTS.md#3-backend-engineer). Milestones below are the original plan.


The backend lead's plan: prep before the clock starts, the 24-hour hackathon hour by hour, milestones with acceptance criteria, cross-team dependencies, cut rules, risks, and the post-hackathon phases.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [DEPLOYMENT](DEPLOYMENT.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) §10–11

---

## 1. Principles for the 24 hours

1. **Golden path first, breadth later** (`../SYSTEM_OVERVIEW.md` §10). Every hour ends with something that runs end to end, even if parts are stubs.
2. **Unblock the other three.** Contracts, seed data and the OpenAPI skeleton ship in the first 3–6 hours. Stubs (a stub twin, a stub planner) exist only so the frontend and app are never waiting. They are labelled and replaced by AI-ML output.
3. **Never compromise the four invariants:** idempotent ingest, `is_simulated` everywhere, the officer approval gate, and a verification path that produces a real `impact`.
4. **Checkpoints at H3, H8, H14, H19 and H22**, where the whole team syncs (10 min) and applies the cut rules (§5).

## 2. Before the clock starts (if the event rules allow; otherwise these are H0 tasks)

| Item | Why | Owner |
|---|---|---|
| AWS account, `ap-south-1`, budget alarm, Bedrock model access requested | model access and SNS sandbox exit take time | backend lead |
| WhatsApp Cloud API app + test number, up to 5 verified recipient numbers, templates `hawa_route_assignment`, `hawa_school_alert`, `hawa_report_outcome` (en/hi) submitted | business-initiated messages need approved templates | backend lead |
| SNS SMS sandbox: verify 2–3 test phones; start DLT registration (it will not finish in time; know the fallback) | Indian SMS rules | backend lead |
| Firebase project + FCM service account JSON | push to the Flutter app | app dev + backend |
| API keys: data.gov.in (CPCB), OpenAQ v3, NASA FIRMS MAP_KEY | live feeds | backend lead |
| Pre-pull every compose image and pin the tags in `.env.example` | venue bandwidth | everyone |
| Download: Delhi GTFS, OSM extract (roads + POIs), MCD ward GeoJSON, WorldPop 100 m | simulator routes, seed | backend + ML |
| Record 48 h of CPCB/OpenAQ/weather/FIRMS responses into `seed/fixtures/demo/` | offline fallback | backend |

## 3. Hour by hour (backend lead)

Aligned with the backend-lead column of PDF §16 and `../SYSTEM_OVERVIEW.md` §11 (compose/Alembic/contracts → simulator + ingest → plan APIs + WS + cache + scheduler → dispatch + notifier + verify orchestration → integration → demo).

| Hour | Work | Output you can show | Check |
|---|---|---|---|
| 0–1 | Repo scaffold per [STRUCTURE.md](STRUCTURE.md); `pyproject` workspace, ruff/mypy/pre-commit; root `docker-compose.yml` (infra profile), `.env.example`, `Makefile` | `make infra` all healthy | `docker compose ps` |
| 1–2 | `hawa_contracts`: enums, ids, packets (§10.6), envelope, topics, redis_keys, core event payloads; `hawa kafka-init` | AI-ML imports `hawa_contracts`; all topics exist | `hawa kafka-init --check` exits 0 |
| 2–3 | Alembic baseline with the DATA_MODEL.md owner: schema `hawa`, PostGIS, the core tables (grid, device, reading partitioned, device_event, asset, plan*, intervention, impact, alert*, outbox, processed_event, auth); `hawa seed` for grid/wards/assets/devices/users | **M0** | `alembic check`; row counts |
| 3–4 | `core/` (config, logifyx logging, context, errors, clock), `bootstrap.py`, `api/main.py` with `/healthz` `/readyz`; OpenAPI skeleton published to web/app | `/docs` live | `curl /readyz` |
| 4–5 | `mqtt-bridge` (aiomqtt → aiokafka) + Mosquitto ACL; simulator v0: 50 HPM on GTFS routes, 30 s packets, noise + RH bias | packets in `hawa.telemetry.raw.v1` | Kafka UI |
| 5–6 | `ingest-worker` v1: decode, validate, dedupe (Redis + DB), calibrate, cell lookup, batch insert, `reading.cleaned`, `live:*` | **M1**: readings in DB < 10 s | SQL count, dedupe test |
| 6–7 | Consumer base class (retries, DLQ, idempotency) + outbox + relay; `device_event` + spikes; simulator: TinyML spike, store-and-forward replay | spike events flowing; replay gives no duplicates | integration test |
| 7–8 | HawaTag in the simulator + ingest spray segments (`intervention`, `spray.*`); `feeds-worker` CPCB/OpenAQ + Open-Meteo (or fixture mode) | **M2** | `reference_observation` rows |
| 8–9 | Auth: login (argon2), OTP (dev OTP), JWT, refresh, RBAC + ward scope; rate limiter | app can log in | auth tests |
| 9–10 | `scheduler` (APScheduler + `lock:sched`), commands for twin/forecast/plan; stub twin (IDW from readings, labelled) until AI-ML lands | `twin_run` every 15 min | scheduler metrics |
| 10–11 | Twin/tiles/hotspots/forecast endpoints; versioned Redis cache; `api-cache` consumer; WebSocket gateway + Redis fan-out; `api-live` | **M3**: map updates live | tile p95, WS message on `twin.updated` |
| 11–12 | Plans API: draft (outbox `cmd.plan.draft`), list/detail, PATCH (+ optimize), simulate (intel_client + breaker), approve/reject with constraints + Idempotency-Key + audit | draft → drafted on WS | plan tests |
| 12–13 | Integrate AI-ML intel-plan + intel-service; fix contract mismatches | real plan with agent reasons | golden path steps 1–5 |
| 13–14 | Buffer / catch-up; **H14 checkpoint** (cut rules) | **M4** | |
| 14–15 | `dispatch-worker`: release, assignment, `task.dispatched`, `alert.requested`; sweep (expiry, ack escalation, missed) | tasks dispatched on approve | saga unit tests (approval gate 100 %) |
| 15–16 | `notifier`: FCM push, SMS (SNS), WhatsApp (Cloud API), log provider, allowlist, fallback chain, `alert_delivery`; tasks API for the app (mine, ack, status, manual fallback) | push + SMS to a real test phone | < 30 s approve → phone |
| 16–17 | Spray ↔ task matching; `task.in_progress` / `done`; `verify_after`; simulated drivers in the simulator (poll tasks, drive, spray) | **M5**: auto-marked stops | e2e steps 6–7a |
| 17–18 | Verify scan (outbox `cmd.verify.run`); `impact.verified` → task verified; impact endpoints; `audit-writer` | impact ± CI on the console | e2e step 7 |
| 18–19 | Simulator injected known effects + ground truth; `hawa-sim backfill`; **H19 checkpoint** | **M6** | verifier recovers the injected effect |
| 19–20 | Integration and bug bash (everyone). Backend: alert-engine Flow C (school WhatsApp at a test number), open data `/open/v1/air` + rate limit | school alert received | 61st request → 429 |
| 20–21 | STRETCH per the cut rules: Citizen Eyes (app upload → ticket → close → outcome); Grafana golden-path dashboard | **M7** | |
| 21–22 | `hawa demo-reset` + `hawa demo-check`; AWS Tier A (EC2 compose + IoT Core bridge + HTTPS) | **M8** | reset twice, green twice |
| 22–24 | Demo video, README, AWS Builder Center blog draft (everyone). Backend: architecture slide, keep the stack stable, freeze `main` | recorded demo | |

## 4. Milestones and acceptance criteria

| # | Hour | Milestone | Acceptance criteria (all must pass) |
|---|---|---|---|
| **M0** | 3 | Foundation | `make infra` healthy in < 3 min with pre-pulled images; `alembic upgrade head` creates every CONTRACTS §8 table the backend owns, and `alembic check` is clean; `hawa kafka-init --check` exits 0 with every topic in the registry present; the AI-ML venv imports `hawa_contracts`, and `TelemetryPacket.model_validate(<§10.6 example>)` passes; `hawa seed` loads the grid, wards, ≥ 50 simulated devices, ≥ 10 assets and demo users idempotently (running it twice changes nothing) |
| **M1** | 6 | Packets land | Simulator with 50 devices → **readings visible in DB < 10 s** after the first packet; ingest p95 (packet `ts` → commit) < 2 s; replaying the same 1,000 packets adds **0 rows** and `hawa_dedupe_hits_total` grows by 1,000; each of the 6 validation rules produces its reason code on `hawa.telemetry.dlq.v1`; every simulated row has `is_simulated=true` (and a real pod, if connected, `false`) |
| **M2** | 8 | Live feed and external data | `reading.cleaned` is on the topic; `live:fleet` has ≥ 50 members; `GET /v1/fleet/live` returns them; a 72 h store-and-forward replay of one device (~8,640 packets) drains in < 2 min; spike events arrive on `hawa.device.event.v1` with `confirmed_by_cloud`; `reference_observation` has CPCB/OpenAQ rows (live or fixture) |
| **M3** | 11 | Twin served live | `cmd.twin.rebuild` every 15 min (or triggered); on `twin.updated`: `twin:version` bumps, tiles for z10–z13 are pre-warmed, WS `twin` pushes within 2 s; tile p95 < 50 ms cached / < 300 ms uncached; cache hit ratio > 80 % on repeated pans; hotspots endpoint ranks by `exposure_ph` with `cause_label` + `cause_conf` |
| **M4** | 14 | Plans and auth | Officer login and field OTP login work; ward scoping per API.md §2.4 (`?ward=` outside scope → 403 `forbidden.ward_scope`, a single object outside scope → 404); `POST /v1/plans/draft` → 202 with the `drafting` row readable immediately → `plan.drafted` over WS `plan:{id}` in < 60 s (stub or AI-ML); `simulate` returns plan vs baseline, and a second call for the same plan version is served from `plan_simulation`; with intel-service stopped, the breaker opens in ≤ 5 failures and returns `503 upstream.aiml_unavailable`; approve twice with the same `Idempotency-Key` gives one approval and identical responses; approving a non-`draft` plan → 409 `plan.not_draft`; a stale `If-Match` → 409 `plan.version_conflict`; a sprinkler on a `burning` cell → 422 `plan.constraint_violation` |
| **M5** | 17 | Dispatch works | Approve (`mode=manual`) → tasks `dispatched` and **push + SMS on a real test phone < 30 s**; a simulated HawaTag spray auto-marks the task `in_progress` → `done` with the intervention linked; with `HAWA_DISPATCH_SPRAY_GRACE_MIN=1` an unserved task becomes `missed`; ack escalation moves push → SMS after the ack timeout; manual done from the app creates an intervention with `source=manual` |
| **M6** | 19 | Verification loop | `verify_after = end_ts + 2 h` (or demo-compressed and labelled); the verify scan emits one `cmd.verify.run` per due intervention (no duplicates within an hour); `impact.verified` → task `verified`; `GET /v1/interventions/{id}/impact` returns effect with `ci_low`/`ci_high`; for backfilled sprays with injected effects, the verifier's effect lies within its CI of the ground truth (AI-ML check, backend supplies inputs) |
| **M7** | 21 | Protect and open up (STRETCH) | Flow C: 19:00 run (triggered) sends a WhatsApp/SMS safe-window alert to the allowlisted school phone, and a second run sends nothing new; `/open/v1/air` serves calibrated cells with `is_simulated` flags, and the 61st request in a minute from one IP → 429 with `Retry-After`; Citizen Eyes: app photo → `report.verified` → ticket → officer assign → inspector close → citizen outcome message |
| **M8** | 22 | Demo-ready | `make demo-reset` completes in < 2 min with golden history (DATA_MODEL §18.3), or < 5 min with the pipeline backfill variant, and `hawa demo-check` is green **twice in a row**; `pytest -m e2e` (golden path) green; the Grafana golden-path dashboard shows live data; AWS Tier A reachable over HTTPS with packets through IoT Core; nothing in the demo uses `latest` image tags |

## 5. Cut rules

From §16: if behind at hour 14, drop wind advection (AI-ML), Citizen Eyes and the school scheduler. **Never drop the What-If screen and causal verification.**

Backend cut order when behind at H14 or H19. Apply from the top:

| Order | Cut | Keep instead |
|---|---|---|
| 1 | Citizen Eyes WhatsApp intake | app upload only (then drop Citizen Eyes entirely, per §16) |
| 2 | School scheduler automation (Flow C runs) | one officer-triggered `POST /v1/alerts` safe-window message to a test number |
| 3 | Evidence report PDF (F22) | — |
| 4 | Open data beyond `/open/v1/air` | `/open/v1/air` with rate limiting |
| 5 | Schema Registry + logifyx Kafka handler | console JSON logs |
| 6 | OpenTelemetry tracing; Grafana | logs + `/metrics` + Kafka UI |
| 7 | Archiver Parquet | partitions only |
| 8 | AWS Tier B (CDK) | Tier A (EC2 compose + IoT Core bridge) |

**Never cut:**
- idempotent ingest and `is_simulated`;
- the approval gate;
- the dispatch saga with HawaTag auto-matching;
- verification orchestration to a real `impact`;
- the What-If proxy;
- `demo-reset`.

## 6. Dependencies

### 6.1 What the backend needs

| Need | From | By | Fallback if late |
|---|---|---|---|
| 500 m / 1 km grid (`grid_500m.parquet`, `grid_meta`) from `build_grid` | AI-ML | H3 | backend generates the grid from the bbox with the same id scheme ([CONTRACTS §2](../CONTRACTS.md#2-identifiers)) |
| DATA_MODEL.md baseline agreed | DATA_MODEL owner | H2 | backend lead decides; AI-ML reviews |
| intel-worker twin (`twin.updated`, `cell_state`, `hotspot`) | AI-ML | H11 | backend stub twin (IDW over the last hour of readings, `model_version=stub-idw`, labelled) |
| intel-plan draft (`plan.drafted` with tasks + review) | AI-ML | H13 | stub greedy planner (nearest available cause-matched asset, `model_version=stub-greedy`, no agent text) |
| intel-service `/internal/v1/simulate`, `/optimize` | AI-ML | H13 | breaker fallback returns stored or stub results |
| intel-verify (`impact.verified`) | AI-ML | H18 | none acceptable for the demo; escalate at H14 if at risk |
| intel-vision (`report.verified`) | AI-ML | H20 (STRETCH) | officer manual verify button |
| WhatsApp templates approved, SNS test numbers verified | lead (pre-event) | H0 | push + in-app only; show WhatsApp on the test number sandbox |
| Flutter app registers the FCM token (`PUT /v1/me/push-token`) | app | H15 | SMS fallback |

### 6.2 What the others need from the backend

| Deliverable | For | By |
|---|---|---|
| `hawa_contracts` package + topics created + seed | AI-ML | H3 |
| OpenAPI skeleton (auth, twin, hotspots, plans, tasks) with example responses | web, app | H4 |
| Twin/tiles/hotspots endpoints + WS `twin` | web | H11 |
| Plans API + WS `plan:{id}` | web | H12 |
| Auth (OTP) + tasks API + WS `tasks:me` + push | app | H15 |
| Impact endpoints | web | H18 |
| `demo-reset` | everyone | H22 |

## 7. Risks (build and demo)

| Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|
| Kafka + Schema Registry + everything else exceeds laptop RAM | M | H | compose profiles; infra-only default; cut order 5–6; a second laptop runs AI-ML | backend |
| Contract drift between backend and AI-ML payloads | H | H | one `hawa_contracts` package; contract tests; sync at every checkpoint | backend + ML |
| AI-ML twin or planner late | M | H | stub twin + stub planner (labelled) keep the web and app unblocked | backend |
| Bedrock latency or quota breaks the spike → draft budget | M | M | the greedy draft is published first, agent notes follow; timeouts in AI-ML | ML |
| SMS blocked (DLT) at the venue | H | M | WhatsApp test number + FCM push; show SMS only if it works | backend |
| Venue network is flaky | M | H | `HAWA_FEEDS_MODE=fixture`, local compose; record the demo video early (H21) | everyone |
| Clock skew on the laptop or a device → `stale_or_future` rejects | L | M | NTP on hosts; simulator clock guard; the reject metric on the dashboard | backend |
| Store-and-forward burst starves live ingest | L | M | keyed partitions (6 local), batch inserts, M2 drain test | backend |
| Approval gate bypass bug | L | Critical | the transition table is the only path; 100 % test coverage on `transitions.py` | backend |
| Demo state not reproducible | M | H | `demo-reset` + `demo-check` rehearsed twice at H22 | backend |
| IoT Rule → MSK auth mismatch (Serverless) | — | — | avoided by PCA-01; the demo uses Tier A | backend |
| Secrets leaked in screen share or repo | L | H | gitleaks pre-commit; `.env` git-ignored; never show `docker compose config` | everyone |

## 8. Post-hackathon phases (§14.1)

| Phase | Scope (§14.1) | Backend work |
|---|---|---|
| **Phase 1: campus pilot (0–3 months)** | one campus or district, an e-rickshaw fleet partner, 10–20 schools; publish verified results | Real device onboarding (IoT fleet provisioning by claim, per-device X.509, OTA via IoT Jobs later); CDK Tier B with MSK provisioned (PCA-01); DLT SMS registration and approved WhatsApp templates; DPDP-compliant consent, retention and deletion flows for phone numbers; backups + restore drill; load test at 10 × pilot; on-call runbook and alarms; `HAWA_OPEN_INCLUDE_SIMULATED=false`; public open data portal and weekly evidence report; instrument KPIs §13.1 (coverage, verified-action share, alert lead time) as metrics |
| **Phase 2: one MCD zone (3–12 months)** | HawaTags on the zone's sprinklers and smog guns; integrate existing machine GPS | New feeds adapter for the agency's machine GPS (interventions with `source=gps_inferred`); agency roles and multi-ward RBAC; zone-scale infra (ingest × 3, 12 telemetry partitions, RDS read replica for open data and analytics, CloudFront on `/open/v1`); 99.5 % SLO with error budgets; audit exports for courts and the Green War Room; `dedupe:pkt` TTL cut to 6 h |
| **Phase 3: NCR-wide, then other NCAP cities (12+ months)** | NCR, other NCAP cities; the effectiveness library becomes the moat | Multi-tenancy (`city_id` in keys, topics and tables, or a deployment per city); 24 telemetry partitions, larger MSK brokers or tiered storage; `reading` hot retention 30 d with a Parquet/Athena lake; Redis cluster mode with hash tags; licensed historical data API (§14) with usage metering; effectiveness library API for other cities |
