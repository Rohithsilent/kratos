import unittest
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException

from app.agents.assistant_agent import AssistantAgent
from app.agents.nutrition_agent import NutritionAgent
from app.ai.schemas import ChatOutput, MealPlanOutput
from app.api.chat import ChatRequest, send_message
from app.api.nutrition import MealPlanRequest, MacroTargetsResponse, generate_meal_plan
from app.core.security import AuthenticatedUser


class FakeGateway:
    def __init__(self, response) -> None:
        self.response = response
        self.calls: list[dict] = []

    async def generate_structured(self, **kwargs):
        self.calls.append(kwargs)
        return self.response


class CompletedEndpointTests(unittest.IsolatedAsyncioTestCase):
    async def test_assistant_agent_returns_a_structured_chat_response(self) -> None:
        response = ChatOutput(response="Try three full-body sessions this week.")
        gateway = FakeGateway(response)

        result = await AssistantAgent(gateway).run("user-1", "How should I train?")

        self.assertEqual(result.response, response.response)
        self.assertEqual(gateway.calls[0]["user_id"], "user-1")

    async def test_assistant_agent_bounds_optional_context(self) -> None:
        gateway = FakeGateway(ChatOutput(response="A concise answer."))

        await AssistantAgent(gateway).run(
            "user-1",
            "Hello",
            context={"notes": "x" * 10_000},
        )

        self.assertLessEqual(
            len(gateway.calls[0]["prompt"]),
            len("User message: Hello\nOptional fitness context: \n") + 2_000
            + len("\nGive practical, concise fitness or nutrition guidance. Do not diagnose medical conditions or recommend dangerous substances."),
        )

    async def test_meal_plan_agent_returns_a_structured_plan(self) -> None:
        response = MealPlanOutput(
            total_calories=2200,
            meals=[],
            pre_workout_meal="Banana and yogurt",
            post_workout_meal="Rice and chicken",
        )
        gateway = FakeGateway(response)

        result = await NutritionAgent(gateway).generate_meal_plan(
            macros={"calories": 2200},
            dietary_restrictions=[],
            meals_per_day=3,
            user_id="user-1",
        )

        self.assertEqual(result["total_calories"], 2200)
        self.assertEqual(gateway.calls[0]["max_output_tokens"], 1_024)

    async def test_rest_chat_rejects_a_mismatched_user_id(self) -> None:
        request = ChatRequest(user_id="user-2", message="Hello")

        with self.assertRaises(HTTPException) as context:
            await send_message(request, AuthenticatedUser("user-1"))

        self.assertEqual(context.exception.status_code, 403)

    async def test_meal_plan_endpoint_uses_the_nutrition_agent(self) -> None:
        request = MealPlanRequest(
            macros=MacroTargetsResponse(
                calories=2200,
                protein_g=150,
                carbs_g=250,
                fat_g=70,
            ),
        )
        expected = {"total_calories": 2200, "meals": []}

        with patch(
            "app.api.nutrition.NutritionAgent.generate_meal_plan",
            AsyncMock(return_value=expected),
        ):
            result = await generate_meal_plan(request, AuthenticatedUser("user-1"))

        self.assertEqual(result, expected)
