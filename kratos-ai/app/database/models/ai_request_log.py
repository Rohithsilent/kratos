"""
KRATOS AI — AI Request Logs Model (Observability).

Logs every AI API call for monitoring, debugging, and cost tracking.
This is the AI observability backbone.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, Index, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin, UUIDMixin


class AIRequestLog(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "ai_request_logs"
    __table_args__ = (
        Index("ix_ai_request_logs_firebase_uid", "firebase_uid"),
        Index("ix_ai_request_logs_endpoint", "endpoint"),
        Index("ix_ai_request_logs_model_used", "model_used"),
        Index("ix_ai_request_logs_status", "status"),
        Index("ix_ai_request_logs_created_at", "created_at"),
        {"comment": "AI API call observability and cost tracking"},
    )

    firebase_uid: Mapped[Optional[str]] = mapped_column(String(128), nullable=True, comment="Firebase UID (nullable for system calls)")
    endpoint: Mapped[str] = mapped_column(String(255), nullable=False, comment="API endpoint that triggered this call")
    agent_type: Mapped[str] = mapped_column(String(50), nullable=False, comment="Agent: assistant|planner|recovery|nutrition|progression")
    model_used: Mapped[str] = mapped_column(String(100), nullable=False)

    prompt_tokens: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    completion_tokens: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    total_tokens: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    latency_ms: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="success", server_default="success", comment="success|error|timeout|rate_limited")
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    error_type: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    request_metadata: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True, comment="Request headers, params, etc.")
    response_metadata: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True, comment="Response metadata, safety ratings, etc.")

    estimated_cost_usd: Mapped[Optional[float]] = mapped_column(Float, nullable=True, comment="Estimated cost in USD")

    def __repr__(self) -> str:
        return f"<AIRequestLog id={self.id} endpoint={self.endpoint} status={self.status} tokens={self.total_tokens}>"
