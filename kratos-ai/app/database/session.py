"""
KRATOS AI — FastAPI Dependency Injection for database sessions.

Usage in endpoints:

    from app.database.session import get_db

    @router.get("/insights")
    async def list_insights(db: AsyncSession = Depends(get_db)):
        repo = AIInsightRepository(db)
        return await repo.list_by_user(user_id)
"""
from __future__ import annotations

from typing import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession

from app.database.postgres import AsyncSessionLocal


async def get_db() -> AsyncIterator[AsyncSession]:
    """
    FastAPI dependency that yields a transactional async database session.

    Commits on success, rolls back on exception, always closes.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
