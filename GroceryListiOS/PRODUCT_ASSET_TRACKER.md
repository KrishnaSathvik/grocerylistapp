# Product asset tracker

Source of truth for names: `GroceryList/Resources/asset_manifest.json`

Style: 1024×1024 transparent PNG, photorealistic grocery cutouts, no text/brands.

---

## Coverage framing (read this first)

| Metric | Meaning | Count (2026-07-17 Phase B1) |
|--------|---------|----------------------------:|
| **Catalog coverage** | Canonical product records in `product_catalog.json` | **146** |
| **Asset completion** | Current catalog records with usable bundled PNGs | **146 / 146** |
| **Phase B1 requested expansion** | Essential produce IDs from the B1 list | **40 / 40** (+ `chicken-drumsticks` correction) |
| **Overall grocery coverage** | Still incomplete beyond the catalog — herbs, many pantry/household items, and brands remain for later phases | **Incomplete** |

Do **not** describe the catalog as globally “complete” just because every current record has an asset.

---

## Summary

| | Count |
|---|------:|
| Categories | **17 / 17** complete |
| Canonical products | **146** |
| Finished product PNGs | **146** |
| Awaiting generation | **0** (within current catalog) |
| Exact duplicate PNG groups | **0** |
| Near-duplicate ahash pairs | **7** (reviewed — see audit) |

Counts derived from `asset_manifest.json` + `Assets.xcassets` (not guessed).

**Quality audit:** `PRODUCT_ASSET_AUDIT.md` and contact sheets under `DesignReferences/asset-audit/`.

---

## Phase A — completed (collision repair + tooling)

Resolver architecture, longer-alias precedence, stale `imageAssetName` reconciliation, export/prompt/audit/normalize tooling, and specific-product splits for milk/egg/apple/rice/beer/etc.

**Before Phase A expansion:** 48 canonical products
**After Phase A:** 108 canonical products

---

## Phase B1 — Essential produce (2026-07-17)

Solves the most visible issue: common fruits/vegetables no longer fall back to `category-produce`.

### Fruits added

`oranges`, `grapes`, `strawberries`, `blueberries`, `watermelon`, `melon`, `cherries`, `peaches`, `pears`, `pineapple`, `mangoes`, `kiwi`, `coconut`, `pomegranate`, `papaya`

### Vegetables added / covered

`carrots`, `corn`, `broccoli`, `cauliflower`, `cucumbers`, `zucchini`, `bell-peppers`, `hot-peppers`, `eggplant`, `mushrooms`, `garlic`, `ginger`, `green-beans`, `cabbage`, `celery`, `radishes`, `asparagus`, `green-peas`, `okra`, `pumpkin`, `plantains`, `bottle-gourd`

Already present from Phase A (kept): `sweet-potatoes`, `green-onions`

### Mapping correction in this phase

`chicken drumsticks` → `product-chicken-drumsticks` (no longer `product-chicken-wings`). Generic vegetable term `drumstick` / moringa is not mapped to chicken.

### Near-duplicate review (before adding B1 art)

| Pair | Decision |
|------|----------|
| oat milk vs conditioner | **Keep both** — false positive; carton+oats vs lavender hair bottle are distinct at 44pt |
| cottage cheese vs yogurt | **Replaced yogurt** — ramekin with strawberry swirl (was foil tub too similar to cottage cheese) |
| egg noodles vs rice noodles | **Keep both** — yellow vs white bundles remain distinguishable at 44pt |
| water vs orange juice | **Keep both** — clear vs opaque orange liquid |
| oat milk / shampoo / conditioner / pasta | **Keep** — silhouette ahash noise; colors/forms differ |
| toothpaste vs diaper cream | **Keep** — both tubes; acceptable for now |

### Produce still on category fallback (examples)

Herbs/greens/Indian produce not in B1: basil, mint, kale, bok choy, bitter gourd, ridge gourd, taro, etc. Unknown typed names still use category illustrations by design.

---

## Commands

```bash
node scripts/export-ios-catalog.mjs
node scripts/verify-product-resolution.mjs
python3 scripts/audit-product-assets.py
python3 GroceryListiOS/scripts/normalize-catalog-assets.py --only product
node scripts/write-product-mapping-audit.mjs

# Install staged generated art
.venv-assets/bin/python scripts/install-generated-product-assets.py \
  --src GroceryListiOS/DesignReferences/asset-audit/staged-b1 \
  --only mangoes,cucumbers,broccoli

xcodebuild test -scheme GroceryList -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Image-generation notes

- Product-specific prompts: `PRODUCT_IMAGE_PROMPTS.json` + `asset_manifest.json` `prompt` fields
- Do **not** use root `scripts/generate-product-assets.py` for final art (obsolete 80×80 placeholders)

---

## Existing-item remapping

No manual image-picker UI. `GroceryItem.imageAssetName` is a cached auto-resolution.

- `ItemAssetResolver` prefers a match from the **current item name**
- Powdered forms (`onion powder`, `garlic powder`) do not match fresh produce roots
- `GroceryItemService.reconcileImageAssets` refreshes stale caches when a list appears

---

## Simulator review (Phase B1)

Interactive review completed on iPhone 17 Pro Simulator. Screenshots + notes:

`DesignReferences/asset-audit/b1-simulator-review/`

- Main list light/dark: produce thumbnails correct and distinct
- Stores/Categories nested rows: product thumbs intentionally omitted by UI design
- Accessibility-large: assets OK; title hyphenation is a pre-existing layout pressure
- Re-run: `GroceryListiOS/scripts/review-b1-produce-simulator.sh`

---

## Next phases (not started)

1. **B2:** herbs, greens, Indian produce (~25–30)
2. **B3:** remaining pantry, snacks, household, baby, pet
3. **B4:** branded entries + approved branded artwork (separate design/legal pass)
