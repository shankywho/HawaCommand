"""SQLAlchemy DeclarativeBase and standard mixins."""
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import MetaData, Boolean, DateTime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

# Standard constraint naming convention
CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    """Base for all SQLAlchemy ORM models."""
    metadata = MetaData(naming_convention=CONVENTION)


class TimestampMixin:
    """Provides automatic created_at and updated_at UTC timestamps."""
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )


class SimulatedMixin:
    """Honesty rule: tracks whether entity is virtual / simulated."""
    is_simulated: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
        index=True,
    )
