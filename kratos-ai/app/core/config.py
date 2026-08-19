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
    GEMINI_API_KEY: str = Field(default="", description="Single Google Gemini API key")
    GEMINI_API_KEYS: str = Field(default="", description="Comma-separated pool of Gemini API keys")

    # Fast responses (sub-second reasoning, high quota)
    GEMINI_FLASH_MODEL: str = "models/gemini-2.5-flash"

    # Deep reasoning (plan generation, complex analysis)
    GEMINI_PRO_MODEL: str = "models/gemini-2.5-pro"

    # Embeddings (vector store indexing)
    GEMINI_EMBEDDING_MODEL: str = "models/text-embedding-004"

    @computed_field  # type: ignore[prop-decorator]
    @property
    def get_gemini_api_keys(self) -> list[str]:
        """Consolidate single and multiple GEMINI_API_KEYS into a deduplicated list."""
        keys: list[str] = []
        if self.GEMINI_API_KEYS:
            keys.extend([k.strip() for k in self.GEMINI_API_KEYS.split(",") if k.strip()])
        if self.GEMINI_API_KEY and self.GEMINI_API_KEY.strip():
            k = self.GEMINI_API_KEY.strip()
            if k not in keys:
                keys.append(k)
        return keys

    # ── Caching & Rate limiting ───────────────────────────────────────────────
    GEMINI_RPM_LIMIT: int = 60          # requests per minute global
    GEMINI_TPM_LIMIT: int = 1_000_000   # tokens per minute global
    USER_RPM_LIMIT: int = 20            # per-user requests per minute limit
    AI_CACHE_TTL_SECONDS: int = 86400   # 24 hours default AI response cache TTL

    # ── Observability ────────────────────────────────────────────────────────
    SENTRY_DSN: str = ""

    # ── CORS ─────────────────────────────────────────────────────────────────
    ALLOWED_ORIGINS: list[str] = ["*"]


settings = Settings()
