#!/bin/bash
set -euo pipefail

PGHOST="${PGHOST:-postgres}"
PGPORT="${PGPORT:-5432}"
PGUSER="${POSTGRES_USER:-postgres}"
PGPASSWORD="${POSTGRES_PASSWORD:?missing POSTGRES_PASSWORD}"
DB_DEV="${PG_DB_DEV:-aujourduy_dev}"
DB_TEST="${PG_DB_TEST:-aujourduy_test}"
BASE_REF="${POSTGRES_DB:-postgres}"
export PGPASSWORD

echo "[pg-ensure] Waiting for Postgres at ${PGHOST}:${PGPORT} user=${PGUSER} db=${BASE_REF}..."
until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$BASE_REF" >/dev/null 2>&1; do
  sleep 1
done
echo "[pg-ensure] Postgres is ready."

create_if_absent() {
  local db="$1"
  local exists
  exists=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$BASE_REF" -tAc "SELECT 1 FROM pg_database WHERE datname='${db}'")
  if [ "$exists" = "1" ]; then
    echo "[pg-ensure] Database '${db}' already exists."
  else
    echo "[pg-ensure] Creating database '${db}'..."
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$BASE_REF" -v ON_ERROR_STOP=1 \
      -c "CREATE DATABASE ${db} TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C.UTF-8' LC_CTYPE 'C.UTF-8';"
    echo "[pg-ensure] Created '${db}'."
  fi
}

create_if_absent "$DB_DEV"
create_if_absent "$DB_TEST"

# Donner le droit de se connecter aux rôles applicatifs
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$BASE_REF" -v ON_ERROR_STOP=1 \
  -c "GRANT CONNECT ON DATABASE ${DB_DEV}  TO app_writer, app_reader, app;"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$BASE_REF" -v ON_ERROR_STOP=1 \
  -c "GRANT CONNECT ON DATABASE ${DB_TEST} TO app_writer, app_reader, app;"

# Vérification finale des bases avant de créer le marqueur
if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB_DEV"  -tAc "SELECT 1" >/dev/null 2>&1 && \
   psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB_TEST" -tAc "SELECT 1" >/dev/null 2>&1; then

  echo "[pg-ensure] ✅ Les bases dev/test existent et sont accessibles."
  echo "[pg-ensure] Creating marker file /tmp/pg-ensure-done..."
  touch /tmp/pg-ensure-done
  ls -la /tmp/pg-ensure-done

else
  echo "[pg-ensure] ❌ ÉCHEC : Les bases dev/test ne sont pas accessibles." >&2
  exit 1
fi

echo "[pg-ensure] Done."
