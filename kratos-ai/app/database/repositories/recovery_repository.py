"""KRATOS AI — Recovery Metric Repository."""
from __future__ import annotations

from datetime import date, timedelta
from typing import Optional, Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models.recovery_metric import RecoveryMetric
from app.database.repositories.base import BaseRepository


class RecoveryMetricRepository(BaseRepository[RecoveryMetric]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(RecoveryMetric, session)

    async def get_latest(self, firebase_uid: str) -> Optional[RecoveryMetric]:
        stmt = (
            select(RecoveryMetric)
            .where(RecoveryMetric.firebase_uid == firebase_uid)
            .order_by(RecoveryMetric.metric_date.desc())
            .limit(1)
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_date_range(
        self,
        firebase_uid: str,
        start_date: date,
        end_date: date,
    ) -> Sequence[RecoveryMetric]:
        stmt = (
            select(RecoveryMetric)
            .where(
                RecoveryMetric.firebase_uid == firebase_uid,
                RecoveryMetric.metric_date >= start_date,
                RecoveryMetric.metric_date <= end_date,
            )
            .order_by(RecoveryMetric.metric_date.asc())
        )
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def get_weekly_trend(self, firebase_uid: str) -> Sequence[RecoveryMetric]:
        start = date.today() - timedelta(days=7)
        return await self.get_date_range(firebase_uid, start, date.today())

    async def get_avg_score(self, firebase_uid: str, days: int = 7) -> float:
        start = date.today() - timedelta(days=days)
        stmt = (
            select(func.avg(RecoveryMetric.recovery_score))
            .where(
                RecoveryMetric.firebase_uid == firebase_uid,
                RecoveryMetric.metric_date >= start,
            )
        )
        result = await self._session.execute(stmt)
        return round(result.scalar_one() or 0.0, 2)

    async def get_risk_distribution(self, firebase_uid: str, days: int = 30) -> dict[str, int]:
        start = date.today() - timedelta(days=days)
        stmt = (
            select(RecoveryMetric.risk_level, func.count())
            .where(
                RecoveryMetric.firebase_uid == firebase_uid,
                RecoveryMetric.metric_date >= start,
            )
            .group_by(RecoveryMetric.risk_level)
        )
        result = await self._session.execute(stmt)
        return dict(result.all())
