"""Unit tests for Phase 0 scaffolding: settings, logging sanitizer, schemas, and geometry."""
import logging
from datetime import datetime, timezone
import pytest
from hawa_ml.settings import settings, mask_secret
from hawa_ml.logging_conf import SecretSanitizingFilter, configure_logging
from hawa_ml.schemas import TelemetryPacket, DeviceRole, GPSData, PMData, EnvData
from hawa_ml.geo import haversine_distance_m, get_cell_id, get_cell_centroid, latlon_to_meters


def test_settings_load_and_mask():
    assert settings is not None
    assert settings.BASE_DIR.exists()
    # Test mask_secret
    assert mask_secret(None) == "[MISSING]"
    assert mask_secret("") == "[MISSING]"
    assert mask_secret("short") == "****"
    assert mask_secret("c6b3833cf46238258d3fced89572ee0c5e696c34154067b9839f58381674adc0") == "c6b3...adc0"


def test_logging_scrubs_secrets(caplog):
    logger = configure_logging("INFO")
    fake_secret = "gsk_1234567890abcdefghijklmnopqrstuvwxyz123456"
    test_msg = f"Connecting to Groq with key {fake_secret}"

    sanitized = SecretSanitizingFilter.sanitize(test_msg)
    assert fake_secret not in sanitized
    assert "[REDACTED_SECRET]" in sanitized


def test_telemetry_packet_validation():
    packet_dict = {
        "v": 1,
        "dev": "HPM-0142",
        "role": "M",
        "seq": 1001,
        "ts": datetime.now(timezone.utc).isoformat(),
        "gps": {"lat": 28.6331, "lon": 77.2194, "spd": 15.0, "hdop": 0.8},
        "pm": {"pm1": 80.0, "pm25": 140.0, "pm10": 220.0},
        "env": {"t": 22.5, "rh": 65.0, "p": 1012.0},
        "flags": ["heater_on"],
    }
    packet = TelemetryPacket(**packet_dict)
    assert packet.dev == "HPM-0142"
    assert packet.role == DeviceRole.MOBILE
    assert packet.pm.pm25 == 140.0


def test_geo_computations():
    # Distance between Connaught Place (28.6315, 77.2167) and India Gate (28.6129, 77.2295) ≈ 2.4 km
    dist = haversine_distance_m(28.6315, 77.2167, 28.6129, 77.2295)
    assert 2000 < dist < 2600

    # Grid cell indexing
    cell_id = get_cell_id(28.6315, 77.2167, cell_size_m=500.0)
    assert cell_id.startswith("G-")
    lat, lon = get_cell_centroid(cell_id, cell_size_m=500.0)
    assert 28.0 < lat < 29.0
    assert 76.5 < lon < 77.5
