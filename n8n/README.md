# n8n - Documentation

Service d'automatisation de workflows avec API REST pour intégration programmatique.

## Table des Matières

- [Architecture](#architecture)
- [Accès Web UI](#accès-web-ui)
- [API REST](#api-rest)
- [Endpoints disponibles](#endpoints-disponibles)
- [Exemples d'utilisation](#exemples-dutilisation)
- [Workflow autonome Claude](#workflow-autonome-claude)
- [Configuration Docker](#configuration-docker)
- [Troubleshooting](#troubleshooting)

---

## Architecture

```
┌─────────────────────────┐
│   Client (Claude/curl)  │
└───────────┬─────────────┘
            │ HTTP REST API
            ↓
┌─────────────────────────┐
│   n8n Service           │
│   Port: 5678            │
│   Mode: filesystem      │
└───────────┬─────────────┘
            │
            ↓
┌─────────────────────────┐
│   Workflows & Credentials│
│   (SQLite + JSON exports)│
└─────────────────────────┘
```

---

## Accès Web UI

**URL :** https://n8n.aujourduy.fr

**Fonctionnalités :**
- Création visuelle de workflows (drag & drop)
- Gestion des credentials
- Historique des exécutions
- Logs et debugging

---

## API REST

### Configuration

**Base URL :** `https://n8n.aujourduy.fr/api/v1/`

**Authentification :** Header `X-N8N-API-KEY`

**Clé API :** Stockée dans `.env` → `N8N_API_KEY`

### Génération de la clé API

1. Aller sur https://n8n.aujourduy.fr
2. Settings → API → Create API Key
3. Copier la clé générée
4. Mettre à jour `.env` :
   ```bash
   N8N_API_KEY=votre_clé_ici
   ```
5. Redémarrer n8n si nécessaire : `docker compose restart n8n`

**Important :** La clé dans `.env` doit correspondre exactement à celle générée dans l'UI n8n.

---

## Endpoints disponibles

### Workflows

| Endpoint | Méthode | Action |
|----------|---------|--------|
| `/workflows` | GET | Lister tous les workflows |
| `/workflows/{id}` | GET | Détails d'un workflow |
| `/workflows` | POST | Créer un workflow |
| `/workflows/{id}` | PUT | Modifier un workflow |
| `/workflows/{id}` | DELETE | Supprimer un workflow |
| `/workflows/{id}/activate` | POST | Activer un workflow |
| `/workflows/{id}/deactivate` | POST | Désactiver un workflow |

### Exécutions

| Endpoint | Méthode | Action |
|----------|---------|--------|
| `/executions` | GET | Lister les exécutions |
| `/executions/{id}` | GET | Détails d'une exécution |
| `/executions/{id}` | DELETE | Supprimer une exécution |
| `/workflows/{id}/execute` | POST | Lancer une exécution manuelle |

### Credentials

| Endpoint | Méthode | Action |
|----------|---------|--------|
| `/credentials` | GET | Lister les credentials |
| `/credentials/{id}` | GET | Détails d'un credential |
| `/credentials` | POST | Créer un credential |
| `/credentials/{id}` | DELETE | Supprimer un credential |

---

## Exemples d'utilisation

### Lister les workflows

```bash
curl -s "https://n8n.aujourduy.fr/api/v1/workflows" \
  --header "X-N8N-API-KEY: $N8N_API_KEY"
```

### Détails d'un workflow

```bash
curl -s "https://n8n.aujourduy.fr/api/v1/workflows/abc123" \
  --header "X-N8N-API-KEY: $N8N_API_KEY"
```

### Activer un workflow

```bash
curl -X POST "https://n8n.aujourduy.fr/api/v1/workflows/abc123/activate" \
  --header "X-N8N-API-KEY: $N8N_API_KEY"
```

### Lancer une exécution

```bash
curl -X POST "https://n8n.aujourduy.fr/api/v1/workflows/abc123/execute" \
  --header "X-N8N-API-KEY: $N8N_API_KEY" \
  --header "Content-Type: application/json" \
  --data '{}'
```

### Voir le résultat d'une exécution

```bash
curl -s "https://n8n.aujourduy.fr/api/v1/executions/xyz789" \
  --header "X-N8N-API-KEY: $N8N_API_KEY"
```

---

## Workflow autonome Claude

Claude peut créer, exécuter et débugger des workflows n8n de manière autonome :

### Processus

```
1. Lister les workflows    → GET /workflows
2. Créer/modifier          → POST/PUT /workflows/{id}
3. Activer                 → POST /workflows/{id}/activate
4. Lancer une exécution    → POST /workflows/{id}/execute
5. Voir les résultats      → GET /executions/{id}
6. Analyser les erreurs
7. Corriger le workflow    → PUT /workflows/{id}
8. Relancer pour vérifier
```

### Capacités

- Créer des workflows avec tous les nodes (y compris AI Agent)
- Débugger en analysant les exécutions échouées
- Corriger et relancer automatiquement
- Configurer les credentials via API

---

## Configuration Docker

### docker-compose.yml

```yaml
n8n:
  image: n8nio/n8n
  container_name: n8n
  environment:
    - N8N_BASIC_AUTH_ACTIVE=true
    - N8N_BASIC_AUTH_USER=${N8N_USER}
    - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
    - N8N_HOST=n8n.aujourduy.fr
    - N8N_PROTOCOL=https
    - WEBHOOK_URL=https://n8n.aujourduy.fr/
  volumes:
    - ./n8n/data:/home/node/.n8n
    - ./n8n/config:/home/node/config
  networks:
    - internal
  ports:
    - "5678:5678"
```

### Volumes

- `./n8n/data:/home/node/.n8n` - Base de données SQLite, credentials chiffrés
- `./n8n/config:/home/node/config` - Configuration et exports

### Variables d'environnement (.env)

```bash
N8N_USER=admin
N8N_PASSWORD=votre_mot_de_passe
N8N_API_KEY=votre_clé_api
N8N_ENCRYPTION_KEY=votre_clé_encryption
```

---

## Export/Import des workflows

Les workflows sont stockés en SQLite mais peuvent être exportés en JSON pour versioning Git.

### Exporter

```bash
make export-n8n
```

Exporte vers `n8n/config/exports/`

### Importer

```bash
make import-n8n
```

Importe depuis `n8n/config/exports/`

### Backup de la clé d'encryption

```bash
make backup-n8n-key
```

**Important :** Sans la clé d'encryption, les credentials ne peuvent pas être déchiffrés.

---

## Troubleshooting

### Erreur : 401 Unauthorized

**Cause :** Clé API invalide ou manquante

**Solution :**
1. Vérifier que `N8N_API_KEY` est défini dans `.env`
2. Vérifier que la clé correspond à celle générée dans l'UI n8n
3. Régénérer la clé si nécessaire

### Erreur : Workflow not found

**Cause :** ID de workflow incorrect

**Solution :**
1. Lister les workflows : `GET /workflows`
2. Utiliser l'ID correct (format : chaîne alphanumérique)

### Erreur : Cannot execute inactive workflow

**Cause :** Le workflow n'est pas activé

**Solution :**
```bash
curl -X POST "https://n8n.aujourduy.fr/api/v1/workflows/{id}/activate" \
  --header "X-N8N-API-KEY: $N8N_API_KEY"
```

### Les credentials ne fonctionnent pas après restore

**Cause :** Clé d'encryption différente

**Solution :**
1. Restaurer la clé d'encryption originale : `make restore-n8n-key`
2. Ou recréer les credentials manuellement dans l'UI

---

## Ressources

- **Documentation officielle n8n :** https://docs.n8n.io/
- **API Reference :** https://docs.n8n.io/api/
- **Community :** https://community.n8n.io/

---

**Dernière mise à jour :** 21 novembre 2025
**Version :** 1.0
