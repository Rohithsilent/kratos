-- ─── KRATOS AI — PostgreSQL Initialization Script ───────────────────────────
-- Runs once on first container creation (mounted into docker-entrypoint-initdb.d).
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";          -- Trigram index for text search
CREATE EXTENSION IF NOT EXISTS "vector";           -- pgvector for AI embeddings

-- Create read-only analytics role (for dashboards, Metabase, etc.)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'kratos_readonly') THEN
        CREATE ROLE kratos_readonly WITH LOGIN PASSWORD 'readonly_change_me';
    END IF;
END $$;

-- Grant read-only access on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO kratos_readonly;
