"""
KRATOS AI — Generic Async Repository Base.

Provides CRUD operations that all domain repositories inherit.
Uses SQLAlchemy 2.x async API with proper type hints.
"""
from __future__ import annotations

import uuid
from typing import Any, Generic, Optional, Sequence, Type, TypeVar

from sqlalchemy import Select, delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.base import Base

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """Generic async CRUD repository."""

    def __init__(self, model: Type[ModelType], session: AsyncSession) -> None:
        self._model = model
        self._session = session

    # ── Create ────────────────────────────────────────────────────────────────
    async def create(self, **kwargs: Any) -> ModelType:
        instance = self._model(**kwargs)
        self._session.add(instance)
        await self._session.flush()
        await self._session.refresh(instance)
        return instance

    async def create_many(self, items: list[dict[str, Any]]) -> list[ModelType]:
        instances = [self._model(**item) for item in items]
        self._session.add_all(instances)
        await self._session.flush()
        for inst in instances:
            await self._session.refresh(inst)
        return instances

    # ── Read ──────────────────────────────────────────────────────────────────
    async def get_by_id(self, record_id: uuid.UUID) -> Optional[ModelType]:
        return await self._session.get(self._model, record_id)

    async def list_all(
        self,
        *,
        offset: int = 0,
        limit: int = 100,
        order_by: Optional[str] = None,
        descending: bool = True,
    ) -> Sequence[ModelType]:
        stmt = select(self._model)
        if order_by and hasattr(self._model, order_by):
            col = getattr(self._model, order_by)
            stmt = stmt.order_by(col.desc() if descending else col.asc())
        stmt = stmt.offset(offset).limit(limit)
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def count(self) -> int:
        stmt = select(func.count()).select_from(self._model)
        result = await self._session.execute(stmt)
        return result.scalar_one()

    # ── Update ────────────────────────────────────────────────────────────────
    async def update_by_id(self, record_id: uuid.UUID, **kwargs: Any) -> Optional[ModelType]:
        instance = await self.get_by_id(record_id)
        if instance is None:
            return None
        for key, value in kwargs.items():
            setattr(instance, key, value)
        await self._session.flush()
        await self._session.refresh(instance)
        return instance

    # ── Delete ────────────────────────────────────────────────────────────────
    async def delete_by_id(self, record_id: uuid.UUID) -> bool:
        instance = await self.get_by_id(record_id)
        if instance is None:
            return False
        await self._session.delete(instance)
        await self._session.flush()
        return True

    # ── Helpers ───────────────────────────────────────────────────────────────
    async def exists(self, record_id: uuid.UUID) -> bool:
        stmt = select(func.count()).select_from(self._model).where(self._model.id == record_id)
        result = await self._session.execute(stmt)
        return result.scalar_one() > 0

    def _base_query(self) -> Select:
        return select(self._model)
