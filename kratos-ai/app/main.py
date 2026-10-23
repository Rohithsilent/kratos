"""KRATOS AI — Production FastAPI application with full AI stack wired in."""
from contextlib import asynccontextmanager
import uuid

from fastapi import FastAPI, Request, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from loguru import logger
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.logging import setup_logging

from app.api.chat import router as chat_router
from app.api.nutrition import router as nutrition_router
from app.api.v1.routes.meals import router as meals_router

# WebSocket handler
from app.websocket.chat_socket import chat_socket_handler
from app.websocket.nutrition_socket import nutrition_socket_handler

# DB + Cache
from app.database.postgres import init_db, close_db
from app.database.session import get_db
from app.cache.redis_client import get_redis, close_redis


# ── Sentry (optional — only if DSN provided) ──────────────────────────────────
if hasattr(settings, "SENTRY_DSN") and settings.SENTRY_DSN:
    try:
        import sentry_sdk
        sentry_sdk.init(dsn=settings.SENTRY_DSN, traces_sample_rate=0.2)
    except ImportError:
        logger.warning("SENTRY_DSN configured but 'sentry_sdk' is not installed.")
    logger.info("Sentry initialised")


# ── Lifespan ──────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging(debug=settings.DEBUG)
    logger.info("🚀 {} v{} starting …", settings.APP_NAME, settings.APP_VERSION)

    # Startup
    try:
        await get_redis()
        logger.info("✅ Redis ready")
    except Exception as exc:
        logger.warning("⚠️  Redis init skipped (not configured?): {}", exc)

    # DB init — verify connectivity (tables managed by Alembic)
    try:
        await init_db()
        logger.info("✅ PostgreSQL ready ({}:{})", settings.POSTGRES_HOST, settings.POSTGRES_PORT)
    except Exception as exc:
        logger.warning("⚠️  DB init skipped (not configured?): {}", exc)

    logger.info("🔥 KRATOS AI — ALL SYSTEMS GO")
    yield

    # Shutdown
    try:
        await close_redis()
    except Exception:
        pass
    try:
        await close_db()
    except Exception:
        pass
    logger.info("🛑 KRATOS AI shut down cleanly")


# ── App factory ───────────────────────────────────────────────────────────────
def create_application() -> FastAPI:
    # Disable interactive docs in production to reduce attack surface
    _docs_url = "/docs" if settings.DEBUG else None
    _redoc_url = "/redoc" if settings.DEBUG else None

    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description=(
            "AI-native fitness intelligence backend for KRATOS. "
            "Powered by Gemini, LangGraph, Pinecone & PostgreSQL."
        ),
        docs_url=_docs_url,
        redoc_url=_redoc_url,
        lifespan=lifespan,
    )

    # ── CORS ─────────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        # credentials=True is only safe when origins are explicit (not "*")
        allow_credentials=settings.ALLOWED_ORIGINS != ["*"],
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
    )

    # ── Request ID middleware ─────────────────────────────────────────────────
    @app.middleware("http")
    async def add_request_id(request: Request, call_next):
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

    # ── Global exception handler ──────────────────────────────────────────────
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.exception("Unhandled exception | path={} error={}", request.url.path, exc)
        return JSONResponse(
            status_code=500,
            content={"detail": "An internal server error occurred. Please try again."},
        )

    # ── REST routers ─────────────────────────────────────────────────────────
    PREFIX = settings.API_V1_PREFIX
    app.include_router(chat_router, prefix=PREFIX)
    app.include_router(nutrition_router, prefix=PREFIX)
    app.include_router(meals_router, prefix=PREFIX)

    # ── WebSocket ─────────────────────────────────────────────────────────────
    @app.websocket("/ws/chat/{user_id}")
    async def ws_chat(user_id: str, websocket: WebSocket):
        """Real-time AI chat stream for Flutter clients."""
        await chat_socket_handler(user_id, websocket)

    @app.websocket("/ws/nutrition/{user_id}")
    async def ws_nutrition(user_id: str, websocket: WebSocket):
        """Real-time AI nutrition intelligence stream for Flutter clients."""
        await nutrition_socket_handler(user_id, websocket)

    # ── Health — deep check with DB ping ──────────────────────────────────────
    @app.get("/health", tags=["System"])
    async def health():
        """
        Health check endpoint.

        Returns basic health without DB check for speed.
        Use /health/deep for full infrastructure check.
        """
        return {
            "status": "healthy",
            "app": settings.APP_NAME,
            "version": settings.APP_VERSION,
        }

    @app.get("/health/deep", tags=["System"])
    async def health_deep():
        """Deep health check — verifies PostgreSQL and Redis connectivity."""
        checks = {"app": settings.APP_NAME, "version": settings.APP_VERSION}

        # PostgreSQL check
        try:
            from app.database.postgres import AsyncSessionLocal
            async with AsyncSessionLocal() as session:
                result = await session.execute(text("SELECT 1"))
                result.scalar_one()
            checks["postgres"] = "healthy"
        except Exception as exc:
            logger.error("Health check DB error: {}", exc)
            checks["postgres"] = "unhealthy"  # Never expose raw exc to callers

        # Redis check
        try:
            redis = await get_redis()
            await redis.ping()
            checks["redis"] = "healthy"
        except Exception as exc:
            logger.error("Health check Redis error: {}", exc)
            checks["redis"] = "unhealthy"  # Never expose raw exc to callers

        all_healthy = all(
            v == "healthy" for k, v in checks.items() if k not in ("app", "version")
        )
        checks["status"] = "healthy" if all_healthy else "degraded"
        return checks

    @app.get("/", tags=["System"])
    async def root():
        return {"message": f"KRATOS AI v{settings.APP_VERSION} — see /docs"}

    return app


app = create_application()
