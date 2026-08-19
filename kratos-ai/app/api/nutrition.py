"""Nutrition API — REST endpoints for macro calculation and meal planning."""
from fastapi import APIRouter, HTTPException, status, UploadFile, File
from pydantic import BaseModel, Field
from loguru import logger

from app.ai.gateway.gemini_gateway import gemini
from app.agents.nutrition_agent import NutritionAgent

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
    water_ml: int = 3000  # Default


class MealPlanRequest(BaseModel):
    macros: MacroTargetsResponse
    dietary_restrictions: list[str] = Field(default_factory=list)
    meals_per_day: int = Field(default=3, ge=2, le=6)


class NutritionScoreRequest(BaseModel):
    intake: dict
    targets: dict


class NutritionCoachRequest(BaseModel):
    intake: dict
    targets: dict


@router.post("/macros", response_model=MacroTargetsResponse)
async def calculate_macros(user_id: str, body: NutritionProfileRequest):
    """Calculate personalised daily macro targets via NutritionAgent."""
    logger.info("POST /nutrition/macros | user={} goal={}", user_id, body.goal)
    agent = NutritionAgent(llm=gemini)
    targets = await agent.calculate_macros(user_id=user_id, profile=body.model_dump())
    targets["water_ml"] = 3000
    return targets


@router.post("/meal-plan")
async def generate_meal_plan(user_id: str, body: MealPlanRequest):
    """Generate a structured daily meal plan from macro targets."""
    logger.info("POST /nutrition/meal-plan | user={}", user_id)
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 3 — Generate meal plan pending")


@router.post("/analyze-image")
async def analyze_food_image(file: UploadFile = File(...)):
    """Analyze an uploaded food image using Vision AI."""
    logger.info("POST /nutrition/analyze-image | filename={}", file.filename)
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    image_bytes = await file.read()
    agent = NutritionAgent(llm=gemini)
    
    try:
        result = await agent.analyze_food_image(image_bytes=image_bytes, mime_type=file.content_type)
        return result
    except Exception as e:
        logger.error(f"Image analysis failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to analyze image")


@router.post("/score")
async def calculate_nutrition_score(body: NutritionScoreRequest):
    """Calculate deterministic nutrition score based on adherence."""
    logger.info("POST /nutrition/score")
    agent = NutritionAgent(llm=gemini)
    return agent.calculate_nutrition_score(intake=body.intake, targets=body.targets)


@router.post("/coach")
async def generate_coach_insight(body: NutritionCoachRequest):
    """Generate conversational AI coach insight based on today's intake and save to Postgres."""
    user_id = body.intake.get("user_id", "anonymous")
    logger.info("POST /nutrition/coach | user={}", user_id)
    agent = NutritionAgent(llm=gemini)
    try:
        result = await agent.generate_coach_insight(intake=body.intake, targets=body.targets, user_id=user_id)
        
        # Save to Postgres
        from app.database.postgres import AsyncSessionLocal
        from app.database.models.ai_insight import AIInsight
        
        # Attempt to get user_id from body if present, else fallback
        user_id = body.intake.get("user_id", "anonymous")
        
        async with AsyncSessionLocal() as session:
            insight = AIInsight(
                firebase_uid=user_id,
                category="nutrition",
                title="Daily Nutrition Insight",
                content=result.get("insight", "No insight generated"),
                priority="medium",
                model_used="gemini-2.5-flash",
                source_data={"intake": body.intake, "targets": body.targets},
                tags=["nutrition", "daily_coach"]
            )
            session.add(insight)
            await session.commit()
            
        return result
    except Exception as e:
        logger.error(f"Coach insight generation failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate coach insight")


@router.get("/log/{user_id}")
async def get_nutrition_log(user_id: str):
    """Retrieve the user's recent nutrition insights from PostgreSQL."""
    logger.info("GET /nutrition/log | user={}", user_id)
    from app.database.postgres import AsyncSessionLocal
    from app.database.models.ai_insight import AIInsight
    from sqlalchemy import select
    
    try:
        async with AsyncSessionLocal() as session:
            stmt = select(AIInsight).where(
                AIInsight.firebase_uid == user_id,
                AIInsight.category == "nutrition"
            ).order_by(AIInsight.created_at.desc()).limit(20)
            
            result = await session.execute(stmt)
            insights = result.scalars().all()
            
            return [
                {
                    "id": str(i.id),
                    "created_at": i.created_at.isoformat(),
                    "title": i.title,
                    "content": i.content,
                    "priority": i.priority
                }
                for i in insights
            ]
    except Exception as e:
        logger.error(f"Failed to fetch nutrition logs: {e}")
        raise HTTPException(status_code=500, detail="Database fetch failed")
