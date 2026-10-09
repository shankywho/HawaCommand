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
| **Phase 6** | **Integration & Verification** | End-to-end integration pipeline test, cross-stack Zod contract validation on all 14 endpoints, zero conflicts | **COMPLETED** | (35/35 tests passing, 14/14 Zod schemas passed) |

---

## Integration Context for Other Teams & Agents

### 1. For AI-ML (`AI-ML/`)
- Install `hawa-contracts` directly as an editable package: `uv pip install -e ../backend/contracts` or as a path dependency.
- Import canonical IDs, topics, enums, and event envelopes from `hawa_contracts`.
- Ensure model outputs carry uncertainty: `p10/p50/p90` for forecasts, `ci_low/ci_high` for verifier, and `cause_conf` for fingerprints.
- Obey hard dispatch constraints: `ALLOWED_ASSETS_PER_CAUSE` from `hawa_contracts.enums`.

### 2. For Web Frontend (`frontend/`)
- Web frontend uses `@hawa/contracts` which mirror the backend `hawa-contracts` schemas.
- REST endpoints served on `http://localhost:8000/v1/*` match [`docs/backend/API.md`](../docs/backend/API.md).
- Responses are strictly validated with Zod in `frontend/src/lib/api.ts`.

### 3. For Mobile App (`app_frontend/`)
- Driver route endpoints and task acknowledgement will be exposed on `/v1/driver/route` and `/v1/tasks/*`.
- Offline outbox submissions must supply `Idempotency-Key` headers matching `hawa_contracts.ids.uuid7()`.
