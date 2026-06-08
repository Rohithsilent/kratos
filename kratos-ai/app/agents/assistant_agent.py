"""
AssistantAgent — General-purpose KRATOS fitness intelligence.

Responsibilities:
- Answer fitness Q&A with context-awareness
- Route complex queries to specialist agents
- Maintain conversational memory via Redis
"""
from __future__ import annotations

from typing import Any
from loguru import logger


class AssistantAgent:
    """Conversational fitness assistant backed by Gemini + LangGraph."""

    def __init__(self, llm: Any, memory: Any | None = None) -> None:
        self.llm = llm
        self.memory = memory
        logger.info("AssistantAgent initialised")

    async def run(self, user_id: str, message: str, context: dict | None = None) -> str:
        """
        Process a user message and return an AI response.

        Args:
            user_id: Firebase UID of the requesting user.
            message: Raw user input.
            context: Optional extra context (profile, recent workouts, etc.).

        Returns:
            AI-generated response string.
        """
        logger.debug("AssistantAgent.run | user={} msg_len={}", user_id, len(message))
        # TODO Phase 2: build LangGraph node, inject memory, call Gemini
        raise NotImplementedError("AssistantAgent.run — implement in Phase 2")
