# HawaCommand Backend — REST API

Purpose: the exact REST surface served by `hawa_backend.api.app:app` today (every registered route, its parameters, a real response, status codes and where the data comes from), followed by the planned surface that is designed but not built.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [DATA_MODEL](DATA_MODEL.md) · [CACHING](CACHING.md) · [LOGGING_AND_OBSERVABILITY](LOGGING_AND_OBSERVABILITY.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../frontend/README.md](../frontend/README.md) · [../app/README.md](../app/README.md) · [../aiml/ARCHITECTURE.md](../aiml/ARCHITECTURE.md)

> Status: 33 operations on 31 paths are registered (verified against `/openapi.json` on 2026-10-10). No route requires authentication, none reads or writes the database, and there is no WebSocket. Everything in §11 is **Planned**.

---

## Contents

1. [Conventions](#1-conventions)
2. [Endpoint index](#2-endpoint-index)
3. [Health](#3-health)
4. [Hotspots and twin](#4-hotspots-and-twin)
5. [Forecast](#5-forecast)
6. [Plans](#6-plans)
7. [Fleet, impact, alerts, driver](#7-fleet-impact-alerts-driver)
8. [Open data](#8-open-data)
9. [Citizen experience](#9-citizen-experience)
10. [Calls the backend makes to AI-ML](#10-calls-the-backend-makes-to-ai-ml)
11. [Planned API (target design)](#11-planned-api-target-design)

---

## 1. Conventions

### 1.1 Base URL, OpenAPI, versioning

| Item | Value |
|---|---|
| Base URL (local) | `http://localhost:8000` (whatever port uvicorn is started on) |
| Prefixes | `/v1` (console and app), `/open/v1` (public read-only), and the unversioned probes `/healthz`, `/health`, `/livez`, `/readyz` |
| OpenAPI | `GET /openapi.json` (FastAPI, title "HawaCommand Command Center API", version `0.1.0`); Swagger UI at `/docs`, ReDoc at `/redoc` |
| Tags | `Health`, `Hotspots & Digital Twin`, `Forecast`, `Plans`, `Fleet & Devices`, `Causal Impact`, `Interventions`, `Alerts`, `Driver PWA`, `Open data`, `Citizen Experience` |
| Typed request models | `DraftPlanRequest`, `ApprovePlanRequest`, `RequestChangesRequest`, `Coordinate`, `SafeRouteRequest`, `MissedMachineReport`. No route declares a `response_model`, so responses are untyped in the schema. |

### 1.2 Formats

| Topic | Rule as built |
|---|---|
| Media type | `application/json` for every response, including errors |
| Field names | camelCase for the console/app routes (they mirror the Zod schemas in `frontend/src/lib/api.ts`); snake_case for `/v1/twin` cells and all `/v1/citizen/*` responses (passed through from `hawa_ml`) |
| Timestamps | UTC ISO-8601 with `Z` and microseconds (`2026-10-10T05:13:02.998373Z`); `/v1/twin` via the AI-ML HTTP path uses `+00:00` |
| Coordinates | `at: [lon, lat]` on hotspots and devices; separate `lat`/`lon` on open data and citizen routes; `/v1/twin?bbox=` is `min_lat,min_lon,max_lat,max_lon` |
| Units | PM in µg/m³; exposure in person-hours (`exposurePh`, `peopleHours`) |
| Uncertainty | Forecast series carry `p10/p50/p90`; impacts `ciLow/ciHigh`; hotspots `conf`/`causeConf` |
| Simulated data | Envelopes carry a top-level `simulated` flag. Its value depends on the data source and is not consistent (README Known issue 6). |
| Pagination | None. Lists are returned whole. |

### 1.3 Headers

| Header | Behaviour (`api/app.py:44-56`) |
|---|---|
| `X-Request-Id` | Read and bound into the request context; echoed in the response **only if the client sent it**. A generated UUIDv7 is used internally otherwise. |
| `X-Correlation-Id` | Same as `X-Request-Id`. |
| `Authorization`, `Idempotency-Key`, `If-Match`, `ETag`, `RateLimit-*` | Not read or set by any route. |

### 1.4 CORS

`CORSMiddleware` with `allow_origins=["*"]`, `allow_credentials=True`, `allow_methods=["*"]`, `allow_headers=["*"]` (`api/app.py:36-42`). Because credentials are allowed, Starlette answers with the caller's own `Origin` (verified: `Origin: http://example.com` gets `access-control-allow-origin: http://example.com` and `access-control-allow-credentials: true`). Preflights return 200 with `access-control-max-age: 600`.

### 1.5 Authentication

**None enforced.** No route depends on a token, role or ward scope. `core/security.py` provides `create_access_token` / `verify_access_token` (HS256 by default, `HAWA_JWT_SECRET`, 1440 min expiry, claims `sub`, `role`, `ward_ids`, `iat`, `exp`), `verify_otp` (accepts `HAWA_DEV_OTP` when `HAWA_ENV` is `development` or `test`), PBKDF2-HMAC-SHA256 password hashing (100 000 iterations, `salt$hexkey`) and `verify_webhook_signature` (`sha256=<hex HMAC>`). They are unit-tested but not wired. Auth endpoints are **Planned** (§11).

### 1.6 Errors

What clients actually receive:

| Status | When | Body |
|---|---|---|
| `404` | Unknown hotspot cell (`GET /v1/hotspots/{cell_id}`), unknown plan id on plan routes | FastAPI `HTTPException`: `{"detail": "Plan 'nope' not found"}` / `{"detail": "Hotspot with cellId 'NOPE' not found"}` |
| `422` | Query/path/body validation | FastAPI default: `{"detail": [{"type": "less_than_equal", "loc": ["query", "hour"], "msg": "Input should be less than or equal to 72", "input": "100", "ctx": {"le": 72}}]}` |
| `500` | Unhandled exception (for example a `hawa_ml` error inside a citizen route) | Starlette default plain-text `Internal Server Error` |

AI-ML failures never surface as errors: `IntelClient` falls back to in-process `hawa_ml`, then to fixtures, and the request still returns 200.

RFC 9457 support exists but is not reached by any route (`core/errors.py`, `api/app.py:58-66`). The handler renders a `HawaException` as `application/problem+json` with `model_dump(exclude_none=True)` of:

| Field | Value |
|---|---|
| `type` | `https://hawacommand.in/errors/{code}` |
| `title`, `status`, `detail`, `code` | from the exception |
| `instance` | the request path |
| `invalid_params` | optional dict |

| Class | Status | `code` | `title` |
|---|---|---|---|
| `NotFoundError(resource, identifier)` | 404 | `not_found` | Resource Not Found |
| `ConflictError(code, detail)` | 409 | caller-supplied | Conflict |
| `ValidationError(detail, invalid_params)` | 422 | `validation_error` | Unprocessable Entity |
| `ForbiddenError(code="forbidden")` | 403 | caller-supplied | Forbidden |
| `UnauthorizedError(detail)` | 401 | `unauthorized` | Unauthorized |
| `RateLimitedError(retry_after_seconds=60)` | 429 | `rate_limited` | Too Many Requests |
| `UpstreamServiceError(service_name, detail)` | 503 | `upstream_unavailable` | Service Unavailable |
| `AimlUnavailableError` | 503 | `upstream.aiml_unavailable` | AI-ML Service Unavailable |
| `AimlTimeoutError` | 504 | `upstream.timeout` | Gateway Timeout |

### 1.7 Data source legend

| Source | Meaning |
|---|---|
| **AI-ML** | `IntelClient` chain: AI-ML HTTP service at `HAWA_AIML_SERVICE_URL`, else in-process `hawa_ml`, else fixtures ([ARCHITECTURE.md](ARCHITECTURE.md) §3). With `hawa_ml` installed and the HTTP service down, hotspot, twin and forecast values come from live WAQI station readings kriged by `hawa_ml`. |
| **AI-ML (in-process)** | Calls `hawa_ml` objects directly, no HTTP and no fallback |
| **AWS** | Optional, only with `HAWA_AWS_ENABLED=true` |
| **Memory** | Module-level Python dict in the API process |
| **Fixture** | `src/hawa_backend/api/fixtures.py` or literals in the route module |
| **DB** | Not used by any route |

## 2. Endpoint index

| # | Method | Path | Status | Data source | Tests |
|---|---|---|---|---|---|
| 1 | GET | `/healthz` | **Implemented** | static | `test_api`, `test_all_routes_comprehensive` |
| 2 | GET | `/health` | **Implemented** | static | `test_all_routes_comprehensive` |
| 3 | GET | `/livez` | **Implemented** | static | same |
| 4 | GET | `/v1/health` | **Implemented** | static | same |
| 5 | GET | `/readyz` | **Stub/Mock** | hard-coded | `test_api`, `test_all_routes_comprehensive` |
| 6 | GET | `/v1/hotspots` | **Implemented** | AI-ML | `test_api`, `test_all_routes_comprehensive`, `test_end_to_end` (fails), `test_aiml_integration` |
| 7 | GET | `/v1/hotspots/{cell_id}` | **Implemented** | AI-ML | `test_all_routes_comprehensive` |
| 8 | GET | `/v1/twin` | **Implemented** | AI-ML | same |
| 9 | GET | `/v1/forecast` | **Implemented** | AI-ML (aggregated from hotspots) | `test_api`, `test_all_routes_comprehensive`, `test_aiml_integration` |
| 10 | GET | `/v1/forecast/{cell_id}` | **Implemented** | AWS, else AI-ML | `test_all_routes_comprehensive`, `test_aws_integration` |
| 11 | GET | `/v1/plans` | **Partial** | Memory + fixture seed plan | `test_api`, `test_all_routes_comprehensive`, `test_end_to_end` |
| 12 | GET | `/v1/plans/{plan_id}` | **Partial** | Memory | same, `test_aws_integration` |
| 13 | POST | `/v1/plans/draft` | **Partial** | AI-ML → Memory | `test_all_routes_comprehensive`, `test_aiml_integration`, `test_aws_integration` |
| 14 | POST | `/v1/plans/{plan_id}/approve` | **Partial** | Memory, optional AWS Step Functions | `test_api`, `test_all_routes_comprehensive`, `test_aws_integration` |
| 15 | POST | `/v1/plans/{plan_id}/request-changes` | **Partial** | Memory | `test_all_routes_comprehensive` |
| 16 | POST | `/v1/plans/{plan_id}/suggestions/{comment_id}/apply` | **Partial** | Memory | `test_api`, `test_all_routes_comprehensive` |
| 17 | GET | `/v1/plans/{plan_id}/compare` | **Partial** | AI-ML (rows hard-coded) | same, `test_aiml_integration` |
| 18 | POST | `/v1/plans/{plan_id}/simulate` | **Partial** | same handler as 17 | `test_all_routes_comprehensive` |
| 19 | GET | `/v1/devices` | **Stub/Mock** | Fixture | `test_api`, `test_all_routes_comprehensive`, `test_end_to_end` |
| 20 | GET | `/v1/impact` | **Partial** | Fixture + AI-ML verification | same |
| 21 | GET | `/v1/impact/library` | **Implemented** | AI-ML | same, `test_aiml_integration` |
| 22 | GET | `/v1/impact/{intervention_id}/verify` | **Partial** | AI-ML | `test_all_routes_comprehensive` |
| 23 | POST | `/v1/impact/{intervention_id}/verify` | **Partial** | AI-ML | same |
| 24 | GET | `/v1/interventions/{intervention_id}/verify` | **Partial** | AI-ML | same |
| 25 | POST | `/v1/interventions/{intervention_id}/verify` | **Partial** | AI-ML | same |
| 26 | GET | `/v1/alerts` | **Stub/Mock** | Fixture | `test_api`, `test_all_routes_comprehensive` |
| 27 | GET | `/v1/driver/route` | **Stub/Mock** | Fixture | same |
| 28 | GET | `/open/v1/air` | **Implemented** | AI-ML (derived from hotspots) | `test_api` |
| 29 | POST | `/v1/citizen/safe-route` | **Implemented** | AI-ML (in-process) | none |
| 30 | GET | `/v1/citizen/safe-window` | **Implemented** | AI-ML (in-process) | none |
| 31 | GET | `/v1/citizen/live-operations` | **Stub/Mock** | `hawa_ml` fleet constant + literals | none |
| 32 | POST | `/v1/citizen/reports/missed-machine` | **Partial** | AI-ML (in-process) audit against a constant fleet table | none |
| 33 | GET | `/v1/citizen/wards/leaderboard` | **Stub/Mock** | literals | none |

The web console calls 6, 9, 11–17, 19–21 and 26–28 (`frontend/src/lib/api.ts`). The Flutter app calls 6, 8, 9, 10, 19, 20, 26, 27, 30, plus `/v1/auth/*` which does not exist.

## 3. Health

`api/routes/health.py`.

#### `GET /healthz`, `GET /health`, `GET /livez`, `GET /v1/health`

> Status: **Implemented**. One handler on four paths. No dependency checks.

`200`:

```json
{"status": "ok"}
```

#### `GET /readyz`

> Status: **Stub/Mock**. Nothing is checked; the database and Redis are never contacted.

`200`:

```json
{"status": "ready", "services": {"api": "ok", "database": "ok", "redis": "ok"}}
```

## 4. Hotspots and twin

`api/routes/hotspots.py`, backed by `IntelClient.get_hotspots` and `IntelClient.get_digital_twin`.

#### `GET /v1/hotspots`

> Status: **Implemented**. Data source: AI-ML (HTTP → in-process on live WAQI stations → fixtures).

| Query | Type | Default | Rule |
|---|---|---|---|
| `hour` | int | `0` | `-24 ≤ hour ≤ 72`, hours relative to now. Sent to AI-ML as hour of day `(8 + hour) % 24`; in the fixture path it scales PM by `1 + 0.15 × ((hour % 24 − 8) / 12)`. |
| `ward` | string | none | `None`, `""`, `all` and `All wards` (case-insensitive) mean every ward. Other values filter by exact (case-insensitive) ward name. A ward unknown to the live source falls back to fixtures. |
| `threshold` | float | `250.0` | Echoed as `thresholdUgm3`; not used to filter. |

At most 10 items are returned. The client asks AI-ML for 50 ranked cells and keeps up to 10 that are at least 4 grid cells apart (`core/places.spread`), then renames them to the nearest of 41 Delhi localities (`core/places.name_places`). Each item carries a 73-point forecast from the AI-ML forecaster (flat ±15/25 % around the current value if none is available).

`200` (live in-process path; one item and one forecast point shown, real response has 10 items × 73 points):

```json
{
  "asOf": "2026-10-10T05:13:02.998373Z",
  "simulated": false,
  "hour": 0,
  "thresholdUgm3": 250.0,
  "items": [
    {
      "cellId": "G-050-072",
      "place": "Mangolpuri",
      "placeFull": "Near Mangolpuri · cell G-050-072 · Ward 3",
      "ward": "Ward-3",
      "at": [77.086, 28.679],
      "pm25": 74.8,
      "band": "Moderate",
      "cause": "Dust",
      "conf": 0.4,
      "causeConf": 0.4,
      "suspectPin": {"label": "Suspect plume for G-050-072", "bearing": "north-west", "distanceKm": 13.5, "travelMin": 270.0},
      "exposurePh": 350656,
      "rank": 1,
      "schools": [{"id": "sch-1", "name": "Govt. Sarvodaya Vidyalaya", "distanceKm": 0.6, "assemblyAt": "08:00"}],
      "assets": ["T-12"],
      "forecast": [{"h": 0, "p10": 78.3, "p50": 95.5, "p90": 122.2}]
    }
  ]
}
```

Field notes: `ward` is echoed at the top level only when a ward filter was given. `band` follows `pm25_band_label` (≤30 Good, ≤60 Satisfactory, ≤90 Moderate, ≤120 Poor, ≤250 Very Poor, else Severe). `cause` is one of `Dust`, `Burning`, `Traffic`, `Industrial`, `Regional smoke`. `schools` is the same fixed list of three schools on every item; `assets` is `["T-12"]` on rank 1 and empty otherwise; `suspectPin.bearing` is always `north-west` and `travelMin` is `distanceKm × 20` on the AI-ML paths. `simulated` is `true` on the HTTP and fixture paths and `false` on the in-process path. Fixture items use slugs as `cellId` (`ghazipur`, `anand`, …) and zone names as `ward` (`East Delhi`, `West`, …).

Codes: `200`, `422` (`hour` out of range).

#### `GET /v1/hotspots/{cell_id}`

> Status: **Implemented**. Data source: AI-ML.

Calls `get_hotspots(limit=50)` with no ward or hour and returns the item whose `cellId` matches (same shape as one `items[]` entry). Codes: `200`; `404` `{"detail": "Hotspot with cellId 'NOPE' not found"}`. Only ids from whichever source answered will match (README Known issue 8).

#### `GET /v1/twin`

> Status: **Implemented**. Data source: AI-ML.

| Query | Type | Default | Rule |
|---|---|---|---|
| `bbox` | string | none | `min_lat,min_lon,max_lat,max_lon`; applied only on the in-process path; malformed values are ignored |
| `ts` | string | none | ISO timestamp; echoed as `timestamp` on the in-process and fixture paths |
| `limit` | int | `500` | `≤ 2000` |

`200` on the in-process path (one of `limit` cells shown; the live grid has 10 600 cells):

```json
{
  "timestamp": "2026-10-10T05:13:06.071089Z",
  "simulated": false,
  "total_cells": 10600,
  "returned_cells": 3,
  "cells": [
    {
      "cell_id": "G-000-000", "row": 0, "col": 0, "latitude": 28.402, "longitude": 76.843,
      "population": 392.571, "vulnerability_weight": 1.0, "primary_land_use": "residential",
      "road_density_km_km2": 2.19, "nearest_school_dist_m": 25492.126, "schools_nearby_count": 0,
      "nearest_hospital_dist_m": 27365.311, "hospitals_nearby_count": 0, "ward": "Ward-1",
      "pm25_est": 52.4, "pm10_est": 76.5, "variance": 76.5, "confidence": 0.84
    }
  ]
}
```

On the HTTP path the AI-ML response is returned unchanged (`timestamp`, `total_cells`, `returned_cells`, `cells`; no `simulated` key). On the fixture path `cells` holds the 10 fixture hotspots (camelCase) with `simulated: false`.

Codes: `200`, `422`.

## 5. Forecast

`api/routes/forecast.py`.

#### `GET /v1/forecast`

> Status: **Implemented**. Data source: AI-ML, aggregated from hotspots by `IntelClient._aggregate_forecast`.

| Query | Type | Default | Rule |
|---|---|---|---|
| `ward` | string | none | Same normalisation as hotspots. Selects which hotspots form `series` and `grap`; `wards[]` is always city-wide. |

How it is built: fetch up to 50 hotspots (city-wide, and again for the ward if one is given); `series` is the mean of their 73-point forecasts; `grap` comes from the cell with the highest P50 peak; `wards[]` sums `exposurePh` per ward, takes each ward's peak P50 and mean `conf`, sorted by people-hours descending. If no hotspot has a forecast, the fixture forecast is returned (`ward: "All Wards"`, no `grap.actions`).

GRAP block (`IntelClient._grap_block`): stage by the peak P50 PM2.5 — `IV` ≥ 381, `III` ≥ 251, `II` ≥ 121, `I` ≥ 61 (and `I` below that); `probability = ½·erfc((stage_min − p50) / (σ√2))` with `σ = max(1, (p90 − p10) / 2.563)`, clamped to 0.01–0.99; `actions` are the AI-ML `mandated_actions` of the horizon whose GRAP stage number is closest.

`200` (one series point, one ward and one action shown; real response has 73 points and 12 wards):

```json
{
  "issuedAt": "2026-10-10T05:13:06.104905Z",
  "ward": "All wards",
  "grap": {
    "stage": "II",
    "likelyAt": "2026-10-13T03:13:06.104905Z",
    "probability": 0.7,
    "headline": "GRAP Stage II expected: PM2.5 peaks near 134 µg/m³ in 70 h at Mangolpuri.",
    "actions": ["Enforce dust control at construction sites > 500 sq m"]
  },
  "series": [{"p10": 78.0, "p50": 95.1, "p90": 121.8, "h": 0}],
  "wards": [{"ward": "Ward-3", "peopleHours": 1889845, "peakPm25": 134, "confidence": 0.4}]
}
```

Codes: `200`, `422`.

#### `GET /v1/forecast/{cell_id}`

> Status: **Implemented**. Data source: AWS when enabled, else AI-ML.

| Parameter | In | Default | Rule |
|---|---|---|---|
| `cell_id` | path | — | any string |
| `pollutant` | query | `pm25` | accepted, **ignored** |
| `issued_at` | query | none | accepted, **ignored** |

Order: `aws.get_aws_forecast(cell_id)` (DynamoDB cache, then Step Functions Express or SageMaker; [DEPLOYMENT.md](DEPLOYMENT.md) §5) → AI-ML `GET /forecast/{cell_id}` → in-process `forecaster_agent.analyze_forecast(cell_id, current_pm25)` (current PM from the live twin, or the twin mean if the cell is unknown) → fixture. Model horizons are expanded to 73 hourly points: known horizons are used as-is; gaps get `p50 = base + 25·sin((h+8)π/12) + 0.5·h`, `p10 = 0.82·p50`, `p90 = 1.28·p50` with `base` = the 1 h P50 (default 210).

`200`: same shape as `GET /v1/forecast` with `ward: "All wards"`, `wards: []` and no `at <place>` in the headline:

```json
{
  "issuedAt": "2026-10-10T05:13:06.581732Z",
  "ward": "All wards",
  "grap": {"stage": "II", "likelyAt": "2026-10-13T03:13:06.581732Z", "probability": 0.58, "headline": "GRAP Stage II expected: PM2.5 peaks near 126 µg/m³ in 70 h.", "actions": ["Enforce dust control at construction sites > 500 sq m"]},
  "series": [{"h": 0, "p10": 71.5, "p50": 87.2, "p90": 111.6}],
  "wards": []
}
```

Codes: `200`, `422`.

## 6. Plans

`api/routes/plans.py`. All plan state lives in the module dict `_ACTIVE_PLANS`; it is lost on restart and not shared between processes. Seed plan `214` (ward `ward-084`, two tasks on `T-12`, one open Auditor comment `com-01`) is created lazily the first time it is listed or fetched. There are no status rules: any action is accepted in any status.

Plan object (as returned by every plan route except compare/simulate):

| Field | Type | Notes |
|---|---|---|
| `id` | string | `214`, or the AI-ML planner's `PLAN-YYYYMMDD-HHMM`, or `plan-{ward}-{epoch}` from the fixture fallback |
| `ward` | string | as requested; an all-wards draft is labelled `All wards` on the AI-ML paths and `all` on the fixture fallback |
| `window` | object | `start`, `end` (now + 10 h, + 4 h), `label` (always `Thu 06:00 – 10:00`) |
| `status` | string | `draft`, `approved` or `changes_requested` |
| `draftedAt`, `draftedBy` | string | |
| `headline` | object | `protectedPct`, `peopleHoursSaved`, `likelyRange[2]`, `peopleHoursUsual`, `peopleHoursPlan`, `assetsUsed`, `assetsTotal` (10), `extraKm` (14.5), `confidence` (0.88) |
| `summary`, `reasoning` | string | |
| `groups[]` | object | `asset`, `kind` (`sprinkler` / `smog_gun`), `label`, `tasks[]` of `{id, op, time, place, action, cause, causeConf, reason, flag?}` |
| `comments[]` | object | `{id, taskId, status ("open" / "applied"), objection, confidence, suggestion: {remove, add}}` |
| `checks[]` | object | three fixed checks `{id, label, detail, ok: true}` |
| `approvedAt`, `approvalNote`, `changesNote`, `executionArn` | string | added by the actions below |

#### `GET /v1/plans`

> Status: **Partial**. Data source: Memory (plus the fixture seed).

`200`: `{"asOf": "...", "simulated": true, "items": [<plan>, ...]}`, sorted by `draftedAt` descending.

```json
{
  "asOf": "2026-10-10T05:13:06.599810Z",
  "simulated": true,
  "items": [
    {
      "id": "214",
      "ward": "ward-084",
      "window": {"start": "2026-10-10T15:13:06.599781Z", "end": "2026-10-10T19:13:06.599781Z", "label": "Thu 06:00 – 10:00"},
      "status": "draft",
      "draftedAt": "2026-10-10T05:13:06.599781Z",
      "draftedBy": "AI-ML Planner (Claude Opus 5)",
      "headline": {"protectedPct": 42.0, "peopleHoursSaved": 14200.0, "likelyRange": [11500.0, 16800.0], "peopleHoursUsual": 34000.0, "peopleHoursPlan": 19800.0, "assetsUsed": 8, "assetsTotal": 10, "extraKm": 14.5, "confidence": 0.88},
      "summary": "Focuses mechanical sweepers on GT Road dust corridor before 07:00 AM rush hour, ...",
      "reasoning": "High PM2.5 (380 ug/m3) forecast at 08:00 combined with low boundary layer. ...",
      "groups": [{"asset": "T-12", "kind": "sprinkler", "label": "Sprinkler 12 (West)", "tasks": [{"id": "tsk-01", "op": "add", "time": "06:10", "place": "Mundka Metro Corridor", "action": "Median misting", "cause": "Dust", "causeConf": 0.82, "reason": "Target unpaved shoulder near bus stops before pedestrian peak"}]}],
      "comments": [{"id": "com-01", "taskId": "tsk-02", "status": "open", "objection": "Sprinkler allocated within 100 m of CPCB station site_301; anti-gaming guard triggered.", "confidence": 0.92, "suggestion": {"remove": "tsk-02", "add": "Relocate spray curtain 250 m upwind to North-West perimeter"}}],
      "checks": [{"id": "chk-01", "label": "No water on open burning", "detail": "All sprinkler routes target Dust only", "ok": true}]
    }
  ]
}
```

#### `GET /v1/plans/{plan_id}`

> Status: **Partial**. Data source: Memory.

`200`: the plan object. `404` `{"detail": "Plan '<id>' not found"}`. `GET /v1/plans/draft` also returns this 404 (the path matches `{plan_id}`).

#### `POST /v1/plans/draft`

> Status: **Partial**. Data source: AI-ML (`IntelClient.draft_plan`), stored in Memory.

Body `DraftPlanRequest`:

| Field | Type | Required | Notes |
|---|---|---|---|
| `ward` | string | yes | `All wards` / `all` / empty draft for every ward |
| `windowStart` | string | no | accepted, **ignored** |

Order: AI-ML `POST /plans/draft` with `{ward, limit_hotspots: 8, shift_hours: 4.0, assets: [T-12 sprinkler at 28.65,77.15, 10 000 L; ASG-07 smog_gun at 28.67,77.13, 8 000 L]}` → in-process `planner_agent.draft_plan(limit_hotspots=6)` plus `auditor_agent.audit_plan` → fixed fallback plan. The result is stored under its `id` (README Known issue 11: same-minute drafts collide).

`200` (AI-ML path, abbreviated):

```json
{
  "id": "PLAN-20261010-0513",
  "ward": "ward-084",
  "window": {"start": "2026-10-10T15:13:48.923207Z", "end": "2026-10-10T19:13:48.923207Z", "label": "Thu 06:00 – 10:00"},
  "status": "draft",
  "draftedAt": "2026-10-10T05:13:48.923207Z",
  "draftedBy": "AI-ML Planner (VRP Optimizer + Auditor Agent)",
  "headline": {"protectedPct": 42.0, "peopleHoursSaved": 823024.7, "likelyRange": [658419.8, 987629.6], "peopleHoursUsual": 1975259.3, "peopleHoursPlan": 1152234.6, "assetsUsed": 2, "assetsTotal": 10, "extraKm": 14.5, "confidence": 0.88},
  "summary": "Exposure-first dispatch for ward-084 avoiding 823025 person-hours.",
  "reasoning": "VRP solver prioritized key school clusters before 8 AM.",
  "groups": [{"asset": "ASG-07", "kind": "smog_gun", "label": "Vehicle ASG-07", "tasks": [{"id": "TASK-001", "op": "add", "time": "05:25", "place": "Cell G-050-072", "action": "suppress_unknown", "cause": "Traffic", "causeConf": 0.82, "reason": "Cause is unknown (conf 40%). Targeting 142158 person-hours exposure reduction."}]}],
  "comments": [{"id": "com-01", "taskId": "TASK-001", "status": "open", "objection": "Plan verified and approved. ...", "confidence": 0.91, "suggestion": {"remove": "TASK-001", "add": "Relocate spray curtain 250 m upwind to North-West perimeter"}}],
  "checks": [{"id": "chk-01", "label": "No water on open burning", "detail": "All sprinkler routes target Dust only", "ok": true}]
}
```

Codes: `200`; `422` when `ward` is missing.

#### `POST /v1/plans/{plan_id}/approve`

> Status: **Partial**. Data source: Memory; AWS Step Functions when configured.

Body `ApprovePlanRequest` is optional: `{"note": "..."}`. Sets `status: "approved"`, `approvedAt`, `approvalNote` (if a note was sent), then calls `aws.start_dispatch(plan)`. If it returns an execution ARN, `executionArn` is set; otherwise the key is removed. With AWS off (the default) there is never an `executionArn`.

Codes: `200` (the updated plan); `404` unknown plan; `422` malformed body.

#### `POST /v1/plans/{plan_id}/request-changes`

> Status: **Partial**. Data source: Memory.

Body `RequestChangesRequest` (required): `{"note": "Shift schedule earlier"}`. Sets `status: "changes_requested"` and `changesNote`. Codes: `200`; `404`; `422` when the body is missing.

#### `POST /v1/plans/{plan_id}/suggestions/{comment_id}/apply`

> Status: **Partial**. Data source: Memory.

Marks every comment with that id as `status: "applied"`. The tasks are not changed. Returns `200` with the plan even when no comment matches. `404` for an unknown plan.

#### `GET /v1/plans/{plan_id}/compare` and `POST /v1/plans/{plan_id}/simulate`

> Status: **Partial**. Data source: AI-ML for `deltaPct`; the rows are hard-coded.

One handler on both. Does not check that the plan exists. AI-ML `POST /plans/{id}/simulate` with `{"hotspots": [], "assets": []}` → in-process `get_whatif_simulator().simulate_comparison(top 5 hotspots, [T-12, ASG-07])` → fixed fallback. Only `delta_gain_pct` is taken from AI-ML.

`200`:

```json
{
  "planId": "214",
  "deltaPct": 42.0,
  "rows": [
    {"asset": "T-12", "usual": "Ring Road fixed sweep", "plan": "Mundka School Corridor", "kmUsual": 22.0, "kmPlan": 28.5, "reachUsual": "1,200 commuters", "reachPlan": "4,800 students & residents", "exposureDelta": -3600.0},
    {"asset": "ASG-07", "usual": "Bawana Industrial Gate", "plan": "Bawana Cluster 3 unpaved zone", "kmUsual": 15.0, "kmPlan": 16.2, "reachUsual": "650 workers", "reachPlan": "2,400 residents", "exposureDelta": -2100.0}
  ]
}
```

## 7. Fleet, impact, alerts, driver

#### `GET /v1/devices`

> Status: **Stub/Mock**. Data source: Fixture (`get_mock_assets`).

`200`: `{"asOf", "simulated": true, "items": [...]}` with two assets, `T-12` (sprinkler, `Spraying`) and `ASG-07` (smog gun, `En route`):

```json
{
  "id": "ASG-07", "kind": "smog_gun", "label": "Anti-Smog Gun 07", "depot": "Rohini Sector 3",
  "task": "Bawana Industrial Gate 2", "status": "En route", "tagSummary": "En route to stop 2",
  "lastPingAt": "2026-10-10T05:13:06.676934Z", "at": [77.051, 28.776], "simulated": true,
  "tag": {"tagId": "HTG-0007", "fw": "v1.4.2", "pumpOn": false, "flowLpm": 0.0, "litresThisRun": 0.0, "tankLitres": 9000.0,
          "sprayWindows": [{"start": "07:45", "end": "09:00"}], "tamperIntact": true, "signalDbm": -72, "trust": 0.91, "lastSeq": 182}
}
```

`T-12`'s tag additionally has `pm10Before` and `pm10Now`.

#### `GET /v1/impact`

> Status: **Partial**. Data source: Fixture (`get_mock_impact`) whose first item's `impact` is replaced by `IntelClient.verify_intervention(...)`; a 36-point observed-vs-control `series` (5 min steps, spray starting at step 12) is then synthesised from the verified effect by `fixtures.impact_series`.

`200` (one series point and one donor cell shown):

```json
{
  "asOf": "2026-10-10T05:13:06.690358Z",
  "simulated": true,
  "summary": {"verifiedPct": 78.4, "targetPct": 85.0, "noEffect": 3, "wrongTool": 1},
  "items": [
    {
      "id": "int-01", "asset": "T-12", "action": "Water Spray", "cellId": "g500-041-077", "place": "Mundka Main Road",
      "cause": "Dust", "startedAt": "2026-10-10T05:13:06.690358Z", "simulated": true,
      "impact": {
        "pollutant": "pm25", "effectPct": -18.8, "ciLow": -22.2, "ciHigh": -15.4, "durationMin": 45,
        "method": "synthetic_control", "donorCells": [{"cellId": "C-2863-7720", "weight": 0.45}], "verdict": "Verified",
        "series": [{"t": "2026-10-10T04:13:06.690358Z", "observed": 330.0, "control": 330.0, "lo": 318.8, "hi": 341.2}]
      }
    }
  ]
}
```

#### `GET /v1/impact/library`

> Status: **Implemented**. Data source: AI-ML (`GET /effectiveness-library`, else `get_effectiveness_library().records`, else 3 fixture records).

`200` (5 records on the AI-ML path; one shown):

```json
{
  "asOf": "2026-10-10T05:13:06.741847Z",
  "simulated": true,
  "items": [{"action": "Water Sprinkler", "cause": "Dust", "weather": "RH < 60%, Wind <= 2.5 m/s", "effectPct": -18.9, "ci": [-22.2, -15.4], "durationMin": 92, "n": 129}]
}
```

`effectPct` is forced negative; `cause` is `Dust` or else `Burning`; `weather` is a constant on the AI-ML paths (README Known issue 9).

#### `GET|POST /v1/impact/{intervention_id}/verify` and `GET|POST /v1/interventions/{intervention_id}/verify`

> Status: **Partial**. Data source: AI-ML. Four operations, one behaviour; no body; the id is passed to AI-ML but no stored intervention is looked up.

Order: AI-ML `POST /interventions/{id}/verify` → in-process `hawa_ml.causal.placebo.verify_injected_intervention_recovery()` (the injected-effect acceptance test, so the result does not depend on the id) → fixed fallback.

`200`:

```json
{"pollutant": "pm25", "effectPct": -18.8, "ciLow": -22.2, "ciHigh": -15.4, "durationMin": 45, "method": "synthetic_control", "donorCells": [{"cellId": "C-2863-7720", "weight": 0.45}, {"cellId": "C-2863-7722", "weight": 0.35}, {"cellId": "C-2864-7721", "weight": 0.2}], "verdict": "Verified"}
```

`verdict` is `Verified` or `Inconclusive`. Donor cells are hard-coded on every path.

#### `GET /v1/alerts`

> Status: **Stub/Mock**. Data source: Fixture (`get_mock_alerts`).

`200`: `{"asOf", "simulated": true, "counts": {"All": 2, "School": 1, "Citizens": 1, "Citizen Eyes": 0}, "items": [...]}`. Items have `id`, `sentAt`, `audience`, `target`, `channel` (`WhatsApp` / `SMS`), `lang`, `message`, `messageHi` (school alert only), `delivered`, `leadTimeH`, `draftedBy`. Nothing is sent to anyone.

#### `GET /v1/driver/route`

> Status: **Stub/Mock**. Data source: Fixture (`get_mock_driver_route`).

| Query | Default |
|---|---|
| `asset` | `T-12` (echoed; the route is the same for every asset) |

`200`:

```json
{
  "asset": "T-12", "assetLabelHi": "वॉटर स्प्रिंकलर १२", "planId": "plan-master-20261112",
  "dateLabel": "Thursday, 12 Nov 2026", "window": "06:00 – 10:00 IST",
  "stops": [{"n": 1, "placeHi": "मुंडका मुख्य मार्ग, मेट्रो पिलर ३४०-३६०", "placeEn": "Mundka Main Road, Metro Pillars 340-360", "actionEn": "Continuous median misting", "from": "06:10", "to": "07:20", "status": "done"}],
  "lastSpray": {"placeHi": "मुंडका मुख्य मार्ग", "litres": 1420.0, "pumpMin": 22.0, "pumpOn": true}
}
```

Three stops with statuses `done`, `active`, `todo`.

## 8. Open data

#### `GET /open/v1/air`

> Status: **Implemented**. Data source: AI-ML (a projection of `get_hotspots`). No rate limit.

| Query | Type | Default | Rule |
|---|---|---|---|
| `ward` | string | none | as for hotspots |
| `limit` | int | `50` | `1 ≤ limit ≤ 200`; the AI-ML paths return at most 50 cells, the fixture path ignores it and returns 10 |

`200`:

```json
{
  "asOf": "2026-10-10T05:13:06.884134Z",
  "simulated": false,
  "pollutant": "pm25",
  "unit": "ug/m3",
  "cells": [{"cellId": "G-050-072", "ward": "Ward-3", "lon": 77.086, "lat": 28.679, "pm25": 74.8, "band": "Moderate", "likelyCause": "Dust", "causeConfidence": 0.4}]
}
```

## 9. Citizen experience

`api/routes/citizen.py`. These routes call `hawa_ml` singletons directly (no HTTP, no fallback), return their snake_case payloads unchanged, and have no tests in `backend/tests`.

#### `POST /v1/citizen/safe-route`

> Status: **Implemented**. Data source: AI-ML (in-process `hawa_ml.exposure.routing.safe_route_optimizer.compute_route_alternatives`); the background PM2.5 is set to the live twin mean first.

Body `SafeRouteRequest`: `{"origin": {"lat": 28.63, "lon": 77.21}, "destination": {"lat": 28.55, "lon": 77.25}, "mode": "cycling"}`; `mode` is `walking`, `cycling` (default), `two_wheeler` or `car`.

`200`: `{origin, destination, mode, ventilation_rate_lpm, fastest, cleanest, balanced}`; each option is:

```json
{"label": "Optimal Balance", "tagline": "Best compromise between travel time & lung intake", "distance_km": 12.4, "duration_min": 48, "time_delta_min": 6, "avg_pm25": 65.9, "inhaled_dose_ug": 94.9, "dose_saved_pct": 18.4, "air_grade": "Satisfactory (Balanced)", "highlights": ["Bypasses congested junctions", "+2 mins travel time", "Balanced exposure"], "waypoints": [[28.63, 77.21], [28.55, 77.25]]}
```

(`fastest` has no `time_delta_min`; waypoints are `[lat, lon]`.)

#### `GET /v1/citizen/safe-window`

> Status: **Implemented**. Data source: AI-ML (in-process `hawa_ml.forecasting.safe_window.safe_window_calculator.compute_daily_window`); baseline set to the live twin mean.

| Query | Default |
|---|---|
| `lat` | `28.6139` |
| `lon` | `77.2090` |
| `persona` | `general` (`asthma_elderly`, `children_school`, `runners_athletes`, `general`) |

`200`: `{persona, persona_label, threshold_pm25, has_safe_window, recommended_window, lowest_pm25, danger_window, peak_pm25, recommendation, timeline[24]}`, with timeline entries `{"hour": 0, "time_label": "00:00", "pm25": 78.6, "band": "Moderate", "color": "#B8920A", "is_safe": true, "inversion_risk": "LOW"}`.

#### `GET /v1/citizen/live-operations`

> Status: **Stub/Mock**. Data source: `hawa_ml.simulation.audit.FLEET_TELEMETRY` (a constant table of 3 vehicles) plus two literal verified interventions.

| Query | Rule |
|---|---|
| `ward` | optional, case-insensitive substring match on each vehicle's `ward` |

`200`: `{"as_of": "2026-10-08T03:00:00Z", "active_fleet_count": 3, "active_fleet": [...], "verified_interventions": [...]}`. Fleet entries: `asset_id, type, ward, assigned_route, status, last_gps [lat, lon], speed_kmh, water_pump_flow_lpm, water_disbursed_liters, contractor_id, dwell_minutes_on_route, is_compliant`. Interventions: `intervention_id, asset_id, action_type, location_name, lat, lon, treated_time, pm10_reduction_pct, pm25_reduction_pct, confidence_interval_95, duration_minutes, water_disbursed_liters, verified_by, status`. `as_of` never changes.

#### `POST /v1/citizen/reports/missed-machine`

> Status: **Partial**. Data source: AI-ML (in-process `iot_auditor.audit_missed_intervention`) against the constant fleet table. Nothing is stored.

Body `MissedMachineReport`: `{"asset_id": "SPR-04", "cell_id": "G-052-054", "ward": "Preet Vihar", "reported_by": "citizen_mobile_app"}` (`reported_by` optional).

`200` for a known asset: `{report_id, timestamp, asset_id, ward, verdict: "MACHINE_ACTIVE_VERIFIED", sla_breach, message, telemetry: {...}}`; for an unknown asset: `verdict: "UNDER_INVESTIGATION"` and no `telemetry`. `422` when a required field is missing.

#### `GET /v1/citizen/wards/leaderboard`

> Status: **Stub/Mock**. Data source: literals in the route.

`200`: `{"total_wards": 250, "leaderboard": [{"rank": 1, "ward_name": "Hauz Khas (Ward 152)", "grade": "A+", "avg_pm25": 118.0, "route_compliance_pct": 98.4, "complaints_resolved_pct": 96.0, "badge": "Green Leader"}, ...7 rows], "methodology": "..."}`.

## 10. Calls the backend makes to AI-ML

`core/intel_client.py` (`IntelClient`, singleton via `get_intel_client()`). Base URL `HAWA_AIML_SERVICE_URL` (default `http://localhost:8100`), per-request `httpx.AsyncClient(timeout=HAWA_AIML_TIMEOUT_SECONDS)` (default 10 s), no auth header, no propagated request ids. Paths are unprefixed (AI-ML mounts its router at `/`, `/v1` and `/internal/v1`). Circuit breaker and fallback rules are in [ARCHITECTURE.md](ARCHITECTURE.md) §3.

| `IntelClient` method | Used by | AI-ML HTTP call | In-process fallback (`hawa_ml`) | Last resort |
|---|---|---|---|---|
| `get_hotspots` | `/v1/hotspots*`, `/v1/forecast`, `/open/v1/air` | `GET /hotspots?ward=<ward or all>&hour=<0-23>&limit=50`, then `GET /forecast/{cell_id}?pm25=<pm25>` per kept cell (concurrently) | `api.deps.get_exposure_engine().get_ranked_hotspots(twin, top_n=50, hour, ward)`, `get_forecaster().predict_cell_forecast` | `fixtures.get_mock_hotspots(hour)` |
| `get_digital_twin` | `/v1/twin` | `GET /twin?bbox&ts&limit` | `api.deps.get_twin_engine().fit_and_predict(live stations)` | fixture hotspots |
| `get_forecast(cell_id)` | `/v1/forecast/{cell_id}` | `GET /forecast/{cell_id}` | `api.deps.forecaster_agent.analyze_forecast` | `fixtures.get_mock_forecast()` |
| `_cell_horizons` | `/v1/forecast` (GRAP actions) | `GET /forecast/{cell_id}?pm25=` | `get_forecaster().predict_cell_forecast` | none |
| `draft_plan` | `POST /v1/plans/draft` | `POST /plans/draft` | `api.deps.planner_agent.draft_plan`, `auditor_agent.audit_plan`, `schemas.AssetSpec/PlanTask/Hotspot` | fixed plan |
| `simulate_plan` | compare / simulate | `POST /plans/{plan_id}/simulate` | `get_whatif_simulator().simulate_comparison` on `get_grid()` | fixed rows |
| `verify_intervention` | impact routes | `POST /interventions/{id}/verify` | `causal.placebo.verify_injected_intervention_recovery()` | fixed result |
| `get_effectiveness_library` | `/v1/impact/library` | `GET /effectiveness-library` | `get_effectiveness_library().records` | 3 fixed records |
| `health` | tests only | `GET /health` | static dict (`mode: in-process` or `fallback`) | — |
| `calibrate_reading` | tests only | — | `drive_by_calibrator.calibrate_reading` | `max(0, 0.85·raw − 0.15·RH + 5)`, trust 0.92 |

The citizen routes import `hawa_ml.exposure.routing.safe_route_optimizer`, `hawa_ml.forecasting.safe_window.safe_window_calculator`, `hawa_ml.simulation.audit.iot_auditor` and `FLEET_TELEMETRY` directly.

## 11. Planned API (target design)

> Status: **Planned**. None of the endpoints, conventions or protocols in this section exist in the code. They are the design the frontend, app and AI-ML documents were written against. The full pre-implementation specification (request/response bodies, examples, error catalogue) is preserved in git history: `git show a33e043:docs/backend/API.md`.

### 11.1 Planned conventions

| Topic | Target design |
|---|---|
| Field names | `snake_case` everywhere (CONTRACTS §1). The built routes use camelCase for the console; a decision is needed before the planned endpoints are added. |
| Errors | RFC 9457 `application/problem+json` for every non-2xx, `type = urn:hawa:problem:<code>`, stable `code` catalogue (`validation_failed`, `auth.token_expired`, `forbidden.ward_scope`, `plan.not_draft`, `plan.version_conflict`, `plan.constraint_violation`, `upstream.aiml_unavailable`, `upstream.timeout`, `rate_limited`, …), `request_id` extension, FastAPI validation errors mapped to `validation_failed` |
| Auth | Officers/admins/analysts: email + password (argon2id). Drivers, inspectors, schools, site managers, citizens: phone OTP (5 min, hashed in Redis). Access JWT (RS256, `kid`, 15 min) + rotating opaque refresh token with reuse detection; Cognito-compatible verifier; deny list `jwt:deny:{jti}` |
| RBAC | Roles `admin`, `officer`, `analyst`, `inspector`, `driver`, `school`, `site_manager`, `citizen` (`hawa_contracts.enums.UserRole`), plus `public` and `service`; ward scoping from `user_ward_scope` (`403 forbidden.ward_scope` for an explicit out-of-scope ward, `404` for a single out-of-scope object) |
| Headers | `X-Request-Id` always generated and echoed; `X-Correlation-Id` defaulting to the request id and forwarded to AI-ML; `traceparent`; `Idempotency-Key` on every state-changing POST/PATCH (Redis `idem:{user_id}:{key}`, 24 h); `If-Match` / `ETag "v{version}"` on plans |
| Pagination | Opaque keyset cursors, `limit` default 50, max 200, `{items, next_cursor}` |
| HTTP caching | `ETag` + `Cache-Control` per resource (tiles immutable with `?v={tile_version}`, forecasts 300 s, open data public 60 s) |
| Rate limits | Redis sliding windows: open data 60/min/IP, OTP 3 per 15 min per phone, login 10 per 15 min, reports 10/h/user, default 600/min/user; `RateLimit-*` and `Retry-After` headers |
| CORS | Allow-list from `HAWA_CORS_ORIGINS`, no credentials |
| OpenAPI | Stable `operationId`s, typed `response_model`s, exported and diffed in CI; generated TypeScript and Dart clients |

### 11.2 Planned endpoints

| Area | Endpoints |
|---|---|
| Auth and session | `POST /v1/auth/login`, `POST /v1/auth/otp/request`, `POST /v1/auth/otp/verify`, `POST /v1/auth/refresh`, `POST /v1/auth/logout`, `GET /v1/auth/jwks.json`, `GET /v1/me`, `PUT /v1/me/push-token`, `DELETE /v1/me/push-token` |
| Twin and cells | `GET /v1/twin/tiles/{z}/{x}/{y}.mvt?v=`, `GET /v1/cells/{cell_id}`, `GET /v1/cells/{cell_id}/history` (the built `GET /v1/twin` returns JSON cells, not GeoJSON) |
| Hotspots, forecast, GRAP | `GET /v1/hotspots?limit=&run_id=&cause=` filters, `GET /v1/forecast/grid`, `GET /v1/grap/outlook`, `GET /v1/grap/checklist` |
| Plans | `202` async draft with a `drafting` row and WebSocket completion, `GET /v1/plans` filters and cursor, `GET /v1/plans/{id}?include=`, `PATCH /v1/plans/{id}` (edits re-optimised via `POST /internal/v1/optimize`), `POST /v1/plans/{id}/reject`, server-side constraint validation (cause → asset type from `ALLOWED_ASSETS_PER_CAUSE`, shift windows, capacity), version checks, audit trail |
| Tasks (field app) | `GET /v1/tasks/mine`, `GET /v1/tasks/{id}`, `POST /v1/tasks/{id}/ack`, `POST /v1/tasks/{id}/status` (manual-done fallback creating an intervention), `POST /v1/tasks/{id}/evidence` |
| Fleet and devices | `GET /v1/assets`, `GET /v1/assets/{id}`, `GET /v1/fleet/live`, device registry `GET/POST /v1/devices`, `GET /v1/devices/{id}`, `GET /v1/devices/{id}/calibration` |
| Interventions and impact | `GET /v1/interventions`, `GET /v1/interventions/{id}`, `GET /v1/interventions/{id}/impact`, `GET /v1/impact/summary`, `GET /v1/effectiveness` |
| Alerts | `GET /v1/alerts` with filters, `GET /v1/alerts/{id}`, `POST /v1/alerts` (officer-triggered), delivery through FCM, WhatsApp Cloud API and SNS SMS |
| Schools | `GET /v1/schools/me`, `GET /v1/schools/{id}/safe-window`, `GET /v1/schools/{id}/indoor-outdoor` |
| Citizen Eyes | `POST /v1/reports`, `GET /v1/reports/mine`, `GET /v1/reports/{id}`, WhatsApp webhook `GET`/`POST /v1/reports/webhook/whatsapp` (HMAC `X-Hub-Signature-256`) |
| Inspections, sites, integrity | `GET /v1/inspections`, `POST /v1/inspections/{id}/assign`, `POST /v1/inspections/{id}/close`, `GET /v1/sites`, `GET /v1/sites/{id}`, `GET /v1/sites/me`, `GET /v1/integrity/flags`, `GET /v1/coverage/blind-spots` |
| Evidence reports, uploads | `GET/POST /v1/evidence-reports`, `GET /v1/evidence-reports/{id}/pdf`, `POST /v1/uploads/presign` |
| Open data | `/open/v1/air?bbox=&ts=&include_simulated=`, `/open/v1/stations`, `/open/v1/cells/{cell_id}/history`, `/open/v1/methods`, per-IP rate limit |
| Ops | `/readyz` with real Postgres, Redis and migration checks (503 when not ready); `/metrics` (Prometheus) |

### 11.3 Planned WebSocket `/v1/ws`

JSON frames over one socket per client; JWT via `Sec-WebSocket-Protocol: bearer, <JWT>` or `?token=`; client ops `subscribe`, `unsubscribe`, `ping`, `pong`, `auth`; server envelope `{channel, type, event_id, seq, ts, data}`; channels `twin`, `hotspots:{ward_id}`, `fleet` (coalesced to 1 Hz), `devices`, `plan:{plan_id}`, `tasks:me`, `alerts:me`, `impact`; fan-out across replicas through the Kafka group `api-live` and Redis pub/sub `ws:{channel}`; server ping every 25 s; close codes 4401, 4403, 4408, 4429. The Flutter app already points at `ws://10.0.2.2:8000/v1/ws` (`app_frontend/lib/app/env.dart:11`).

### 11.4 Planned internal client to AI-ML

The target replaces today's unprefixed calls with `/internal/v1/simulate`, `/internal/v1/optimize`, `/internal/v1/exposure`, `/internal/v1/models` and `/internal/v1/healthz` (CONTRACTS §7), a shared pooled `httpx.AsyncClient`, `Authorization: Bearer ${HAWA_INTERNAL_TOKEN}`, propagated `X-Request-Id`/`X-Correlation-Id`/`traceparent`, per-endpoint connect/read timeouts, one retry on connect errors, a breaker that also opens on ≥ 50 % failures over 20 calls, and errors surfaced as `503 upstream.aiml_unavailable` / `504 upstream.timeout` instead of silent fallbacks.
