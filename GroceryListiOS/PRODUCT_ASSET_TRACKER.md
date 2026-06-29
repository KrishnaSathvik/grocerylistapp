# Product asset tracker

Source of truth for names: `GroceryList/Resources/asset_manifest.json`

Style: 1024×1024 transparent PNG, photorealistic single product, no text/brands.

---

## Summary

| | Count |
|---|------:|
| Categories | **16 / 16** complete |
| Products | **48 / 48** complete |
| Remaining | **0** |
| Pass 2 remakes | **5 / 5** done (2026-06-29) |
| Pass 3 improves | **13 / 13** done (2026-06-29) |

**Catalog coverage:** Every entry in `asset_manifest.json` has a bundled imageset in `Assets.xcassets`.

**Quality audit:** All 64 assets **Keep** after Pass 3. See `DesignReferences/asset-audit/ASSET_QUALITY_AUDIT.md`.

---

## Pass 2 — Quality remakes (5/5 done)

Regenerated 2026-06-29 for thumbnail readability at 44pt. Style refs: `product-eggs-brown`, `product-kimchi`, `product-bananas`.

| Asset | Test items | Result |
|-------|------------|--------|
| `product-eggs-white` | `eggs`, `white eggs` | Top-down grey carton, 6 visible white eggs |
| `product-milk-whole` | `milk`, `whole milk` | White carton, blue stripe + milk-drop icon, blue cap |
| `product-yogurt` | `yogurt` | Cup with peeled foil lid, visible yogurt inside |
| `product-gochujang` | `gochujang` | Squat red Korean paste tub + chili cue |
| `product-dog-food` | `dog food` | Brown bag with bone icon + kibble bowl |

Comparison grids: `DesignReferences/asset-audit/pass2-old-vs-new-44pt.png`, `pass2-old-vs-new-56pt.png`.  
Old assets backed up in `DesignReferences/asset-audit/pass2-old/`.

---

## Pass 3 — Quality improves (13/13 done)

Improved 2026-06-29 for thumbnail readability and variant distinctness. Simplified busy categories to 2–3 anchor items.

| Asset | Fix |
|-------|-----|
| `category-drinks` | 3 items: water, OJ, coffee cup |
| `category-dairy` | 3 items: milk carton, cheese, eggs — nothing clipped |
| `category-frozen` | 2 items: pizza + ice cream |
| `category-snacks` | 3 items: chips bag, popcorn, cookie |
| `category-pantry` | 3 items: pasta jar, rice bag, red can — more color |
| `category-misc` | Shopping basket + bag — distinct from pantry |
| `product-milk-oat` | Warm tan carton, large oat stalk graphics |
| `product-milk-soy` | Light green carton, large soy pod graphics |
| `product-cilantro` | Feathery leaves, tied stems |
| `product-spinach` | Dark broad crinkled leaves, no tie |
| `product-rice-white` | Clean clear plastic rice bag |
| `product-flour` | White paper bag + scoop (not burlap sack) |
| `product-frozen-pizza` | Pizza in box, no frost/shrink-wrap noise |

Comparison grids: `DesignReferences/asset-audit/pass3-old-vs-new-44pt.png`, `pass3-old-vs-new-56pt.png`.  
Old assets backed up in `DesignReferences/asset-audit/pass3-old/`.  
Processing script: `scripts/process-pass3-assets.py`.

**User replacements (2026-06-29):** Six category assets swapped for user-provided art via `scripts/install-user-category-assets.py`. Previous Pass 3 versions backed up in `DesignReferences/asset-audit/user-categories-old/`.

---

## Done — Final batch (10)

| # | Asset name | Display name | Test item |
|---|------------|--------------|-----------|
| 1 | `product-yogurt` | Yogurt | `yogurt` |
| 2 | `product-kimchi` | Kimchi | `kimchi` |
| 3 | `product-ice-cream` | Ice Cream | `ice cream` |
| 4 | `product-frozen-pizza` | Frozen Pizza | `frozen pizza` |
| 5 | `product-chips` | Chips | `chips` |
| 6 | `product-paper-towels` | Paper Towels | `paper towels` |
| 7 | `product-toilet-paper` | Toilet Paper | `toilet paper` |
| 8 | `product-dish-soap` | Dish Soap | `dish soap` |
| 9 | `product-diapers` | Diapers | `diapers` |
| 10 | `product-dog-food` | Dog Food | `dog food` |

---

## Batch history

| Batch | Theme | Count | Status |
|-------|--------|------:|--------|
| 1 | Produce | 8 | done |
| 2 | Dairy | 8 | done |
| 3 | Produce finish + bakery | 5 | done |
| 4 | Meat | 5 | done |
| 5 | Pantry + condiments | 6 | done |
| 6 | Drinks + seafood | 6 | done |
| 7 | Final (yogurt, kimchi, frozen, snacks, household, baby, pet) | 10 | done |
| 8 | Pass 2 quality remakes (5 Regenerate assets) | 5 | done |
| 9 | Pass 3 quality improves (13 Improve assets) | 13 | done |

---

## Categories (16/16) — all bundled

| Asset | Category id |
|-------|-------------|
| `category-produce` | produce |
| `category-dairy` | dairy |
| `category-meat` | meat |
| `category-seafood` | seafood |
| `category-bakery` | bakery |
| `category-deli` | deli |
| `category-frozen` | frozen |
| `category-pantry` | pantry |
| `category-snacks` | snacks |
| `category-condiments` | condiments |
| `category-drinks` | drinks |
| `category-household` | household |
| `category-health` | health |
| `category-baby` | baby |
| `category-pet` | pet |
| `category-misc` | misc |

No additional categories needed — matches web app `CATEGORIES` (16 ids).

---

## Products (48/48) — all bundled

See `product_catalog.json` for full list. Resolver maps ~700 web aliases → these 48 canonical products → category fallback only when no product keyword matches.

---

## What is NOT covered (by design)

| Gap | Behavior |
|-----|----------|
| Items with no product keyword match | Shows **category** illustration (e.g. unknown → `category-misc`) |
| ~650+ web `ITEM_ICONS` aliases without a canonical product | Category fallback via keyword detection |
| New grocery items not in catalog | `category-misc` or detected category |

**Future expansion (optional, not required for v1):**
- Add more canonical products to `CANONICAL_PRODUCTS` in `scripts/export-ios-catalog.mjs`, regenerate JSON, create matching assets
- Health category has no dedicated products yet (shampoo, toothpaste, etc.) — uses `category-health` fallback
- Deli only has `product-kimchi` — other deli items use `category-deli`

---

## Non-catalog assets (keep)

| Asset | Purpose |
|-------|---------|
| `onboarding_shop_smarter` etc. (4) | Onboarding heroes |
| `empty_list_illustration` etc. (3) | Empty states |
| `AppIcon`, `AccentColor` | App chrome |

---

## Verify after changes

```bash
node scripts/export-ios-catalog.mjs
# Run simulator with sample items from each category
xcodebuild test -only-testing:GroceryListTests/V1PolishProductFallbackTests
```
