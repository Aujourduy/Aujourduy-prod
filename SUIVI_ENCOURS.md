# SUIVI EN COURS - Aujourduy Production

## 🚀 État du déploiement

### ✅ Services opérationnels
- **PostgreSQL PROD** : UP et healthy
- **PgBouncer PROD** : UP et healthy (port 6432)
- **Rails PROD** : UP et fonctionnel (http://localhost:3002)
- **Solid Queue PROD** : UP et fonctionnel ✅ FIXÉ
- **n8n-prod** : UP et fonctionnel (http://localhost:5679) ✅ FIXÉ
- **Playwright PROD** : UP

### ⚠️ Non-critique
- **pgadmin-prod** : UP mais unhealthy (interface admin, non-bloquant)

## 📋 Tâches en cours

### ✅ Session 26 - Complété (2025-12-02)
- [x] Vérifier création GitHub repository Aujourduy-prod
- [x] Tester accès https://3graces.community via Cloudflare Tunnel
- [x] Tester OAuth Google en production via HTTPS
- [x] Tests complets du site (homepage, events, teachers, practices)
- [x] Copier base de données DEV → PROD (initialisation)
- [x] Benchmarking performance DEV vs PROD
- [x] Créer outil automatisé `db-dev-prod` pour copie BDD
- [x] Configurer www.3graces.community (Cloudflare Tunnel)

### Priorité 1 - À faire
- [ ] Tester Rails API depuis le domaine public
- [ ] Configurer n8n-prod avec workflows production
- [ ] Implémenter CI/CD (GitHub Actions recommandé)

### Priorité 2 - Configuration
- [ ] Vérifier backups automatiques PostgreSQL
- [ ] Investiguer pgadmin-prod unhealthy (si nécessaire, non-bloquant)

### Priorité 3 - Tests
- [ ] Tests end-to-end en production
- [ ] Vérifier scraping en production
- [ ] Tester tous les endpoints API

## 📝 Notes techniques

### Problèmes résolus (Session actuelle)
1. ✅ Connexion PostgreSQL : Copie pgbouncer.ini depuis DEV avec adaptations
2. ✅ Authentification SCRAM-SHA-256 : Ajout userlist.txt
3. ✅ Bases manquantes : Création cache/queue/cable
4. ✅ Permissions : Droits CREATE pour app_prod
5. ✅ Fichiers de test : Déplacés de lib/ vers scripts/ (18 fichiers)
6. ✅ Rails démarre et répond aux requêtes
7. ✅ OAuth redirect URI : omniauth.rb dynamique avec ENV variables
8. ✅ Git repository : Créé et pushé sur GitHub
9. ✅ Solid Queue : Fix schedule recurring "yearly_scraping" (cron format)
10. ✅ n8n-prod : Fix encryption key mismatch + port configuration (5678)
11. ✅ Cloudflare Tunnel : https://3graces.community accessible et fonctionnel
12. ✅ OAuth Google : Testé et validé en production via HTTPS
13. ✅ n8n Cloudflare Tunnel : https://n8n-prod.3graces.community accessible

### Fichiers déplacés
- `/home/dang/Aujourduy-prod/rails/lib/` → `scripts/`
  - Tous les `test_*.rb`
  - `ui_tester.rb`
  - `*_debug*.rb`
  - Total : 18+ fichiers

### Configuration PostgreSQL
- Bases créées : `aujourduy_production`, `_cache`, `_queue`, `_cable`
- Utilisateur : `app_prod` avec droits CREATE sur schéma public
- Connexion : Rails → PgBouncer (6432) → PostgreSQL (5432)
- Auth : SCRAM-SHA-256 via userlist.txt

### Cloudflare Tunnel
- **Rails App** : `https://3graces.community` → `http://localhost:3002` ✅ TESTÉ
- **Rails App (www)** : `https://www.3graces.community` → `http://localhost:3002` ✅ TESTÉ (Session 26)
- **n8n** : `https://n8n-prod.3graces.community` → `http://localhost:5679` ✅ TESTÉ
- Tunnel : `tunnel-n8n` (réutilisé pour les trois hostnames)
- Status : Opérationnel, OAuth validé, www configuré

## 🔄 Prochaine session

**Commencer par :**
1. Implémenter CI/CD (GitHub Actions recommandé)
2. Configurer n8n-prod avec workflows production
3. Tester Rails API depuis domaine public
4. Tests end-to-end de l'application en production

**Fichiers modifiés (non commités) :**
- `SUIVI_GLOBAL.md` : Nouveau fichier créé (session 26)
- `SUIVI_APPRIS.md` : Nouveau fichier créé (leçons)
- `SUIVI_ENCOURS.md` : Mise à jour statut (session 26)
- `README_DB_COPY.md` : Documentation outil db-dev-prod
- `db-dev-to-prod.sh` : Script copie BDD
- `~/.bashrc` : Alias db-dev-prod

**Configuration réseau :**
- Rails PROD : http://localhost:3002 → https://3graces.community
- n8n PROD : http://localhost:5679 → https://n8n-prod.3graces.community
- PgBouncer : 100.95.124.70:6433 (Tailscale)
- PgAdmin : 100.95.124.70:5051 (Tailscale)

**Outils de gestion :**
- **Copie BDD DEV → PROD** : `db-dev-prod` (alias) ✅ Créé Session 26
  - Script : `/home/dang/Aujourduy-prod/db-dev-to-prod.sh`
  - Documentation : `README_DB_COPY.md`
  - Affiche stats avant/après
  - Demande confirmation
  - Dump automatique avec timestamp
  - Dernière utilisation : 2025-12-02 (55 users, 44 events copiés)
