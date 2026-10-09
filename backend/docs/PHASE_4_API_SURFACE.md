# Phase 4: API Command Surface

## Overview
Phase 4 implements the complete REST command surface required by the Next.js officer console (`frontend/`) and the Flutter mobile driver application (`app_frontend/`). Every endpoint strictly adheres to [`docs/backend/API.md`](../../docs/backend/API.md) and the Zod contracts defined in `frontend/src/contracts/`.

## Artifacts & Components Created

1. **`hawa_backend.api.app`** (`src/hawa_backend/api/app.py`):
   - FastAPI application factory `create_app()` with OpenAPI documentation available at `/docs`.
   - Wildcard CORS configuration allowing cross-origin requests from web console and mobile emulators.
   - Context middleware extracting and injecting `X-Request-Id` and `X-Correlation-Id` headers.
   - RFC 9457 Problem Details error handler for domain exceptions.

2. **Route Handlers** (`src/hawa_backend/api/routes/`):
   - **`health.py`**:
     - `GET /healthz`: Kubernetes/container liveness probe.
     - `GET /readyz`: Readiness check confirming database and cache status.
   - **`hotspots.py`**:
     - `GET /v1/hotspots`: Returns ranked pollution clusters filtered by `hour` (-24 to +72), `ward`, and PM2.5 `threshold`.
     - Returns cell coordinates, PM2.5 concentration, CPCB band, cause attribution (`Dust`, `Traffic`, `Burning`, `Regional smoke`), confidence scores, upwind suspect pin, nearby schools, and 72-hour forecast series.
   - **`forecast.py`**:
     - `GET /v1/forecast`: Returns the city-wide or ward-specific 72-hour forecast with P10/P50/P90 quantile curves, GRAP stage alerts (Stage I–IV), and vulnerable population exposure metrics.
   - **`plans.py`**:
     - `GET /v1/plans`: Lists all daily master and reactive plans.
     - `GET /v1/plans/{id}`: Detailed plan view with asset groupings, route stops, agent reasoning, checks, and auditor comments.
     - `POST /v1/plans/draft`: Triggers a new plan drafting cycle.
     - `POST /v1/plans/{id}/approve`: Officer human-in-the-loop approval endpoint with audit notes and Step Functions / saga execution tracking.
     - `POST /v1/plans/{id}/request-changes`: Rejects or requests modifications with officer notes.
     - `POST /v1/plans/{id}/suggestions/{comment_id}/apply`: Applies Auditor agent suggestions (e.g., swapping a machine or moving an upwind perimeter).
     - `GET /v1/plans/{id}/compare`: What-If simulator endpoint comparing status-quo routes against the AI plan (person-hours saved, delta %).
   - **`devices.py`**:
     - `GET /v1/devices`: Live fleet tracking for water sprinklers, anti-smog guns, and sweepers with real-time pump telemetry, flow rate (LPM), and HawaTag status.
   - **`impact.py`**:
     - `GET /v1/impact`: Causally verified intervention curves comparing observed concentrations against synthetic control donors.
     - `GET /v1/impact/library`: Empirical Intervention Effectiveness Library stratified by cause and machine type.
   - **`alerts.py`**:
     - `GET /v1/alerts`: Multi-channel bilingual alerts sent to schools (safe outdoor activity windows) and citizens.
   - **`driver.py`**:
     - `GET /v1/driver/route`: Turn-by-turn mobile driver view with Hindi-first stop labels (`placeHi`), action descriptions, and auto-done status.

3. **`hawa_backend.api.fixtures`** (`src/hawa_backend/api/fixtures.py`):
   - High-fidelity demo fixtures conforming to Proposal v3 and Claude Design exports, ensuring out-of-the-box UI parity even before historical databases are populated.

## Testing & Verification
All unit and integration tests in `tests/api/test_api.py` were executed:
```bash
PYTHONPATH=src:contracts .venv/bin/pytest tests/api
# 9 passed in 0.90s (100% pass)
```

Verified test cases include:
- Health probe endpoints returning 200 OK.
- `GET /v1/hotspots` spatial filtering and diurnal hour scaling.
- `GET /v1/forecast` 73-point forecast arrays and GRAP Stage II triggers.
- Plan lifecycle transitions: `draft` $\to$ apply suggestion $\to$ `approve` (generating execution ARN).
- What-If plan comparison calculating delta percentages.
- Live asset telemetry carrying HawaTag flow rates and pump status.
- Causal impact verification curves and library records.
- Driver route stops with bilingual English/Hindi copy.
- Request and correlation ID header preservation.
