"""
WebSocket Nutrition Handler — real-time AI nutrition intelligence for KRATOS.

Flow:
    Flutter → WS connect → send intake/targets data
    → receive streaming AI insights token by token
    → proactive coaching after meal logging
"""
from __future__ import annotations

import json
from loguru import logger
from fastapi import WebSocket, WebSocketDisconnect

from app.ai.gateway.gemini_gateway import gemini, GeminiModel
from google.genai import types as genai_types
from app.database.postgres import AsyncSessionLocal
from app.database.models.ai_insight import AIInsight
from app.cache.redis_client import cache_get, cache_set
import time


def _nutrition_insight_key(user_id: str, date: str) -> str:
    return f"kratos:nutrition_insight:{user_id}:{date}"


async def nutrition_socket_handler(user_id: str, websocket: WebSocket) -> None:
    """
    Main WebSocket handler for nutrition intelligence streaming.

    Supported message types from client:
    - analyze: Generate AI coach insight based on current intake/targets
    - fit_check: Pre-log impact assessment for a scanned food item
    - meal_logged: Proactive insight after a meal is logged
    """
    await websocket.accept()
    logger.info("Nutrition WS connected | user={}", user_id)

    try:
        while True:
            raw = await websocket.receive_text()
            payload = json.loads(raw)
            msg_type = payload.get("type", "")

            if msg_type == "analyze":
                await _handle_analyze(user_id, websocket, payload)
            elif msg_type == "fit_check":
                await _handle_fit_check(user_id, websocket, payload)
            elif msg_type == "meal_logged":
                await _handle_meal_logged(user_id, websocket, payload)
            else:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "content": f"Unknown message type: {msg_type}",
                }))

    except WebSocketDisconnect:
        logger.info("Nutrition WS disconnected | user={}", user_id)
    except Exception as exc:
        logger.exception("Nutrition WS error | user={} error={}", user_id, exc)


async def _handle_analyze(user_id: str, websocket: WebSocket, payload: dict) -> None:
    """Stream an AI nutrition coaching insight based on current intake vs targets."""
    intake = payload.get("intake", {})
    targets = payload.get("targets", {})
    today = payload.get("date", "")

    # Check Redis cache first
    cache_key = _nutrition_insight_key(user_id, today)
    cached = await cache_get(cache_key)
    if cached and not payload.get("force_refresh", False):
        await websocket.send_text(json.dumps({
            "type": "cached_insight",
            "content": cached,
        }))
        return

    system_instruction = (
        "You are KRATOS, an elite AI nutrition coach embedded in a fitness app. "
        "Be concise, punchy, and motivational. Use short sentences. "
        "Never use bullet points or markdown formatting. "
        "Speak like a personal trainer who genuinely cares."
    )

    prompt = (
        f"My daily nutrition targets are: {json.dumps(targets)}. "
        f"So far today I have consumed: {json.dumps(intake)}. "
        "Give me a short insight (2-3 sentences) on how I'm doing today, "
        "then one very specific, actionable piece of advice for my next meal. "
        "End with a short motivational line."
    )

    contents = [genai_types.Content(
        role="user",
        parts=[genai_types.Part.from_text(text=prompt)]
    )]

    start_time = time.time()
    await websocket.send_text(json.dumps({"type": "stream_start"}))

    full_response = ""
    try:
        async for chunk in gemini.stream(
            contents=contents,
            model=GeminiModel.FLASH,
            system_instruction=system_instruction,
        ):
            full_response += chunk
            await websocket.send_text(json.dumps({
                "type": "stream_chunk",
                "content": chunk,
            }))
    except Exception as e:
        logger.error("Nutrition Gemini stream error: {}", e)
        error_msg = "\n[Connection interrupted. Please try again.]"
        full_response += error_msg
        await websocket.send_text(json.dumps({
            "type": "stream_chunk",
            "content": error_msg,
        }))

    await websocket.send_text(json.dumps({"type": "stream_end"}))

    # Cache and persist
    if full_response.strip():
        latency = (time.time() - start_time) * 1000

        # Cache in Redis (2 hour TTL)
        await cache_set(cache_key, full_response, ttl_seconds=7200)

        # Save to PostgreSQL
        try:
            async with AsyncSessionLocal() as session:
                insight = AIInsight(
                    firebase_uid=user_id,
                    category="nutrition",
                    title="AI Coach Insight",
                    content=full_response,
                    priority="medium",
                    model_used="gemini-3.6-flash",
                    source_data={"intake": intake, "targets": targets},
                    tags=["nutrition", "daily_coach", "streaming"],
                )
                session.add(insight)
                await session.commit()
        except Exception as e:
            logger.error("Failed to persist nutrition insight: {}", e)


async def _handle_fit_check(user_id: str, websocket: WebSocket, payload: dict) -> None:
    """Calculate pre-log impact assessment locally (fast, no AI needed)."""
    scanned_food = payload.get("food", {})
    current_intake = payload.get("intake", {})
    targets = payload.get("targets", {})

    # Calculate projected totals
    projected = {
        "calories": current_intake.get("calories", 0) + scanned_food.get("calories", 0),
        "protein_g": current_intake.get("protein_g", 0) + scanned_food.get("protein", 0),
        "carbs_g": current_intake.get("carbs_g", 0) + scanned_food.get("carbs", 0),
        "fats_g": current_intake.get("fats_g", 0) + scanned_food.get("fats", 0),
    }

    # Calculate percentages
    cal_pct = round((projected["calories"] / max(1, targets.get("calories", 2200))) * 100)
    pro_pct = round((projected["protein_g"] / max(1, targets.get("protein_g", 150))) * 100)
    carb_pct = round((projected["carbs_g"] / max(1, targets.get("carbs_g", 250))) * 100)
    fat_pct = round((projected["fats_g"] / max(1, targets.get("fats_g", 70))) * 100)

    # Generate warnings
    warnings = []
    if cal_pct > 100:
        warnings.append(f"⚠️ This will put you {cal_pct - 100}% over your calorie target.")
    if fat_pct > 100:
        warnings.append(f"⚠️ You'll exceed your fat limit by {projected['fats_g'] - targets.get('fats_g', 70)}g.")

    # Generate verdict
    if not warnings:
        if cal_pct >= 85:
            verdict = "Almost at your target. This fits perfectly."
        else:
            verdict = "Looks good! You have room for more."
    else:
        verdict = "Consider a lighter option."

    await websocket.send_text(json.dumps({
        "type": "fit_check_result",
        "projected": projected,
        "percentages": {
            "calories": cal_pct,
            "protein": pro_pct,
            "carbs": carb_pct,
            "fats": fat_pct,
        },
        "warnings": warnings,
        "verdict": verdict,
    }))


async def _handle_meal_logged(user_id: str, websocket: WebSocket, payload: dict) -> None:
    """Stream a proactive insight immediately after a meal is logged."""
    food_name = payload.get("food_name", "your meal")
    intake = payload.get("intake", {})
    targets = payload.get("targets", {})

    system_instruction = (
        "You are KRATOS, an elite AI nutrition coach. "
        "Be encouraging, concise, and specific. No bullet points or markdown. "
        "Speak like a personal trainer celebrating progress."
    )

    prompt = (
        f"I just logged '{food_name}' to my nutrition tracker. "
        f"My updated daily intake is now: {json.dumps(intake)}. "
        f"My daily targets are: {json.dumps(targets)}. "
        "Give me a one-sentence reaction to this meal, "
        "then a quick tip for my next meal to stay on track. Keep it very short."
    )

    contents = [genai_types.Content(
        role="user",
        parts=[genai_types.Part.from_text(text=prompt)]
    )]

    await websocket.send_text(json.dumps({"type": "stream_start"}))

    full_response = ""
    try:
        async for chunk in gemini.stream(
            contents=contents,
            model=GeminiModel.FLASH,
            system_instruction=system_instruction,
        ):
            full_response += chunk
            await websocket.send_text(json.dumps({
                "type": "stream_chunk",
                "content": chunk,
            }))
    except Exception as e:
        logger.error("Nutrition meal_logged stream error: {}", e)

    await websocket.send_text(json.dumps({"type": "stream_end"}))

    # Update Redis cache with the new insight
    today = payload.get("date", "")
    if today and full_response.strip():
        cache_key = _nutrition_insight_key(user_id, today)
        await cache_set(cache_key, full_response, ttl_seconds=7200)
