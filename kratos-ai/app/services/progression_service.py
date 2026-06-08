"""ProgressionService — Tracks strength trends and applies progressive overload."""
from __future__ import annotations

from loguru import logger
import numpy as np


class ProgressionService:
    """Analyses workout history to detect progression trends and plateaus."""

    def calculate_volume_trend(self, sessions: list[dict]) -> dict:
        """
        Calculate weekly volume trend from workout sessions.

        Args:
            sessions: List of session dicts with 'total_volume' key.

        Returns:
            Dict with trend (up/flat/down), slope, and plateau_detected flag.
        """
        if len(sessions) < 3:
            return {"trend": "insufficient_data", "slope": 0, "plateau_detected": False}

        volumes = np.array([s.get("total_volume", 0) for s in sessions], dtype=float)
        x = np.arange(len(volumes))
        slope, _ = np.polyfit(x, volumes, 1)

        trend = "up" if slope > 2 else ("down" if slope < -2 else "flat")
        plateau = abs(slope) < 2 and len(sessions) >= 4

        logger.debug("ProgressionService | slope={:.2f} trend={} plateau={}", slope, trend, plateau)
        return {"trend": trend, "slope": round(slope, 2), "plateau_detected": plateau}

    def recommend_overload(self, exercise: str, last_weight_kg: float, last_reps: int) -> dict:
        """
        Simple progressive overload recommendation.

        Strategy: if last_reps >= target_reps → increase weight by ~2.5%
        """
        target_reps = 12
        if last_reps >= target_reps:
            new_weight = round(last_weight_kg * 1.025 / 2.5) * 2.5  # round to 2.5kg
            return {"exercise": exercise, "recommended_weight_kg": new_weight, "action": "increase_weight"}
        return {"exercise": exercise, "recommended_weight_kg": last_weight_kg, "action": "maintain_weight"}
