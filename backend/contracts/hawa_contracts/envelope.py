"""Kafka event envelope and context specification (§5.1)."""
from datetime import datetime, timezone
from typing import Generic, Optional, TypeVar
from pydantic import BaseModel, Field
from .ids import uuid7

T = TypeVar("T")


class EventContext(BaseModel):
    """Context metadata attached to every Kafka event."""
    event_id: str = Field(default_factory=uuid7)
    event_type: str = Field(..., description="Canonical event name, e.g. reading.cleaned")
    event_version: str = Field("1.0.0", description="Semver version of the payload schema")
    timestamp: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    )
    producer: str = Field(..., description="Service name that produced the event")
    correlation_id: str = Field(default_factory=uuid7)
    causation_id: Optional[str] = None
    is_simulated: bool = False


class Envelope(BaseModel, Generic[T]):
    """Standard event envelope wrapping all Kafka messages."""
    context: EventContext
    data: T
