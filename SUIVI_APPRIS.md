# SUIVI APPRIS - Aujourduy Production

## Base de connaissances - Leçons et solutions

### 🚀 Best Practice : Git-based Deployment avec Kamal (Session 27)

**Architecture actuelle (à migrer) :**
- 2 repos Git séparés : `Aujourduy` (dev) et `Aujourduy-prod` (prod)
- Déploiement : rsync manuel + copie DB complète
- Risques : Perte données prod, pas de rollback, pas de traçabilité

**Architecture recommandée (Rails 8 best practice) :**
```
Un seul repo Git avec branches :
- main → Production (3graces.community)
- develop → Dev (dev.aujourduy.fr)
- feature/* → Features en cours

Déploiement : git push main → Kamal → Zero-downtime deployment
Données : Migrations incrémentales (pas de copie DB)
```

**Workflow Kamal :**
1. Développer en `develop`, commit, push
2. Merger vers `main` (ou cherry-pick commits)
3. Push → Kamal détecte et déploie automatiquement
4. Kamal : build → push image → lance containers → migrate DB → switch trafic → zero downtime
5. Si problème : `kamal rollback` (retour version précédente en 1 commande)

**Bénéfices vs approche actuelle :**
| Critère | Actuel (rsync) | Kamal |
|---------|----------------|-------|
| Perte données prod | ⚠️ Risque élevé (copie DB) | ✅ Aucune (migrations) |
| Rollback | ❌ Manuel et complexe | ✅ 1 commande |
| Downtime | ⚠️ Redémarrage requis | ✅ Zero downtime |
| Traçabilité | ⚠️ Manuelle (SUIVI*.md) | ✅ Git historique |
| CI/CD | ❌ Aucun | ✅ Intégrable facilement |

**Documentation complète :**
- Plan détaillé : ~/Aujourduy/SUIVI_ENCOURS.md (4 phases de migration)
- Justification : ~/Aujourduy/SUIVI_APPRIS.md (comparaison détaillée)

**Statut :** Planifié, à implémenter lors d'une session dédiée

---

### 🔄 Copie Base de Données DEV → PROD (Session 26)

**Outil créé :**
- Script : `/home/dang/Aujourduy-prod/db-dev-to-prod.sh`
- Alias : `db-dev-prod`
- Documentation : `README_DB_COPY.md`

**Fonctionnement :**
1. Dump de DEV avec `pg_dump --clean --if-exists`
2. Restauration dans PROD via `psql`
3. Stats avant/après pour validation
4. Confirmation interactive (sécurité)
5. Nettoyage automatique

**Important :**
- Les credentials PROD sont extraites dynamiquement du `.env` PROD
- Les credentials DEV sont en dur (base stable)
- Dump horodaté pour traçabilité

---

### 🌐 Configuration Domaine www avec Cloudflare (Session 26)

**Problème :**
- www.3graces.community pointait vers Google Sites au lieu de Rails

**Cause :**
- Ancien CNAME dans Cloudflare DNS : `www → ghs.googlehosted.com`

**Solution :**
1. Supprimer le CNAME existant dans Cloudflare DNS (PAS IONOS)
2. Ajouter www.3graces.community dans Cloudflare Tunnel public hostnames
3. Cloudflare crée automatiquement le bon CNAME vers le tunnel

**Architecture DNS :**
```
IONOS (registrar) → Nameservers Cloudflare
                  ↓
Cloudflare DNS → apex (3graces.community) → Tunnel
              → www (www.3graces.community) → Tunnel
              → n8n-prod → Tunnel
```

**Leçon :**
- Toujours vérifier où sont gérés les records (registrar vs CDN/DNS)
- IONOS est juste le registrar, Cloudflare gère le DNS
- Cloudflare Tunnel gère automatiquement les CNAME après ajout du hostname

---

### ⚡ Performance Rails DEV vs PROD (Session 26)

**Benchmarks mesurés :**
- Homepage : 33% plus rapide en PROD
- Events : 30% plus rapide
- Teachers : 35% plus rapide

**Pourquoi seulement 30% ?**
- DEV est déjà très optimisé (PostgreSQL, PgBouncer, Docker)
- Les gains typiques (50-70%) s'appliquent aux setups DEV mal configurés (SQLite, async jobs, etc.)
- Avec même architecture DEV/PROD, le gain vient principalement de :
  - Moins de logging (84% moins en PROD)
  - Mode production Rails (pas de reload, optimisations)
  - Cloudflare CDN pour assets statiques

**Différences Logging :**
- DEV : log_level = :debug (0) → ~25 lignes/requête
- PROD : log_level = :info (1) → 4 lignes/requête
- Impact : Moins d'I/O disque, logs plus lisibles

---

### 🐳 Docker Compose Production (Sessions précédentes)

**Services critiques :**
- `postgres-prod` : PostgreSQL 16 avec SCRAM-SHA-256
- `pgbouncer-prod` : Connection pooling (transaction mode, port 6432)
- `rails-prod` : App Rails sur port 3002
- `solid-queue-prod` : Background jobs Rails 8
- `n8n-prod` : Automation (port 5679)
- `playwright` : Tests E2E

**Configuration PgBouncer :**
- Fichier : `pgbouncer/pgbouncer.ini`
- Mode : transaction
- Auth : SCRAM-SHA-256 via `userlist.txt`
- Port exposé : 6433 (Tailscale), 6432 (interne Docker)

---

### 🔐 OAuth Google Production (Sessions précédentes)

**Configuration :**
- `rails/config/initializers/omniauth.rb` : Redirect URI dynamique selon ENV
- Variables : `RAILS_HOST`, `RAILS_FORCE_SSL`
- Callback : https://3graces.community/users/auth/google_oauth2/callback

**Leçon :**
- TOUJOURS tester OAuth en HTTPS avant de déployer
- Les redirect URIs doivent être configurés dans Google Cloud Console
- Rails détecte automatiquement HTTPS via Cloudflare headers

---

### 🔄 Solid Queue Production (Sessions précédentes)

**Configuration :**
- `rails/config/recurring.yml` : Schedule des jobs récurrents
- Format cron accepté pour les schedules complexes
- Exemple : `"0 3 1 1 *"` pour "1er janvier à 3h"

**Problème rencontré :**
- Schedule au format texte "yearly" causait des erreurs
- Solution : Utiliser format cron standard

---

### 🔑 n8n Production (Sessions précédentes)

**Configuration critique :**
- `N8N_ENCRYPTION_KEY` : DOIT être identique entre DEV et PROD pour importer workflows
- `N8N_PORT` : 5678 en PROD (cohérence avec nom de domaine)
- Cloudflare Tunnel : https://n8n-prod.3graces.community

**Leçon :**
- Si encryption key différente, les credentials ne sont pas importables
- Toujours vérifier le port dans `.env` ET `docker-compose.yml`
