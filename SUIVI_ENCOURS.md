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

### Priorité 1 - Vérification
- [ ] Tester accès https://3graces.community via Cloudflare Tunnel
- [ ] Vérifier OAuth Google en production via https
- [ ] Tester Rails API depuis le domaine public

### Priorité 2 - Configuration
- [ ] Configurer n8n-prod avec workflows production
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
- Domaine : `3graces.community`
- Cible : `http://localhost:3002`
- Tunnel : `tunnel-n8n` (réutilisé)
- Status : Configuré, à tester

## 🔄 Prochaine session

**Commencer par :**
1. ✅ ~~Vérifier état de n8n-prod et solid-queue-prod~~ → FIXÉ
2. Tester accès https://3graces.community via Cloudflare Tunnel
3. Vérifier OAuth Google fonctionne en HTTPS
4. Tests end-to-end de l'application en production

**Fichiers modifiés (non commités) :**
- `.env` : N8N_ENCRYPTION_KEY + N8N_PORT
- `rails/config/recurring.yml` : Schedule format yearly_scraping
- `SUIVI_ENCOURS.md` : Mise à jour statut

**Configuration réseau :**
- Rails PROD : http://localhost:3002
- n8n PROD : http://localhost:5679
- Cloudflare Tunnel : 3graces.community → localhost:3002
