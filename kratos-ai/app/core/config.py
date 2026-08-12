from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, computed_field


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── App ──────────────────────────────────────────────────────────────────
    APP_NAME: str = "KRATOS AI"
    APP_VERSION: str = "2.0.0"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # ── PostgreSQL (AI Intelligence Database) ────────────────────────────────
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "kratos_ai"
    POSTGRES_USER: str = "kratos"
    POSTGRES_PASSWORD: str = Field(..., description="PostgreSQL password")

    # Connection pool tuning
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_ECHO: bool = False

    @computed_field  # type: ignore[prop-decorator]
    @property
    def DATABASE_URL(self) -> str:
        """Construct async PostgreSQL URL from granular env vars."""
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    # ── Redis ────────────────────────────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379/0"

    # ── Gemini AI — Gemini 2.5 models ────────────────────────────────────────
    GEMINI_API_KEY: str = Field(..., description="Google Gemini API key")

    # Fast responses (sub-second reasoning, high quota)
    GEMINI_FLASH_MODEL: str = "models/gemini-2.5-flash"

    # Deep reasoning (plan generation, complex analysis)
    GEMINI_PRO_MODEL: str = "models/gemini-2.5-pro"

    # Embeddings (vector store indexing)
    GEMINI_EMBEDDING_MODEL: str = "models/text-embedding-004"

    # ── Rate limiting ─────────────────────────────────────────────────────────
    GEMINI_RPM_LIMIT: int = 60          # requests per minute
    GEMINI_TPM_LIMIT: int = 1_000_000   # tokens per minute

    # ── Observability ────────────────────────────────────────────────────────
    SENTRY_DSN: str = ""

    # ── CORS ─────────────────────────────────────────────────────────────────
    ALLOWED_ORIGINS: list[str] = ["*"]


settings = Settings()
