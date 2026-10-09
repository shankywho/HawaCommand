"""Database engine and session lifecycle management."""
from typing import AsyncGenerator, Optional
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from ..core.config import get_settings

_ENGINE: Optional[AsyncEngine] = None
_SESSIONMAKER: Optional[async_sessionmaker[AsyncSession]] = None


def get_engine(database_url: Optional[str] = None) -> AsyncEngine:
    """Get or create singleton async database engine."""
    global _ENGINE
    if _ENGINE is None or database_url is not None:
        url = database_url or get_settings().database_url
        # If sqlite in-memory for testing, enable check_same_thread=False
        connect_args = {}
        if url.startswith("sqlite"):
            connect_args["check_same_thread"] = False
        
        _ENGINE = create_async_engine(
            url,
            echo=get_settings().debug,
            future=True,
            connect_args=connect_args,
        )
    return _ENGINE


def get_sessionmaker(engine: Optional[AsyncEngine] = None) -> async_sessionmaker[AsyncSession]:
    """Get or create sessionmaker bound to the active engine."""
    global _SESSIONMAKER
    eng = engine or get_engine()
    if _SESSIONMAKER is None or engine is not None:
        _SESSIONMAKER = async_sessionmaker(
            bind=eng,
            class_=AsyncSession,
            expire_on_commit=False,
            autoflush=False,
        )
    return _SESSIONMAKER


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency for yielding transactional database sessions."""
    maker = get_sessionmaker()
    async with maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
