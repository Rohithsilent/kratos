"""NutritionService — TDEE, macro calculation, and meal plan orchestration."""
from __future__ import annotations

from loguru import logger


_ACTIVITY_MULTIPLIERS = {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
}

_GOAL_ADJUSTMENTS = {
    "bulk": 300,      # caloric surplus
    "cut": -500,      # deficit
    "maintain": 0,
}


class NutritionService:
    """Calculates TDEE and macro targets using Mifflin-St Jeor equation."""

    def calculate_tdee(
        self,
        weight_kg: float,
        height_cm: float,
        age: int,
        gender: str,
        activity_level: str,
    ) -> int:
        """Return Total Daily Energy Expenditure in kcal."""
        if gender == "male":
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
        else:
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161

        multiplier = _ACTIVITY_MULTIPLIERS.get(activity_level, 1.55)
        tdee = int(bmr * multiplier)
        logger.debug("NutritionService.tdee | bmr={:.0f} tdee={}", bmr, tdee)
        return tdee

    def calculate_macros(
        self,
        weight_kg: float,
        height_cm: float,
        age: int,
        gender: str,
        activity_level: str,
        goal: str,
    ) -> dict:
        """Return daily macro targets dict."""
        tdee = self.calculate_tdee(weight_kg, height_cm, age, gender, activity_level)
        calories = tdee + _GOAL_ADJUSTMENTS.get(goal, 0)

        # Standard macro split (protein-first approach)
        protein_g = int(weight_kg * 2.2)          # 2.2g per kg
        fat_g = int(calories * 0.25 / 9)           # 25% of calories
        carbs_g = int((calories - protein_g * 4 - fat_g * 9) / 4)
        water_ml = int(weight_kg * 35)

        return {
            "calories": calories,
            "protein_g": protein_g,
            "carbs_g": max(carbs_g, 50),
            "fat_g": fat_g,
            "water_ml": water_ml,
        }
