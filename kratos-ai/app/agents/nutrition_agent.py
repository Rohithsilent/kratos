"""
NutritionAgent — Nutrition intelligence layer.

Responsibilities:
- Calculate personalised TDEE, macros, and calorie targets
- Generate meal plans aligned with training schedule
- Adapt nutrition based on body composition changes
- Handle dietary restrictions and preferences
"""
from __future__ import annotations

from typing import Any
from loguru import logger


class NutritionAgent:
    """AI agent for personalised nutrition planning and adaptation."""

    def __init__(self, llm: Any) -> None:
        self.llm = llm
        logger.info("NutritionAgent initialised")

    async def calculate_macros(self, user_id: str, profile: dict) -> dict:
        """
        Calculate personalised daily macro targets.

        Args:
            user_id: Firebase UID.
            profile: Dict with weight_kg, height_cm, age, gender,
                     activity_level, goal (bulk/cut/maintain).

        Returns:
            Macro targets dict: {calories, protein_g, carbs_g, fat_g}.
        """
        logger.debug("NutritionAgent.calculate_macros | user={}", user_id)
        # TODO Phase 2: use Mifflin-St Jeor + goal multipliers + Gemini refinement
        raise NotImplementedError("NutritionAgent.calculate_macros — implement in Phase 2")

    async def generate_meal_plan(self, user_id: str, macros: dict, preferences: dict) -> dict:
        """Generate a structured daily meal plan from macro targets."""
        logger.debug("NutritionAgent.generate_meal_plan | user={}", user_id)
        raise NotImplementedError("NutritionAgent.generate_meal_plan — implement in Phase 2")
