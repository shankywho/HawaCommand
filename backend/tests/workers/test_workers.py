"""Unit tests for ingest worker, simulator, and dispatch saga."""
import pytest
from datetime import datetime, timezone
from hawa_backend.workers.ingest import IngestProcessor
from hawa_backend.workers.simulator import FleetSimulator
from hawa_backend.workers.dispatch import DispatchSagaManager
from hawa_contracts import TelemetryPacket, SprayPacket
from hawa_contracts.enums import TaskStatus


def test_ingest_processor_happy_path():
    processor = IngestProcessor()
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    packet = TelemetryPacket(
        dev="HPM-0142",
        seq=1,
        ts=now_iso,
        lat=28.682,
        lon=77.035,
        spd=18.0,
        pm25=160.0,
        pm10=240.0,
        rh=65.0,
        t=21.0,
        is_simulated=True,
    )

    reading, rejected, spike = processor.process_packet(packet, baseline_pm25=80.0)
    assert rejected is None
    assert reading is not None
    assert reading.device_id == "HPM-0142"
    assert reading.cell_500m_id.startswith("g500-")
    assert reading.cell_1km_id.startswith("g1k-")
    # Calibration applied: 0.85 * 160 - 0.15 * 65 + 5.0 = 136 - 9.75 + 5 = 131.25
    assert 125.0 <= reading.pm25 <= 135.0
    assert reading.is_simulated is True
    # Not a 3x spike over baseline 80
    assert spike is None


def test_ingest_deduplication():
    processor = IngestProcessor()
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    packet = TelemetryPacket(
        dev="HPM-0142",
        seq=5,
        ts=now_iso,
        lat=28.682,
        lon=77.035,
        spd=10.0,
        pm25=95.0,
        rh=55.0,
        t=22.0,
    )

    # First pass: accepted
    r1, rej1, _ = processor.process_packet(packet)
    assert r1 is not None
    assert rej1 is None

    # Second pass: duplicate rejected
    r2, rej2, _ = processor.process_packet(packet)
    assert r2 is None
    assert rej2 is not None
    assert rej2.reason == "duplicate_packet"


def test_ingest_spike_detection():
    processor = IngestProcessor()
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    
    # Very high PM2.5 packet (380 ug/m3 vs baseline 80)
    packet = TelemetryPacket(
        dev="HPM-0007",
        seq=88,
        ts=now_iso,
        lat=28.625,
        lon=77.329,
        spd=5.0,
        pm25=380.0,
        rh=50.0,
        t=19.0,
    )

    reading, rejected, spike = processor.process_packet(packet, baseline_pm25=80.0)
    assert reading is not None
    assert spike is not None
    assert spike.device_id == "HPM-0007"
    assert spike.rise_factor >= 3.0
    assert spike.confirmed_by_cloud is True


def test_fleet_simulator():
    sim = FleetSimulator(device_count=5)
    batch = sim.generate_telemetry_batch()
    assert len(batch) == 5
    first = batch[0]
    assert first.dev == "HPM-0001"
    assert first.is_simulated is True
    assert 28.5 <= first.lat <= 28.8
    assert 77.0 <= first.lon <= 77.3

    spray = sim.generate_spray_event(asset_id="AST-SPR-0012", action="start")
    assert spray.asset == "AST-SPR-0012"
    assert spray.flow_lpm == 65.0
    assert spray.is_simulated is True


def test_dispatch_saga_matching():
    saga = DispatchSagaManager()
    
    # 1. Release plan
    tasks = [
        {"id": "tsk-101", "asset_id": "AST-SPR-0012", "place": "Mundka Corridor", "time": "06:10"},
        {"id": "tsk-102", "asset_id": "AST-ASG-0007", "place": "Bawana Industrial Gate", "time": "07:30"},
    ]
    dispatched = saga.release_plan_tasks(plan_id="plan-001", tasks=tasks)
    assert len(dispatched) == 2
    assert dispatched[0].status == TaskStatus.DISPATCHED

    # 2. HawaTag starts spraying
    spray_start = SprayPacket(
        tag="HTG-0012",
        asset="AST-SPR-0012",
        seq=1,
        ts="2026-11-12T06:12:00Z",
        lat=28.682,
        lon=77.035,
        action="start",
        flow_lpm=60.0,
        pump_a=14.0,
        litres_cum=100.0,
    )
    res_start = saga.match_spray_event(spray_start)
    assert res_start is None  # still in progress
    assert saga._active_tasks["tsk-101"]["status"] == TaskStatus.IN_PROGRESS

    # 3. HawaTag stops spraying -> auto-completes task and triggers verification
    spray_stop = SprayPacket(
        tag="HTG-0012",
        asset="AST-SPR-0012",
        seq=2,
        ts="2026-11-12T06:55:00Z",
        lat=28.682,
        lon=77.035,
        action="stop",
        flow_lpm=0.0,
        pump_a=0.0,
        litres_cum=1450.0,
    )
    res_stop = saga.match_spray_event(spray_stop)
    assert res_stop is not None
    task_done, verify_cmd = res_stop
    assert task_done.task_id == "tsk-101"
    assert task_done.source == "hawa_tag"
    assert verify_cmd.intervention_id == task_done.intervention_id
    assert saga._active_tasks["tsk-101"]["status"] == TaskStatus.DONE
