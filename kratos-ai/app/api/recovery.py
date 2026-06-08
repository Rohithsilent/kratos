"""Recovery API — REST endpoints for recovery analysis and recommendations."""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from loguru import logger

router = APIRouter(prefix="/recovery", tags=["Recovery"])


class RecoveryMetricsRequest(BaseModel):
    sleep_hours: float = Field(..., ge=0, le=24, description="Hours slept last night")
    soreness_level: int = Field(..., ge=1, le=10, description="Muscle soreness 1–10")
    last_workout_intensity: int = Field(..., ge=1, le=10, description="Last session intensity 1–10")
    hrv: float | None = Field(None, description="Heart rate variability (optional)")


class RecoveryReportResponse(BaseModel):
    score: float = Field(..., description="Recovery score 0–100")
    status: str = Field(..., description="ready | caution | rest")
    recommendations: list[str]
    adjusted_training: str


@router.post("/analyse", response_model=RecoveryReportResponse)
async def analyse_recovery(body: RecoveryMetricsRequest):
    """
    Analyse recovery metrics and return personalised recommendations.

    This endpoint feeds data into the RecoveryAgent via the FitnessGraph.
    """
    logger.info("POST /recovery/analyse | metrics={}", body.model_dump())
    # TODO Phase 2: call RecoveryAgent through FitnessGraph
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — RecoveryAgent not yet wired")


@router.get("/status/{user_id}")
async def get_recovery_status(user_id: str):
    """Get the latest cached recovery status for a user."""
    logger.info("GET /recovery/status | user={}", user_id)
    # TODO Phase 2: pull from Redis cache
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — cache layer pending")
