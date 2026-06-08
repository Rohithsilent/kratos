"""
KRATOS AI — Async PostgreSQL Engine and Session Factory.

Production-grade connection pool configuration:
- pool_size=10          → base connections kept alive
- max_overflow=20       → burst capacity (30 total max)
- pool_pre_ping=True    → detect stale connections before use
- pool_recycle=3600     → recycle connections every hour
- pool_timeout=30       → max wait for a connection from pool
"""
from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from loguru import logger

from app.core.config import settings


# ── Async Engine ──────────────────────────────────────────────────────────────
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_pre_ping=True,
    pool_recycle=3600,
    pool_timeout=30,
    echo=settings.DB_ECHO,
    connect_args={
        # asyncpg-specific: statement cache size per connection
        "statement_cache_size": 0,       # disable for pgbouncer compat
        "command_timeout": 60,
    },
)


# ── Session Factory ───────────────────────────────────────────────────────────
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


# ── Lifecycle ─────────────────────────────────────────────────────────────────
async def init_db() -> None:
    """
    Verify database connectivity on startup.

    In production, tables are managed exclusively by Alembic migrations.
    This function only validates the connection — it does NOT create tables.
    """
    from app.database.base import Base  # noqa: F401
    # Import all models so Alembic and metadata.create_all can see them
    import app.database.models  # noqa: F401

    async with engine.begin() as conn:
        # Connectivity check
        await conn.execute(
            __import__("sqlalchemy").text("SELECT 1")
        )
    logger.info("✅ PostgreSQL connection verified (pool_size={}, max_overflow={})",
                settings.DB_POOL_SIZE, settings.DB_MAX_OVERFLOW)


async def create_all_tables() -> None:
    """
    Create all tables — DEVELOPMENT ONLY.

    In production, use: alembic upgrade head
    """
    from app.database.base import Base
    import app.database.models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("✅ Database tables created (dev mode)")


async def close_db() -> None:
    """Dispose the async engine connection pool."""
    await engine.dispose()
    logger.info("🔌 PostgreSQL connection pool disposed")
