# HawaCommand Backend — Implementation Phases & Integration Guide

Welcome! This document is the **authoritative roadmap and status tracker** for the `backend/` service of HawaCommand.
Any agent or human engineer working on or integrating with the backend must consult this document.

---

## Roadmap & Phase Status

| Phase | Title | Scope | Status | Verification & Docs |
|---|---|---|---|---|
| **Phase 1** | **Foundation & Contracts** | Root configuration, workspace setup, canonical enums, IDs, units, packets, envelopes, Kafka topics, Redis keys, domain events | **COMPLETED** | [`docs/PHASE_1_FOUNDATION.md`](docs/PHASE_1_FOUNDATION.md) (All unit tests passing) |
| **Phase 2** | **Core Runtime & Security** | Settings (`pydantic-settings`), contextual logging with PII masking, RFC 9457 errors, JWT/Argon2 security, IST clock abstraction | **COMPLETED** | [`docs/PHASE_2_CORE_RUNTIME.md`](docs/PHASE_2_CORE_RUNTIME.md) (All unit tests passing) |
| **Phase 3** | **Database & Data Models** | SQLAlchemy 2.0 async models for grid, devices, readings, assets, plans, tasks, interventions, alerts, outbox, spatial helpers | **COMPLETED** | [`docs/PHASE_3_DATABASE_MODELS.md`](docs/PHASE_3_DATABASE_MODELS.md) (All unit tests passing) |
| **Phase 4** | **API Command Surface** | FastAPI app factory, CORS, health probes, `/v1/hotspots`, `/v1/forecast`, `/v1/plans`, `/v1/devices`, `/v1/impact`, `/v1/alerts`, `/v1/driver/route` | **COMPLETED** | [`docs/PHASE_4_API_SURFACE.md`](docs/PHASE_4_API_SURFACE.md) (All unit & integration tests passing) |
| **Phase 5** | **Ingest, Workers & Sagas** | MQTT/telemetry ingestion, packet dedupe, fleet simulator, dispatch saga choreography, verification runner | **COMPLETED** | [`docs/PHASE_5_WORKERS_AND_SIMULATOR.md`](docs/PHASE_5_WORKERS_AND_SIMULATOR.md) (All unit & saga tests passing) |
| **Phase 6** | **Integration & Verification** | End-to-end integration pipeline test, cross-stack Zod contract validation (`frontend/scripts/verify_backend_contracts.ts`) on 14 endpoints | **PARTIAL** | Test run 2026-10-10: 64 passed, 1 failed (`tests/integration/test_end_to_end.py::test_full_mission_air_pipeline` expects simulated hotspots) |

> **Status note (2026-10-10).** "Completed" above means the code for the phase exists and its unit tests pass. It does not mean the parts are wired together: Alembic migrations (`backend/migrations/`) and a seed script (`src/hawa_backend/db/seed.py`) now exist, but the API does not use the database models, nothing publishes to or consumes from Kafka, Redis is not used, and the workers are not connected to MQTT. See [README.md](README.md#implementation-status) and [docs/backend/README.md](../docs/backend/README.md).

---

## Integration Context for Other Teams & Agents

### 1. For AI-ML (`AI-ML/`)
- Install `hawa-contracts` directly as an editable package: `pip install -e ../backend/contracts`. Note that today AI-ML does not import `hawa_contracts`; the dependency runs the other way (the backend imports `hawa_ml`, see `src/hawa_backend/api/routes/citizen.py` and `src/hawa_backend/core/intel_client.py`).
- Import canonical IDs, topics, enums, and event envelopes from `hawa_contracts`.
- Ensure model outputs carry uncertainty: `p10/p50/p90` for forecasts, `ci_low/ci_high` for verifier, and `cause_conf` for fingerprints.
- Obey hard dispatch constraints: `ALLOWED_ASSETS_PER_CAUSE` from `hawa_contracts.enums`.

### 2. For Web Frontend (`frontend/`)
- The web frontend keeps hand-written Zod schemas in `frontend/src/contracts/` that mirror the backend's camelCase responses (there is no `@hawa/contracts` package).
- REST endpoints served on `http://localhost:8000/v1/*` match [`docs/backend/API.md`](../docs/backend/API.md).
- Responses are strictly validated with Zod in `frontend/src/lib/api.ts`.

### 3. For Mobile App (`app_frontend/`)
- `/v1/driver/route` exists (fixture). `/v1/tasks/*`, `/v1/auth/*`, `/v1/inspections*`, `/v1/reports*`, `/v1/uploads/presign` and `/v1/ws` are Planned; the app uses its in-app fake backend for them.
- Offline outbox submissions must supply `Idempotency-Key` headers matching `hawa_contracts.ids.uuid7()`.
