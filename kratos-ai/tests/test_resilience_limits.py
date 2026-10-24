import unittest
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException

from app.api.nutrition import analyze_food_image
from app.cache import redis_client
from app.core.config import settings
from app.core.security import AuthenticatedUser


class FailingRedis:
    async def ping(self) -> bool:
        raise ConnectionError("Redis unavailable")


class FakeImageUpload:
    content_type = "image/jpeg"
    filename = "large.jpg"

    async def read(self, size: int) -> bytes:
        return b"x" * size


class ResilienceAndLimitTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self) -> None:
        redis_client._memory_cache.clear()
        redis_client._memory_rate_limits.clear()

    async def test_cache_uses_in_memory_fallback_when_redis_is_down(self) -> None:
        with patch(
            "app.cache.redis_client.get_redis",
            AsyncMock(side_effect=ConnectionError("Redis unavailable")),
        ):
            await redis_client.cache_set("test-key", {"value": 1}, ttl_seconds=60)
            value = await redis_client.cache_get("test-key")

        self.assertEqual(value, {"value": 1})

    async def test_rate_limiter_still_enforces_limits_without_redis(self) -> None:
        with patch(
            "app.cache.redis_client.get_redis",
            AsyncMock(side_effect=ConnectionError("Redis unavailable")),
        ):
            first = await redis_client.check_redis_rate_limit("user-1", limit=2)
            second = await redis_client.check_redis_rate_limit("user-1", limit=2)
            third = await redis_client.check_redis_rate_limit("user-1", limit=2)

        self.assertEqual(first, (True, 1))
        self.assertEqual(second, (True, 2))
        self.assertEqual(third, (False, 2))

    async def test_image_endpoint_rejects_uploads_larger_than_the_limit(self) -> None:
        with self.assertRaises(HTTPException) as context:
            await analyze_food_image(
                FakeImageUpload(),
                AuthenticatedUser("user-1"),
            )

        self.assertEqual(context.exception.status_code, 413)
        self.assertEqual(settings.MAX_IMAGE_UPLOAD_BYTES, 5 * 1024 * 1024)
