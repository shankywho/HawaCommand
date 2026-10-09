"""Clock protocol and time abstractions with IST (Asia/Kolkata) presentation."""
from datetime import datetime, timezone, timedelta
from typing import Protocol

IST_OFFSET = timedelta(hours=5, minutes=30)
IST_TZ = timezone(IST_OFFSET, name="IST")


class Clock(Protocol):
    """Abstract clock interface for deterministic testing."""
    def now_utc(self) -> datetime:
        ...

    def now_ist(self) -> datetime:
        ...


class SystemClock:
    """Production real-time clock."""
    def now_utc(self) -> datetime:
        return datetime.now(timezone.utc)

    def now_ist(self) -> datetime:
        return datetime.now(IST_TZ)


class FrozenClock:
    """Deterministic test clock frozen at a specific moment."""
    def __init__(self, frozen_at: datetime):
        if frozen_at.tzinfo is None:
            self._frozen = frozen_at.replace(tzinfo=timezone.utc)
        else:
            self._frozen = frozen_at.astimezone(timezone.utc)

    def now_utc(self) -> datetime:
        return self._frozen

    def now_ist(self) -> datetime:
        return self._frozen.astimezone(IST_TZ)

    def advance(self, delta: timedelta) -> None:
        self._frozen += delta


def to_utc_iso(dt: datetime) -> str:
    """Format datetime as UTC ISO-8601 with Z suffix."""
    utc_dt = dt.astimezone(timezone.utc)
    return utc_dt.isoformat().replace("+00:00", "Z")


def to_ist_label(dt: datetime) -> str:
    """Format datetime as friendly IST display string, e.g. 'Thu 08:30 IST'."""
    ist_dt = dt.astimezone(IST_TZ)
    return ist_dt.strftime("%a %H:%M IST")
