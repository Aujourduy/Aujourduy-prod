const { test, expect } = require('@playwright/test');

const BASE_URL = process.env.BASE_URL || 'http://rails:3001';

test.describe('Aujourduy E2E Tests', () => {
  test('Homepage loads successfully', async ({ page }) => {
    await page.goto(BASE_URL);
    await expect(page).toHaveTitle(/Aujourduy/);
  });

  test('User can view events list', async ({ page }) => {
    await page.goto(`${BASE_URL}/event_occurrences`);
    await expect(page.locator('.event-card')).toBeVisible();
  });

  test('User can view teacher profile', async ({ page }) => {
    await page.goto(`${BASE_URL}/teachers`);
    await page.locator('.teacher-card').first().click();
    await expect(page.locator('h1')).toBeVisible();
  });

  test('User can search events', async ({ page }) => {
    await page.goto(`${BASE_URL}/event_occurrences`);
    await page.fill('input[name="search"]', 'yoga');
    await page.click('button[type="submit"]');
    await expect(page.locator('.event-card')).toBeVisible();
  });

  test('User sign up flow', async ({ page }) => {
    await page.goto(`${BASE_URL}/users/sign_up`);
    await page.fill('input[name="user[email]"]', `test${Date.now()}@example.com`);
    await page.fill('input[name="user[password]"]', 'password123456');
    await page.fill('input[name="user[password_confirmation]"]', 'password123456');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL(/dashboard|event_occurrences/);
  });

  test('User can view venues map', async ({ page }) => {
    await page.goto(`${BASE_URL}/venues`);
    await expect(page.locator('#map')).toBeVisible({ timeout: 10000 });
  });

  test('Navigation menu works', async ({ page }) => {
    await page.goto(BASE_URL);
    await page.click('a[href="/event_occurrences"]');
    await expect(page).toHaveURL(/event_occurrences/);

    await page.click('a[href="/teachers"]');
    await expect(page).toHaveURL(/teachers/);
  });

  test('Mobile responsive menu', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 }); // iPhone
    await page.goto(BASE_URL);
    await page.click('.mobile-menu-button');
    await expect(page.locator('.mobile-menu')).toBeVisible();
  });

  test('Event filters work', async ({ page }) => {
    await page.goto(`${BASE_URL}/event_occurrences`);
    await page.click('text=Filters');
    await page.selectOption('select[name="practice"]', { index: 1 });
    await page.click('button:has-text("Apply")');

    await expect(page).toHaveURL(/practice/);
  });

  test('PWA manifest is accessible', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/manifest.json`);
    expect(response.status()).toBe(200);
    const manifest = await response.json();
    expect(manifest.name).toBeTruthy();
  });
});

test.describe('Admin Tests', () => {
  test('Admin can access Avo dashboard', async ({ page }) => {
    // Login as admin first
    await page.goto(`${BASE_URL}/users/sign_in`);
    await page.fill('input[name="user[email]"]', 'bonjour.duy@gmail.com');
    await page.fill('input[name="user[password]"]', process.env.ADMIN_PASSWORD || 'password');
    await page.click('button[type="submit"]');

    await page.goto(`${BASE_URL}/avo`);
    await expect(page.locator('text=Dashboard')).toBeVisible({ timeout: 5000 });
  });

  test('Admin can view scraped events', async ({ page }) => {
    // Assuming already logged in
    await page.goto(`${BASE_URL}/avo/resources/scraped_events`);
    await expect(page).toHaveTitle(/Scraped events/);
  });
});

test.describe('Performance Tests', () => {
  test('Homepage loads within acceptable time', async ({ page }) => {
    const startTime = Date.now();
    await page.goto(BASE_URL);
    const loadTime = Date.now() - startTime;

    expect(loadTime).toBeLessThan(3000); // 3 seconds
  });

  test('Event list pagination works', async ({ page }) => {
    await page.goto(`${BASE_URL}/event_occurrences`);

    if (await page.locator('text=Next').isVisible()) {
      await page.click('text=Next');
      await expect(page).toHaveURL(/page=2/);
    }
  });
});
