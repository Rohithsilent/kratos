"""
RoutingService — Decides which AI model / agent handles a request.

Strategy:
- Flash  → quick Q&A, chat, simple lookups  (low latency)
- Pro    → plan generation, deep analysis   (high quality)
- Agents → specialist tasks (recovery, nutrition, progression)
"""
from __future__ import annotations

from enum import Enum
from loguru import logger


class RouteTarget(str, Enum):
    FLASH = "flash"
    PRO = "pro"
    RECOVERY_AGENT = "recovery_agent"
    PLANNER_AGENT = "planner_agent"
    NUTRITION_AGENT = "nutrition_agent"
    PROGRESSION_AGENT = "progression_agent"


# Keywords that signal a specialist agent is needed
_ROUTING_MAP: dict[RouteTarget, list[str]] = {
    RouteTarget.RECOVERY_AGENT: ["recovery", "sore", "rest", "fatigue", "sleep", "hrv", "deload"],
    RouteTarget.PLANNER_AGENT: ["plan", "program", "schedule", "week", "split", "periodis"],
    RouteTarget.NUTRITION_AGENT: ["macro", "calorie", "diet", "meal", "protein", "eat", "nutrition"],
    RouteTarget.PROGRESSION_AGENT: ["plateau", "progress", "overload", "strength", "1rm", "pr"],
}

# Prompts that need deep reasoning → Pro model
_PRO_TRIGGERS = ["generate", "create", "build", "analyse", "design", "optimise"]


class RoutingService:
    """Lightweight keyword-based router for AI requests."""

    def route(self, message: str) -> RouteTarget:
        """
        Determine the best handler for a given user message.

        Args:
            message: Raw user input string.

        Returns:
            RouteTarget indicating which model / agent to invoke.
        """
        lower = message.lower()

        for target, keywords in _ROUTING_MAP.items():
            if any(kw in lower for kw in keywords):
                logger.debug("RoutingService → {} (keyword match)", target)
                return target

        if any(kw in lower for kw in _PRO_TRIGGERS):
            logger.debug("RoutingService → PRO (complexity trigger)")
            return RouteTarget.PRO

        logger.debug("RoutingService → FLASH (default)")
        return RouteTarget.FLASH
