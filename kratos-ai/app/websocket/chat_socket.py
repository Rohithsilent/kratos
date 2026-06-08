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

            # TODO Phase 2: stream from GeminiGateway via FitnessGraph
            await websocket.send_text(json.dumps({
                "type": "stream_start",
            }))

            placeholder = "[AI response — Phase 2: FitnessGraph not yet wired]"
            await websocket.send_text(json.dumps({
                "type": "stream_chunk",
                "content": placeholder,
            }))

            await websocket.send_text(json.dumps({
                "type": "stream_end",
            }))

            await append_chat_message(user_id, "assistant", placeholder)

    except WebSocketDisconnect:
        manager.disconnect(user_id)
    except Exception as exc:
        logger.exception("WS error | user={} error={}", user_id, exc)
        manager.disconnect(user_id)
