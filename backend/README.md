# HawaCommand Backend

The central nervous system of HawaCommand: edge packet validation & calibration, PostGIS spatial persistence, asynchronous Kafka event streaming, dispatch saga orchestration, and the REST/WebSocket command surface for officers and drivers.

---

## Architecture & Phases

All development follows a disciplined, phase-wise implementation with test verification and documentation after every phase:

- [**PHASES.md**](PHASES.md) — Master roadmap and status guide for all agents and contributors.
- [**Phase 1: Foundation & Contracts**](docs/PHASE_1_FOUNDATION.md) — Canonical enums, IDs, units, MQTT packets, envelopes, topics, and domain events (`hawa-contracts`).
- [**Phase 2: Core Runtime & Security**](docs/PHASE_2_CORE_RUNTIME.md) — Pydantic settings, contextual logging with PII masking, RFC 9457 errors, JWT security, and clock abstractions.
- [**Phase 3: Database & PostGIS Models**](docs/PHASE_3_DATABASE_MODELS.md) — SQLAlchemy 2.0 models for grid, devices, readings, assets, plans, tasks, interventions, alerts, and outbox.
- [**Phase 4: API Command Surface**](docs/PHASE_4_API_SURFACE.md) — FastAPI application with `/healthz`, `/v1/hotspots`, `/v1/forecast`, `/v1/plans`, `/v1/devices`, `/v1/impact`, `/v1/alerts`, and `/v1/driver/route`.
- [**Phase 5: Ingest, Simulator & Sagas**](docs/PHASE_5_WORKERS_AND_SIMULATOR.md) — Edge telemetry deduplication, Huber humidity calibration, 3x spike detection, virtual fleet simulator, and automated HawaTag spray matching.
- **Phase 6: Integration & Verification** — End-to-end integration test across all subsystems, cross-stack Zod contract validation on all 14 endpoints with zero conflicts.

---

## Quick Start

### 1. Installation
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
uv pip install -e contracts
uv pip install -r pyproject.toml
```

### 2. Run Test Suite
```bash
PYTHONPATH=src:contracts .venv/bin/pytest tests contracts/tests
```
*Current test status: 35 passed (100% pass rate).*

### 3. Start API Server
```bash
PYTHONPATH=src:contracts .venv/bin/uvicorn hawa_backend.api.app:app --host 0.0.0.0 --port 8000 --reload
```
Interactive OpenAPI documentation will be accessible at `http://localhost:8000/docs`.

### 4. CLI Tool
```bash
PYTHONPATH=src:contracts .venv/bin/python -m hawa_backend.cli config
```
