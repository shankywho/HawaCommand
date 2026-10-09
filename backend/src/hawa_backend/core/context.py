"""Contextvars for asynchronous request and correlation tracking."""
from contextvars import ContextVar
from dataclasses import dataclass, field
from typing import List, Optional
from hawa_contracts.ids import uuid7


@dataclass
class RequestContext:
    request_id: str = field(default_factory=uuid7)
    correlation_id: str = field(default_factory=uuid7)
    causation_id: Optional[str] = None
    user_id: Optional[str] = None
    role: Optional[str] = None
    ward_ids: List[str] = field(default_factory=list)
    is_simulated: bool = False


_CURRENT_CONTEXT: ContextVar[RequestContext] = ContextVar("current_context", default=RequestContext())


def get_current_context() -> RequestContext:
    """Get the active request/task context."""
    return _CURRENT_CONTEXT.get()


def set_current_context(ctx: RequestContext) -> None:
    """Set the active request/task context."""
    _CURRENT_CONTEXT.set(ctx)


def bind_context(
    request_id: Optional[str] = None,
    correlation_id: Optional[str] = None,
    causation_id: Optional[str] = None,
    user_id: Optional[str] = None,
    role: Optional[str] = None,
    is_simulated: bool = False,
) -> RequestContext:
    """Create and bind a new context with default fallbacks."""
    ctx = RequestContext(
        request_id=request_id or uuid7(),
        correlation_id=correlation_id or uuid7(),
        causation_id=causation_id,
        user_id=user_id,
        role=role,
        is_simulated=is_simulated,
    )
    set_current_context(ctx)
    return ctx
