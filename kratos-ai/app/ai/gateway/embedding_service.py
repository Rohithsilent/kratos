"""
EmbeddingService — Manages vector embeddings and Pinecone operations.

Responsibilities:
- Generate embeddings via Gemini text-embedding-004
- Upsert user fitness context into Pinecone
- Retrieve semantically similar workouts / nutrition data
- Namespace by user_id for data isolation
"""
from __future__ import annotations

from loguru import logger

from app.ai.gateway.gemini_gateway import GeminiGateway


class EmbeddingService:
    """
    Vector embedding layer using Gemini embeddings + Pinecone.

    Each user's data lives in its own Pinecone namespace
    (namespace = user_id) ensuring strict data isolation.
    """

    def __init__(self, gemini: GeminiGateway, pinecone_index: "Any") -> None:
        self.gemini = gemini
        self.index = pinecone_index
        logger.info("EmbeddingService initialised")

    async def upsert_workout(self, user_id: str, workout_id: str, workout_text: str) -> None:
        """
        Embed a workout description and store in Pinecone.

        Args:
            user_id: Namespace / user isolation key.
            workout_id: Unique workout identifier (becomes vector ID).
            workout_text: Human-readable workout description to embed.
        """
        embedding = await self.gemini.embed(workout_text)
        self.index.upsert(
            vectors=[{"id": workout_id, "values": embedding, "metadata": {"user_id": user_id}}],
            namespace=user_id,
        )
        logger.debug("EmbeddingService.upsert_workout | user={} id={}", user_id, workout_id)

    async def search_similar(self, user_id: str, query: str, top_k: int = 5) -> list[dict]:
        """
        Semantic search for workouts/plans similar to query.

        Args:
            user_id: Pinecone namespace.
            query: Natural language search query.
            top_k: Number of results to return.

        Returns:
            List of matched vector metadata dicts.
        """
        embedding = await self.gemini.embed(query)
        result = self.index.query(
            vector=embedding,
            top_k=top_k,
            namespace=user_id,
            include_metadata=True,
        )
        logger.debug("EmbeddingService.search_similar | user={} matches={}", user_id, len(result.matches))
        return [m.metadata for m in result.matches]
