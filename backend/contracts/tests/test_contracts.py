"""Unit tests for hawa_contracts package."""
import pytest
from datetime import datetime, timezone, timedelta
from hawa_contracts import (
    uuid7,
    is_valid_device_id,
    is_valid_asset_id,
    format_cell_500m,
    format_cell_1km,
    parse_cell_500m,
    cell_500m_to_1km,
    pm25_to_category,
    calculate_indicative_aqi,
    aqi_to_grap_stage,
    AqiCategory,
    GrapStage,
    CauseLabel,
    AssetType,
    ALLOWED_ASSETS_PER_CAUSE,
    TelemetryPacket,
    DeviceEventPacket,
    SprayPacket,
    validate_packet,
    REASON_FUTURE_TIMESTAMP,
    REASON_OUT_OF_BOUNDS,
    REASON_HARDWARE_FAULT,
    Envelope,
    EventContext,
    Topic,
    RedisKeyBuilder,
)


def test_uuid7_generation():
    id1 = uuid7()
    id2 = uuid7()
    assert id1 != id2
    # Verify version 7 is in the 13th hex character (index 14 with dashes)
    assert id1[14] == '7'
    # UUID length
    assert len(id1) == 36


def test_id_regexes():
    assert is_valid_device_id("HPM-0142")
    assert is_valid_device_id("HPS-0007-O")
    assert is_valid_device_id("HPS-0007-I")
    assert is_valid_device_id("HTG-0012")
    assert not is_valid_device_id("INVALID-123")

    assert is_valid_asset_id("AST-SPR-0012")
    assert is_valid_asset_id("AST-ASG-0007")
    assert is_valid_asset_id("AST-SWP-0003")
    assert is_valid_asset_id("AST-TEAM-0001")
    assert not is_valid_asset_id("AST-CAR-0001")


def test_grid_mappings():
    assert format_cell_500m(41, 77) == "g500-041-077"
    assert format_cell_1km(20, 38) == "g1k-020-038"
    assert parse_cell_500m("g500-041-077") == (41, 77)
    # Cell conversion: row 41 -> row 20, col 77 -> col 38
    assert cell_500m_to_1km("g500-041-077") == "g1k-020-038"


def test_aqi_and_grap():
    assert pm25_to_category(25.0) == AqiCategory.GOOD
    assert pm25_to_category(45.0) == AqiCategory.SATISFACTORY
    assert pm25_to_category(75.0) == AqiCategory.MODERATE
    assert pm25_to_category(110.0) == AqiCategory.POOR
    assert pm25_to_category(180.0) == AqiCategory.VERY_POOR
    assert pm25_to_category(350.0) == AqiCategory.SEVERE

    assert aqi_to_grap_stage(150) == GrapStage.STAGE_0
    assert aqi_to_grap_stage(250) == GrapStage.STAGE_1
    assert aqi_to_grap_stage(350) == GrapStage.STAGE_2
    assert aqi_to_grap_stage(420) == GrapStage.STAGE_3
    assert aqi_to_grap_stage(480) == GrapStage.STAGE_4

    # Indicative AQI calculation
    aqi = calculate_indicative_aqi(pm25=110.0, pm10=260.0)
    assert 201 <= aqi <= 300


def test_cause_constraints():
    # Dust allows sprinklers, sweepers, etc.
    assert AssetType.SPRINKLER in ALLOWED_ASSETS_PER_CAUSE[CauseLabel.DUST]
    assert AssetType.SWEEPER in ALLOWED_ASSETS_PER_CAUSE[CauseLabel.DUST]
    
    # Burning only allows inspection team
    assert ALLOWED_ASSETS_PER_CAUSE[CauseLabel.BURNING] == {AssetType.INSPECTION_TEAM}
    
    # Regional smoke cannot use any machines
    assert len(ALLOWED_ASSETS_PER_CAUSE[CauseLabel.REGIONAL_SMOKE]) == 0


def test_telemetry_packet_validation():
    now_utc = datetime.now(timezone.utc)
    ts_now = now_utc.isoformat().replace("+00:00", "Z")

    packet = TelemetryPacket(
        dev="HPM-0142",
        seq=101,
        ts=ts_now,
        lat=28.6139,
        lon=77.2090,  # New Delhi coordinates
        spd=22.5,
        pm25=185.0,
        pm10=290.0,
        rh=65.0,
        t=18.5,
        flags=[],
    )
    assert validate_packet(packet, now_utc) is None

    # Future timestamp
    future_ts = (now_utc + timedelta(seconds=120)).isoformat().replace("+00:00", "Z")
    future_packet = packet.model_copy(update={"ts": future_ts})
    assert validate_packet(future_packet, now_utc) == REASON_FUTURE_TIMESTAMP

    # Out of Delhi bounding box
    out_packet = packet.model_copy(update={"lat": 19.0760, "lon": 72.8777}) # Mumbai
    assert validate_packet(out_packet, now_utc) == REASON_OUT_OF_BOUNDS

    # Hardware fault flag
    fault_packet = packet.model_copy(update={"flags": ["fan_stall"]})
    assert validate_packet(fault_packet, now_utc) == REASON_HARDWARE_FAULT


def test_spray_and_event_packets():
    sp = SprayPacket(
        tag="HTG-0012",
        asset="AST-SPR-0012",
        seq=42,
        ts="2026-11-12T06:30:00Z",
        lat=28.625,
        lon=77.329,
        action="start",
        flow_lpm=120.0,
        pump_a=14.2,
        litres_cum=350.0,
    )
    assert sp.action == "start"
    assert sp.flow_lpm == 120.0

    ep = DeviceEventPacket(
        dev="HPM-0007",
        seq=999,
        ts="2026-11-12T06:42:00Z",
        type="spike",
        data={"pm25_rise_ratio": 3.2, "baseline_pm25": 90.0},
    )
    assert ep.type == "spike"


def test_envelope_and_redis():
    ctx = EventContext(
        event_type="test.event",
        producer="test-runner",
    )
    env = Envelope(context=ctx, data={"status": "ok"})
    assert env.context.event_type == "test.event"
    assert env.data["status"] == "ok"

    keys = RedisKeyBuilder("test")
    assert keys.dedupe_packet("HPM-0142", 101) == "hawa:test:dedupe:packet:HPM-0142:101"
    assert keys.hotspots("ward-084") == "hawa:test:hotspots:ward-084"
