# 🔄 Copie Base de Données DEV → PROD

## Utilisation

### Option 1 : Alias (recommandé)

Depuis n'importe quel dossier :

```bash
db-dev-prod
```

**Note :** L'alias sera disponible après avoir rechargé le shell (`source ~/.bashrc` ou ouvrir un nouveau terminal)

### Option 2 : Script direct

```bash
/home/dang/Aujourduy-prod/db-dev-to-prod.sh
```

Ou depuis le dossier PROD :

```bash
cd /home/dang/Aujourduy-prod
./db-dev-to-prod.sh
```

## Fonctionnement

Le script effectue les étapes suivantes :

1. **Affiche les statistiques actuelles** (DEV et PROD)
2. **Demande confirmation** (tapez `oui` pour continuer)
3. **Dump de la base DEV** → fichier temporaire avec timestamp
4. **Restauration dans PROD** via psql
5. **Vérification** des données copiées
6. **Nettoyage** automatique du dump temporaire

## Sécurité

- ⚠️ **Demande confirmation** avant d'écraser les données PROD
- ✅ Dump horodaté pour traçabilité
- ✅ Nettoyage automatique des fichiers temporaires
- ✅ Arrêt immédiat en cas d'erreur (`set -e`)

## Exemple de sortie

```
🔄 Copie base de données DEV → PROD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Stats AVANT copie:
---
DEV  - Users: 55, Events: 44, Teachers: 55
PROD - Users: 55, Events: 44, Teachers: 55

⚠️  Cette opération va ÉCRASER toutes les données PROD
Continuer ? (oui/non) : oui

1️⃣  Dump de la base DEV...
✅ Dump créé: /tmp/aujourduy_dev_dump_20251202_161234.sql (3516 lignes)

2️⃣  Restauration dans PROD...
✅ Données restaurées

3️⃣  Vérification...
PROD - Users: 55, Events: 44, Teachers: 55

4️⃣  Nettoyage...
✅ Dump temporaire supprimé

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Copie DEV → PROD terminée avec succès !
```

## Cas d'usage

- **Initialisation PROD** avec données de test DEV
- **Synchronisation** périodique des données
- **Restauration rapide** après tests en PROD

## Limitations

- Les données PROD sont **complètement écrasées**
- Nécessite que les conteneurs Docker DEV et PROD soient actifs
- Pas de backup automatique de PROD avant copie

## Modification du script

Le script est situé ici :
```
/home/dang/Aujourduy-prod/db-dev-to-prod.sh
```

Les credentials sont extraits automatiquement depuis :
- DEV : `/home/dang/Aujourduy/.env`
- PROD : `/home/dang/Aujourduy-prod/.env`
