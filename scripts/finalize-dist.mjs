import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dist = path.join(root, "dist");
const appDir = path.join(dist, "app");
const pwaIndex = path.join(dist, "index.html");
const marketingIndex = path.join(dist, "home", "index.html");
const appIndex = path.join(appDir, "index.html");

if (!fs.existsSync(pwaIndex)) {
  console.error("finalize-dist: dist/index.html (PWA) not found — run vite build first");
  process.exit(1);
}

if (!fs.existsSync(marketingIndex)) {
  console.error("finalize-dist: dist/home/index.html not found");
  process.exit(1);
}

fs.mkdirSync(appDir, { recursive: true });
fs.renameSync(pwaIndex, appIndex);
fs.copyFileSync(marketingIndex, pwaIndex);

const swPath = path.join(dist, "sw.js");
if (fs.existsSync(swPath)) {
  let sw = fs.readFileSync(swPath, "utf8");
  sw = sw
    .replace(/\{url:"index\.html"/g, '{url:"app/index.html"')
    .replace(
      /createHandlerBoundToURL\("index\.html"\)/g,
      'createHandlerBoundToURL("app/index.html")',
    );
  fs.writeFileSync(swPath, sw);
}

const registerPath = path.join(dist, "registerSW.js");
if (fs.existsSync(registerPath)) {
  let register = fs.readFileSync(registerPath, "utf8");
  register = register.replace(/scope:\s*'\/'/, "scope: '/app/'");
  fs.writeFileSync(registerPath, register);
}

console.log("finalize-dist: marketing homepage at /, web app at /app/");
