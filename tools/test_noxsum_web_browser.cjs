#!/usr/bin/env node
"use strict";

/**
 * Browser smoke for the actual Godot 4.7 Web export.
 * Requires: npm install --no-save playwright pngjs
 * Serve builds/web on http://127.0.0.1:8765 before running.
 *
 * Captures screenshots for human layout review. Canvas pixel diversity is
 * only a smoke signal, NOT proof that every control is visible or correct.
 */

const { chromium } = require("playwright");
const { PNG } = require("pngjs");
const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");

const BASE = process.env.NOXSUM_TEST_URL || "http://127.0.0.1:8765";
const OUT = path.resolve(process.env.NOXSUM_QA_DIR || "builds/web-qa");
fs.mkdirSync(OUT, { recursive: true });
const results = [];

function changedAreaRatio(before, after) {
  const a = PNG.sync.read(before), b = PNG.sync.read(after);
  assert.equal(a.width, b.width);
  assert.equal(a.height, b.height);
  let changed = 0, total = 0;
  for (let y = 0; y < a.height; y += 12) {
    for (let x = 0; x < a.width; x += 12) {
      const i = (y * a.width + x) * 4;
      const d = Math.abs(a.data[i] - b.data[i])
        + Math.abs(a.data[i + 1] - b.data[i + 1])
        + Math.abs(a.data[i + 2] - b.data[i + 2]);
      if (d > 90) changed++;
      total++;
    }
  }
  return Math.round(changed / total * 1000) / 1000;
}

function screenshotDiversity(buffer) {
  const png = PNG.sync.read(buffer);
  const colors = new Set();
  for (let y = 0; y < png.height; y += 12) {
    for (let x = 0; x < png.width; x += 12) {
      const i = (y * png.width + x) * 4;
      const q = 32; // Coarse quantization to ignore compression and subpixels.
      colors.add([0, 1, 2].map(c => Math.floor(png.data[i + c] / q)).join(":"));
    }
  }
  return colors.size;
}

async function scenario(browser, name, { width, height, mobile = false, throttle = false, previewOnly = false, dpr = mobile ? 2 : 1 }) {
  const context = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: dpr,
    isMobile: mobile,
    hasTouch: mobile,
    javaScriptEnabled: true,
    serviceWorkers: "block",
  });
  const page = await context.newPage();
  const errors = [];
  const warnings = [];
  const badResponses = [];
  const failedRequests = [];
  const progressObservations = [];
  page.on("pageerror", error => errors.push(String(error)));
  page.on("console", msg => {
    if (msg.type() === "error") errors.push(msg.text());
    if (msg.type() === "warning") warnings.push(msg.text());
  });
  page.on("response", res => {
    if (res.status() >= 400) badResponses.push(res.status() + " " + res.url());
  });
  page.on("requestfailed", req => failedRequests.push(req.url() + ": " + (req.failure()?.errorText || "unknown")));

  const cdp = await context.newCDPSession(page);
  await cdp.send("Network.enable");
  await cdp.send("Network.setCacheDisabled", { cacheDisabled: true });
  if (throttle) {
    await cdp.send("Network.emulateNetworkConditions", {
      offline: false,
      latency: 50,
      downloadThroughput: 1_250_000, // 10 Mbps in bytes/second.
      uploadThroughput: 625_000,
      connectionType: "cellular4g",
    });
  }

  const t0 = Date.now();
  let navigated = false;
  try {
    await page.goto(BASE + "/", { waitUntil: "domcontentloaded", timeout: 180_000 });
    navigated = true;
    const initial = await page.locator("#noxsum-loading").count();
    assert.equal(initial, 1, "Loading UI should be present at DOMContentLoaded");

    // Record progress via the page, without calling Godot internals.
    const samples = [];
    const sampler = setInterval(async () => {
      try {
        const sample = await page.locator("#noxsum-loading .loading-percent").textContent({ timeout: 1000 });
        if (sample && samples[samples.length - 1] !== sample) samples.push(sample);
      } catch { /* loader already removed */ }
    }, 600);

    try {
      await page.waitForFunction(() => !document.querySelector("#noxsum-loading"), null, {
        timeout: throttle ? 180_000 : 120_000,
      });
    } finally {
      clearInterval(sampler);
    }
    const startupMs = Date.now() - t0;
    await page.waitForTimeout(2_000); // Let the HOME/opening first frame settle.
    const state = await page.evaluate(() => {
      const canvas = document.getElementById("canvas");
      const rect = canvas.getBoundingClientRect();
      return {
        title: document.title,
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
        rect: {
          x: Math.round(rect.x), y: Math.round(rect.y),
          width: Math.round(rect.width), height: Math.round(rect.height),
        },
        viewportWidth: window.innerWidth,
        viewportHeight: window.innerHeight,
        devicePixelRatio: window.devicePixelRatio,
        resources: performance.getEntriesByType("resource")
          .filter(entry => /\.(pck|wasm|js)(\?|$)/.test(entry.name))
          .map(entry => ({
            name: entry.name.split("/").pop(),
            durationMs: Math.round(entry.duration),
            transferSize: entry.transferSize,
            encodedBodySize: entry.encodedBodySize,
          })),
      };
    });

    assert.equal(state.title, "NOXSUM", "Browser title should be NOXSUM");
    assert.ok(state.canvasWidth > 0 && state.canvasHeight > 0, "Canvas must be initialized");
    assert.ok(state.rect.width >= width - 2, "Canvas should span the available CSS viewport");
    assert.ok(state.rect.height >= height - 2, "Canvas should span the available CSS viewport");
    assert.ok(!badResponses.length, "HTTP failures: " + badResponses.join(", "));
    assert.ok(!failedRequests.length, "Failed requests: " + failedRequests.join(", "));
    assert.ok(!errors.length, "Browser errors: " + errors.join(", "));

    const screenshotName = name + ".png";
    const image = await page.screenshot({ path: path.join(OUT, screenshotName), fullPage: true });
    const diversity = screenshotDiversity(image);
    assert.ok(diversity > 6, "Screenshot is almost monochrome, review failed render");
    const extraScreenshots = [];
    // Verify pointer flow beyond HOME; screenshots remain subject to visual review.
    if (!throttle && !previewOnly) {
      const playX = width / 2;
      const playY = height - 190;
      if (mobile) await page.touchscreen.tap(playX, playY);
      else await page.mouse.click(playX, playY);
      await page.waitForTimeout(900);
      await page.keyboard.press("Escape"); // Skip first-run prologue via ui_cancel.
      await page.waitForTimeout(2_300);
      const stageName = name + "-after-play.png";
      const stageImage = await page.screenshot({ path: path.join(OUT, stageName), fullPage: true });
      const stageDiversity = screenshotDiversity(stageImage);
      assert.ok(stageDiversity > 6, "Stage screenshot appears blank");
      assert.ok(changedAreaRatio(image, stageImage) > 0.08, "PLAY did not visibly leave HOME");
      assert.ok(!errors.length, "Browser errors after PLAY: " + errors.join(", "));
      extraScreenshots.push({ screenshot: stageName, coarseColors: stageDiversity });
      // Dismiss the first-play tutorial and capture the actual shadow boards.
      const guideX = width / 2;
      const guideY = height / 2 + 200; // Center of anchored LET'S PLAY across viewport heights.
      if (mobile) await page.touchscreen.tap(guideX, guideY);
      else await page.mouse.click(guideX, guideY);
      await page.waitForTimeout(900);
      const boardName = name + "-gr01-board.png";
      const boardImage = await page.screenshot({ path: path.join(OUT, boardName), fullPage: true });
      const boardDiversity = screenshotDiversity(boardImage);
      assert.ok(boardDiversity > 6, "GR01 board screenshot appears blank");
      assert.ok(changedAreaRatio(stageImage, boardImage) > 0.02, "Guide did not visibly dismiss");
      assert.ok(!errors.length, "Browser errors after guide dismissal: " + errors.join(", "));
      extraScreenshots.push({ screenshot: boardName, coarseColors: boardDiversity });
    }
    const result = {
      name, pass: true, startupMs, loadingSamples: samples.slice(0, 25),
      extraScreenshots,
      screenshot: screenshotName, coarseColors: diversity, state,
      warnings: warnings.slice(0, 12),
    };
    console.log(JSON.stringify(result, null, 2));
    results.push(result);
  } catch (error) {
    const failure = {
      name, pass: false, navigated, error: String(error),
      badResponses, failedRequests, errors: errors.slice(0, 30),
      warnings: warnings.slice(0, 10),
    };
    try {
      failure.screenshot = name + "-failure.png";
      await page.screenshot({ path: path.join(OUT, failure.screenshot), fullPage: true });
    } catch { /* browser may not be responsive */ }
    console.error(JSON.stringify(failure, null, 2));
    results.push(failure);
  } finally {
    await context.close();
  }
}

async function checkSharePages(browser) {
  const ctx = await browser.newContext();
  const details = {};
  for (const lang of ["ja", "en"]) {
    const response = await ctx.request.get(BASE + "/" + lang + "/");
    assert.equal(response.status(), 200, lang + " share page must return 200");
    const html = await response.text();
    assert.match(html, /property="og:image"/);
    const imageResponse = await ctx.request.get(BASE + "/ogp/noxsum-" + lang + ".png");
    assert.equal(imageResponse.status(), 200, lang + " OGP image must return 200");
    details[lang] = { page: response.status(), ogp: imageResponse.status() };
  }
  await ctx.close();
  results.push({ name: "localized-share-pages", pass: true, details });
}

(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: [
      "--disable-dev-shm-usage",
      "--enable-webgl",
      "--enable-unsafe-swiftshader",
      "--use-gl=angle",
      "--use-angle=swiftshader",
    ],
  });
  try {
    await scenario(browser, "desktop-720x900", { width: 720, height: 900 });
    await scenario(browser, "mobile-360x800", { width: 360, height: 800, mobile: true });
    await scenario(browser, "iphone13-390x844-dpr3", { width: 390, height: 844, mobile: true, dpr: 3 });
    await scenario(browser, "pixel7-412x915-dpr2625", { width: 412, height: 915, mobile: true, dpr: 2.625 });
    // Capture landscape without simulating portrait-only PLAY controls.
    await scenario(browser, "iphone13-landscape-750x342-dpr3", { width: 750, height: 342, mobile: true, dpr: 3, previewOnly: true });
    await scenario(browser, "pixel7-landscape-915x412-dpr2625", { width: 915, height: 412, mobile: true, dpr: 2.625, previewOnly: true });
    await scenario(browser, "desktop-wide-1280x720", { width: 1280, height: 720, previewOnly: true });
    await scenario(browser, "mobile-405x900-10mbps", { width: 405, height: 900, mobile: true, throttle: true });
    try {
      await checkSharePages(browser);
    } catch (error) {
      results.push({ name: "localized-share-pages", pass: false, error: String(error) });
    }
  } finally {
    await browser.close();
    fs.writeFileSync(path.join(OUT, "browser-results.json"), JSON.stringify(results, null, 2) + "\n");
    console.log("Summary:", results.map(r => r.name + "=" + (r.pass ? "PASS" : "FAIL")).join(", "));
    if (results.some(r => !r.pass)) process.exitCode = 1;
  }
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
