"""
WebSocket Chat Handler — real-time AI streaming for KRATOS.

Flow:
    Flutter → WS connect (with Firebase token) → authenticate
    → receive message → safety check → FitnessGraph triage
    → stream Gemini response back token by token
"""
from __future__ import annotations

import json
from loguru import logger
from fastapi import WebSocket, WebSocketDisconnect

from app.ai.safety.validation import validate_input
from app.ai.gateway.gemini_gateway import gemini, GeminiModel
from google.genai import types as genai_types
from app.database.postgres import AsyncSessionLocal
from app.database.repositories.ai_conversation_repository import AIConversationRepository
from app.database.models.ai_conversation import AIConversation
from app.cache.redis_client import cache_delete, cache_get, cache_set, session_list_key, active_session_key
import uuid
import time

class ConnectionManager:
    """Tracks active WebSocket connections per user."""

    def __init__(self) -> None:
        self._active: dict[str, WebSocket] = {}

    async def connect(self, user_id: str, ws: WebSocket) -> None:
        await ws.accept()
        self._active[user_id] = ws
        logger.info("WS connected | user={} total={}", user_id, len(self._active))

    def disconnect(self, user_id: str) -> None:
        self._active.pop(user_id, None)
        logger.info("WS disconnected | user={} total={}", user_id, len(self._active))

    async def send(self, user_id: str, data: dict) -> None:
        ws = self._active.get(user_id)
        if ws:
            await ws.send_text(json.dumps(data))

    @property
    def connected_users(self) -> list[str]:
        return list(self._active.keys())


manager = ConnectionManager()


async def chat_socket_handler(user_id: str, websocket: WebSocket) -> None:
    """
    Main WebSocket handler for a single user session.

    Handles:
    - Connection authentication (Phase 2: Firebase token check)
    - Message receive / safety validation
    - AI response streaming
    - Graceful disconnect
    """
    await manager.connect(user_id, websocket)

    try:
        # 1. Setup Session
        conversation_id_str = websocket.query_params.get("conversation_id")
        if conversation_id_str:
            conversation_id = uuid.UUID(conversation_id_str)
        else:
            conversation_id = uuid.uuid4()
            
        turn_index = 0
        cache_key = active_session_key(str(conversation_id))

        # Check active session buffer in Redis
        cached_history = await cache_get(cache_key)
        history_payload = []

        if cached_history is not None:
            # Cache Hit
            history_payload = cached_history
            turn_index = len(history_payload) // 2
            logger.info("Session buffer hit | conv={}", conversation_id)
        else:
            # Cache Miss: Fetch from Postgres and populate Redis
            logger.info("Session buffer miss, loading from DB | conv={}", conversation_id)
            async with AsyncSessionLocal() as session:
                repo = AIConversationRepository(session)
                db_history = await repo.list_by_conversation(conversation_id)
                
                for turn in db_history:
                    history_payload.append({"role": "user", "content": turn.user_message})
                    history_payload.append({"role": "assistant", "content": turn.ai_response})
                    turn_index = max(turn_index, turn.turn_index + 1)
            
            # Store in Redis with 1 hour TTL
            await cache_set(cache_key, history_payload, ttl_seconds=3600)
                
        await websocket.send_text(json.dumps({
            "type": "history",
            "conversation_id": str(conversation_id),
            "messages": history_payload
        }))

        while True:
            raw = await websocket.receive_text()
            payload = json.loads(raw)
            message = payload.get("message", "")

            if not message.strip():
                continue

            # Safety validation
            safety = validate_input(message)
            if not safety.is_safe:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "content": safety.reason,
                }))
                continue

            user_text = safety.sanitised_text or message
            logger.info("WS message | user={} conv={} len={}", user_id, conversation_id, len(user_text))

            # 2. Build Gemini Context from Redis Active Session
            current_history = await cache_get(cache_key) or []
            
            contents = []
            for msg in current_history:
                role = "user" if msg["role"] == "user" else "model"
                contents.append(genai_types.Content(role=role, parts=[genai_types.Part.from_text(text=msg["content"])]))
            
            # Add the current user message
            contents.append(genai_types.Content(role="user", parts=[genai_types.Part.from_text(text=user_text)]))

            # 3. Stream from Gemini
            start_time = time.time()
            await websocket.send_text(json.dumps({
                "type": "stream_start",
            }))

            system_instruction = (
                "You are KRATOS, an elite AI fitness and nutrition coach. "
                "You are concise, highly knowledgeable, and motivational. "
                "You help users with diet, automated workout plans, and general health queries.\n"
                "IMPORTANT: If the user asks you to create a workout plan, you MUST output the workout in a strictly formatted JSON block wrapped in ```json_workout tags. "
                "The JSON MUST follow this exact schema:\n"
                "```json_workout\n"
                "{\n"
                "  \"name\": \"Workout Name\",\n"
                "  \"split\": \"E.g., Push, Pull, Chest, Full Body\",\n"
                "  \"exercises\": [\n"
                "    {\n"
                "      \"name\": \"Exercise Name\",\n"
                "      \"sets\": 3,\n"
                "      \"reps\": 10,\n"
                "      \"restSeconds\": 60\n"
                "    }\n"
                "  ]\n"
                "}\n"
                "```\n"
                "You may include conversational text before and after this JSON block to encourage the user."
            )

            full_response = ""
            try:
                async for chunk in gemini.stream(
                    contents=contents,
                    model=GeminiModel.FLASH,
                    system_instruction=system_instruction,
                    user_id=user_id,
                ):
                    full_response += chunk
                    await websocket.send_text(json.dumps({
                        "type": "stream_chunk",
                        "content": chunk,
                    }))
            except Exception as e:
                logger.error("Gemini stream error: {}", e)
                error_msg = "\n[Connection interrupted. Please try again.]"
                full_response += error_msg
                await websocket.send_text(json.dumps({
                    "type": "stream_chunk",
                    "content": error_msg,
                }))

            await websocket.send_text(json.dumps({
                "type": "stream_end",
            }))

            # 4. Update Redis Active Session & Save to PostgreSQL
            if full_response.strip():
                latency = (time.time() - start_time) * 1000
                
                # Update Redis Active Buffer
                current_history.append({"role": "user", "content": user_text})
                current_history.append({"role": "assistant", "content": full_response})
                await cache_set(cache_key, current_history, ttl_seconds=3600)
                
                # Save permanent turn to Postgres
                async with AsyncSessionLocal() as session:
                    repo = AIConversationRepository(session)
                    new_turn = AIConversation(
                        firebase_uid=user_id,
                        conversation_id=conversation_id,
                        turn_index=turn_index,
                        role="assistant",
                        user_message=user_text,
                        ai_response=full_response,
                        agent_type="assistant",
                        model_used="models/gemini-3.6-flash",
                        latency_ms=latency
                    )
                    session.add(new_turn)
                    await session.commit()
                    
                # Invalidate the sessions list cache
                await cache_delete(session_list_key(user_id))
                
                turn_index += 1

    except WebSocketDisconnect:
        manager.disconnect(user_id)
    except Exception as exc:
        logger.exception("WS error | user={} error={}", user_id, exc)
        manager.disconnect(user_id)
