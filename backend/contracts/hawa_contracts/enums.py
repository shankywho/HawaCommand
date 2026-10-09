"""Canonical enums across HawaCommand as defined in docs/CONTRACTS.md §3."""
from enum import Enum, IntEnum


class StrEnum(str, Enum):
    """String enum for serialization compatibility."""
    def __str__(self) -> str:
        return self.value


class DeviceRole(StrEnum):
    M = "M"          # Mobile sensor (bus, e-rickshaw, bike)
    S = "S"          # Sentinel stationary sensor (school, depot)
    TAG = "TAG"      # Intervention tracker on vehicle/sprinkler
    EYE = "EYE"      # Optical camera / Smoky-vehicle detector


class DevicePlacement(StrEnum):
    MOBILE = "mobile"
    OUTDOOR = "outdoor"
    INDOOR = "indoor"
    VEHICLE_MOUNTED_TAG = "vehicle_mounted_tag"
    ROADSIDE = "roadside"


class DeviceStatus(StrEnum):
    PROVISIONED = "provisioned"
    ACTIVE = "active"
    DEGRADED = "degraded"
    OFFLINE = "offline"
    RETIRED = "retired"


class TrustBand(StrEnum):
    HIGH = "high"       # >= 0.8
    MEDIUM = "medium"   # 0.5 - 0.8
    LOW = "low"         # < 0.5


class Pollutant(StrEnum):
    PM1 = "pm1"
    PM25 = "pm25"
    PM10 = "pm10"
    NO2 = "no2"
    CO = "co"
    NH3 = "nh3"
    VOC = "voc"
    CO2 = "co2"


class CauseLabel(StrEnum):
    DUST = "dust"
    TRAFFIC = "traffic"
    BURNING = "burning"
    REGIONAL_SMOKE = "regional_smoke"
    MIXED = "mixed"
    UNKNOWN = "unknown"


class AssetType(StrEnum):
    SPRINKLER = "sprinkler"
    ANTI_SMOG_GUN = "anti_smog_gun"
    SWEEPER = "sweeper"
    INSPECTION_TEAM = "inspection_team"


class AssetStatus(StrEnum):
    AVAILABLE = "available"
    ON_TASK = "on_task"
    OFF_SHIFT = "off_shift"
    MAINTENANCE = "maintenance"
    OFFLINE = "offline"


class GrapStage(IntEnum):
    STAGE_0 = 0
    STAGE_1 = 1
    STAGE_2 = 2
    STAGE_3 = 3
    STAGE_4 = 4


class AqiCategory(StrEnum):
    GOOD = "good"
    SATISFACTORY = "satisfactory"
    MODERATE = "moderate"
    POOR = "poor"
    VERY_POOR = "very_poor"
    SEVERE = "severe"


class PlanMode(StrEnum):
    MASTER = "master"
    REPLAN = "replan"
    SPIKE = "spike"
    MANUAL = "manual"


class PlanStatus(StrEnum):
    DRAFTING = "drafting"
    DRAFT = "draft"
    CHANGES_REQUESTED = "changes_requested"
    APPROVED = "approved"
    DISPATCHING = "dispatching"
    DONE = "done"
    FAILED = "failed"


class TaskOp(StrEnum):
    ADD = "add"
    DEL = "del"


class TaskStatus(StrEnum):
    DISPATCHED = "dispatched"
    ACKNOWLEDGED = "acknowledged"
    IN_PROGRESS = "in_progress"
    DONE = "done"
    VERIFIED = "verified"
    MISSED = "missed"
    ESCALATED = "escalated"
    FAILED = "failed"


class Verdict(StrEnum):
    VERIFIED = "verified"
    INCONCLUSIVE = "inconclusive"
    NO_EFFECT = "no_effect"


class Audience(StrEnum):
    SCHOOL = "School"
    CITIZENS = "Citizens"
    CITIZEN_EYES = "Citizen Eyes"
    WORKERS = "Workers"
    DRIVERS = "Drivers"


class Channel(StrEnum):
    WHATSAPP = "WhatsApp"
    SMS = "SMS"
    FCM = "FCM"
    IN_APP = "InApp"


class Lang(StrEnum):
    EN = "en"
    HI = "hi"
    HI_EN = "hi+en"


class UserRole(StrEnum):
    OFFICER = "officer"
    ADMIN = "admin"
    ANALYST = "analyst"
    DRIVER = "driver"
    INSPECTOR = "inspector"
    SCHOOL = "school"
    CITIZEN = "citizen"
    SITE_MANAGER = "site_manager"


# Allowed machine assignments constraint matrix (§3)
# Water cannot be sprayed on smoke; trucks cannot be sent for regional smoke.
ALLOWED_ASSETS_PER_CAUSE: dict[CauseLabel, set[AssetType]] = {
    CauseLabel.DUST: {AssetType.SPRINKLER, AssetType.ANTI_SMOG_GUN, AssetType.SWEEPER, AssetType.INSPECTION_TEAM},
    CauseLabel.TRAFFIC: {AssetType.INSPECTION_TEAM},
    CauseLabel.BURNING: {AssetType.INSPECTION_TEAM},
    CauseLabel.REGIONAL_SMOKE: set(),  # No machines can fix regional smoke, only warnings/protection
    CauseLabel.MIXED: {AssetType.SPRINKLER, AssetType.ANTI_SMOG_GUN, AssetType.SWEEPER, AssetType.INSPECTION_TEAM},
    CauseLabel.UNKNOWN: {AssetType.INSPECTION_TEAM},
}
