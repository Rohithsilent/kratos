"""Planner API — REST endpoints for adaptive workout plan generation."""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from loguru import logger

router = APIRouter(prefix="/planner", tags=["Planner"])


class UserProfileRequest(BaseModel):
    goal: str = Field(..., description="bulk | cut | maintain | strength | endurance")
    fitness_level: str = Field(..., description="beginner | intermediate | advanced")
    available_days: int = Field(..., ge=1, le=7, description="Training days per week")
    equipment: list[str] = Field(default_factory=list, description="Available equipment list")
    injuries: list[str] = Field(default_factory=list, description="Active injury notes")


class WorkoutPlanResponse(BaseModel):
    plan_id: str
    weeks: int
    sessions: list[dict]
    notes: str


@router.post("/generate", response_model=WorkoutPlanResponse)
async def generate_plan(user_id: str, body: UserProfileRequest):
    """
    Generate a personalised weekly workout plan via PlannerAgent.
    """
    logger.info("POST /planner/generate | user={} goal={}", user_id, body.goal)
    # TODO Phase 2: route to PlannerAgent via FitnessGraph
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — PlannerAgent pending")


@router.post("/adapt/{plan_id}")
async def adapt_plan(plan_id: str, feedback: dict):
    """Adapt an existing plan based on user feedback."""
    logger.info("POST /planner/adapt | plan={}", plan_id)
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — adaptive planner pending")


@router.get("/current/{user_id}")
async def get_current_plan(user_id: str):
    """Fetch the user's active workout plan."""
    logger.info("GET /planner/current | user={}", user_id)
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — DB layer pending")
