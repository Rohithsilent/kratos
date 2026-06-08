"""KRATOS AI — AI Insight Repository."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional, Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models.ai_insight import AIInsight
from app.database.repositories.base import BaseRepository


class AIInsightRepository(BaseRepository[AIInsight]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(AIInsight, session)

    async def list_by_user(
        self,
        firebase_uid: str,
        *,
        category: Optional[str] = None,
        priority: Optional[str] = None,
        include_dismissed: bool = False,
        offset: int = 0,
        limit: int = 50,
    ) -> Sequence[AIInsight]:
        stmt = select(AIInsight).where(AIInsight.firebase_uid == firebase_uid)
        if category:
            stmt = stmt.where(AIInsight.category == category)
        if priority:
            stmt = stmt.where(AIInsight.priority == priority)
        if not include_dismissed:
            stmt = stmt.where(AIInsight.is_dismissed == False)  # noqa: E712
        stmt = stmt.order_by(AIInsight.created_at.desc()).offset(offset).limit(limit)
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def list_active(
        self,
        firebase_uid: str,
        *,
        limit: int = 10,
    ) -> Sequence[AIInsight]:
        """Get non-expired, non-dismissed insights ordered by priority."""
        now = datetime.utcnow()
        stmt = (
            select(AIInsight)
            .where(
                AIInsight.firebase_uid == firebase_uid,
                AIInsight.is_dismissed == False,  # noqa: E712
                (AIInsight.expires_at == None) | (AIInsight.expires_at > now),  # noqa: E711
            )
            .order_by(
                # critical > high > medium > low
                func.array_position(
                    func.cast(["critical", "high", "medium", "low"], type_=None),
                    AIInsight.priority,
                ).asc(),
                AIInsight.created_at.desc(),
            )
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def mark_dismissed(self, insight_id: uuid.UUID) -> Optional[AIInsight]:
        return await self.update_by_id(insight_id, is_dismissed=True)

    async def mark_acted_upon(self, insight_id: uuid.UUID) -> Optional[AIInsight]:
        return await self.update_by_id(insight_id, is_acted_upon=True)

    async def add_feedback(self, insight_id: uuid.UUID, rating: int) -> Optional[AIInsight]:
        return await self.update_by_id(insight_id, feedback_rating=rating)

    async def count_by_category(self, firebase_uid: str) -> dict[str, int]:
        stmt = (
            select(AIInsight.category, func.count())
            .where(AIInsight.firebase_uid == firebase_uid)
            .group_by(AIInsight.category)
        )
        result = await self._session.execute(stmt)
        return dict(result.all())
