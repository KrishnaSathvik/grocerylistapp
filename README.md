# 🛒 Grocery List

A modern notepad-style grocery list PWA with smart features.

![Grocery List](https://grocerylistapp.vercel.app/og-image.png)

## Features

- **15 Smart Categories** — Auto-detects category as you type (500+ keywords including Indian groceries)
- **Quantity Parsing** — Type "2x milk", "3 bananas", or "eggs x4"
- **Swipe to Delete** — Swipe left on mobile to reveal delete zone
- **Undo Delete** — 3.5 second recovery toast with Undo button
- **Drag to Reorder** — Grip handle to rearrange items (desktop)
- **Handwritten Checkmark** — Animated SVG draw + strikethrough
- **Pagination** — 10 items per page with smooth page-flip animation
- **Share / Copy** — Native share API or clipboard fallback
- **Dark Mode** — Auto-follows system preference via `prefers-color-scheme`
- **Paper Texture** — SVG noise overlay + corner curl + spiral binding
- **PWA** — Installable, works offline with service worker
- **SEO Optimized** — Open Graph, Twitter Cards, JSON-LD structured data

## Tech Stack

- React 18
- Vite 6
- vite-plugin-pwa (Workbox)
- CSS Variables for theming
- Zero external UI libraries

## Getting Started

```bash
# Install dependencies
npm install

# Run dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

Or connect your GitHub repo to [vercel.com](https://vercel.com) for automatic deployments.

## PWA Icons

Before deploying, add these icon files to `/public`:
- `favicon.ico` (32x32)
- `favicon-16.png` (16x16)
- `favicon-32.png` (32x32)
- `apple-touch-icon.png` (180x180)
- `icon-192.png` (192x192)
- `icon-512.png` (512x512)
- `og-image.png` (1200x630)

You can generate these from a single source using [realfavicongenerator.net](https://realfavicongenerator.net) or [favicon.io](https://favicon.io).

## Project Structure

```
grocery-list/
├── public/
│   ├── robots.txt
│   └── sitemap.xml
├── src/
│   ├── GroceryList.jsx    # Main component (all-in-one)
│   └── main.jsx           # React entry point
├── index.html             # HTML with SEO meta tags
├── package.json
├── vercel.json            # Vercel deployment config
├── vite.config.js         # Vite + PWA config
└── README.md
```

## License

MIT
