"""
Redis client — async caching and pub/sub layer.

Provides:
- Async Redis client (singleton)
- Cache helpers: get, set, delete with TTL
- Session cache for chat history
- Recovery score cache
"""
from __future__ import annotations

import json
import time
from typing import Any

import redis.asyncio as aioredis
from loguru import logger

from app.core.config import settings


# ── Singleton connection pool ─────────────────────────────────────────────────
_redis: aioredis.Redis | None = None


async def get_redis() -> aioredis.Redis:
    """Return (or create) the global async Redis client."""
    global _redis
    if _redis is None:
        _redis = await aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
        )
        logger.info("Redis connected → {}", settings.REDIS_URL)
    return _redis


async def close_redis() -> None:
    """Close the Redis connection pool on shutdown."""
    global _redis
    if _redis:
        await _redis.aclose()
        _redis = None
        logger.info("Redis connection closed")


# ── Cache helpers ─────────────────────────────────────────────────────────────

async def cache_set(key: str, value: Any, ttl_seconds: int = 3600) -> None:
    """Serialise and store a value in Redis with TTL."""
    r = await get_redis()
    await r.setex(key, ttl_seconds, json.dumps(value))


async def cache_get(key: str) -> Any | None:
    """Retrieve and deserialise a value from Redis. Returns None if missing."""
    r = await get_redis()
    raw = await r.get(key)
    return json.loads(raw) if raw else None


async def cache_delete(key: str) -> None:
    """Delete a cache key."""
    r = await get_redis()
    await r.delete(key)


# ── Fitness-specific cache helpers ────────────────────────────────────────────

def recovery_key(user_id: str) -> str:
    return f"kratos:recovery:{user_id}"


def plan_key(user_id: str) -> str:
    return f"kratos:plan:{user_id}"


def chat_session_key(user_id: str) -> str:
    return f"kratos:chat:{user_id}"

def active_session_key(conversation_id: str) -> str:
    """Key for caching the active conversation history."""
    return f"kratos:session_buffer:{conversation_id}"

def session_list_key(user_id: str) -> str:
    return f"kratos:sessions:{user_id}"

async def get_cached_recovery(user_id: str) -> dict | None:
    return await cache_get(recovery_key(user_id))


async def set_cached_recovery(user_id: str, data: dict, ttl: int = 43200) -> None:
    """Cache recovery score for 12 hours."""
    await cache_set(recovery_key(user_id), data, ttl)


# ── Redis Sliding-Window Rate Limiter ─────────────────────────────────────────

async def check_redis_rate_limit(
    key: str,
    limit: int = 20,
    window_seconds: int = 60,
) -> tuple[bool, int]:
    """
    Check if a rate limit is exceeded using Redis Sorted Set sliding window.

    Returns:
        (allowed: bool, current_count: int)
    """
    try:
        r = await get_redis()
        now = time.time()
        cutoff = now - window_seconds
        pipe = r.pipeline()
        pipe.zremrangebyscore(key, 0, cutoff)
        pipe.zcard(key)
        pipe.zadd(key, {f"{now}": now})
        pipe.expire(key, window_seconds + 10)
        results = await pipe.execute()
        count = results[1]
        if count >= limit:
            return False, count
        return True, count + 1
    except Exception as exc:
        logger.warning("Redis rate limit check failed (falling back to allowed): {}", exc)
        return True, 0


# ── AI Response Cache Helpers ──────────────────────────────────────────────────

def ai_cache_key(prompt_hash: str) -> str:
    return f"kratos:ai_cache:{prompt_hash}"


async def get_ai_response_cache(prompt_hash: str) -> Any | None:
    try:
        return await cache_get(ai_cache_key(prompt_hash))
    except Exception as exc:
        logger.warning("Failed to fetch AI response cache: {}", exc)
        return None


async def set_ai_response_cache(
    prompt_hash: str,
    data: Any,
    ttl: int = settings.AI_CACHE_TTL_SECONDS,
) -> None:
    try:
        await cache_set(ai_cache_key(prompt_hash), data, ttl_seconds=ttl)
    except Exception as exc:
        logger.warning("Failed to set AI response cache: {}", exc)


