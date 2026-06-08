"""KRATOS AI — AI Conversation Repository."""
from __future__ import annotations

import uuid
from typing import Optional, Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models.ai_conversation import AIConversation
from app.database.repositories.base import BaseRepository


class AIConversationRepository(BaseRepository[AIConversation]):
    def __init__(self, session: AsyncSession) -> None:
        super().__init__(AIConversation, session)

    async def list_by_conversation(
        self,
        conversation_id: uuid.UUID,
        *,
        limit: int = 100,
    ) -> Sequence[AIConversation]:
        stmt = (
            select(AIConversation)
            .where(AIConversation.conversation_id == conversation_id)
            .order_by(AIConversation.turn_index.asc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def list_user_conversations(
        self,
        firebase_uid: str,
        *,
        offset: int = 0,
        limit: int = 50,
    ) -> Sequence[AIConversation]:
        stmt = (
            select(AIConversation)
            .where(AIConversation.firebase_uid == firebase_uid)
            .order_by(AIConversation.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def get_token_usage(self, firebase_uid: str) -> dict:
        stmt = (
            select(
                func.sum(AIConversation.prompt_tokens).label("total_prompt"),
                func.sum(AIConversation.completion_tokens).label("total_completion"),
                func.sum(AIConversation.total_tokens).label("total_all"),
                func.count().label("total_turns"),
                func.avg(AIConversation.latency_ms).label("avg_latency_ms"),
            )
            .where(AIConversation.firebase_uid == firebase_uid)
        )
        result = await self._session.execute(stmt)
        row = result.one()
        return {
            "total_prompt_tokens": row.total_prompt or 0,
            "total_completion_tokens": row.total_completion or 0,
            "total_tokens": row.total_all or 0,
            "total_turns": row.total_turns or 0,
            "avg_latency_ms": round(row.avg_latency_ms or 0, 2),
        }

    async def get_usage_by_agent(self, firebase_uid: str) -> list[dict]:
        stmt = (
            select(
                AIConversation.agent_type,
                func.count().label("count"),
                func.sum(AIConversation.total_tokens).label("tokens"),
            )
            .where(AIConversation.firebase_uid == firebase_uid)
            .group_by(AIConversation.agent_type)
        )
        result = await self._session.execute(stmt)
        return [{"agent": r.agent_type, "count": r.count, "tokens": r.tokens or 0} for r in result.all()]
