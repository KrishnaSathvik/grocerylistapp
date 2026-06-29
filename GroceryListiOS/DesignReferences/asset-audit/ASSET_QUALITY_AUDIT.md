# Asset Quality Audit — 64 Bundled Grocery Assets

**Date:** 2026-06-28 (Pass 1) · **Pass 2:** 2026-06-29 · **Pass 3:** 2026-06-29  
**Scope:** 48 product + 16 category assets in `Assets.xcassets`  
**Goal:** Thumbnail readability at 44–56pt in `ItemRow` (`ItemThumbnailView`, size 44)

## Summary (after Pass 3 — complete)

| Verdict | Count | Action |
|---------|------:|--------|
| **Keep** | 64 | All assets pass audit |
| **Improve** | 0 | Pass 3 complete |
| **Regenerate** | 0 | Pass 2 complete |

**Pass 3 result:** All 13 Improve assets remade and promoted to **Keep**. Build + `V1PolishProductFallbackTests` passed. **Asset quality audit is complete.**

## Preview Grids

Generated in this folder for manual review:

| File | Description |
|------|-------------|
| `audit-all-64-at-48pt.png` | Full set at 48pt with Keep/Improve/Regenerate labels |
| `audit-categories-44pt.png` | Categories at 44pt |
| `audit-categories-56pt.png` | Categories at 56pt |
| `audit-products-44pt.png` | Products at 44pt |
| `audit-products-56pt.png` | Products at 56pt |
| `compare-high-risk-products-56pt.png` | 18 flagged products side-by-side |
| `compare-blurry-categories-56pt.png` | 8 flagged categories side-by-side |
| `compare-eggs-white-vs-brown-56pt.png` | Egg variant pair |
| `compare-milk-variants-56pt.png` | All 4 milk variants |
| `compare-rice-variants-56pt.png` | Rice variant pair |
| `pass2-old-vs-new-44pt.png` | Pass 2 before/after at 44pt |
| `pass2-old-vs-new-56pt.png` | Pass 2 before/after at 56pt |
| `pass3-old-vs-new-44pt.png` | Pass 3 before/after at 44pt (all 13) |
| `pass3-old-vs-new-56pt.png` | Pass 3 before/after at 56pt (all 13) |

---

## Pass 2 — Completed (2026-06-29)

Regenerated 5 assets only. No catalog or resolver changes.

| Asset | Old issue | Pass 2 fix | 44pt check |
|-------|-----------|------------|------------|
| `product-eggs-white` | Invisible white eggs | Top-down grey carton, 6 white eggs, soft shadows | Pass |
| `product-milk-whole` | Black panel vanished | White carton, blue stripe, milk-drop icon, blue cap | Pass |
| `product-yogurt` | Harsh shadow, generic cylinder | Peeled foil lid, visible yogurt, even lighting | Pass |
| `product-gochujang` | Generic red jar | Squat red tub, paste texture, chili cue | Pass |
| `product-dog-food` | Blank pouch | Brown bag + bone icon + kibble bowl | Pass |

Technical validation: 1024×1024 RGBA PNG, corner alpha = 0, no baked checkerboard.  
Old assets: `pass2-old/`. Processing script: `scripts/process-pass2-assets.py`.

---

---

## Pass 3 — Completed (2026-06-29)

Improved 13 assets only. No catalog or resolver changes.

| Asset | Old issue | Pass 3 fix | 44pt check |
|-------|-----------|------------|------------|
| `category-drinks` | 6 thin items cluttered | 3 anchors: water, OJ, coffee | Pass |
| `category-dairy` | Busy, carton clipped | 3 items: milk, cheese, eggs | Pass |
| `category-frozen` | Too many secondary items | Pizza + ice cream only | Pass |
| `category-snacks` | 6+ snacks blur together | Chips bag, popcorn, cookie | Pass |
| `category-pantry` | Washed-out beige palette | Pasta jar, rice bag, red can | Pass |
| `category-misc` | Blurred with pantry | Shopping basket + bag | Pass |
| `product-milk-oat` | Faint oat icon | Warm tan carton, large oat graphics | Pass |
| `product-milk-soy` | Weak green-cap cue | Light green carton, large soy pods | Pass |
| `product-cilantro` | Generic green bunch | Feathery leaves, tied stems | Pass |
| `product-spinach` | Confusable with cilantro | Broad dark crinkled leaves | Pass |
| `product-rice-white` | Cutout artifacts | Clean clear plastic rice bag | Pass |
| `product-flour` | Same burlap as basmati | White paper bag + scoop | Pass |
| `product-frozen-pizza` | Frost/shrink-wrap noise | Pizza in open box, clean toppings | Pass |

Technical validation: 1024×1024 RGBA PNG, corner alpha = 0, no baked checkerboard.  
Old assets: `pass3-old/`. Processing script: `scripts/process-pass3-assets.py`.

---

## Pass 3 Queue (13 Improve — completed)

| Priority | Asset | Status |
|---------:|-------|--------|
| 1 | `category-drinks` | **Done → Keep** |
| 2 | `category-dairy` | **Done → Keep** |
| 3 | `category-frozen` | **Done → Keep** |
| 4 | `category-snacks` | **Done → Keep** |
| 5 | `category-pantry` | **Done → Keep** |
| 6 | `category-misc` | **Done → Keep** |
| 7 | `product-milk-oat` | **Done → Keep** |
| 8 | `product-milk-soy` | **Done → Keep** |
| 9 | `product-cilantro` | **Done → Keep** |
| 10 | `product-spinach` | **Done → Keep** |
| 11 | `product-rice-white` | **Done → Keep** |
| 12 | `product-flour` | **Done → Keep** |
| 13 | `product-frozen-pizza` | **Done → Keep** |

---

## Pass 1 Archive — Priority Remake List (superseded by Pass 2)

The 5 Regenerate items below were remade in Pass 2 and are now **Keep**.

| Priority | Asset | Pass 1 verdict | Pass 2 status |
|---------:|-------|----------------|---------------|
| 1 | `product-eggs-white` | Regenerate | **Done → Keep** |
| 2 | `product-milk-whole` | Regenerate | **Done → Keep** |
| 3 | `product-yogurt` | Regenerate | **Done → Keep** |
| 4 | `product-dog-food` | Regenerate | **Done → Keep** |
| 5 | `product-gochujang` | Regenerate | **Done → Keep** |

---

## Full Audit Sheet — Categories (16)

| Asset | Recognizable? | Distinct? | Good at 44pt? | Verdict | Notes |
|-------|:-:|:-:|:-:|---------|-------|
| `category-produce` | yes | yes | yes | **Keep** | Vibrant lettuce, tomato, carrot, banana — strong silhouette |
| `category-dairy` | yes | yes | yes | **Keep** | Pass 3: milk + cheese + eggs, nothing clipped |
| `category-meat` | yes | yes | yes | **Keep** | Red/pink cluster reads as meat; distinct from seafood |
| `category-seafood` | yes | yes | yes | **Keep** | Salmon + shrimp + lemon — excellent contrast vs meat |
| `category-bakery` | yes | yes | yes | **Keep** | Bread, baguette, croissant, bagel — warm, iconic shapes |
| `category-deli` | yes | yes | yes | **Keep** | Ham slices + wrap cross-section — clear deli signal |
| `category-frozen` | yes | yes | yes | **Keep** | Pass 3: pizza + ice cream only |
| `category-pantry` | yes | yes | yes | **Keep** | Pass 3: pasta jar, rice bag, red can |
| `category-snacks` | yes | yes | yes | **Keep** | Pass 3: chips, popcorn, cookie |
| `category-condiments` | yes | yes | yes | **Keep** | Red sauce jar + olive oil bottle — high contrast |
| `category-drinks` | yes | yes | yes | **Keep** | Pass 3: water, OJ, coffee — 3 clear anchors |
| `category-household` | yes | yes | yes | **Keep** | Paper towels + spray + sponge — distinct from health |
| `category-health` | yes | yes | yes | **Keep** | Toothbrush + shampoo — clearly personal care |
| `category-baby` | yes | yes | yes | **Keep** | Diapers + bottle — instant read |
| `category-pet` | yes | yes | yes | **Keep** | Kibble bag + bowl + bone — strong pet signal |
| `category-misc` | yes | yes | yes | **Keep** | Pass 3: shopping basket — distinct from pantry |

---

## Full Audit Sheet — Products (48)

| Asset | Recognizable? | Distinct? | Good at 44pt? | Verdict | Notes |
|-------|:-:|:-:|:-:|---------|-------|
| `product-milk-whole` | yes | yes | yes | **Keep** | Pass 2: white carton, blue stripe, milk-drop icon |
| `product-milk-oat` | yes | yes | yes | **Keep** | Pass 3: warm tan carton, large oat graphics |
| `product-milk-almond` | yes | yes | yes | **Keep** | Almond icon large enough to survive 44pt |
| `product-milk-soy` | yes | yes | yes | **Keep** | Pass 3: green carton, large soy pod graphics |
| `product-eggs-white` | yes | yes | yes | **Keep** | Pass 2: top-down grey carton, 6 visible white eggs |
| `product-eggs-brown` | yes | yes | yes | **Keep** | Six brown eggs, high contrast — reference quality |
| `product-butter` | yes | yes | yes | **Keep** | Yellow stick on dish — clear |
| `product-cheese` | yes | yes | yes | **Keep** | Swiss wedge with holes — iconic |
| `product-yogurt` | yes | yes | yes | **Keep** | Pass 2: peeled foil lid, visible yogurt inside |
| `product-bananas` | yes | yes | yes | **Keep** | Bold yellow silhouette |
| `product-apples` | yes | yes | yes | **Keep** | Red cluster — instant read |
| `product-tomatoes` | yes | yes | yes | **Keep** | Vine tomatoes — distinctive |
| `product-onions` | yes | yes | yes | **Keep** | Yellow onion + half — clear |
| `product-potatoes` | yes | yes | yes | **Keep** | Brown texture reads well |
| `product-cilantro` | yes | yes | yes | **Keep** | Pass 3: feathery leaves, tied stems |
| `product-spinach` | yes | yes | yes | **Keep** | Pass 3: broad dark leaves, distinct from cilantro |
| `product-avocados` | yes | yes | yes | **Keep** | Pit cross-section is strong differentiator |
| `product-lemons` | yes | yes | yes | **Keep** | Yellow + slice — clear |
| `product-bread-loaf` | yes | yes | yes | **Keep** | Crusty loaf + slice |
| `product-bagels` | yes | yes | yes | **Keep** | Sesame bagels — distinct from bread |
| `product-tortillas` | yes | yes | yes | **Keep** | Stacked flat rounds |
| `product-naan` | yes | yes | yes | **Keep** | Char spots distinguish from tortillas |
| `product-chicken-breast` | yes | yes | yes | **Keep** | Pink breast on tray |
| `product-ground-beef` | yes | yes | yes | **Keep** | Red mound — distinct from steak |
| `product-steak` | yes | yes | yes | **Keep** | Marbled red cut |
| `product-bacon` | yes | yes | yes | **Keep** | Streaky strips — unique shape |
| `product-pork` | yes | yes | yes | **Keep** | Pale pink chops vs red steak |
| `product-salmon` | yes | yes | yes | **Keep** | Orange fillet — strong color |
| `product-shrimp` | yes | yes | yes | **Keep** | Pink shrimp pile |
| `product-rice-basmati` | yes | yes | yes | **Keep** | Burlap sack — excellent thumbnail |
| `product-rice-white` | yes | yes | yes | **Keep** | Pass 3: clean clear plastic bag |
| `product-pasta` | yes | yes | yes | **Keep** | Spaghetti bundle — tall but readable |
| `product-flour` | yes | yes | yes | **Keep** | Pass 3: white paper bag + scoop |
| `product-olive-oil` | yes | yes | yes | **Keep** | Tall bottle + cork — clear |
| `product-gochujang` | yes | yes | yes | **Keep** | Pass 2: squat red tub + chili cue |
| `product-kimchi` | yes | yes | yes | **Keep** | Red cabbage in jar — excellent |
| `product-coffee` | yes | yes | yes | **Keep** | Bean sack + cup |
| `product-tea` | yes | yes | yes | **Keep** | Green tin + cup — distinct from coffee |
| `product-water` | yes | yes | yes | **Keep** | Clear bottle + blue cap |
| `product-orange-juice` | yes | yes | yes | **Keep** | Orange liquid bottle |
| `product-ice-cream` | yes | yes | yes | **Keep** | Three scoops — colorful, clear |
| `product-frozen-pizza` | yes | yes | yes | **Keep** | Pass 3: pizza in box, no frost noise |
| `product-chips` | yes | yes | yes | **Keep** | Yellow bag — strong color block |
| `product-paper-towels` | yes | yes | yes | **Keep** | Single tall roll |
| `product-toilet-paper` | yes | yes | yes | **Keep** | Two-roll stack — distinct from towels |
| `product-dish-soap` | yes | yes | yes | **Keep** | Green bottle — clear |
| `product-diapers` | yes | yes | yes | **Keep** | Stacked diapers |
| `product-dog-food` | yes | yes | yes | **Keep** | Pass 2: bone icon bag + kibble bowl |

---

## Variant Pair Analysis

### Eggs: white vs brown
- **Brown:** Keep — six visible brown eggs, top-down, high contrast.
- **White:** Regenerate — posterized high-contrast style; white eggs merge with white carton. Users cannot tell white vs brown at a glance.

**Remake direction:** Match brown-eggs composition (top-down carton, 6 eggs) but use a **slightly grey/tan carton** or **soft shadow under each egg** so white shells remain visible at 44pt.

### Milk: whole / oat / almond / soy
- **Whole:** Regenerate — needs a white/light carton with visible "milk" cue (drop icon or light blue accent panel), not a black face.
- **Almond:** Keep — almond illustration survives scaling.
- **Oat & Soy:** Improve — push carton color further apart (oat = warm tan, soy = light green tint); enlarge plant icons to 30%+ of face area.

### Rice: white vs basmati
- **Basmati:** Keep — burlap sack is distinct and thumbnail-friendly.
- **White:** Improve — keep clear-bag concept (good distinctness from sack) but clean up top-edge masking artifacts.

### Cilantro vs spinach
- Both Improve — at 44pt they collapse to "green bunch."
- **Remake direction:** Cilantro = feathery delicate leaves + tied stems. Spinach = broader crinkled leaves, darker green, no tie.

### Flour vs rice-basmati
- Both use burlap sacks — 31% pixel diff at 64px. Flour is acceptable but could use a **paper bag** or **flour scoop** to differentiate from rice sack.

### Paper towels vs toilet paper
- Both Keep — single roll vs two-roll stack reads clearly at 44pt (26% diff).

### Meat vs seafood (categories)
- Both Keep — red/pink meat cluster vs orange/white seafood + lemon are well separated.

### Bakery vs pantry (categories)
- Both readable; pantry is more neutral/busy. Pantry → Improve.

### Household vs health (categories)
- Both Keep — cleaning supplies vs toothbrush/shampoo are distinct enough.

---

## Style Consistency Notes

The set is **mostly cohesive** — soft-lit product photography / 3D hybrid on transparent backgrounds. Minor inconsistencies:

1. **Extreme contrast assets** (`product-eggs-white`, `product-yogurt`, `product-milk-whole`) use harsh shadow treatment unlike the rest.
2. **Fill ratio** — tall narrow items (`milk-*`, `olive-oil`, `water`, `dish-soap`, `paper-towels`) occupy ~18–25% of frame; they read smaller in 44pt circles than produce clusters.
3. **Category composition pattern** — most categories use 4–6 item clusters; simpler 2–3 item compositions would scale better.

**Recommendation for remakes:** Match the `product-eggs-brown`, `product-kimchi`, `product-bananas` family — centered subject, 60–75% frame fill, soft shadow, no harsh half-object blackout.

---

## Pass 2 — Regeneration Brief (5 assets)

When ready to regenerate, use these directions:

| Asset | Visual direction |
|-------|------------------|
| `product-eggs-white` | Top-down open carton, 6 white eggs, light grey carton for contrast, soft shadow per egg |
| `product-milk-whole` | White carton, light blue accent stripe or milk-drop icon, blue cap, no black panels |
| `product-yogurt` | White plastic cup, foil lid partially peeled, hint of white yogurt inside, even soft lighting |
| `product-gochujang` | Short wide red tub with **distinctive shape** (Korean paste tub profile) plus visible paste texture; optionally small chili icon (no text) |
| `product-dog-food` | Brown kibble bag with **bone or paw icon**, visible kibble through cutout or bowl beside bag |

---

## Next Steps

1. ~~**Pass 2:** Regenerate the 5 **Regenerate** assets~~ — **Done (2026-06-29)**
2. ~~**Pass 3:** Improve the 13 **Improve** assets~~ — **Done (2026-06-29)**
3. Optional: add `AssetQualityTests` snapshot comparing thumbnail render at 44pt for regression.
4. Optional: regenerate `audit-all-64-at-48pt.png` with all-Keep labels for final sign-off.
