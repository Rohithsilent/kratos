"""Chat API — REST endpoints for AI assistant interactions."""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from loguru import logger

from app.ai.safety.validation import validate_input
from app.database.postgres import AsyncSessionLocal
from app.database.repositories.ai_conversation_repository import AIConversationRepository
from app.cache.redis_client import cache_get, cache_set, session_list_key

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


@router.get("/sessions/{user_id}")
async def get_chat_sessions(user_id: str, limit: int = 50):
    """Retrieve all past chat sessions for a user, using Redis cache."""
    logger.info("GET /chat/sessions | user={} limit={}", user_id, limit)
    
    try:
        # 1. Check Redis cache first
        cache_key = session_list_key(user_id)
        cached_sessions = await cache_get(cache_key)
        if cached_sessions is not None:
            logger.info("Cache hit for sessions: {}", user_id)
            return cached_sessions

        # 2. Cache miss — fetch from Postgres
        logger.info("Cache miss for sessions: {}, fetching from DB...", user_id)
        async with AsyncSessionLocal() as session:
            repo = AIConversationRepository(session)
            history = await repo.list_user_conversations(user_id, limit=limit)
            
            sessions = {}
            for turn in history:
                cid = str(turn.conversation_id)
                if cid not in sessions:
                    summary = turn.user_message[:50] + "..." if turn.user_message and len(turn.user_message) > 50 else turn.user_message
                    sessions[cid] = {
                        "id": cid,
                        "created_at": turn.created_at.isoformat(),
                        "summary": summary
                    }
            
            session_list = list(sessions.values())
            
            # 3. Store in cache (1 hour TTL)
            await cache_set(cache_key, session_list, ttl_seconds=3600)
            
            return session_list
    except Exception as e:
        logger.error(f"Failed to fetch chat sessions: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch chat sessions")


@router.get("/history/{user_id}/{conversation_id}")
async def get_session_history(user_id: str, conversation_id: str):
    """Retrieve full history for a specific chat session."""
    logger.info("GET /chat/history | user={} conv={}", user_id, conversation_id)
    import uuid
    
    try:
        cid = uuid.UUID(conversation_id)
        async with AsyncSessionLocal() as session:
            repo = AIConversationRepository(session)
            db_history = await repo.list_by_conversation(cid)
            
            history_payload = []
            for turn in db_history:
                history_payload.append({"role": "user", "content": turn.user_message})
                history_payload.append({"role": "assistant", "content": turn.ai_response})
                
            return history_payload
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid conversation_id format")
    except Exception as e:
        logger.error(f"Failed to fetch chat history: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch chat history")
