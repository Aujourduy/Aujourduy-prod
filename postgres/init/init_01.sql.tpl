-- Le rôle admin_dba est déjà créé automatiquement par POSTGRES_USER
-- Création des autres rôles uniquement
CREATE ROLE ${PG_WRITER_USER} WITH LOGIN PASSWORD '${PG_WRITER_PASSWORD}';
CREATE ROLE ${PG_READER_USER} WITH LOGIN PASSWORD '${PG_READER_PASSWORD}';
CREATE ROLE ${APP_DATABASE_USER} WITH LOGIN PASSWORD '${APP_DATABASE_PASSWORD}';

-- Attribution des droits de connexion
GRANT CONNECT ON DATABASE ${PG_DB_PROD} TO ${PG_WRITER_USER}, ${PG_READER_USER}, ${APP_DATABASE_USER};

-- Connexion à la base de production
\connect ${PG_DB_PROD}

-- Attribution des privilèges par défaut sur les futures tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ${PG_READER_USER}, ${APP_DATABASE_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${PG_WRITER_USER}, ${APP_DATABASE_USER};

-- S'assurer que les rôles peuvent utiliser le schéma public
GRANT USAGE ON SCHEMA public TO ${PG_WRITER_USER}, ${PG_READER_USER}, ${APP_DATABASE_USER};