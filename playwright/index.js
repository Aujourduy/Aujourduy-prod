const express = require('express');
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;
const createLocalFile = process.env.CREATE_LOCAL_FILE === 'false';

let browser; // Navigateur global
let browserStartTime = Date.now();
const BROWSER_LIFETIME_MS = 6 * 60 * 60 * 1000; // 6 heures
const activeContexts = new Set(); // Track active contexts

app.use(express.json());

// Endpoint health check
app.get('/health', (req, res) => {
  const uptime = Date.now() - browserStartTime;
  const hours = Math.floor(uptime / (1000 * 60 * 60));
  const minutes = Math.floor((uptime % (1000 * 60 * 60)) / (1000 * 60));

  res.json({
    status: 'healthy',
    browser: browser ? 'active' : 'inactive',
    browserUptime: `${hours}h ${minutes}m`,
    activeContexts: activeContexts.size,
    uiTestSession: uiTestContext ? 'active' : 'inactive',
    memoryUsage: process.memoryUsage().heapUsed / 1024 / 1024 + ' MB'
  });
});

// Fonction pour recycler le browser si nécessaire
async function ensureFreshBrowser() {
  const now = Date.now();
  if (browser && (now - browserStartTime) > BROWSER_LIFETIME_MS) {
    console.log('♻️ Recyclage du browser après 6 heures...');
    try {
      // Fermer tous les contextes actifs
      for (const context of activeContexts) {
        try {
          await context.close();
        } catch (e) {
          console.error('Erreur fermeture contexte:', e.message);
        }
      }
      activeContexts.clear();

      // Fermer le browser
      await browser.close();
      browser = null;
    } catch (e) {
      console.error('Erreur recyclage browser:', e.message);
    }
  }

  if (!browser) {
    browser = await chromium.launch({
      args: [
        '--disable-dev-shm-usage',
        '--disable-blink-features=AutomationControlled',
        '--no-sandbox'
      ]
    });
    browserStartTime = Date.now();
    console.log('🚀 Nouveau browser lancé');
  }

  return browser;
}

app.post('/render', async (req, res) => {
  const { url } = req.body;
  console.log('📥 Requête reçue avec body brut :', req.body);
  console.log('🌐 URL extraite :', url);

  if (!url) return res.status(400).send('Missing URL');
  console.log('▶️ Requête reçue pour URL :', url);

  let context;
  try {
    const currentBrowser = await ensureFreshBrowser();
    context = await currentBrowser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    });
    activeContexts.add(context); // Track le contexte

    await context.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => false });
    });

    const page = await context.newPage();
    await page.goto(url, { waitUntil: 'load', timeout: 90000 });
    console.log('✅ Page principale chargée');

    // Attendre un peu que le contenu dynamique se charge (important pour les sites comme Wix)
    await page.waitForTimeout(5000);

    try {
      const acceptButton = await page.waitForSelector('button[name="agree"]', { timeout: 3000 });
      if (acceptButton) {
        await acceptButton.click();
        console.log('🍪 Bouton "Accepter tous" cliqué');
        await page.waitForTimeout(1000);
      }
    } catch (e) {
      console.log('ℹ️ Aucun bouton de cookies trouvé ou timeout dépassé');
    }

    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.emulateMedia({ reducedMotion: 'reduce' });

    await page.evaluate(async () => {
      await new Promise((resolve) => {
        let totalHeight = 0;
        const distance = 100;
        const timer = setInterval(() => {
          window.scrollBy(0, distance);
          totalHeight += distance;
          if (totalHeight >= document.body.scrollHeight) {
            clearInterval(timer);
            resolve();
          }
        }, 100);
      });
    });

    await page.waitForTimeout(500);

    const screenshotPath = path.join(__dirname, 'outputs', 'last_screenshot.png');
    if (!fs.existsSync(path.dirname(screenshotPath))) {
      fs.mkdirSync(path.dirname(screenshotPath), { recursive: true });
    }

    try {
      await page.screenshot({ path: screenshotPath, fullPage: true, timeout: 60000 });
      console.log('📸 Screenshot capturé :', screenshotPath);
    } catch (e) {
      console.error('❌ Échec de la capture d’écran :', e);
    }

    const frames = page.frames();
    console.log('🔍 Frames détectés :');
    frames.forEach(f => console.log(' - ', f.url()));
    const frame = frames.find(f => f.url().includes('multi_event.php') && f.url().includes('multi='));

    let htmlContent;
    if (frame) {
      console.log('🔗 Iframe ciblée trouvée :', frame.url());

      await frame.evaluate(async () => {
        await new Promise((resolve) => {
          let totalHeight = 0;
          const distance = 100;
          const timer = setInterval(() => {
            window.scrollBy(0, distance);
            totalHeight += distance;
            if (totalHeight >= document.body.scrollHeight) {
              clearInterval(timer);
              resolve();
            }
          }, 200);
        });
      });

      await page.waitForTimeout(3000);
      htmlContent = await frame.content();
    } else {
      console.log('⚠️ Aucune iframe spécifique trouvée, fallback sur le contenu principal');
      await page.waitForTimeout(2000);
      htmlContent = await page.content();
    }

    console.log('📦 HTML récupéré, taille :', htmlContent.length);

    if (createLocalFile) {
      const fileName = url.replace(/[^a-z0-9]/gi, '_').toLowerCase();
      const filePath = path.join(__dirname, `${fileName}.html`);
      fs.writeFileSync(filePath, htmlContent);
      console.log(`💾 Fichier HTML sauvegardé : ${filePath}`);

      const now = new Date();
      const timestamp = now.toISOString().replace(/T/, '-').replace(/:/g, '-').split('.')[0];
      const datedFileName = `playwright-result_${timestamp}.html`;
      const datedFilePath = path.join(__dirname, 'outputs', datedFileName);
      if (!fs.existsSync(path.dirname(datedFilePath))) {
        fs.mkdirSync(path.dirname(datedFilePath), { recursive: true });
      }
      fs.writeFileSync(datedFilePath, htmlContent);
      console.log(`💾 Fichier HTML horodaté sauvegardé : ${datedFilePath}`);
    } else {
      console.log('🚫 CREATE_LOCAL_FILE désactivé, aucun fichier sauvegardé');
    }

    await page.close();
    await context.close();
    activeContexts.delete(context); // Retirer du tracking
    res.send(htmlContent);
  } catch (error) {
    console.error('❌ Erreur :', error);
    if (context) {
      try {
        await context.close();
        activeContexts.delete(context); // Retirer du tracking même en cas d'erreur
      } catch (e) {
        console.error('Erreur fermeture contexte:', e.message);
      }
    }
    res.status(500).send('Erreur lors du rendu');
  }
});

// ====================================================================
// NOUVEAUX ENDPOINTS POUR TESTS UI INTERACTIFS
// ====================================================================

// Session de test UI (gardée en mémoire pour la session)
let uiTestContext = null;
let uiTestPage = null;

// POST /ui-test - Naviguer vers une page Rails et prendre un screenshot
// OPTIMISÉ pour notre site Rails (pas de timers longs comme pour Wix)
app.post('/ui-test', async (req, res) => {
  const { path: urlPath, action, viewport } = req.body;
  console.log('🧪 UI Test - Path:', urlPath, 'Action:', action, 'Viewport:', viewport);

  try {
    // Fermer la session précédente si elle existe
    if (action === 'start' || !uiTestContext) {
      if (uiTestContext) {
        await uiTestContext.close();
        activeContexts.delete(uiTestContext);
      }

      const currentBrowser = await ensureFreshBrowser();
      uiTestContext = await currentBrowser.newContext({
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        viewport: viewport || { width: 1920, height: 1080 },  // Viewport configurable (défaut: desktop)
        ignoreHTTPSErrors: true  // Ignorer les erreurs de certificat SSL en dev
      });
      activeContexts.add(uiTestContext); // Track le contexte UI

      uiTestPage = await uiTestContext.newPage();
    }

    // Naviguer vers la page (Rails ou autre)
    // Si urlPath commence par http:// ou https://, l'utiliser directement
    // Sinon, concaténer avec http://rails:3000 (rétrocompatibilité)
    const fullUrl = urlPath && (urlPath.startsWith('http://') || urlPath.startsWith('https://'))
      ? urlPath
      : `http://rails:3000${urlPath}`;
    console.log('🌐 Navigating to:', fullUrl);
    await uiTestPage.goto(fullUrl, { waitUntil: 'load', timeout: 15000 });

    // Attente courte pour le rendu (Rails est rapide)
    await uiTestPage.waitForTimeout(500);

    // Prendre screenshot
    const screenshotPath = path.join(__dirname, 'outputs', 'ui-test-screenshot.png');
    if (!fs.existsSync(path.dirname(screenshotPath))) {
      fs.mkdirSync(path.dirname(screenshotPath), { recursive: true });
    }
    await uiTestPage.screenshot({ path: screenshotPath, fullPage: false });
    console.log('📸 Screenshot saved:', screenshotPath);

    // Récupérer le HTML complet (pour analyse du DOM)
    const htmlContent = await uiTestPage.content();

    // Récupérer le texte visible
    const visibleText = await uiTestPage.evaluate(() => {
      return document.body.innerText;
    });

    // Récupérer le title
    const title = await uiTestPage.title();

    // Récupérer l'URL actuelle (peut avoir changé avec une redirection)
    const currentUrl = uiTestPage.url();

    res.json({
      success: true,
      title,
      currentUrl,
      htmlContent,  // HTML complet pour analyse
      visibleText: visibleText.substring(0, 5000), // Limiter à 5000 chars
      screenshotPath,
      message: 'Page loaded successfully'
    });

  } catch (error) {
    console.error('❌ UI Test Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// POST /ui-click - Cliquer sur un élément
app.post('/ui-click', async (req, res) => {
  const { selector, text } = req.body;
  console.log('🖱️ UI Click - Selector:', selector, 'Text:', text);

  if (!uiTestPage) {
    return res.status(400).json({ success: false, error: 'No active UI test session' });
  }

  try {
    if (selector) {
      await uiTestPage.click(selector, { timeout: 5000 });
    } else if (text) {
      await uiTestPage.click(`text=${text}`, { timeout: 5000 });
    } else {
      throw new Error('Either selector or text must be provided');
    }

    await uiTestPage.waitForTimeout(1000);

    // Prendre screenshot après le clic
    const screenshotPath = path.join(__dirname, 'outputs', 'ui-test-screenshot.png');
    await uiTestPage.screenshot({ path: screenshotPath, fullPage: false });

    const currentUrl = uiTestPage.url();
    const title = await uiTestPage.title();

    res.json({
      success: true,
      message: 'Click successful',
      currentUrl,
      title,
      screenshotPath
    });

  } catch (error) {
    console.error('❌ UI Click Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// POST /ui-fill - Remplir un champ
app.post('/ui-fill', async (req, res) => {
  const { selector, value } = req.body;
  console.log('✍️ UI Fill - Selector:', selector, 'Value:', value);

  if (!uiTestPage) {
    return res.status(400).json({ success: false, error: 'No active UI test session' });
  }

  try {
    await uiTestPage.fill(selector, value, { timeout: 5000 });
    await uiTestPage.waitForTimeout(500);

    res.json({
      success: true,
      message: 'Fill successful'
    });

  } catch (error) {
    console.error('❌ UI Fill Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// POST /ui-get-text - Récupérer le texte d'un élément ou de la page
app.post('/ui-get-text', async (req, res) => {
  const { selector } = req.body;
  console.log('📖 UI Get Text - Selector:', selector);

  if (!uiTestPage) {
    return res.status(400).json({ success: false, error: 'No active UI test session' });
  }

  try {
    let text;
    if (selector) {
      text = await uiTestPage.textContent(selector, { timeout: 5000 });
    } else {
      text = await uiTestPage.evaluate(() => document.body.innerText);
    }

    res.json({
      success: true,
      text
    });

  } catch (error) {
    console.error('❌ UI Get Text Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// POST /ui-close - Fermer la session UI
app.post('/ui-close', async (req, res) => {
  console.log('🛑 UI Close session');

  try {
    if (uiTestContext) {
      await uiTestContext.close();
      activeContexts.delete(uiTestContext); // Retirer du tracking
      uiTestContext = null;
      uiTestPage = null;
    }

    res.json({
      success: true,
      message: 'UI test session closed'
    });

  } catch (error) {
    console.error('❌ UI Close Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// POST /ui-evaluate - Évaluer du JavaScript dans la page
app.post('/ui-evaluate', async (req, res) => {
  const { code } = req.body;
  console.log('🔍 UI Evaluate - Code:', code);

  if (!uiTestPage) {
    return res.status(400).json({ success: false, error: 'No active UI test session' });
  }

  try {
    const result = await uiTestPage.evaluate((code) => {
      return eval(code);
    }, code);

    res.json({
      success: true,
      result
    });

  } catch (error) {
    console.error('❌ UI Evaluate Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ====================================================================
// FIN NOUVEAUX ENDPOINTS
// ====================================================================

(async () => {
  browser = await chromium.launch({
    args: [
      '--disable-dev-shm-usage',
      '--disable-blink-features=AutomationControlled',
      '--no-sandbox'
    ]
  });
  browserStartTime = Date.now();

  // Nettoyage périodique toutes les heures
  setInterval(async () => {
    console.log('🧹 Nettoyage périodique - Contextes actifs:', activeContexts.size);

    // Nettoyer les contextes qui pourraient être orphelins
    const contextsToRemove = [];
    for (const context of activeContexts) {
      try {
        // Tester si le contexte est toujours valide
        await context.pages();
      } catch (e) {
        // Le contexte est probablement fermé ou corrompu
        contextsToRemove.push(context);
      }
    }

    for (const context of contextsToRemove) {
      activeContexts.delete(context);
      console.log('🗑️ Contexte orphelin retiré');
    }

    // Si trop de contextes actifs, suggérer un recyclage
    if (activeContexts.size > 10) {
      console.log('⚠️ Beaucoup de contextes actifs:', activeContexts.size);
    }
  }, 60 * 60 * 1000); // Toutes les heures

  app.listen(port, () => {
    console.log(`✅ API Playwright en écoute sur http://localhost:${port}`);
  });
})();

process.on('SIGINT', async () => {
  console.log('🛑 Arrêt du serveur...');

  // Fermer tous les contextes actifs
  for (const context of activeContexts) {
    try {
      await context.close();
    } catch (e) {
      console.error('Erreur fermeture contexte:', e.message);
    }
  }
  activeContexts.clear();

  // Fermer le browser
  if (browser) {
    try {
      await browser.close();
    } catch (e) {
      console.error('Erreur fermeture browser:', e.message);
    }
  }

  process.exit();
});
