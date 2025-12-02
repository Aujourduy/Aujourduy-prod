#!/bin/bash
set -euo pipefail

# Ce script est exécuté automatiquement par Postgres
# lors de l'initialisation si /var/lib/postgresql/data est vide.

echo "📦 Initialisation des rôles applicatifs (app_writer, app_reader)..."

psql -v ON_ERROR_STOP=1 \
    -v APP_WRITER_PASSWORD="${APP_WRITER_PASSWORD:-}" \
    -v APP_READER_PASSWORD="${APP_READER_PASSWORD:-}" \
    --username "${POSTGRES_USER}" \
    --dbname   postgres <<'EOSQL'


-- Créer app_writer si inexistant
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_writer') THEN
    CREATE ROLE app_writer WITH LOGIN PASSWORD :'APP_WRITER_PASSWORD';
  END IF;
END
$$;

-- Créer app_reader si inexistant
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_reader') THEN
    CREATE ROLE app_reader WITH LOGIN PASSWORD :'APP_READER_PASSWORD';
  END IF;
END
$$;

-- Autoriser leur connexion à la base
GRANT CONNECT ON DATABASE :DBNAME TO app_writer, app_reader;

-- Droits par défaut (s'appliquent aux objets futurs du schéma public)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO app_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_writer;

EOSQL

echo "✅ Rôles applicatifs initialisés avec succès."
