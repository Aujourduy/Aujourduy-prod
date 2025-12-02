#!/bin/bash
# Script de copie base de données DEV → PROD
# Usage: ./db-dev-to-prod.sh

set -e  # Arrêt en cas d'erreur

echo "🔄 Copie base de données DEV → PROD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Chemins
DEV_DIR="/home/dang/Aujourduy"
PROD_DIR="/home/dang/Aujourduy-prod"
DUMP_FILE="/tmp/aujourduy_dev_dump_$(date +%Y%m%d_%H%M%S).sql"

# Credentials DEV (from Aujourduy/.env)
DEV_USER="admin_dba"
DEV_PASSWORD="S1sWT6nahWfuWaytvCAtt6bQVnZGwmvayBPg0DJZ"
DEV_DB="aujourduy_dev"

# Credentials PROD (from Aujourduy-prod/.env)
PROD_USER="admin_dba_prod"
PROD_PASSWORD=$(grep "^PG_ADMIN_PASSWORD=" "$PROD_DIR/.env" | cut -d'=' -f2)
PROD_DB="aujourduy_production"

echo "📊 Stats AVANT copie:"
echo "---"
cd "$DEV_DIR"
docker compose exec -T rails rails runner "puts 'DEV  - Users: ' + User.count.to_s + ', Events: ' + Event.count.to_s + ', Teachers: ' + Teacher.count.to_s" 2>/dev/null || echo "DEV inaccessible"

cd "$PROD_DIR"
docker compose exec -T rails-prod rails runner "puts 'PROD - Users: ' + User.count.to_s + ', Events: ' + Event.count.to_s + ', Teachers: ' + Teacher.count.to_s" 2>/dev/null || echo "PROD inaccessible"
echo ""

echo "⚠️  Cette opération va ÉCRASER toutes les données PROD"
read -p "Continuer ? (oui/non) : " CONFIRM

if [ "$CONFIRM" != "oui" ]; then
    echo "❌ Opération annulée"
    exit 1
fi

echo ""
echo "1️⃣  Dump de la base DEV..."
cd "$DEV_DIR"
docker compose exec -T -e PGPASSWORD="$DEV_PASSWORD" postgres \
    pg_dump -U "$DEV_USER" -d "$DEV_DB" --clean --if-exists > "$DUMP_FILE"

LINES=$(wc -l < "$DUMP_FILE")
echo "✅ Dump créé: $DUMP_FILE ($LINES lignes)"

echo ""
echo "2️⃣  Restauration dans PROD..."
cd "$PROD_DIR"
cat "$DUMP_FILE" | docker compose exec -T postgres-prod \
    psql -U "$PROD_USER" -d "$PROD_DB" > /dev/null 2>&1

echo "✅ Données restaurées"

echo ""
echo "3️⃣  Vérification..."
docker compose exec -T rails-prod rails runner "puts 'PROD - Users: ' + User.count.to_s + ', Events: ' + Event.count.to_s + ', Teachers: ' + Teacher.count.to_s" 2>/dev/null

echo ""
echo "4️⃣  Nettoyage..."
rm -f "$DUMP_FILE"
echo "✅ Dump temporaire supprimé"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Copie DEV → PROD terminée avec succès !"
echo ""
