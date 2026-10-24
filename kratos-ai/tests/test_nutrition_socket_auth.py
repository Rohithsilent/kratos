import json
import unittest
from unittest.mock import AsyncMock, patch

from app.core.security import AuthenticatedUser
from app.websocket.nutrition_socket import nutrition_socket_handler


class StubWebSocket:
    def __init__(self) -> None:
        self.sent: list[dict] = []
        self.close_code: int | None = None

    async def accept(self) -> None:
        pass

    async def send_text(self, payload: str) -> None:
        self.sent.append(json.loads(payload))

    async def close(self, code: int) -> None:
        self.close_code = code


class NutritionSocketAuthenticationTests(unittest.IsolatedAsyncioTestCase):
    async def test_rejects_a_missing_or_invalid_token(self) -> None:
        websocket = StubWebSocket()

        with patch(
            "app.websocket.nutrition_socket.verify_websocket_token",
            AsyncMock(return_value=None),
        ):
            await nutrition_socket_handler("user-a", websocket)

        self.assertEqual(websocket.close_code, 4001)
        self.assertEqual(websocket.sent[0]["type"], "error")

    async def test_rejects_a_token_for_another_user(self) -> None:
        websocket = StubWebSocket()

        with patch(
            "app.websocket.nutrition_socket.verify_websocket_token",
            AsyncMock(return_value=AuthenticatedUser("user-b")),
        ):
            await nutrition_socket_handler("user-a", websocket)

        self.assertEqual(websocket.close_code, 4003)
        self.assertEqual(websocket.sent[0]["type"], "error")
