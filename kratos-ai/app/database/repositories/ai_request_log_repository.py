"""KRATOS AI — AI Request Log Repository (Observability)."""
from __future__ import annotations

from datetime import datetime, timedelta
from typing import Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models.ai_request_log import AIRequestLog
from app.database.repositories.base import BaseRepository


class AIRequestLogRepository(BaseRepository[AIRequestLog]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(AIRequestLog, session)

    async def get_error_logs(
        self,
        *,
        hours: int = 24,
        limit: int = 100,
    ) -> Sequence[AIRequestLog]:
        since = datetime.utcnow() - timedelta(hours=hours)
        stmt = (
            select(AIRequestLog)
            .where(AIRequestLog.status != "success", AIRequestLog.created_at >= since)
            .order_by(AIRequestLog.created_at.desc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def get_usage_summary(self, hours: int = 24) -> dict:
        since = datetime.utcnow() - timedelta(hours=hours)
        stmt = (
            select(
                func.count().label("total_requests"),
                func.sum(AIRequestLog.total_tokens).label("total_tokens"),
                func.avg(AIRequestLog.latency_ms).label("avg_latency_ms"),
                func.sum(AIRequestLog.estimated_cost_usd).label("total_cost_usd"),
            )
            .where(AIRequestLog.created_at >= since)
        )
        result = await self._session.execute(stmt)
        row = result.one()
        # Error rate
        err_stmt = (
            select(func.count())
            .select_from(AIRequestLog)
            .where(AIRequestLog.status != "success", AIRequestLog.created_at >= since)
        )
        err_count = (await self._session.execute(err_stmt)).scalar_one()
        total = row.total_requests or 0
        return {
            "total_requests": total,
            "total_tokens": row.total_tokens or 0,
            "avg_latency_ms": round(row.avg_latency_ms or 0, 2),
            "total_cost_usd": round(row.total_cost_usd or 0, 6),
            "error_count": err_count,
            "error_rate": round(err_count / total, 4) if total > 0 else 0.0,
        }

    async def get_usage_by_model(self, hours: int = 24) -> list[dict]:
        since = datetime.utcnow() - timedelta(hours=hours)
        stmt = (
            select(
                AIRequestLog.model_used,
                func.count().label("count"),
                func.sum(AIRequestLog.total_tokens).label("tokens"),
                func.avg(AIRequestLog.latency_ms).label("avg_latency"),
            )
            .where(AIRequestLog.created_at >= since)
            .group_by(AIRequestLog.model_used)
        )
        result = await self._session.execute(stmt)
        return [
            {"model": r.model_used, "count": r.count, "tokens": r.tokens or 0, "avg_latency_ms": round(r.avg_latency or 0, 2)}
            for r in result.all()
        ]
