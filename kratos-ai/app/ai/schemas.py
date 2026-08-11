"""
KRATOS AI — Structured output schemas.

RULE: Every Gemini call MUST return one of these Pydantic models.
      Never return raw text paragraphs.

All schemas are JSON-serialisable and map directly to Flutter models.
"""
from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field


# ── Nutrition ─────────────────────────────────────────────────────────────────

class MacroOutput(BaseModel):
    calories: int
    protein_g: int
    carbs_g: int
    fat_g: int
    water_ml: int
    meal_timing_notes: str


class Meal(BaseModel):
    name: str
    time: str
    calories: int
    protein_g: int
    carbs_g: int
    fat_g: int
    foods: list[str]


class MealPlanOutput(BaseModel):
    total_calories: int
    meals: list[Meal]
    pre_workout_meal: str
    post_workout_meal: str
    supplements: list[str] = Field(default_factory=list)


class FoodAnalysisOutput(BaseModel):
    food_name: str = Field(..., description="Name of the food identified")
    calories: int = Field(..., description="Estimated calories")
    protein_g: int = Field(..., description="Estimated protein in grams")
    carbs_g: int = Field(..., description="Estimated carbs in grams")
    fats_g: int = Field(..., description="Estimated fats in grams")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence in analysis (0-1)")


class NutritionCoachOutput(BaseModel):
    insight: str = Field(..., description="A short, conversational coaching insight based on today's intake.")
    actionable_advice: str = Field(..., description="What the user should do next (e.g., eat more protein).")



# ── Assistant Chat ────────────────────────────────────────────────────────────

class ChatOutput(BaseModel):
    response: str = Field(..., description="Conversational AI response")
    follow_up_questions: list[str] = Field(default_factory=list, max_length=3)
    action_items: list[str] = Field(default_factory=list)
    route_explanation: str = Field(default="", description="Internal routing note")


# ── Generic AI Error ──────────────────────────────────────────────────────────

class AIErrorOutput(BaseModel):
    error: str
    code: str
    safe_message: str = "I encountered an issue processing your request. Please try again."
