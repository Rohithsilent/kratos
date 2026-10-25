#!/usr/bin/env sh
set -eu

# A single Container Apps replica is used for the low-cost deployment. Applying
# already-applied Alembic migrations is a no-op, so this keeps schema and image
# versions in sync during every release without baking credentials into the image.
if [ "${RUN_MIGRATIONS_ON_START:-false}" = "true" ]; then
  echo "Applying Alembic migrations..."
  alembic upgrade head
fi

exec uvicorn app.main:app \
  --host 0.0.0.0 \
  --port "${PORT:-8000}" \
  --workers 1 \
  --loop uvloop \
  --access-log
