<p align="center">
  <img src="public/logo.png" alt="Grocery List Logo" width="128" height="128" />
</p>

<h1 align="center">Grocery List</h1>

<p align="center">A modern notepad-style grocery list PWA with smart features.</p>

<p align="center">
  <img src="public/og-image.png" alt="Grocery List Preview" width="600" />
</p>

## Features

- **15 Smart Categories** — Auto-detects category as you type (1,300+ keywords covering American, Indian, and Asian groceries)
- **1,280+ Item Emojis** — Instant emoji preview and icons for every grocery item
- **18 Stores** — Costco, Walmart, Target, Trader Joe's, Whole Foods Market, Kroger, ALDI, H-E-B, Amazon Fresh, Publix, Gerbes, Sam's Club, Indian Bazaar, Pan Asia Supermarket, Patel Brothers, H Mart, 99 Ranch Market, Sprouts Farmers Market
- **Store Tagging** — Assign items to stores with "@costco" or "@hmart", group by store view with favicons
- **Quantity Parsing** — Type "2x milk", "3 bananas", or "eggs x4"
- **Smart Sorting** — Checked items automatically move to the bottom
- **Swipe to Delete** — Swipe left on mobile to reveal delete zone
- **Undo Delete** — 3.5 second recovery toast with Undo button
- **Drag to Reorder** — Grip handle to rearrange items (desktop)
- **Handwritten Checkmark** — Animated SVG draw + strikethrough
- **Pagination** — 12 items per page with smooth page-flip animation
- **Share / Copy** — Native share API or clipboard fallback
- **Dark Mode** — Auto-follows system preference via `prefers-color-scheme`
- **Paper Texture** — SVG noise overlay + corner curl + spiral binding
- **PWA** — Installable, works offline with service worker
- **SEO Optimized** — Open Graph, Twitter Cards, JSON-LD structured data

## Grocery Coverage

Comprehensive coverage across all categories with Indian and Asian specialty items:

| Category | Examples |
|----------|----------|
| **Produce** | Standard + lauki, karela, arbi, turai, amla, chikoo, sitaphal, edamame, bok choy |
| **Dairy** | Standard + paneer, ghee, dahi, malai, khoya, shrikhand, lassi |
| **Meat & Seafood** | Standard + mutton, goat, keema + pomfret, rohu, surmai, bangda, hilsa |
| **Pantry & Grains** | Standard + basmati, poha, maggi, dal varieties + bajra, ragi, jowar, makhana, sattu |
| **Condiments & Spices** | Standard + garam masala, hing, kasuri methi, 15+ masala blends, achar, chutneys |
| **Snacks** | Standard + murukku, chakli, khakhra, gathiya, namak para, kurkure, parle-g |
| **Drinks** | Standard + rooh afza, jaljeera, thandai, badam milk, thumbs up, limca, rasna, tang |
| **Household** | Standard + agarbatti, harpic, phenyl + broom, mop, toilet cleaner |

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

All icons are included in `/public`:
- `favicon.ico` — Browser tab icon
- `favicon.svg` — SVG favicon for modern browsers
- `favicon-16x16.png` / `favicon-32x32.png` — PNG fallbacks
- `apple-touch-icon.png` (180x180) — iOS home screen
- `android-chrome-192x192.png` / `android-chrome-512x512.png` — Android PWA
- `logo.png` — App header logo
- `og-image.png` (1200x630) — Social sharing preview

## Project Structure

```
grocery-list/
├── public/
│   ├── robots.txt
│   └── sitemap.xml
├── src/
│   ├── components/
│   │   ├── CheckMark.jsx      # Animated check circle
│   │   ├── GroceryItem.jsx    # Item row (unchecked + checked variants)
│   │   ├── Header.jsx         # Title, item count, view toggle, share
│   │   ├── InputBar.jsx       # Text input, emoji preview, store autocomplete
│   │   ├── ListView.jsx       # List view with unchecked/checked sections
│   │   ├── Pagination.jsx     # Prev/next buttons, dots, page label
│   │   ├── StoreView.jsx      # Store-grouped view with headers
│   │   ├── SwipeRow.jsx       # Swipe-to-delete gesture wrapper
│   │   └── Toast.jsx          # Fixed-position toast with undo
│   ├── data/
│   │   ├── categories.js      # Category definitions + keyword lists
│   │   ├── itemEmojis.js      # Item emoji mappings + lookup function
│   │   └── stores.js          # Store definitions + favicon helper
│   ├── GroceryList.jsx        # Root component (state, handlers, composition)
│   ├── itemIcons.js           # Item icon detection
│   ├── notepadStyles.js       # Global CSS styles
│   ├── utils.js               # detectCategory(), parseQty()
│   └── main.jsx               # React entry point
├── index.html                 # HTML with SEO meta tags
├── package.json
├── vercel.json                # Vercel deployment config
├── vite.config.js             # Vite + PWA config
└── README.md
```

## License

MIT
