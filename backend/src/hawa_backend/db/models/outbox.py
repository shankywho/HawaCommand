"""Transactional outbox and idempotency deduplication."""
from datetime import datetime
from sqlalchemy import String, DateTime, JSON
from sqlalchemy.orm import Mapped, mapped_column
from ..base import Base


class OutboxEvent(Base):
    """Transactional outbox event ensuring atomic database writes and Kafka publication."""
    __tablename__ = "outbox_event"

    event_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    topic: Mapped[str] = mapped_column(String(128), index=True, nullable=False)
    payload: Mapped[dict] = mapped_column(JSON, nullable=False)
    status: Mapped[str] = mapped_column(String(16), default="pending", index=True)  # pending | published
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class ProcessedEvent(Base):
    """Consumer idempotency store preventing duplicate event processing."""
    __tablename__ = "processed_event"

    event_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    consumer_group: Mapped[str] = mapped_column(String(64), primary_key=True)
    processed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
