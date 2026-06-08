"""KRATOS AI — Recommendation Log Repository."""
from __future__ import annotations

from typing import Optional, Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models.recommendation_log import RecommendationLog
from app.database.repositories.base import BaseRepository


class RecommendationLogRepository(BaseRepository[RecommendationLog]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(RecommendationLog, session)

    async def list_by_user(
        self,
        firebase_uid: str,
        *,
        domain: Optional[str] = None,
        offset: int = 0,
        limit: int = 50,
    ) -> Sequence[RecommendationLog]:
        stmt = select(RecommendationLog).where(RecommendationLog.firebase_uid == firebase_uid)
        if domain:
            stmt = stmt.where(RecommendationLog.domain == domain)
        stmt = stmt.order_by(RecommendationLog.created_at.desc()).offset(offset).limit(limit)
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def list_pending(self, firebase_uid: str) -> Sequence[RecommendationLog]:
        stmt = (
            select(RecommendationLog)
            .where(
                RecommendationLog.firebase_uid == firebase_uid,
                RecommendationLog.was_seen == False,  # noqa: E712
            )
            .order_by(RecommendationLog.created_at.desc())
        )
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def mark_seen(self, rec_id) -> Optional[RecommendationLog]:
        return await self.update_by_id(rec_id, was_seen=True)

    async def record_outcome(self, rec_id, status: str, data: Optional[dict] = None) -> Optional[RecommendationLog]:
        from datetime import datetime
        kwargs = {"outcome_status": status, "outcome_measured_at": datetime.utcnow()}
        if data:
            kwargs["outcome_data"] = data
        return await self.update_by_id(rec_id, **kwargs)

    async def get_acceptance_rate(self, firebase_uid: str) -> dict:
        total_stmt = select(func.count()).select_from(RecommendationLog).where(RecommendationLog.firebase_uid == firebase_uid)
        accepted_stmt = (
            select(func.count()).select_from(RecommendationLog)
            .where(RecommendationLog.firebase_uid == firebase_uid, RecommendationLog.was_accepted == True)  # noqa: E712
        )
        total = (await self._session.execute(total_stmt)).scalar_one()
        accepted = (await self._session.execute(accepted_stmt)).scalar_one()
        return {
            "total": total,
            "accepted": accepted,
            "rate": round(accepted / total, 4) if total > 0 else 0.0,
        }
