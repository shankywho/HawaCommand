"""Domain event registry and exports."""
from typing import Any, Callable, Dict, Tuple, Type
from pydantic import BaseModel

EVENT_REGISTRY: Dict[Tuple[str, str], Type[BaseModel]] = {}


def register_event(event_type: str, version: str = "1.0.0") -> Callable[[Type[BaseModel]], Type[BaseModel]]:
    """Decorator to register an event payload model in the global event registry."""
    def decorator(cls: Type[BaseModel]) -> Type[BaseModel]:
        EVENT_REGISTRY[(event_type, version)] = cls
        return cls
    return decorator
