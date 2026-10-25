import unittest

from app.core.config import Settings


class ProductionSettingsTests(unittest.TestCase):
    def make_settings(self, **overrides):
        values = {
            "POSTGRES_PASSWORD": "test-password",
            "ENVIRONMENT": "production",
            "POSTGRES_SSL": True,
            "GEMINI_API_KEY": "test-key",
            "ALLOWED_ORIGINS": ["https://app.example.com"],
        }
        values.update(overrides)
        return Settings(**values)

    def test_production_accepts_explicit_https_origin_and_tls(self) -> None:
        self.make_settings().validate_production_settings()

    def test_production_accepts_empty_origins_for_mobile(self) -> None:
        self.make_settings(ALLOWED_ORIGINS=[]).validate_production_settings()

    def test_production_rejects_wildcard_cors(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "ALLOWED_ORIGINS"):
            self.make_settings(ALLOWED_ORIGINS=["*"]).validate_production_settings()

    def test_production_rejects_non_https_origin(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "ALLOWED_ORIGINS"):
            self.make_settings(ALLOWED_ORIGINS=["http://insecure.example.com"]).validate_production_settings()

    def test_production_requires_tls_and_a_gemini_key(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "POSTGRES_SSL"):
            self.make_settings(POSTGRES_SSL=False).validate_production_settings()
        with self.assertRaisesRegex(RuntimeError, "GEMINI_API_KEY"):
            self.make_settings(
                GEMINI_API_KEY="",
                GEMINI_API_KEYS="",
            ).validate_production_settings()
