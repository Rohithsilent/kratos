"""
KRATOS AI — Meal Entry Model.

Stores user meal history natively in PostgreSQL to allow AI agents 
to query and analyze historical nutrition data efficiently using SQL.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base, TimestampMixin

class MealEntryModel(TimestampMixin, Base):
    """A logged meal by the user."""

    __tablename__ = "meal_entries"
    __table_args__ = (
        Index("ix_meal_entries_firebase_uid", "firebase_uid"),
        Index("ix_meal_entries_date", "date"),
        {"comment": "User logged meal history"},
    )

    # ── Identifiers ──────────────────────────────────────────────────────────
    id: Mapped[str] = mapped_column(
        String(64),
        primary_key=True,
        comment="Client-generated unique ID",
    )

    # ── User Reference ────────────────────────────────────────────────────────
    firebase_uid: Mapped[str] = mapped_column(
        String(128),
        nullable=False,
        comment="Firebase UID of the user who logged this meal",
    )

    # ── Meal Content ──────────────────────────────────────────────────────────
    date: Mapped[str] = mapped_column(
        String(10),
        nullable=False,
        comment="Date of the meal (YYYY-MM-DD)",
    )
    food_name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        comment="Name of the food",
    )
    calories: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        comment="Total calories",
    )
    protein: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        comment="Total protein in grams",
    )
    carbs: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        comment="Total carbohydrates in grams",
    )
    fats: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        comment="Total fats in grams",
    )
    meal_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        comment="Type of meal: breakfast, lunch, dinner, snack",
    )
    logged_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        comment="When the meal was logged",
    )
    source: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="manual",
        server_default="manual",
        comment="Source of entry: manual | ai_scan",
    )
    serving_size: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
        comment="Serving size in grams",
    )

    def __repr__(self) -> str:
        return (
            f"<MealEntryModel id={self.id} user={self.firebase_uid} "
            f"food={self.food_name} calories={self.calories}>"
        )
