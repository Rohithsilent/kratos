"""
KRATOS AI — Database Models Package.

Imports all ORM models so that:
1. Alembic can auto-detect them for migrations.
2. Base.metadata.create_all() registers all tables.

IMPORTANT: These are AI-intelligence models ONLY.
Operational data (users, workouts, nutrition) lives in Firebase.
"""
from app.database.models.ai_insight import AIInsight           # noqa: F401
from app.database.models.ai_conversation import AIConversation # noqa: F401
from app.database.models.recovery_metric import RecoveryMetric # noqa: F401
from app.database.models.recommendation_log import RecommendationLog  # noqa: F401
from app.database.models.ai_request_log import AIRequestLog   # noqa: F401

__all__ = [
    "AIInsight",
    "AIConversation",
    "RecoveryMetric",
    "RecommendationLog",
    "AIRequestLog",
]
