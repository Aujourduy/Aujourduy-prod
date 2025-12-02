#!/bin/bash
set -e

echo "🛠  [generate_init.sh] Lancement de la génération des fichiers init"

required_vars=(
  PG_ADMIN_USER PG_ADMIN_PASSWORD
  PG_WRITER_USER PG_WRITER_PASSWORD
  PG_READER_USER PG_READER_PASSWORD
  PG_DB_PROD
)
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Variable obligatoire manquante : $var" >&2
    exit 1
  fi
done

echo "📁 Template d'entrée : /tpl/init_01.sql.tpl"
echo "📁 Fichier de sortie : /out/init_01.sql"

echo "🔍 Variables visibles dans ce conteneur :"
echo "  PG_ADMIN_USER=${PG_ADMIN_USER}"
echo "  PG_ADMIN_PASSWORD=*** HIDDEN ***"
echo "  PG_WRITER_USER=${PG_WRITER_USER}"
echo "  PG_WRITER_PASSWORD=*** HIDDEN ***"
echo "  PG_READER_USER=${PG_READER_USER}"
echo "  PG_READER_PASSWORD=*** HIDDEN ***"
echo "  PG_DB_PROD=${PG_DB_PROD}"

echo "📦 Installation de envsubst (gettext)..."
apk add --no-cache gettext > /dev/null

echo "🔁 Génération de init_01.sql..."
envsubst < /tpl/init_01.sql.tpl > /out/init_01.sql

echo "✅ Fichier SQL généré :"
cat /out/init_01.sql

echo "🔁 Génération de userlist.txt pour PgBouncer..."
printf '"%s" "%s"\n' "$PG_ADMIN_USER" "$PG_ADMIN_PASSWORD" > /out/userlist.txt
printf '"%s" "%s"\n' "$PG_WRITER_USER" "$PG_WRITER_PASSWORD" >> /out/userlist.txt
printf '"%s" "%s"\n' "$PG_READER_USER" "$PG_READER_PASSWORD" >> /out/userlist.txt

echo "✅ Fichier userlist.txt généré :"
cat /out/userlist.txt

echo "🎉 [generate_init.sh] Terminé avec succès."
