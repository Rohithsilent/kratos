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
        self.llm = llm  # Expected to be GeminiGateway
        logger.info("NutritionAgent initialised")

    async def calculate_macros(self, user_id: str, profile: dict) -> dict:
        """Calculate daily macro targets using Mifflin-St Jeor."""
        # Simple implementation for phase 2 completeness
        weight = profile.get("weight_kg", 70)
        height = profile.get("height_cm", 175)
        age = profile.get("age", 25)
        gender = profile.get("gender", "male")
        goal = profile.get("goal", "maintain")

        # Mifflin-St Jeor
        if gender == "male":
            bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
        else:
            bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161

        tdee = bmr * 1.55  # Moderate activity default

        if goal == "bulk":
            calories = int(tdee + 500)
        elif goal == "cut":
            calories = int(tdee - 500)
        else:
            calories = int(tdee)

        protein_g = int(weight * 2.2)  # ~2.2g per kg
        fat_g = int((calories * 0.25) / 9)
        carbs_g = int((calories - (protein_g * 4) - (fat_g * 9)) / 4)

        return {
            "calories": calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g
        }

    async def analyze_food_image(self, image_bytes: bytes, mime_type: str, user_id: str | None = None) -> dict:
        """Uses Gemini Vision to estimate macros from a food image."""
        logger.debug("NutritionAgent.analyze_food_image called | user={}", user_id)
        from app.ai.schemas import FoodAnalysisOutput
        
        prompt = (
            "Analyze this image of food. Identify what it is, and provide a realistic "
            "estimation of its nutritional content including total calories, protein, "
            "carbohydrates, and fats. Be as accurate as possible for standard portion sizes."
        )
        
        result = await self.llm.analyse_image(
            image_bytes=image_bytes,
            prompt=prompt,
            schema=FoodAnalysisOutput,
            mime_type=mime_type,
            user_id=user_id,
        )
        return result.model_dump()

    def calculate_nutrition_score(self, intake: dict, targets: dict) -> dict:
        """Deterministically calculate a 0-100 score based on macro adherence."""
        logger.debug("NutritionAgent.calculate_nutrition_score called")
        
        cal_pct = min(1.0, intake.get("calories", 0) / max(1, targets.get("calories", 1)))
        pro_pct = min(1.0, intake.get("protein_g", 0) / max(1, targets.get("protein_g", 1)))
        
        # Simple weighted score: 60% protein adherence, 40% calorie adherence
        score_val = int((pro_pct * 60) + (cal_pct * 40))
        
        # Provide deterministic insights to save LLM latency
        if score_val < 30:
            insight = "Off track. Time to eat right."
        elif score_val < 70:
            insight = "Making progress, but you need more protein."
        elif score_val < 90:
            insight = "Great day! Almost hit all targets."
        else:
            insight = "Perfectly balanced. Keep it up!"
            
        return {
            "score": score_val,
            "insight": insight
        }

    async def generate_coach_insight(self, intake: dict, targets: dict, user_id: str | None = None) -> dict:
        """Uses Gemini Flash to provide a personalized conversational coaching insight."""
        logger.debug("NutritionAgent.generate_coach_insight called | user={}", user_id)
        from app.ai.schemas import NutritionCoachOutput
        from app.ai.gateway.gemini_gateway import GeminiModel
        
        prompt = (
            f"I am a user tracking my nutrition. Today my targets are: {targets}. "
            f"So far today, I have consumed: {intake}. "
            "Act as a supportive, highly knowledgeable fitness and nutrition coach. "
            "Provide a short, punchy insight (1-2 sentences) on how I am doing today, "
            "and one very specific actionable piece of advice for my next meal. "
            "Do not use robotic phrasing."
        )
        
        result = await self.llm.generate_structured(
            prompt=prompt,
            schema=NutritionCoachOutput,
            model=GeminiModel.FLASH,
            user_id=user_id,
        )
        return result.model_dump()
