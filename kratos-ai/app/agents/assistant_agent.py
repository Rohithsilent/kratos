"""
AssistantAgent — General-purpose KRATOS fitness intelligence.

Responsibilities:
- Answer fitness Q&A with context-awareness
- Return structured, safe fitness guidance
"""
from __future__ import annotations

import json
from typing import Any

from app.ai.gateway.gemini_gateway import GeminiModel
from app.ai.schemas import ChatOutput
from app.core.config import settings
from loguru import logger


class AssistantAgent:
    """Conversational fitness assistant backed by Gemini Flash."""

    def __init__(self, llm: Any, memory: Any | None = None) -> None:
        self.llm = llm
        self.memory = memory
        logger.info("AssistantAgent initialised")

    async def run(
        self,
        user_id: str,
        message: str,
        context: dict | None = None,
    ) -> ChatOutput:
        """
        Process a user message and return an AI response.

        Args:
            user_id: Firebase UID of the requesting user.
            message: Raw user input.
            context: Optional extra context (profile, recent workouts, etc.).

        Returns:
            Validated assistant response.
        """
        logger.debug("AssistantAgent.run | user={} msg_len={}", user_id, len(message))
        context_json = json.dumps(context or {}, ensure_ascii=False, default=str)
        # Context is optional client input. Bound it independently of the message
        # limit so it cannot turn a small request into an expensive model call.
        context_json = context_json[: settings.CHAT_MAX_MESSAGE_CHARS]
        prompt = (
            "User message: " + message + "\n"
            "Optional fitness context: " + context_json + "\n"
            "Give practical, concise fitness or nutrition guidance. Do not diagnose "
            "medical conditions or recommend dangerous substances."
        )
        return await self.llm.generate_structured(
            prompt=prompt,
            schema=ChatOutput,
            model=GeminiModel.FLASH,
            system_instruction=(
                "You are KRATOS, a concise AI fitness coach. "
                "Use encouraging, evidence-aware guidance and state limits clearly."
            ),
            temperature=0.4,
            max_output_tokens=512,
            user_id=user_id,
        )
