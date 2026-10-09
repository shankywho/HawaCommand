"""Kafka topic names and consumer group definitions (§5.2)."""
from dataclasses import dataclass
from typing import List
from .enums import StrEnum


class Topic(StrEnum):
    # Ingest & Telemetry
    TELEMETRY_RAW = "hawa.telemetry.raw.v1"
    TELEMETRY_CLEAN = "hawa.telemetry.clean.v1"
    TELEMETRY_DLQ = "hawa.telemetry.dlq.v1"
    
    # Device & Hardware
    DEVICE_EVENT = "hawa.device.event.v1"
    INTERVENTION_SEGMENT = "hawa.intervention.segment.v1"
    
    # Feeds
    FEED_REFERENCE = "hawa.feed.reference.v1"
    FEED_WEATHER = "hawa.feed.weather.v1"
    FEED_FIRE = "hawa.feed.fire.v1"
    
    # Commands
    CMD_TWIN = "hawa.cmd.twin.v1"
    CMD_FORECAST = "hawa.cmd.forecast.v1"
    CMD_PLAN = "hawa.cmd.plan.v1"
    CMD_VERIFY = "hawa.cmd.verify.v1"
    CMD_TRAIN = "hawa.cmd.train.v1"
    CMD_DISPATCH = "hawa.cmd.dispatch.v1"
    CMD_ALERT = "hawa.cmd.alert.v1"
    CMD_MAINTENANCE = "hawa.cmd.maintenance.v1"
    
    # Analytical Updates
    TWIN_UPDATED = "hawa.twin.updated.v1"
    HOTSPOT_UPDATED = "hawa.hotspot.updated.v1"
    FORECAST_ISSUED = "hawa.forecast.issued.v1"
    IMPACT_VERIFIED = "hawa.impact.verified.v1"
    
    # Operational Lifecycle
    PLAN_LIFECYCLE = "hawa.plan.lifecycle.v1"
    TASK_LIFECYCLE = "hawa.task.lifecycle.v1"
    ALERT_REQUESTED = "hawa.alert.requested.v1"
    ALERT_DELIVERY = "hawa.alert.delivery.v1"
    REPORT_LIFECYCLE = "hawa.report.lifecycle.v1"
    AUDIT = "hawa.audit.v1"


class ConsumerGroup(StrEnum):
    INGEST = "hawa-ingest-worker"
    DISPATCH = "hawa-dispatch-worker"
    NOTIFIER = "hawa-notifier"
    SCHEDULER = "hawa-scheduler"
    API_CACHE = "hawa-api-cache"
    API_LIVE = "hawa-api-live"
    INTEL_TWIN = "hawa-intel-twin"
    INTEL_FORECAST = "hawa-intel-forecast"
    INTEL_PLAN = "hawa-intel-plan"
    INTEL_VERIFY = "hawa-intel-verify"
    INTEL_SPIKE = "hawa-intel-spike"
    AUDIT_WRITER = "hawa-audit-writer"


@dataclass(frozen=True)
class TopicConfig:
    name: str
    partitions: int = 3
    retention_ms: int = 7 * 24 * 3600 * 1000  # 7 days default
    cleanup_policy: str = "delete"


ALL_TOPICS: List[TopicConfig] = [
    TopicConfig(Topic.TELEMETRY_RAW, partitions=6),
    TopicConfig(Topic.TELEMETRY_CLEAN, partitions=6),
    TopicConfig(Topic.TELEMETRY_DLQ, partitions=3),
    TopicConfig(Topic.DEVICE_EVENT, partitions=3),
    TopicConfig(Topic.INTERVENTION_SEGMENT, partitions=3),
    TopicConfig(Topic.FEED_REFERENCE, partitions=1),
    TopicConfig(Topic.FEED_WEATHER, partitions=1),
    TopicConfig(Topic.FEED_FIRE, partitions=1),
    TopicConfig(Topic.CMD_TWIN, partitions=1),
    TopicConfig(Topic.CMD_FORECAST, partitions=1),
    TopicConfig(Topic.CMD_PLAN, partitions=3),
    TopicConfig(Topic.CMD_VERIFY, partitions=3),
    TopicConfig(Topic.CMD_TRAIN, partitions=1),
    TopicConfig(Topic.CMD_DISPATCH, partitions=1),
    TopicConfig(Topic.CMD_ALERT, partitions=1),
    TopicConfig(Topic.CMD_MAINTENANCE, partitions=1),
    TopicConfig(Topic.TWIN_UPDATED, partitions=3),
    TopicConfig(Topic.HOTSPOT_UPDATED, partitions=3),
    TopicConfig(Topic.FORECAST_ISSUED, partitions=3),
    TopicConfig(Topic.IMPACT_VERIFIED, partitions=3),
    TopicConfig(Topic.PLAN_LIFECYCLE, partitions=3),
    TopicConfig(Topic.TASK_LIFECYCLE, partitions=3),
    TopicConfig(Topic.ALERT_REQUESTED, partitions=3),
    TopicConfig(Topic.ALERT_DELIVERY, partitions=3),
    TopicConfig(Topic.REPORT_LIFECYCLE, partitions=3),
    TopicConfig(Topic.AUDIT, partitions=3),
]
