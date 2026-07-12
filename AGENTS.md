# AGENTS.md

## Cursor Cloud specific instructions

This repo is primarily a **Vite + React 18 PWA** (a notepad-style grocery list app). It also contains:
- `api/share/` — Vercel serverless functions for share links, backed by `@vercel/kv` (only active on Vercel; degrades to a `503 "Share service not configured"` locally when `KV_REST_API_URL` is unset, so local sharing falls back to URL-hash / QR encoding).
- `GroceryListiOS/` — a native SwiftUI iOS app requiring macOS + Xcode. **Out of scope on this Linux VM** (cannot build/run here).

### Dev / build / test (web app)
Standard commands (see `package.json` and `README.md`):
- Dev server: `npm run dev` → serves on `http://localhost:5173`.
- Build: `npm run build` (runs `vite build` then `scripts/finalize-dist.mjs`).
- Tests: there is **no** test framework or lint script. The two "tests" are node verification scripts: `npm run verify-category-detection` and `npm run verify-product-resolution`.

### Non-obvious routing gotcha
There is no `lint` script and no ESLint config — do not expect `npm run lint` to exist.

The dev/preview server uses custom middleware in `vite.config.js` (`marketingStaticPages`), so routes matter:
- `/` → marketing homepage (static `home/index.html`).
- `/app` (or `/app/`) → the actual React grocery-list application. **Test the app at `/app`, not `/`.**
- `/privacy`, `/support` → static marketing pages; `/s/:id` → share landing.

### Python scripts
Some `scripts/*.py` and `npm run generate-*` / `ios:*` tasks require Python 3 (+ Pillow) and are only for asset generation; they are not needed to run or test the web app.
