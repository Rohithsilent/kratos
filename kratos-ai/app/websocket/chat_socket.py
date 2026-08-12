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
from app.cache.redis_client import append_chat_message, get_chat_history
from app.ai.gateway.gemini_gateway import gemini, GeminiModel
from google.genai import types as genai_types

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
        # Send chat history on connect
        history = await get_chat_history(user_id)
        await websocket.send_text(json.dumps({"type": "history", "messages": history}))

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

            # Store user message
            await append_chat_message(user_id, "user", safety.sanitised_text or message)
            logger.info("WS message | user={} len={}", user_id, len(message))

            history = await get_chat_history(user_id)
            
            # 2. Convert to Gemini Content format
            contents = []
            for msg in history:
                role = "model" if msg["role"] == "assistant" else "user"
                contents.append(
                    genai_types.Content(
                        role=role,
                        parts=[genai_types.Part.from_text(text=msg["content"])]
                    )
                )

            # 3. Stream from Gemini
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

            # 4. Save AI response
            if full_response.strip():
                await append_chat_message(user_id, "assistant", full_response)

    except WebSocketDisconnect:
        manager.disconnect(user_id)
    except Exception as exc:
        logger.exception("WS error | user={} error={}", user_id, exc)
        manager.disconnect(user_id)
