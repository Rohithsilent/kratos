import sys
from loguru import logger


def setup_logging(debug: bool = False) -> None:
    """Configure structured logging with Loguru."""
    logger.remove()

    level = "DEBUG" if debug else "INFO"

    logger.add(
        sys.stdout,
        level=level,
        format=(
            "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | "
            "<level>{level: <8}</level> | "
            "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - "
            "<level>{message}</level>"
        ),
        colorize=True,
    )

    logger.add(
        "logs/kratos-ai.log",
        level="INFO",
        rotation="10 MB",
        retention="14 days",
        compression="gz",
        serialize=True,  # JSON format for log aggregation
    )

    logger.info("🔥 KRATOS AI logging initialised — level={}", level)
