"""User accounts, authentication credentials, and security audit log."""
from datetime import datetime
from typing import Optional
from sqlalchemy import String, Boolean, DateTime, JSON, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from ..base import Base, TimestampMixin


class AppUser(Base, TimestampMixin):
    """Registered application user (officer, driver, inspector, principal)."""
    __tablename__ = "app_user"

    user_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    phone_e164: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(128), nullable=False)
    role: Mapped[str] = mapped_column(String(32), nullable=False)  # officer | driver | inspector | school
    ward_ids: Mapped[list] = mapped_column(JSON, default=list)
    hashed_password: Mapped[Optional[str]] = mapped_column(String(256), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class RefreshToken(Base, TimestampMixin):
    """Session refresh token."""
    __tablename__ = "refresh_token"

    token_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("app_user.user_id"), index=True)
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)


class AuditLog(Base):
    """Immutable audit trail for plan approvals, edits, and dispatches."""
    __tablename__ = "audit_log"

    log_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    actor: Mapped[str] = mapped_column(String(128), index=True, nullable=False)
    action: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(128), index=True, nullable=False)
    details: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
