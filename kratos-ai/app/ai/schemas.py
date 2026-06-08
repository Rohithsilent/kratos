"""
KRATOS AI — Structured output schemas.

RULE: Every Gemini call MUST return one of these Pydantic models.
      Never return raw text paragraphs.

All schemas are JSON-serialisable and map directly to Flutter models.
"""
from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field


# ── Recovery ──────────────────────────────────────────────────────────────────

class RecoveryOutput(BaseModel):
    recovery_score: int = Field(..., ge=0, le=100, description="Overall recovery score")
    status: Literal["optimal", "good", "caution", "rest"] = Field(...)
    recommendation: str = Field(..., description="Primary action recommendation")
    training_adjustment: str = Field(..., description="How today's training should change")
    soreness_areas: list[str] = Field(default_factory=list)
    sleep_quality: Literal["poor", "fair", "good", "excellent"] = Field(...)
    tips: list[str] = Field(default_factory=list, max_length=3)


# ── Workout Plan ──────────────────────────────────────────────────────────────

class ExerciseSet(BaseModel):
    reps: int
    weight_kg: float | None = None
    rest_seconds: int = 60


class Exercise(BaseModel):
    name: str
    muscle_group: str
    sets: list[ExerciseSet]
    notes: str = ""


class WorkoutSession(BaseModel):
    day: str                        # "Monday", "Wednesday", etc.
    name: str                       # "Push A", "Leg Day", etc.
    duration_minutes: int
    intensity: Literal["light", "moderate", "hard", "max"]
    exercises: list[Exercise]


class WorkoutPlanOutput(BaseModel):
    plan_name: str
    goal: str
    weeks: int
    sessions_per_week: int
    sessions: list[WorkoutSession]
    periodisation_notes: str
    deload_week: int | None = None


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


# ── Progression ───────────────────────────────────────────────────────────────

class ExerciseProgressionOutput(BaseModel):
    exercise: str
    trend: Literal["progressing", "plateau", "regressing", "insufficient_data"]
    weeks_at_plateau: int = 0
    recommended_weight_kg: float
    recommended_reps: int
    strategy: Literal["increase_weight", "increase_reps", "deload", "technique_focus", "maintain"]
    explanation: str


class ProgressionReportOutput(BaseModel):
    overall_trend: Literal["improving", "plateau", "declining"]
    exercises: list[ExerciseProgressionOutput]
    weekly_volume_change_pct: float
    plateau_detected: bool
    next_session_focus: str


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
