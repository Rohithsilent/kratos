#!/bin/bash
# ─── KRATOS AI — Database Setup Script ───────────────────────────────────────
# Run this script to initialize your production-grade PostgreSQL AI database.
# ─────────────────────────────────────────────────────────────────────────────

set -e

echo "🚀 KRATOS AI — Database Initialization"
echo "----------------------------------------"

# 1. Start the Docker/Podman Compose services
echo "1️⃣  Starting PostgreSQL and Redis via Podman Compose..."
podman-compose up -d postgres redis

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

# 2. Setup Alembic Migrations
echo "2️⃣  Running Alembic autogenerate to create initial migration..."
source venv/bin/activate 2>/dev/null || echo "⚠️  Make sure you are in your virtual environment."

alembic revision --autogenerate -m "initial_ai_models"

# 3. Apply Migrations
echo "3️⃣  Applying migrations to the database..."
alembic upgrade head

echo "✅ Database setup complete!"
echo ""
echo "💡 Useful Commands:"
echo "  podman-compose logs -f postgres    # View DB logs"
echo "  alembic history                    # View migration history"
echo "  podman exec -it kratos-postgres psql -U kratos -d kratos_ai  # Access DB shell"
