"""
KRATOS AI — Phase 2 Live Test
Tests the GeminiGateway against the real API key.

Run:
    cd kratos-ai
    source venv/bin/activate
    python test_gemini.py
"""
import asyncio
import json
import sys
import os

# Ensure app is importable
sys.path.insert(0, os.path.dirname(__file__))

# Set env vars before importing settings
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("PINECONE_API_KEY", "dummy")
os.environ.setdefault("FIREBASE_PROJECT_ID", "dummy")

from app.ai.gateway.gemini_gateway import GeminiGateway, GeminiModel
from app.ai.schemas import (
    RecoveryOutput,
    MacroOutput,
    ChatOutput,
    ExerciseProgressionOutput,
)


async def test_connection(gw: GeminiGateway):
    print("\n" + "="*60)
    print("TEST 1 — Connection Health Check")
    print("="*60)
    ok = await gw.test_connection()
    status = "✅ PASS" if ok else "❌ FAIL"
    print(f"  Result: {status}")
    return ok


async def test_structured_recovery(gw: GeminiGateway):
    print("\n" + "="*60)
    print("TEST 2 — Structured Recovery Analysis (Flash)")
    print("="*60)

    prompt = """
    Analyse this user's recovery status and return a structured report.

    User metrics:
    - Sleep: 6.5 hours (below average)
    - Soreness level: 7/10 (legs — heavy squat session yesterday)
    - Last workout intensity: 9/10
    - HRV: 42ms (lower than baseline of 58ms)
    - Days since last rest day: 4

    Return a complete recovery assessment.
    """

    result: RecoveryOutput = await gw.generate_structured(
        prompt=prompt,
        schema=RecoveryOutput,
        model=GeminiModel.FLASH,
        temperature=0.3,
    )
    print(f"  Recovery Score : {result.recovery_score}/100")
    print(f"  Status         : {result.status}")
    print(f"  Recommendation : {result.recommendation}")
    print(f"  Training Adj.  : {result.training_adjustment}")
    print(f"  Sleep Quality  : {result.sleep_quality}")
    print(f"  Tips           : {result.tips}")
    print("  ✅ PASS — structured JSON validated")
    return result


async def test_structured_macros(gw: GeminiGateway):
    print("\n" + "="*60)
    print("TEST 3 — Macro Calculation (Flash, JSON enforced)")
    print("="*60)

    prompt = """
    Calculate precise daily macro targets for this user.

    Profile:
    - Weight: 82kg
    - Height: 178cm
    - Age: 26
    - Gender: male
    - Activity: active (trains 5x/week, strength + cardio)
    - Goal: lean bulk (muscle gain with minimal fat)

    Use Mifflin-St Jeor equation with protein-first macro split.
    """

    result: MacroOutput = await gw.generate_structured(
        prompt=prompt,
        schema=MacroOutput,
        model=GeminiModel.FLASH,
        temperature=0.2,
    )
    print(f"  Calories  : {result.calories} kcal")
    print(f"  Protein   : {result.protein_g}g")
    print(f"  Carbs     : {result.carbs_g}g")
    print(f"  Fat       : {result.fat_g}g")
    print(f"  Water     : {result.water_ml}ml")
    print(f"  Timing    : {result.meal_timing_notes}")
    print("  ✅ PASS — structured JSON validated")
    return result


async def test_chat_response(gw: GeminiGateway):
    print("\n" + "="*60)
    print("TEST 4 — Chat Response with Follow-ups (Flash)")
    print("="*60)

    prompt = """
    User question: "I've been training for 6 months and my bench press hasn't 
    improved in 3 weeks. I'm stuck at 80kg for 5 reps. What should I do?"

    Provide a helpful, actionable response with follow-up questions.
    """

    result: ChatOutput = await gw.generate_structured(
        prompt=prompt,
        schema=ChatOutput,
        model=GeminiModel.FLASH,
        temperature=0.6,
    )
    print(f"  Response       : {result.response[:100]}...")
    print(f"  Follow-ups     : {result.follow_up_questions}")
    print(f"  Action Items   : {result.action_items}")
    print("  ✅ PASS — structured JSON validated")
    return result


async def test_pro_model(gw: GeminiGateway):
    print("\n" + "="*60)
    print("TEST 5 — Deep Reasoning (Pro model)")
    print("="*60)

    prompt = """
    Analyse this athlete's progression data and return a detailed report.

    Exercise: Squat
    Last 4 weeks performance:
    - Week 1: 100kg × 5 reps
    - Week 2: 100kg × 5 reps  
    - Week 3: 102.5kg × 4 reps
    - Week 4: 102.5kg × 4 reps

    Goal: Strength (1RM improvement)
    """

    result: ExerciseProgressionOutput = await gw.generate_structured(
        prompt=prompt,
        schema=ExerciseProgressionOutput,
        model=GeminiModel.PRO,
        temperature=0.3,
    )
    print(f"  Exercise       : {result.exercise}")
    print(f"  Trend          : {result.trend}")
    print(f"  Strategy       : {result.strategy}")
    print(f"  Next Weight    : {result.recommended_weight_kg}kg × {result.recommended_reps} reps")
    print(f"  Explanation    : {result.explanation[:100]}...")
    print("  ✅ PASS — Pro model structured JSON validated")
    return result


async def main():
    print("\n🔥 KRATOS AI — Phase 2 Gemini Gateway Test Suite")
    print("   API: Gemini 2.5 Flash + Pro | JSON-enforced structured outputs")

    gw = GeminiGateway()
    results = {}

    connected = await test_connection(gw)
    if not connected:
        print("\n❌ Cannot connect to Gemini. Check API key in .env")
        sys.exit(1)

    results["recovery"] = await test_structured_recovery(gw)
    results["macros"] = await test_structured_macros(gw)
    results["chat"] = await test_chat_response(gw)
    results["progression"] = await test_pro_model(gw)

    print("\n" + "="*60)
    print("🏆 ALL TESTS PASSED — Phase 2 Complete")
    print("="*60)
    print("\nKey validation:")
    print(f"  ✅ Flash model  : {gw._models[GeminiModel.FLASH]}")
    print(f"  ✅ Pro model    : {gw._models[GeminiModel.PRO]}")
    print(f"  ✅ JSON schemas : RecoveryOutput, MacroOutput, ChatOutput, ProgressionOutput")
    print(f"  ✅ Rate limiter : {gw._rate_limiter._rpm} RPM")
    print("\nNext: Phase 3 — Wire agents into LangGraph nodes\n")


if __name__ == "__main__":
    asyncio.run(main())
