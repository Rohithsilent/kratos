"""HydrationService — Dynamic water intake recommendations."""
from __future__ import annotations

from loguru import logger


class HydrationService:
    """
    Calculates personalised daily water targets.

    Formula: base 35ml/kg + 500ml per hour of exercise
    Adjusted for climate and sweat rate.
    """

    def calculate_daily_target(
        self,
        weight_kg: float,
        exercise_hours: float = 0.0,
        climate: str = "temperate",
    ) -> int:
        """
        Return daily water target in millilitres.

        Args:
            weight_kg: Body weight.
            exercise_hours: Hours of exercise planned today.
            climate: temperate | hot | humid

        Returns:
            Recommended water intake in ml.
        """
        base_ml = weight_kg * 35
        exercise_ml = exercise_hours * 500
        climate_bonus = {"hot": 500, "humid": 300, "temperate": 0}.get(climate, 0)
        total = int(base_ml + exercise_ml + climate_bonus)
        logger.debug("HydrationService | weight={} → {}ml", weight_kg, total)
        return total

    def hourly_reminder(self, target_ml: int, waking_hours: int = 16) -> int:
        """Return ml to drink per waking hour to hit daily target."""
        return int(target_ml / waking_hours)
