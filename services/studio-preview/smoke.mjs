// Screenshot smoke test for a running dev server (Expo web build or website), at phone size.
// node smoke.mjs <baseUrl> <outDir>
// Opens the home screen, follows up to 8 in-app links, saves one PNG per
// screen plus index.html, and fails on uncaught page errors.
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const [base, out] = process.argv.slice(2);
const browser = await chromium.launch();
// iPhone-sized viewport (390×844 pt) set explicitly; device presets get
// renamed between Playwright releases.
const context = await browser.newContext({
  viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, colorScheme: "dark",
  userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
});
const page = await context.newPage();
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));

const shots = [];
async function shoot(url, name) {
  // The first load compiles the web bundle, which can take a while.
  await page.goto(url, { waitUntil: "networkidle", timeout: 180_000 });
  await page.waitForTimeout(800);
  const file = `${String(shots.length + 1).padStart(2, "0")}-${name}.png`;
  await page.screenshot({ path: path.join(out, file), fullPage: false });
  shots.push({ file, url });
}

await shoot(base, "home");
const hrefs = await page.$$eval("a[href^='/']", (as) => [...new Set(as.map((a) => a.getAttribute("href")))]);
for (const href of hrefs.filter((h) => h !== "/").slice(0, 8)) {
  await shoot(new URL(href, base).toString(), href.replace(/[^a-z0-9]+/gi, "-").replace(/^-|-$/g, "") || "screen");
}
await browser.close();

const cards = shots.map((s) => `<figure><img src="${s.file}"><figcaption>${s.url.replace(base, "") || "/"}</figcaption></figure>`).join("");
fs.writeFileSync(path.join(out, "index.html"), `<!doctype html><meta name=viewport content="width=device-width"><title>Preview screenshots</title>
<style>body{font:14px system-ui;margin:16px;display:flex;flex-wrap:wrap;gap:16px}figure{margin:0;width:260px}img{width:100%;border:1px solid #ddd;border-radius:12px}</style>
${errors.length ? `<p style="color:#b00;width:100%">Page errors: ${errors.map((e) => e.replace(/</g, "&lt;")).join(" | ")}</p>` : ""}${cards}`);

console.log(`${shots.length} screens, ${errors.length} page errors`);
if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}
