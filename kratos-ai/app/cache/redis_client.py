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
_memory_cache: dict[str, tuple[float, str]] = {}
_memory_rate_limits: dict[str, list[float]] = {}


async def get_redis() -> aioredis.Redis:
    """Return (or create) the global async Redis client."""
    global _redis
    if _redis is None:
        client = aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
        )
        try:
            await client.ping()
        except Exception:
            await client.aclose()
            raise
        _redis = client
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

def _set_memory_cache(key: str, value: Any, ttl_seconds: int) -> None:
    _memory_cache.pop(key, None)
    _memory_cache[key] = (time.monotonic() + ttl_seconds, json.dumps(value))
    while len(_memory_cache) > settings.IN_MEMORY_CACHE_MAX_ENTRIES:
        _memory_cache.pop(next(iter(_memory_cache)))


def _get_memory_cache(key: str) -> Any | None:
    entry = _memory_cache.get(key)
    if entry is None:
        return None
    expires_at, raw = entry
    if time.monotonic() >= expires_at:
        _memory_cache.pop(key, None)
        return None
    return json.loads(raw)


async def cache_set(key: str, value: Any, ttl_seconds: int = 3600) -> None:
    """Store a value in Redis, falling back to a bounded local cache."""
    try:
        r = await get_redis()
        await r.setex(key, ttl_seconds, json.dumps(value))
    except Exception as exc:
        logger.warning("Redis cache write failed; using in-memory cache: {}", exc)
        _set_memory_cache(key, value, ttl_seconds)


async def cache_get(key: str) -> Any | None:
    """Retrieve a cached value, using local storage if Redis is unavailable."""
    try:
        r = await get_redis()
        raw = await r.get(key)
        return json.loads(raw) if raw else None
    except Exception as exc:
        logger.warning("Redis cache read failed; using in-memory cache: {}", exc)
        return _get_memory_cache(key)


async def cache_delete(key: str) -> None:
    """Delete a cache key from both Redis and the local fallback."""
    _memory_cache.pop(key, None)
    try:
        r = await get_redis()
        await r.delete(key)
    except Exception as exc:
        logger.warning("Redis cache delete failed; local cache entry removed: {}", exc)


# ── Fitness-specific cache helpers ────────────────────────────────────────────

def recovery_key(user_id: str) -> str:
    return f"kratos:recovery:{user_id}"


def plan_key(user_id: str) -> str:
    return f"kratos:plan:{user_id}"


def chat_session_key(user_id: str) -> str:
    return f"kratos:chat:{user_id}"

def active_session_key(user_id: str, conversation_id: str) -> str:
    """Key for caching the active conversation history scoped to user."""
    return f"kratos:session_buffer:{user_id}:{conversation_id}"

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
        logger.warning("Redis rate limit check failed; using in-memory limiter: {}", exc)
        now = time.monotonic()
        requests = _memory_rate_limits.get(key, [])
        requests = [timestamp for timestamp in requests if now - timestamp < window_seconds]
        if len(requests) >= limit:
            _memory_rate_limits[key] = requests
            return False, len(requests)
        requests.append(now)
        _memory_rate_limits[key] = requests
        return True, len(requests)


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


