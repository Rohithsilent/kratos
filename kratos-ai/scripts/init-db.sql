-- ─── KRATOS AI — PostgreSQL Initialization Script ───────────────────────────
-- Runs once on first container creation (mounted into docker-entrypoint-initdb.d).
-- ─────────────────────────────────────────────────────────────────────────────

-- Extensions used by the current relational schema. Keep this compatible with
-- Azure Database for PostgreSQL; vector storage is not part of this deployment.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";          -- Trigram index for text search
