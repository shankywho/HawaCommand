"""HawaCommand Canonical Contracts Package."""
__version__ = "0.1.0"

from .enums import (
    DeviceRole,
    DevicePlacement,
    DeviceStatus,
    TrustBand,
    Pollutant,
    CauseLabel,
    AssetType,
    AssetStatus,
    GrapStage,
    AqiCategory,
    PlanMode,
    PlanStatus,
    TaskOp,
    TaskStatus,
    Verdict,
    Audience,
    Channel,
    Lang,
    UserRole,
    ALLOWED_ASSETS_PER_CAUSE,
)
from .ids import (
    uuid7,
    uuid7_deterministic,
    format_cell_500m,
    format_cell_1km,
    parse_cell_500m,
    parse_cell_1km,
    cell_500m_to_1km,
    is_valid_device_id,
    is_valid_asset_id,
)
from .units import (
    C_SAFE_PM25,
    C_SAFE_PM10,
    pm25_to_category,
    pm10_to_category,
    calculate_indicative_aqi,
    aqi_to_grap_stage,
)
from .packets import (
    TelemetryPacket,
    DeviceEventPacket,
    SprayPacket,
    validate_packet,
    REASON_FUTURE_TIMESTAMP,
    REASON_OUT_OF_BOUNDS,
    REASON_HARDWARE_FAULT,
)
from .envelope import EventContext, Envelope
from .topics import Topic, ConsumerGroup, ALL_TOPICS
from .redis_keys import RedisKeyBuilder
