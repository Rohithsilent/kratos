"""
KRATOS AI — AI Insights Model.

Stores AI-generated fitness insights, analysis results, and intelligence outputs.
Each insight is tied to a Firebase user via ``firebase_uid`` (no FK — Firebase owns user data).

Examples of stored insights:
- "Your bench press has plateaued — try drop sets"
- "Recovery score trending down — consider a deload week"
- "Protein intake 15% below target for 3 consecutive days"
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, Index, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin, UUIDMixin


class AIInsight(UUIDMixin, TimestampMixin, Base):
    """AI-generated fitness insight or recommendation."""

    __tablename__ = "ai_insights"
    __table_args__ = (
        Index("ix_ai_insights_firebase_uid", "firebase_uid"),
        Index("ix_ai_insights_category", "category"),
        Index("ix_ai_insights_created_at", "created_at"),
        Index("ix_ai_insights_priority", "priority"),
        Index("ix_ai_insights_uid_category", "firebase_uid", "category"),
        {"comment": "AI-generated fitness insights and analysis results"},
    )

    # ── User Reference ────────────────────────────────────────────────────────
    firebase_uid: Mapped[str] = mapped_column(
        String(128),
        nullable=False,
        comment="Firebase UID of the user this insight belongs to",
    )

    # ── Insight Content ───────────────────────────────────────────────────────
    category: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        comment="Insight category: workout | nutrition | recovery | general | progression",
    )
    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        comment="Short human-readable insight title",
    )
    content: Mapped[str] = mapped_column(
        Text,
        nullable=False,
        comment="Full insight text / analysis body",
    )
    priority: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="medium",
        server_default="medium",
        comment="Priority level: low | medium | high | critical",
    )

    # ── AI Metadata ───────────────────────────────────────────────────────────
    model_used: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        comment="Gemini model that generated this insight",
    )
    confidence_score: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
        comment="AI confidence in this insight (0.0 – 1.0)",
    )
    source_data: Mapped[Optional[dict]] = mapped_column(
        JSONB,
        nullable=True,
        comment="Source context/data the AI used to generate this insight",
    )
    tags: Mapped[Optional[list]] = mapped_column(
        JSONB,
        nullable=True,
        default=list,
        comment="Searchable tags: ['plateau', 'bench_press', 'strength']",
    )

    # ── User Feedback ─────────────────────────────────────────────────────────
    is_dismissed: Mapped[bool] = mapped_column(
        default=False,
        server_default="false",
        comment="Whether the user dismissed this insight",
    )
    is_acted_upon: Mapped[bool] = mapped_column(
        default=False,
        server_default="false",
        comment="Whether the user took action on this insight",
    )
    feedback_rating: Mapped[Optional[int]] = mapped_column(
        nullable=True,
        comment="User rating of insight quality (1–5)",
    )

    # ── Expiry ────────────────────────────────────────────────────────────────
    expires_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        comment="When this insight becomes stale (nullable = never expires)",
    )

    def __repr__(self) -> str:
        return (
            f"<AIInsight id={self.id} user={self.firebase_uid} "
            f"category={self.category} priority={self.priority}>"
        )
