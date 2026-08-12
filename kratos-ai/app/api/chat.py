"""Chat API — REST endpoints for AI assistant interactions."""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from loguru import logger

from app.ai.safety.validation import validate_input

router = APIRouter(prefix="/chat", tags=["Chat"])


class ChatRequest(BaseModel):
    user_id: str = Field(..., description="Firebase UID")
    message: str = Field(..., min_length=1, max_length=2000)
    context: dict = Field(default_factory=dict, description="Optional extra context")


class ChatResponse(BaseModel):
    user_id: str
    response: str
    route_used: str
    tokens_used: int | None = None


@router.post("/message", response_model=ChatResponse)
async def send_message(body: ChatRequest):
    """
    Send a message to the KRATOS AI assistant.

    Routes through safety validation → FitnessGraph triage → Gemini.
    For real-time streaming use the WebSocket endpoint instead.
    """
    # Safety check first
    safety = validate_input(body.message)
    if not safety.is_safe:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=safety.reason)

    logger.info("POST /chat/message | user={} msg_len={}", body.user_id, len(body.message))
    # TODO Phase 2: invoke fitness_graph.ainvoke(state)
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Phase 2 — FitnessGraph not yet wired")


@router.get("/history/{user_id}")
async def get_chat_history_api(user_id: str, limit: int = 20):
    """Retrieve recent chat history for a user."""
    from app.cache.redis_client import get_chat_history
    logger.info("GET /chat/history | user={} limit={}", user_id, limit)
    
    try:
        history = await get_chat_history(user_id)
        # Limit to the requested number of messages, mostly recent
        return history[-limit:] if history else []
    except Exception as e:
        logger.error(f"Failed to fetch chat history: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch chat history")
