"""
KRATOS AI — Recommendation Logs Model.

Tracks every AI recommendation with full lifecycle:
generation → delivery → user response → outcome measurement.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, Index, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin, UUIDMixin


class RecommendationLog(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "recommendation_logs"
    __table_args__ = (
        Index("ix_rec_logs_firebase_uid", "firebase_uid"),
        Index("ix_rec_logs_domain", "domain"),
        Index("ix_rec_logs_created_at", "created_at"),
        Index("ix_rec_logs_outcome", "outcome_status"),
        Index("ix_rec_logs_uid_domain", "firebase_uid", "domain"),
        {"comment": "AI recommendation tracking with feedback loop"},
    )

    firebase_uid: Mapped[str] = mapped_column(String(128), nullable=False)
    domain: Mapped[str] = mapped_column(String(50), nullable=False, comment="workout|nutrition|recovery|supplement|lifestyle")
    recommendation_type: Mapped[str] = mapped_column(String(50), nullable=False, comment="exercise_swap|volume_adjust|meal_plan|rest_day|deload")
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    reasoning: Mapped[Optional[str]] = mapped_column(Text, nullable=True, comment="AI chain-of-thought")

    trigger_context: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)
    user_context_snapshot: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)

    model_used: Mapped[str] = mapped_column(String(100), nullable=False)
    agent_type: Mapped[str] = mapped_column(String(50), nullable=False)
    confidence_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    priority: Mapped[str] = mapped_column(String(20), nullable=False, default="medium", server_default="medium")

    was_seen: Mapped[bool] = mapped_column(default=False, server_default="false")
    was_accepted: Mapped[Optional[bool]] = mapped_column(nullable=True)
    user_feedback: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    outcome_status: Mapped[Optional[str]] = mapped_column(String(30), nullable=True, comment="pending|positive|neutral|negative|unknown")
    outcome_measured_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    outcome_data: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    def __repr__(self) -> str:
        return f"<RecommendationLog id={self.id} user={self.firebase_uid} domain={self.domain}>"
