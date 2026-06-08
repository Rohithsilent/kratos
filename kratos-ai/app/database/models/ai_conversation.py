"""
KRATOS AI — AI Conversations Model.

Stores AI conversation history with full observability:
- Token counts (prompt + completion)
- Latency tracking
- Model/agent routing
- Conversation threading via ``conversation_id``

This is the AI memory layer — NOT a chat persistence table.
It tracks which model answered, how many tokens were used, and the quality
of the response for continuous improvement.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, Index, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin, UUIDMixin


class AIConversation(UUIDMixin, TimestampMixin, Base):
    """Single AI conversation turn (user message + AI response pair)."""

    __tablename__ = "ai_conversations"
    __table_args__ = (
        Index("ix_ai_conversations_firebase_uid", "firebase_uid"),
        Index("ix_ai_conversations_conversation_id", "conversation_id"),
        Index("ix_ai_conversations_agent_type", "agent_type"),
        Index("ix_ai_conversations_created_at", "created_at"),
        Index("ix_ai_conversations_uid_conv", "firebase_uid", "conversation_id"),
        {"comment": "AI conversation history with token/cost tracking"},
    )

    # ── User & Thread ─────────────────────────────────────────────────────────
    firebase_uid: Mapped[str] = mapped_column(
        String(128),
        nullable=False,
        comment="Firebase UID of the user",
    )
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        nullable=False,
        default=uuid.uuid4,
        comment="Groups messages into a conversation thread",
    )
    turn_index: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
        comment="Message order within the conversation (0-based)",
    )

    # ── Content ───────────────────────────────────────────────────────────────
    role: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        comment="Message role: user | assistant | system | tool",
    )
    user_message: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
        comment="The user's input message",
    )
    ai_response: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
        comment="The AI's generated response",
    )

    # ── Routing & Model ───────────────────────────────────────────────────────
    agent_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="assistant",
        comment="Which agent handled this: assistant | planner | recovery | nutrition | progression",
    )
    model_used: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        comment="Gemini model used for this response",
    )

    # ── Token Economics ───────────────────────────────────────────────────────
    prompt_tokens: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
        comment="Number of prompt (input) tokens",
    )
    completion_tokens: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
        comment="Number of completion (output) tokens",
    )
    total_tokens: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
        comment="Total tokens (prompt + completion)",
    )

    # ── Performance ───────────────────────────────────────────────────────────
    latency_ms: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
        comment="End-to-end response latency in milliseconds",
    )

    # ── Context & Metadata ────────────────────────────────────────────────────
    context_data: Mapped[Optional[dict]] = mapped_column(
        JSONB,
        nullable=True,
        comment="Additional context sent to the model (user profile snapshot, etc.)",
    )
    tool_calls: Mapped[Optional[list]] = mapped_column(
        JSONB,
        nullable=True,
        comment="Tool/function calls made during this turn",
    )

    # ── Quality Tracking ──────────────────────────────────────────────────────
    feedback_rating: Mapped[Optional[int]] = mapped_column(
        nullable=True,
        comment="User satisfaction rating (1–5)",
    )
    was_regenerated: Mapped[bool] = mapped_column(
        default=False,
        server_default="false",
        comment="Whether the user requested a regeneration",
    )

    def __repr__(self) -> str:
        return (
            f"<AIConversation id={self.id} user={self.firebase_uid} "
            f"agent={self.agent_type} tokens={self.total_tokens}>"
        )
