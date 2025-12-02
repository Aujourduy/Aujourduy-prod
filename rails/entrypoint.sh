#!/bin/bash

set -e

echo "🔧 [Rails] Vérification de la configuration (ENV: ${RAILS_ENV})..."

# Déterminer quelle base de données utiliser selon l'environnement
if [ "$RAILS_ENV" = "production" ]; then
    DB_NAME="${PG_DB_PROD}"
    echo "📌 Mode PRODUCTION - Base: ${DB_NAME}"
else
    DB_NAME="${PG_DB_DEV}"
    echo "📌 Mode DEVELOPMENT - Base: ${DB_NAME}"
fi

# Vérifier que les variables d'environnement sont définies
if [ -z "$DB_NAME" ] || [ -z "$APP_DATABASE_USER" ] || [ -z "$APP_DATABASE_PASSWORD" ]; then
    echo "❌ Variables d'environnement manquantes !"
    echo "DB_NAME: ${DB_NAME:-'NON DÉFINIE'}"
    echo "APP_DATABASE_USER: ${APP_DATABASE_USER:-'NON DÉFINIE'}"
    echo "APP_DATABASE_PASSWORD: ${APP_DATABASE_PASSWORD:-'[MASQUÉ]'}"
    exit 1
fi

echo "📦 [Rails] Vérification des gems..."
if ! bundle check >/dev/null 2>&1; then
    echo "📦 Installation des gems manquantes..."
    bundle install
fi

echo "🧹 [Rails] Nettoyage des fichiers PID..."
rm -f /app/tmp/pids/server.pid

echo "🗄️ [Rails] Vérification de la base de données..."

# Attendre que la base de données soit prête
echo "⏳ Attente de la disponibilité de la base de données..."
max_attempts=30
attempt=0
until bin/rails runner "ActiveRecord::Base.connection" >/dev/null 2>&1 || [ $attempt -eq $max_attempts ]; do
    attempt=$((attempt + 1))
    echo "⏳ Tentative $attempt/$max_attempts..."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Impossible de se connecter à la base de données après $max_attempts tentatives"
    exit 1
fi

echo "✅ Connexion à la base de données établie"

# Créer la base si elle n'existe pas (uniquement en dev)
if [ "$RAILS_ENV" != "production" ]; then
    bin/rails db:create || true
fi

# Exécuter les migrations
echo "🗄️ Exécution des migrations..."
bin/rails db:migrate

# Seeds uniquement en dev
if [ "$RAILS_ENV" != "production" ] && [ -f "db/seeds.rb" ]; then
    echo "🌱 Chargement des données de seed..."
    bin/rails db:seed
fi

# Précompiler les assets en production
if [ "$RAILS_ENV" = "production" ]; then
    echo "🎨 Précompilation des assets..."
    bin/rails assets:precompile
fi

echo "🚀 [Rails] Démarrage du serveur..."
exec bin/rails server -b 0.0.0.0 -p 3000