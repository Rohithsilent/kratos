"""Nutrition API — REST endpoints for macro calculation and meal planning."""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from loguru import logger

router = APIRouter(prefix="/nutrition", tags=["Nutrition"])


class NutritionProfileRequest(BaseModel):
    weight_kg: float = Field(..., gt=0)
    height_cm: float = Field(..., gt=0)
    age: int = Field(..., ge=13, le=100)
    gender: str = Field(..., description="male | female | other")
    activity_level: str = Field(..., description="sedentary | light | moderate | active | very_active")
    goal: str = Field(..., description="bulk | cut | maintain")


class MacroTargetsResponse(BaseModel):
    calories: int
    protein_g: int
    carbs_g: int
    fat_g: int
    water_ml: int


class MealPlanRequest(BaseModel):
    macros: MacroTargetsResponse
    dietary_restrictions: list[str] = Field(default_factory=list)
    meals_per_day: int = Field(default=3, ge=2, le=6)


@router.post("/macros", response_model=MacroTargetsResponse)
async def calculate_macros(user_id: str, body: NutritionProfileRequest):
    """Calculate personalised daily macro targets via NutritionAgent."""
    logger.info("POST /nutrition/macros | user={} goal={}", user_id, body.goal)
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — NutritionAgent pending")


@router.post("/meal-plan")
async def generate_meal_plan(user_id: str, body: MealPlanRequest):
    """Generate a structured daily meal plan from macro targets."""
    logger.info("POST /nutrition/meal-plan | user={}", user_id)
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — NutritionAgent pending")


@router.get("/log/{user_id}")
async def get_nutrition_log(user_id: str):
    """Retrieve the user's recent nutrition log."""
    logger.info("GET /nutrition/log | user={}", user_id)
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — DB layer pending")
