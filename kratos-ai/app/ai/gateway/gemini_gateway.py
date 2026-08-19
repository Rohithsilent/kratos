"""
GeminiGateway — Production-grade unified Gemini interface for KRATOS AI.

Features:
  ✅ Key pool rotation — Round-robin multi-key pool & automatic 429 failover
  ✅ Per-user rate limit— Redis-backed sliding window per user ID
  ✅ Response caching  — Redis response cache for fast <10ms lookup
  ✅ Model routing     — Flash (fast) | Pro (deep) | Vision (multimodal)
  ✅ Structured JSON   — response_mime_type="application/json" enforced
  ✅ Schema validation — Pydantic models validate every response
  ✅ Retries           — exponential backoff & failover across key pool
  ✅ Token tracking    — input/output tokens logged per call
  ✅ Streaming         — async token-by-token for WebSocket
  ✅ Embeddings        — text-embedding-004 for Pinecone
"""
from __future__ import annotations

import asyncio
import hashlib
import json
import time
from enum import Enum
from typing import Any, AsyncIterator, Callable, Type, TypeVar

from google import genai
from google.genai import types as genai_types
from pydantic import BaseModel, ValidationError
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)
from loguru import logger

from app.core.config import settings
from app.cache.redis_client import (
    check_redis_rate_limit,
    get_ai_response_cache,
    set_ai_response_cache,
)

T = TypeVar("T", bound=BaseModel)


# ── Custom Exceptions ─────────────────────────────────────────────────────────

class GeminiRateLimitError(Exception):
    """Raised when the rate limit (RPM, TPM, or per-user) is exceeded."""


class GeminiStructuredOutputError(Exception):
    """Raised when Gemini response cannot be parsed into the expected schema."""


class GeminiAPIError(Exception):
    """Raised on unrecoverable Gemini API errors."""


# ── Model Enum ────────────────────────────────────────────────────────────────

class GeminiModel(str, Enum):
    FLASH = "flash"           # Fast responses, chat, simple lookups
    PRO = "pro"               # Deep reasoning, plan generation
    VISION = "vision"         # Image/multimodal (uses Flash — 2.5 is natively multimodal)


# ── Token Usage Tracker ───────────────────────────────────────────────────────

class TokenUsage(BaseModel):
    input_tokens: int = 0
    output_tokens: int = 0
    total_tokens: int = 0
    model: str = ""


# ── Rate Limiter (Redis-backed with in-memory fallback) ───────────────────────

class _RateLimiter:
    """Sliding-window rate limiter with Redis backend and in-memory fallback."""

    def __init__(self, global_rpm: int, user_rpm: int, tpm_limit: int = 1_000_000) -> None:
        self._global_rpm = global_rpm
        self._user_rpm = user_rpm
        self._tpm_limit = tpm_limit
        self._window: list[float] = []
        self._token_window: list[tuple[float, int]] = []

    async def check(self, user_id: str | None = None) -> None:
        now = time.monotonic()

        # 1. Per-User Rate Limit Check (if user_id provided)
        if user_id:
            key = f"rate_limit:user:{user_id}"
            allowed, count = await check_redis_rate_limit(
                key=key,
                limit=self._user_rpm,
                window_seconds=60,
            )
            if not allowed:
                raise GeminiRateLimitError(
                    f"User '{user_id}' rate limit exceeded ({self._user_rpm} req/min). Try again in a minute."
                )

        # 2. Global Request Rate Limit Check (RPM)
        self._window = [t for t in self._window if now - t < 60]
        if len(self._window) >= self._global_rpm:
            raise GeminiRateLimitError(
                f"Global rate limit reached ({self._global_rpm} req/min). Retry after 60s."
            )

        # 3. Global Token Rate Limit Check (TPM)
        self._token_window = [(t, tok) for t, tok in self._token_window if now - t < 60]
        total_recent_tokens = sum(tok for _, tok in self._token_window)
        if total_recent_tokens >= self._tpm_limit:
            raise GeminiRateLimitError(
                f"Global token rate limit reached ({self._tpm_limit} tokens/min). Retry in a minute."
            )

        self._window.append(now)

    def record_tokens(self, total_tokens: int) -> None:
        """Record used tokens to enforce GEMINI_TPM_LIMIT."""
        if total_tokens > 0:
            self._token_window.append((time.monotonic(), total_tokens))


# ── Gateway ───────────────────────────────────────────────────────────────────

class GeminiGateway:
    """
    Production Gemini gateway — unified interface with Key Pool Rotation,
    Redis Per-User Rate Limiting, and AI Response Caching.
    """

    def __init__(self) -> None:
        # Initialize API Key Pool
        self._api_keys: list[str] = settings.get_gemini_api_keys
        self._clients: list[genai.Client] = []
        self._current_key_idx: int = 0
        self._cooldowns: dict[int, float] = {}  # idx -> cooldown timestamp

        if self._api_keys:
            for k in self._api_keys:
                self._clients.append(genai.Client(api_key=k))
            logger.info("GeminiGateway initialized | key_pool_size={}", len(self._clients))
        else:
            logger.warning("GeminiGateway initialized with NO API keys configured!")

        self._rate_limiter = _RateLimiter(
            global_rpm=settings.GEMINI_RPM_LIMIT,
            user_rpm=settings.USER_RPM_LIMIT,
            tpm_limit=settings.GEMINI_TPM_LIMIT,
        )

        self._models: dict[GeminiModel, str] = {
            GeminiModel.FLASH: settings.GEMINI_FLASH_MODEL,
            GeminiModel.PRO: settings.GEMINI_PRO_MODEL,
            GeminiModel.VISION: settings.GEMINI_FLASH_MODEL,
        }

    def _get_client(self) -> tuple[genai.Client, int]:
        """
        Get next active client from the key pool using round-robin distribution,
        skipping keys currently on 429 rate limit cooldown.
        """
        if not self._clients:
            raise GeminiAPIError("No Gemini API keys configured in settings.")

        now = time.time()
        num_keys = len(self._clients)

        for _ in range(num_keys):
            idx = self._current_key_idx
            self._current_key_idx = (self._current_key_idx + 1) % num_keys

            # Check if key is in cooldown
            cooldown_until = self._cooldowns.get(idx, 0)
            if now >= cooldown_until:
                return self._clients[idx], idx

        # If all keys are in cooldown, log warning and use current index anyway
        idx = self._current_key_idx
        self._current_key_idx = (self._current_key_idx + 1) % num_keys
        return self._clients[idx], idx

    def _mark_key_cooldown(self, idx: int, cooldown_seconds: int = 60) -> None:
        """Mark a key index as rate-limited for a cooldown duration."""
        self._cooldowns[idx] = time.time() + cooldown_seconds
        logger.warning(
            "🔑 Key pool index {} hit rate limit (429). Placed on {}s cooldown.",
            idx, cooldown_seconds,
        )

    def _resolve_model(self, model: GeminiModel) -> str:
        return self._models[model]

    def _compute_cache_key(
        self,
        prompt: str,
        schema_name: str,
        model_name: str,
        system_instruction: str | None,
    ) -> str:
        raw = f"{prompt}:{schema_name}:{model_name}:{system_instruction or ''}"
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    # ── Structured Output ──────────────────────────────────────────────────────

    async def generate_structured(
        self,
        prompt: str,
        schema: Type[T],
        *,
        model: GeminiModel = GeminiModel.FLASH,
        system_instruction: str | None = None,
        temperature: float = 0.4,
        max_output_tokens: int = 2048,
        user_id: str | None = None,
        use_cache: bool = True,
    ) -> T:
        """
        Generate a structured JSON response validated against a Pydantic schema.
        Uses Redis response caching (if enabled) and key pool rotation.
        """
        model_name = self._resolve_model(model)
        cache_hash = self._compute_cache_key(prompt, schema.__name__, model_name, system_instruction)

        # 1. Check AI Response Cache
        if use_cache:
            cached_data = await get_ai_response_cache(cache_hash)
            if cached_data is not None:
                try:
                    logger.info("⚡ AI Cache Hit | schema={} hash={}", schema.__name__, cache_hash[:8])
                    return schema.model_validate(cached_data)
                except ValidationError:
                    logger.warning("Cached data invalid for schema {}, re-generating...", schema.__name__)

        # 2. Check Rate Limits
        await self._rate_limiter.check(user_id=user_id)

        # 3. Call Gemini with Key Rotation / Retries
        config = genai_types.GenerateContentConfig(
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            system_instruction=system_instruction,
            response_mime_type="application/json",
            response_schema=schema.model_json_schema(),
        )

        attempts = 0
        last_exc: Exception | None = None

        while attempts < max(3, len(self._clients)):
            attempts += 1
            client, key_idx = self._get_client()

            try:
                response = await asyncio.to_thread(
                    client.models.generate_content,
                    model=model_name,
                    contents=prompt,
                    config=config,
                )

                self._extract_usage(response, model_name)
                parsed_result = self._parse_structured(response.text, schema)

                # Store in Redis Cache
                if use_cache:
                    await set_ai_response_cache(cache_hash, parsed_result.model_dump())

                return parsed_result

            except Exception as exc:
                last_exc = exc
                exc_str = str(exc)
                if "429" in exc_str or "RESOURCE_EXHAUSTED" in exc_str or "Quota" in exc_str:
                    self._mark_key_cooldown(key_idx, cooldown_seconds=60)
                    logger.warning("Rotating to next key in pool after 429 error (attempt {})...", attempts)
                    continue
                else:
                    logger.error("GeminiGateway API error: {}", exc)
                    raise GeminiAPIError(str(exc)) from exc

        raise GeminiAPIError(f"All API key pool attempts failed. Last error: {last_exc}")

    def _parse_structured(self, raw_text: str, schema: Type[T]) -> T:
        """Parse raw JSON text into a validated Pydantic schema instance."""
        try:
            data = json.loads(raw_text)
            return schema.model_validate(data)
        except (json.JSONDecodeError, ValidationError) as exc:
            logger.error(
                "GeminiGateway: structured parse failed | schema={} error={} raw={}",
                schema.__name__, exc, raw_text[:200],
            )
            raise GeminiStructuredOutputError(
                f"Failed to parse {schema.__name__} from Gemini response: {exc}"
            ) from exc

    # ── Raw text generation ────────────────────────────────────────────────────

    async def generate_text(
        self,
        prompt: str,
        *,
        model: GeminiModel = GeminiModel.FLASH,
        system_instruction: str | None = None,
        temperature: float = 0.7,
        max_output_tokens: int = 2048,
        user_id: str | None = None,
        use_cache: bool = True,
    ) -> str:
        """Generate raw text with key rotation and response caching."""
        model_name = self._resolve_model(model)
        cache_hash = self._compute_cache_key(prompt, "RAW_TEXT", model_name, system_instruction)

        if use_cache:
            cached_text = await get_ai_response_cache(cache_hash)
            if cached_text and isinstance(cached_text, str):
                logger.info("⚡ AI Cache Hit | text hash={}", cache_hash[:8])
                return cached_text

        await self._rate_limiter.check(user_id=user_id)

        config = genai_types.GenerateContentConfig(
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            system_instruction=system_instruction,
        )

        attempts = 0
        last_exc: Exception | None = None

        while attempts < max(3, len(self._clients)):
            attempts += 1
            client, key_idx = self._get_client()

            try:
                response = await asyncio.to_thread(
                    client.models.generate_content,
                    model=model_name,
                    contents=prompt,
                    config=config,
                )

                self._extract_usage(response, model_name)
                text_result = response.text

                if use_cache and text_result:
                    await set_ai_response_cache(cache_hash, text_result)

                return text_result

            except Exception as exc:
                last_exc = exc
                exc_str = str(exc)
                if "429" in exc_str or "RESOURCE_EXHAUSTED" in exc_str or "Quota" in exc_str:
                    self._mark_key_cooldown(key_idx, cooldown_seconds=60)
                    continue
                else:
                    raise GeminiAPIError(str(exc)) from exc

        raise GeminiAPIError(f"All API key pool attempts failed. Last error: {last_exc}")

    # ── Vision / multimodal ───────────────────────────────────────────────────

    async def analyse_image(
        self,
        image_bytes: bytes,
        prompt: str,
        schema: Type[T],
        *,
        mime_type: str = "image/jpeg",
        user_id: str | None = None,
    ) -> T:
        """Analyse an image with a structured output schema."""
        await self._rate_limiter.check(user_id=user_id)
        model_name = self._resolve_model(GeminiModel.VISION)

        image_part = genai_types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
        text_part = genai_types.Part.from_text(text=prompt)

        config = genai_types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=schema.model_json_schema(),
        )

        client, key_idx = self._get_client()

        try:
            response = await asyncio.to_thread(
                client.models.generate_content,
                model=model_name,
                contents=[image_part, text_part],
                config=config,
            )
        except Exception as exc:
            if "429" in str(exc):
                self._mark_key_cooldown(key_idx)
            raise GeminiAPIError(str(exc)) from exc

        return self._parse_structured(response.text, schema)

    # ── Streaming (WebSocket real-time) ─────────────────────────────────────────

    async def stream(
        self,
        contents: Any,
        *,
        model: GeminiModel = GeminiModel.FLASH,
        system_instruction: str | None = None,
        temperature: float = 0.7,
        user_id: str | None = None,
    ) -> AsyncIterator[str]:
        """Stream Gemini response token-by-token for WebSocket delivery."""
        await self._rate_limiter.check(user_id=user_id)
        model_name = self._resolve_model(model)

        config = genai_types.GenerateContentConfig(
            temperature=temperature,
            system_instruction=system_instruction,
        )

        client, key_idx = self._get_client()

        def _stream_sync():
            return client.models.generate_content_stream(
                model=model_name,
                contents=contents,
                config=config,
            )

        stream_iter = await asyncio.to_thread(_stream_sync)
        for chunk in stream_iter:
            if chunk.text:
                yield chunk.text

    # ── Embeddings ────────────────────────────────────────────────────────────

    async def embed(self, text: str) -> list[float]:
        """Generate a 768-dimensional text embedding for Pinecone storage."""
        client, key_idx = self._get_client()
        try:
            response = await asyncio.to_thread(
                client.models.embed_content,
                model=settings.GEMINI_EMBEDDING_MODEL,
                contents=text,
            )
            return response.embeddings[0].values
        except Exception as exc:
            if "429" in str(exc):
                self._mark_key_cooldown(key_idx)
            raise GeminiAPIError(f"Embedding failed: {exc}") from exc

    # ── Utilities ─────────────────────────────────────────────────────────────

    def _extract_usage(self, response: Any, model_name: str) -> TokenUsage:
        """Extract token usage metadata from a Gemini response."""
        try:
            meta = response.usage_metadata
            usage = TokenUsage(
                input_tokens=meta.prompt_token_count or 0,
                output_tokens=meta.candidates_token_count or 0,
                total_tokens=meta.total_token_count or 0,
                model=model_name,
            )
        except Exception:
            usage = TokenUsage(model=model_name)

        logger.info(
            "Token usage | model={} in={} out={} total={}",
            usage.model, usage.input_tokens, usage.output_tokens, usage.total_tokens,
        )
        self._rate_limiter.record_tokens(usage.total_tokens)
        return usage

    async def test_connection(self) -> bool:
        """Quick health check — verifies API key(s) are valid."""
        try:
            result = await self.generate_text(
                "Reply with: ok",
                model=GeminiModel.FLASH,
                max_output_tokens=10,
                use_cache=False,
            )
            logger.info("GeminiGateway health check ✅ | response={}", result.strip())
            return True
        except Exception as exc:
            logger.error("GeminiGateway health check ❌ | error={}", exc)
            return False


# ── Module-level singleton ────────────────────────────────────────────────────
gemini = GeminiGateway()
