"""PlannerService — Business logic for adaptive workout plan management."""
from __future__ import annotations

from loguru import logger


class PlannerService:
    """Orchestrates PlannerAgent + persists plans to PostgreSQL."""

    async def generate_plan(self, user_id: str, profile: dict) -> dict:
        logger.info("PlannerService.generate_plan | user={}", user_id)
        # TODO Phase 2: call PlannerAgent, persist to DB, cache active plan
        raise NotImplementedError("Phase 2")

    async def get_active_plan(self, user_id: str) -> dict | None:
        # TODO Phase 2: query DB for active plan
        return None
