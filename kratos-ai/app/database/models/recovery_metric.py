"""
KRATOS AI — Recovery Metrics Model.

Stores AI-computed recovery analytics — NOT raw user input.
Firebase stores the raw recovery logs; this table stores the AI's
analysis, trend detection, and computed recovery intelligence.

Examples:
- Weekly recovery trend score
- Overtraining risk probability
- Sleep quality impact analysis
- Muscle group fatigue mapping
"""
from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import Date, Float, Index, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin, UUIDMixin


class RecoveryMetric(UUIDMixin, TimestampMixin, Base):
    """AI-computed recovery analytics for a user on a given date."""

    __tablename__ = "recovery_metrics"
    __table_args__ = (
        Index("ix_recovery_metrics_firebase_uid", "firebase_uid"),
        Index("ix_recovery_metrics_metric_date", "metric_date"),
        Index("ix_recovery_metrics_metric_type", "metric_type"),
        Index("ix_recovery_metrics_uid_date", "firebase_uid", "metric_date"),
        Index("ix_recovery_metrics_risk_level", "risk_level"),
        {"comment": "AI-computed recovery analytics and trend data"},
    )

    # ── User Reference ────────────────────────────────────────────────────────
    firebase_uid: Mapped[str] = mapped_column(
        String(128),
        nullable=False,
        comment="Firebase UID of the user",
    )

    # ── Metric Identity ───────────────────────────────────────────────────────
    metric_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
        comment="Date this metric was computed for",
    )
    metric_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        comment="Metric type: daily_score | weekly_trend | fatigue_map | overtraining_risk",
    )

    # ── Computed Values ───────────────────────────────────────────────────────
    recovery_score: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        comment="AI-computed recovery score (0.0 – 100.0)",
    )
    risk_level: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="low",
        server_default="low",
        comment="Risk level: low | moderate | high | critical",
    )
    readiness_status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="ready",
        server_default="ready",
        comment="Training readiness: ready | caution | rest",
    )

    # ── Input Signals ─────────────────────────────────────────────────────────
    sleep_quality_score: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
        comment="AI-assessed sleep quality (0.0 – 10.0)",
    )
    soreness_index: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
        comment="Aggregated soreness index from user reports",
    )
    training_load_7d: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
        comment="Rolling 7-day training load metric",
    )
    hrv_trend: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
        comment="HRV trend value if available",
    )

    # ── AI Analysis ───────────────────────────────────────────────────────────
    analysis_summary: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
        comment="AI-generated human-readable recovery analysis",
    )
    muscle_fatigue_map: Mapped[Optional[dict]] = mapped_column(
        JSONB,
        nullable=True,
        comment="Per-muscle-group fatigue levels: {'chest': 0.7, 'legs': 0.3, ...}",
    )
    recommendations: Mapped[Optional[list]] = mapped_column(
        JSONB,
        nullable=True,
        comment="AI recovery recommendations: ['deload', 'sleep_more', ...]",
    )
    contributing_factors: Mapped[Optional[dict]] = mapped_column(
        JSONB,
        nullable=True,
        comment="Factors that influenced the score: {'sleep': -0.2, 'volume': -0.1}",
    )

    # ── Model Metadata ────────────────────────────────────────────────────────
    model_used: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        comment="AI model that computed this metric",
    )
    confidence: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
        comment="AI confidence in this metric (0.0 – 1.0)",
    )

    def __repr__(self) -> str:
        return (
            f"<RecoveryMetric id={self.id} user={self.firebase_uid} "
            f"date={self.metric_date} score={self.recovery_score} "
            f"risk={self.risk_level}>"
        )
