"""KRATOS AI — Production FastAPI application with full AI stack wired in."""
from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import FastAPI, WebSocket, Depends
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.logging import setup_logging

# Routers
from app.api.chat import router as chat_router
from app.api.recovery import router as recovery_router
from app.api.planner import router as planner_router
from app.api.nutrition import router as nutrition_router

# WebSocket handler
from app.websocket.chat_socket import chat_socket_handler

# DB + Cache
from app.database.postgres import init_db, close_db
from app.database.session import get_db
from app.cache.redis_client import get_redis, close_redis


# ── Sentry (optional — only if DSN provided) ──────────────────────────────────
if hasattr(settings, "SENTRY_DSN") and settings.SENTRY_DSN:
    sentry_sdk.init(dsn=settings.SENTRY_DSN, traces_sample_rate=0.2)
    logger.info("Sentry initialised")


# ── Lifespan ──────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging(debug=settings.DEBUG)
    logger.info("🚀 {} v{} starting …", settings.APP_NAME, settings.APP_VERSION)

    # Startup
    await get_redis()
    logger.info("✅ Redis ready")

    # DB init — verify connectivity (tables managed by Alembic)
    try:
        await init_db()
        logger.info("✅ PostgreSQL ready ({}:{})", settings.POSTGRES_HOST, settings.POSTGRES_PORT)
    except Exception as exc:
        logger.warning("⚠️  DB init skipped (not configured?): {}", exc)

    logger.info("🔥 KRATOS AI — ALL SYSTEMS GO")
    yield

    # Shutdown
    await close_redis()
    await close_db()
    logger.info("🛑 KRATOS AI shut down cleanly")


# ── App factory ───────────────────────────────────────────────────────────────
def create_application() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description=(
            "AI-native fitness intelligence backend for KRATOS. "
            "Powered by Gemini, LangGraph, Pinecone & PostgreSQL."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # ── CORS ─────────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── REST routers ─────────────────────────────────────────────────────────
    PREFIX = settings.API_V1_PREFIX
    app.include_router(chat_router, prefix=PREFIX)
    app.include_router(recovery_router, prefix=PREFIX)
    app.include_router(planner_router, prefix=PREFIX)
    app.include_router(nutrition_router, prefix=PREFIX)

    # ── WebSocket ─────────────────────────────────────────────────────────────
    @app.websocket("/ws/chat/{user_id}")
    async def ws_chat(user_id: str, websocket: WebSocket):
        """Real-time AI chat stream for Flutter clients."""
        await chat_socket_handler(user_id, websocket)

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
            checks["postgres"] = f"unhealthy: {exc}"

        # Redis check
        try:
            redis = await get_redis()
            await redis.ping()
            checks["redis"] = "healthy"
        except Exception as exc:
            checks["redis"] = f"unhealthy: {exc}"

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
