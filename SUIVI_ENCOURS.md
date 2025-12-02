# SUIVI EN COURS - Aujourduy Production

## 🚀 État du déploiement

### ✅ Services opérationnels
- **PostgreSQL PROD** : UP et healthy
- **PgBouncer PROD** : UP et healthy (port 6432)
- **Rails PROD** : UP et fonctionnel (http://localhost:3002)
- **Playwright PROD** : UP

### ⚠️ À fixer
- **n8n-prod** : En boucle de redémarrage (probablement fichiers de test dans lib/)
- **solid-queue-prod** : En boucle de redémarrage (même cause probable)
- **pgadmin-prod** : UP mais unhealthy (à investiguer si besoin)

## 📋 Tâches en cours

### Priorité 1 - Déploiement
- [ ] Fixer n8n-prod (nettoyer fichiers de test)
- [ ] Fixer solid-queue-prod (nettoyer fichiers de test)
- [ ] Vérifier accès https://3graces.community via Cloudflare Tunnel
- [ ] Tester OAuth Google en production

### Priorité 2 - Configuration
- [ ] Investiguer pgadmin-prod unhealthy (si nécessaire)
- [ ] Configurer n8n-prod avec workflows production
- [ ] Vérifier backups automatiques PostgreSQL

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
1. Vérifier état de n8n-prod et solid-queue-prod
2. Nettoyer fichiers de test si nécessaire
3. Tester accès https://3graces.community

**Ne pas oublier :**
- Les scripts de test sont dans `/home/dang/Aujourduy-prod/rails/scripts/`
- Le dossier lib/ doit rester vide de fichiers de test en PROD
