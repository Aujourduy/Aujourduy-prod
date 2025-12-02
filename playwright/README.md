# Playwright Service - Documentation Complète

Service HTTP autonome qui expose une API pour scraper des sites web avec rendu JavaScript via Playwright.

## 📋 Table des Matières

- [Architecture](#architecture)
- [Endpoints API](#endpoints-api)
- [Configuration Docker](#configuration-docker)
- [Utilisation depuis Rails (Aujourduy)](#utilisation-depuis-rails-aujourduy)
- [Utilisation depuis un autre projet](#utilisation-depuis-un-autre-projet)
- [Développement et Debug](#développement-et-debug)
- [Troubleshooting](#troubleshooting)

---

## Architecture

```
┌─────────────────────────┐
│   Client (Rails/Autre)  │
└───────────┬─────────────┘
            │ HTTP POST
            ↓
┌─────────────────────────┐
│  Playwright Service     │
│  (Express HTTP Server)  │
│  Port: 3000 (interne)   │
└───────────┬─────────────┘
            │
            ↓
┌─────────────────────────┐
│   Chromium Browser      │
│   (headless)            │
└───────────┬─────────────┘
            │
            ↓
┌─────────────────────────┐
│   Site Web Cible        │
│   (avec JS rendering)   │
└─────────────────────────┘
```

**Caractéristiques :**
- Serveur Express standalone (Node.js)
- Browser Chromium persistant (réutilise la même instance)
- Rendu JavaScript complet (sites Wix, SPA, etc.)
- Anti-détection basique (user-agent, webdriver masqué)
- Screenshots automatiques
- Gestion des cookies (auto-accept)
- Scroll automatique pour lazy-loading

---

## Endpoints API

### 1. POST `/render` - Scraping HTML avec rendu JS

**Usage principal :** Récupérer le HTML complet d'un site après rendu JavaScript.

**Request :**
```json
POST http://playwright:3000/render
Content-Type: application/json

{
  "url": "https://example.com/events"
}
```

**Response :**
- **Success (200)** : HTML content (text/html)
- **Error (400)** : `Missing URL`
- **Error (500)** : `Erreur lors du rendu`

**Comportement :**
1. Ouvre un nouveau contexte browser (session isolée)
2. Configure user-agent réaliste + masque webdriver
3. Navigate vers l'URL (`waitUntil: 'load'`, timeout 90s)
4. Attend 5s pour rendu dynamique (Wix, etc.)
5. Détecte et clique sur boutons cookies (`button[name="agree"]`)
6. Scroll complet de la page (lazy-loading)
7. Détecte iframes spécifiques (`multi_event.php`) et les scroll aussi
8. Prend screenshot (`outputs/last_screenshot.png`)
9. Sauvegarde HTML horodaté (`outputs/playwright-result_YYYY-MM-DD-HH-MM-SS.html`)
10. Retourne le HTML

**Fichiers générés :**
- `playwright/outputs/last_screenshot.png` - Screenshot de la page (fullPage)
- `playwright/outputs/playwright-result_*.html` - HTML horodaté (si `CREATE_LOCAL_FILE != 'false'`)

**Limitations connues :**
- ❌ Sites avec HTTP/2 Protocol Error (anti-bot avancé)
- ⚠️ Timeout possible si site très lent (>90s)

---

### 2. POST `/ui-test` - Tests UI interactifs

**Usage :** Tests E2E pour application Rails (ou autre SPA). **Mis à jour 2025-11-26** : Support URLs complètes + viewport configurable.

**Request :**
```json
POST http://playwright:3000/ui-test
Content-Type: application/json

{
  "path": "/events",           // Chemin Rails OU URL complète (http://...)
  "action": "start",            // Optionnel : "start" pour nouvelle session
  "viewport": {                 // Optionnel : viewport personnalisé
    "width": 375,
    "height": 667
  }
}
```

**Exemples :**
```json
// Test Rails classique (défaut: desktop 1920x1080)
{"path": "/events", "action": "start"}

// Test site Jekyll en local avec viewport smartphone
{"path": "http://host.docker.internal:4000", "action": "start", "viewport": {"width": 375, "height": 667}}

// Test site externe avec viewport tablet
{"path": "https://example.com", "action": "start", "viewport": {"width": 768, "height": 1024}}
```

**Response :**
```json
{
  "success": true,
  "title": "Liste des événements",
  "currentUrl": "http://rails:3000/events",
  "htmlContent": "<html>...",
  "visibleText": "Texte visible sur la page (max 5000 chars)",
  "screenshotPath": "/app/outputs/ui-test-screenshot.png",
  "message": "Page loaded successfully"
}
```

**Paramètres :**
- **path** (string, requis) :
  - Chemin Rails : `/events` → `http://rails:3000/events`
  - URL complète : `http://host.docker.internal:4000` → utilisée directement
- **action** (string, optionnel) : `"start"` pour démarrer une nouvelle session (ferme la précédente si existe)
- **viewport** (object, optionnel) :
  - `{width: number, height: number}`
  - Défaut : `{width: 1920, height: 1080}` (desktop)

**Viewports courants :**
```javascript
// Smartphones
{"width": 375, "height": 667}   // iPhone SE
{"width": 390, "height": 844}   // iPhone 12/13/14
{"width": 360, "height": 640}   // Android petit

// Tablets
{"width": 768, "height": 1024}  // iPad
{"width": 820, "height": 1180}  // iPad Air

// Desktop
{"width": 1920, "height": 1080} // Full HD (défaut)
{"width": 1366, "height": 768}  // Laptop
```

**Optimisations :**
- Timeout court (15s au lieu de 90s)
- Pas de scroll automatique
- `waitUntil: 'load'` uniquement (sites rapides)
- Ignore erreurs SSL (pour dev)

---

### 3. POST `/ui-click` - Cliquer sur un élément

**Request :**
```json
POST http://playwright:3000/ui-click
Content-Type: application/json

{
  "selector": "button.btn-primary"
}
```

ou avec texte :
```json
{
  "text": "Se connecter"
}
```

**Response :**
```json
{
  "success": true,
  "message": "Click successful",
  "currentUrl": "http://rails:3000/dashboard",
  "title": "Dashboard",
  "screenshotPath": "/app/outputs/ui-test-screenshot.png"
}
```

**Comportement :**
- Clique sur l'élément (timeout 5s)
- Attend 1s après le clic
- Prend screenshot
- Retourne URL et title actuels

---

### 4. POST `/ui-fill` - Remplir un champ

**Request :**
```json
POST http://playwright:3000/ui-fill
Content-Type: application/json

{
  "selector": "input[name='email']",
  "value": "test@example.com"
}
```

**Response :**
```json
{
  "success": true,
  "message": "Fill successful"
}
```

---

### 5. POST `/ui-get-text` - Récupérer texte

**Request :**
```json
POST http://playwright:3000/ui-get-text
Content-Type: application/json

{
  "selector": ".alert-success"
}
```

ou sans sélecteur (tout le body) :
```json
{}
```

**Response :**
```json
{
  "success": true,
  "text": "Connexion réussie !"
}
```

---

### 6. POST `/ui-close` - Fermer session UI

**Request :**
```json
POST http://playwright:3000/ui-close
Content-Type: application/json

{}
```

**Response :**
```json
{
  "success": true,
  "message": "UI test session closed"
}
```

**Important :** Ferme le contexte browser et libère la mémoire.

---

## Configuration Docker

### docker-compose.yml

```yaml
playwright:
  build:
    context: ./playwright
  container_name: playwright
  volumes:
    - ./playwright:/app
    - ./playwright/outputs:/app/outputs
    - /app/node_modules  # Preserve node_modules from image
  networks:
    - internal
```

**Variables d'environnement :**
- `CREATE_LOCAL_FILE` (défaut: `true`) - Sauvegarder HTML localement ou non

**Ports :**
- Port 3000 interne (pas exposé sur l'hôte) - Accessible uniquement via réseau Docker `internal`

**Volumes :**
- `./playwright:/app` - Code source (hot-reload possible)
- `./playwright/outputs:/app/outputs` - Screenshots et HTML générés
- `/app/node_modules` - Node modules du container (pas écrasés par l'hôte)

### Dockerfile

```dockerfile
FROM mcr.microsoft.com/playwright:focal
WORKDIR /app
COPY package*.json ./
RUN npm install && npx playwright install --with-deps
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

**Base image :** `mcr.microsoft.com/playwright:focal`
- Ubuntu Focal (20.04)
- Playwright + browsers (Chromium, Firefox, Webkit) pré-installés
- Dépendances système pour browsers headless

---

## Utilisation depuis Rails (Aujourduy)

### Service Ruby : `HtmlScraperService`

**Localisation :** `rails/app/services/html_scraper_service.rb`

**Usage simple :**
```ruby
html = HtmlScraperService.scrape("https://example.com")
if html
  puts "HTML récupéré : #{html.length} caractères"
else
  puts "Erreur lors du scraping"
end
```

**Usage avancé (avec instance) :**
```ruby
scraper = HtmlScraperService.new("https://example.com")
html = scraper.scrape!

if scraper.error
  Rails.logger.error("Erreur: #{scraper.error}")
else
  # Traiter le HTML
  doc = Nokogiri::HTML(html)
  # ...
end
```

**Configuration :**
- **URL API :** `http://playwright:3000/render` (hardcodée)
- **Timeout :** 120 secondes
- **Open timeout :** 10 secondes

**Exceptions gérées :**
- `Timeout::Error` - Timeout dépassé
- `StandardError` - Erreurs réseau, HTTP, parsing JSON, etc.

**Screenshots :**
Les screenshots sont automatiquement sauvegardés dans `playwright/outputs/last_screenshot.png` (accessible depuis l'hôte).

---

## Utilisation depuis un autre projet

### Prérequis

Ton projet doit pouvoir communiquer avec le service Playwright via HTTP. Trois options :

#### Option 1 : Utiliser le même réseau Docker

Si ton projet est dans Docker Compose :

```yaml
# docker-compose.yml de ton projet
services:
  mon-app:
    # ...
    networks:
      - aujourduy_internal  # Rejoindre le réseau d'Aujourduy
    external_links:
      - playwright

networks:
  aujourduy_internal:
    external: true
```

Ensuite, utilise l'URL : `http://playwright:3000/render`

#### Option 2 : Exposer le port (non recommandé en prod)

Modifier `docker-compose.yml` d'Aujourduy :

```yaml
playwright:
  # ...
  ports:
    - "3000:3000"  # Expose sur l'hôte
```

Ensuite, utilise l'URL : `http://localhost:3000/render` (ou `http://IP_SERVEUR:3000/render`)

⚠️ **Attention :** Pas d'authentification, n'expose pas en production sans protection !

#### Option 3 : Docker network externe

Créer un réseau Docker partagé :

```bash
docker network create shared-playwright
```

Modifier `docker-compose.yml` d'Aujourduy :
```yaml
playwright:
  # ...
  networks:
    - internal
    - shared-playwright

networks:
  internal:
    driver: bridge
  shared-playwright:
    external: true
```

Dans ton projet :
```yaml
services:
  mon-app:
    # ...
    networks:
      - shared-playwright

networks:
  shared-playwright:
    external: true
```

---

### Exemples dans différents langages

#### Python

```python
import requests

def scrape_with_playwright(url):
    response = requests.post(
        'http://playwright:3000/render',
        json={'url': url},
        timeout=120
    )

    if response.status_code == 200:
        return response.text
    else:
        raise Exception(f"Erreur {response.status_code}: {response.text}")

# Usage
html = scrape_with_playwright("https://example.com")
print(f"HTML récupéré : {len(html)} caractères")
```

#### Node.js

```javascript
const axios = require('axios');

async function scrapeWithPlaywright(url) {
  try {
    const response = await axios.post('http://playwright:3000/render', {
      url: url
    }, {
      timeout: 120000
    });

    return response.data;
  } catch (error) {
    console.error('Erreur scraping:', error.message);
    throw error;
  }
}

// Usage
(async () => {
  const html = await scrapeWithPlaywright('https://example.com');
  console.log(`HTML récupéré : ${html.length} caractères`);
})();
```

#### PHP

```php
<?php

function scrapeWithPlaywright($url) {
    $ch = curl_init('http://playwright:3000/render');

    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['url' => $url]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 120);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);

    $html = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    curl_close($ch);

    if ($httpCode !== 200) {
        throw new Exception("Erreur HTTP $httpCode");
    }

    return $html;
}

// Usage
$html = scrapeWithPlaywright('https://example.com');
echo "HTML récupéré : " . strlen($html) . " caractères\n";
?>
```

#### Bash / cURL

```bash
#!/bin/bash

URL_TO_SCRAPE="https://example.com"

curl -X POST http://playwright:3000/render \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"$URL_TO_SCRAPE\"}" \
  --max-time 120 \
  -o output.html

if [ $? -eq 0 ]; then
  echo "✅ Scraping réussi : $(wc -c < output.html) caractères"
else
  echo "❌ Erreur lors du scraping"
fi
```

---

## Développement et Debug

### Démarrer le service

```bash
# Démarrer tous les services (depuis dossier Aujourduy)
docker compose up -d

# Démarrer uniquement Playwright
docker compose up -d playwright

# Voir les logs en temps réel
docker compose logs -f playwright
```

### Tester manuellement avec curl

```bash
# Test basic
curl -X POST http://localhost:3000/render \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}' \
  -o test-output.html

# Vérifier le screenshot généré
ls -lh playwright/outputs/last_screenshot.png
```

### Accéder au container

```bash
# Shell interactif
docker compose exec playwright sh

# Vérifier les fichiers générés
ls -lh /app/outputs/

# Tester Node directement
node -e "console.log('Test Node.js')"
```

### Modifier le code

Le volume `./playwright:/app` permet le hot-reload :

1. Éditer `playwright/index.js`
2. Redémarrer le container : `docker compose restart playwright`
3. Tester les changements

**Important :** Pas de hot-reload automatique, redémarrage nécessaire.

### Variables d'environnement

Modifier dans `docker-compose.yml` :

```yaml
playwright:
  # ...
  environment:
    - CREATE_LOCAL_FILE=false  # Désactiver sauvegarde HTML
```

---

## Troubleshooting

### ❌ Erreur : `curl: (7) Failed to connect to playwright port 3000`

**Cause :** Le service n'est pas accessible ou pas démarré.

**Solutions :**
1. Vérifier que le service tourne : `docker compose ps playwright`
2. Vérifier les logs : `docker compose logs playwright`
3. Vérifier le réseau Docker : `docker network ls`
4. Si depuis l'hôte, vérifier que le port est exposé (voir Option 2 ci-dessus)

---

### ❌ Erreur : `Timeout lors du scraping`

**Cause :** Le site est trop lent ou bloqué.

**Solutions :**
1. Augmenter le timeout dans `HtmlScraperService` (Rails) ou ton client HTTP
2. Vérifier que le site est accessible : `curl -I https://site-cible.com`
3. Tester manuellement dans Playwright : `docker compose exec playwright node`

---

### ❌ Erreur : `HTTP/2 Protocol Error`

**Cause :** Détection anti-bot avancée (cf. LESSONS_LEARNED.md - Session 13).

**Solutions :**
- Ajouter stealth plugins Playwright (à implémenter)
- Ajouter délais aléatoires
- Utiliser proxy rotatifs
- **Temporaire :** Exclure ce site du scraping

---

### ❌ Screenshot vide ou noir

**Cause :** Page pas complètement chargée.

**Solutions :**
1. Augmenter le délai après `goto()` (actuellement 5s)
2. Attendre un sélecteur spécifique : `await page.waitForSelector('.content')`
3. Vérifier avec `page.screenshot({ fullPage: false })` (viewport uniquement)

---

### ❌ Memory leak / Browser qui consomme trop de RAM

**Cause :** Contextes browser pas fermés correctement.

**Solutions :**
1. Vérifier que tous les `context.close()` sont bien dans un `finally` block
2. Redémarrer le service : `docker compose restart playwright`
3. Limiter le nombre de contextes simultanés (actuellement 1 par requête)

---

### 🐛 Debug approfondi

Activer les logs Playwright :

```javascript
// Dans playwright/index.js
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
  logger: {
    isEnabled: (name, severity) => true,
    log: (name, severity, message) => console.log(`[${severity}] ${message}`)
  }
});
```

---

## 📚 Ressources

- **Documentation officielle Playwright :** https://playwright.dev/
- **API Playwright Node.js :** https://playwright.dev/docs/api/class-playwright
- **Docker Image officielle :** https://playwright.dev/docs/docker
- **LESSONS_LEARNED.md :** Bugs et solutions rencontrés dans Aujourduy

---

## 📝 Notes

- Le service utilise un browser Chromium **persistant** (lancé au démarrage du serveur, réutilisé pour toutes les requêtes)
- Chaque requête crée un **nouveau contexte** (session isolée avec cookies séparés)
- Les screenshots sont **écrasés** à chaque requête (`last_screenshot.png`)
- Les fichiers HTML sont **horodatés** et conservés (sauf si `CREATE_LOCAL_FILE=false`)
- Le service est **stateless** (pas de persistence entre redémarrages)

---

**Dernière mise à jour :** 19 novembre 2025
**Version :** 1.0
**Auteur :** Aujourduy Project
