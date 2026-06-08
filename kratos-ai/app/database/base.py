"""
KRATOS AI — Declarative Base and ORM Mixins.

Provides:
- Base         — The single DeclarativeBase for all models.
- UUIDMixin    — Auto-generated UUID4 primary keys.
- TimestampMixin — created_at / updated_at with server-side defaults.
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Shared declarative base for every ORM model in KRATOS AI."""
    pass


class UUIDMixin:
    """Mixin that adds a UUID4 primary key column named ``id``."""

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=func.gen_random_uuid(),
        comment="UUID4 primary key",
    )


class TimestampMixin:
    """Mixin that adds ``created_at`` and ``updated_at`` server-side timestamps."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        comment="Row creation timestamp (server-side)",
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
        comment="Last update timestamp (auto-refreshed on UPDATE)",
    )
