# Phase 5: Ingest Pipeline, Fleet Simulator & Dispatch Saga

> **Status (2026-10-10).** Partial: ingest dedupe and calibration, the simulator and the dispatch saga are classes with unit tests; none is connected to MQTT, Kafka or the database. Overview: [backend/README.md](../README.md#implementation-status).


## Overview
Phase 5 implements the real-time event workers that close the operational loop: validating and calibrating raw sensor packets, simulating synthetic vehicle fleets and spray tags, tracking active dispatch sagas, and automatically completing driver tasks via HawaTag pump telemetry.

## Artifacts & Components Created

1. **`hawa_backend.workers.ingest`** (`src/hawa_backend/workers/ingest.py`):
   - `IngestProcessor`:
     - **Deduplication**: Enforces strict packet uniqueness based on `(device_id, seq)` within a rolling window. Replays generate `ReadingRejected` (`reason="duplicate_packet"`).
     - **Validation**: Rejects packets with future timestamps (> 60 s clock skew), coordinates outside Delhi NCR boundaries, or hardware error flags (`fan_stall`).
     - **Spatial Grid Assignment**: Projects WGS84 GPS coordinates into 500 m computational cells (`g500-*`) and parent 1 km planning cells (`g1k-*`).
     - **Humidity Compensation**: Applies the Huber calibration formula $PM_{2.5} = \max(0, 0.85 \cdot PM_{2.5,\text{raw}} - 0.15 \cdot RH + 5.0)$ to eliminate fog-induced optical over-reading.
     - **Indicative AQI Calculation**: Computes CPCB sub-indices and categories.
     - **Spike Detection**: Emits `DeviceSpike` when calibrated PM2.5 rises $\ge 3\times$ above recent baseline.

2. **`hawa_backend.workers.simulator`** (`src/hawa_backend/workers/simulator.py`):
   - `FleetSimulator`:
     - Generates authentic batches of 30 s `TelemetryPacket`s across simulated DTC buses and delivery bikes in Delhi corridors.
     - Simulates diurnal pollution cycles and local hotspot plumes.
     - Emits `SprayPacket` events with water flow rate (LPM), pump current (Amperes), and cumulative volume.
     - Strictly enforces the honesty rule by stamping `is_simulated = True`.

3. **`hawa_backend.workers.dispatch`** (`src/hawa_backend/workers/dispatch.py`):
   - `DispatchSagaManager`:
     - Releases approved plan tasks to field drivers (`TaskDispatched`).
     - Automatically monitors incoming HawaTag telemetry:
       - On `spray.start`: Transitions matching task to `in_progress`.
       - On `spray.stop`: Auto-marks task as `done` (`source="hawa_tag"`), links physical intervention ID, and immediately publishes `CmdVerifyRun` to trigger synthetic-control verification without manual paperwork.

## Testing & Verification
All unit tests in `tests/workers/test_workers.py` were executed:
```bash
PYTHONPATH=src:contracts .venv/bin/pytest tests/workers
# 5 passed in 0.13s (100% pass)
```

Verified test cases include:
- Clean packet ingestion with calibration and grid cell assignment.
- Idempotent rejection of replayed duplicate packets.
- Real-time cloud confirmation of $3\times$ PM2.5 spike events.
- Fleet simulator batch generation within Delhi bounds.
- Automated spray matching: `dispatched` $\to$ `in_progress` $\to$ `done` $\to$ `cmd.verify.run`.

## Overall Backend Test Summary
Across all 5 phases:
```bash
PYTHONPATH=src:contracts .venv/bin/pytest tests contracts/tests
# 34 passed in 0.81s (100% pass)
```
