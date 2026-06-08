"""RecoveryService — Business logic for recovery analysis."""
from __future__ import annotations

from loguru import logger
from app.cache.redis_client import get_cached_recovery, set_cached_recovery


class RecoveryService:
    """Orchestrates RecoveryAgent calls and caching."""

    async def get_recovery_report(self, user_id: str, metrics: dict) -> dict:
        # Try cache first (valid for 12h)
        cached = await get_cached_recovery(user_id)
        if cached:
            logger.debug("RecoveryService: cache hit | user={}", user_id)
            return cached

        # TODO Phase 2: call RecoveryAgent
        report = {
            "score": 0.0,
            "status": "unknown",
            "recommendations": [],
            "adjusted_training": "Pending AI analysis",
        }
        await set_cached_recovery(user_id, report)
        return report
