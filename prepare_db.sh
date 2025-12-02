#!/bin/bash
set -euo pipefail
echo "🛠  Préparation des fichiers de base de données..."

# Vérifier que .env existe
if [ ! -f ".env" ]; then
  echo "❌ Fichier .env introuvable." >&2
  exit 1
fi

# Charger les variables
set -a
source .env
set +a

# Créer le répertoire de sortie s'il n'existe pas
mkdir -p ./postgres/init/generated

# Générer init_01.sql
echo "📁 Génération de init_01.sql..."
envsubst < ./postgres/init/init_01.sql.tpl > ./postgres/init/generated/init_01.sql

# Générer userlist.txt depuis le template
echo "📁 Génération de userlist.txt..."
envsubst < ./postgres/init/userlist.txt.tpl > ./postgres/init/generated/userlist.txt

echo "✅ Fichiers générés dans ./postgres/init/generated/"
echo "   - init_01.sql"
echo "   - userlist.txt"