# Phase 1: Foundation & Shared Contracts

> **Status (2026-10-10).** Implemented: `hawa_contracts` package and its tests pass. Overview: [backend/README.md](../README.md#implementation-status).


## Overview
Phase 1 establishes the bedrock of the HawaCommand backend. It provides the installable Python package `hawa-contracts` which is shared across the Backend and the AI-ML pipelines to ensure 100% type safety and contract adherence.

## Artifacts & Components Created

1. **Workspace & Configuration**:
   - `backend/pyproject.toml`: Configures the `hawa-backend` project and includes the `contracts/` directory as an editable dependency.
   - `backend/.python-version`: Pins Python version to `3.11`.
   - `backend/.env.example`: Standard development defaults for ports, database URLs, Redis, Kafka, and auth secrets.

2. **Package `hawa-contracts` (`backend/contracts/`)**:
   - `enums.py`: Canonical string & integer enums matching `docs/CONTRACTS.md §3`:
     - Device & placement enums (`DeviceRole`, `DevicePlacement`, `DeviceStatus`, `TrustBand`)
     - Pollutants & causes (`Pollutant`, `CauseLabel`)
     - Asset types and statuses (`AssetType`, `AssetStatus`)
     - Policy stages & bands (`GrapStage`, `AqiCategory`, `Verdict`)
     - Dispatch constraints matrix: `ALLOWED_ASSETS_PER_CAUSE` enforcing that water is never sprayed on smoke and trucks are not assigned for regional smoke.
   - `ids.py`:
     - Time-ordered UUIDv7 generator (`uuid7()`)
     - Deterministic UUIDv5 generator (`uuid7_deterministic()`)
     - Grid cell formatting and parsing: `g500-{row:03d}-{col:03d}` and `g1k-{row:03d}-{col:03d}`
     - Regex validators for devices, assets, schools, sites, and wards.
   - `units.py`:
     - Safe exposure thresholds ($C_{\text{safe}}$ PM2.5 = 60 $\mu g/m^3$, PM10 = 100 $\mu g/m^3$)
     - CPCB sub-index formulas and AQI category mapping (`pm25_to_category`, `calculate_indicative_aqi`)
     - Graded Response Action Plan (GRAP) stage mapper (`aqi_to_grap_stage`).
   - `packets.py`:
     - Pydantic models for raw edge packets: `TelemetryPacket` (30 s reading), `DeviceEventPacket` (spike/fault), `SprayPacket` (HawaTag spray log).
     - Validation helper `validate_packet()` with explicit failure reason codes (`REASON_FUTURE_TIMESTAMP`, `REASON_OUT_OF_BOUNDS`, `REASON_HARDWARE_FAULT`).
   - `envelope.py`:
     - Generic Kafka envelope `Envelope[T]` with structured `EventContext` (tracking `event_id`, `correlation_id`, `causation_id`, and `is_simulated`).
   - `topics.py`:
     - Definitions for all 26 Kafka topics and consumer groups (`hawa.telemetry.raw.v1`, `hawa.plan.lifecycle.v1`, etc.).
   - `redis_keys.py`:
     - Standard key builders (`RedisKeyBuilder`) with TTL constants for deduplication, tile caches, live fleet tracking, and distributed locks.
   - `events/`:
     - Domain event payloads: `ReadingCleaned`, `DeviceSpike`, `SprayStarted`, `SprayStopped`, `CmdTwinRebuild`, `TwinUpdated`, `HotspotUpdated`, `ForecastIssued`, `PlanDrafted`, `PlanApproved`, `TaskDispatched`, `AlertRequested`, `ImpactVerified`.

## Testing & Verification
All unit tests in `contracts/tests/test_contracts.py` were executed and verified:
```bash
.venv/bin/pytest contracts/tests
# 8 passed in 0.52s (100% pass)
```

Verified test cases include:
- Monotonic timestamp ordering and RFC 9562 compliance of UUIDv7.
- Precise regex validation for devices (`HPM-*`, `HPS-*`, `HTG-*`) and assets (`AST-SPR-*`, `AST-ASG-*`, `AST-SWP-*`).
- 500 m to 1 km spatial cell aggregation.
- CPCB AQI breakpoints and GRAP stage thresholds.
- Hardware packet validation, timestamp skew rejection, and spatial bounding box checks.
- Edge spray packet telemetry parsing.
