# B6A beverages / snacks replacements — review notes

**Date:** 2026-07-18  
**Status:** Complete — installed into `Assets.xcassets`

## Selection / substitutions

| Requested | Selected | Reason |
|-----------|----------|--------|
| `cola` | — | No canonical; not in queue |
| `lemon-lime-soda` | — | No canonical; not in queue |
| `ginger-ale` | `ginger-ale` | In queue |
| `root-beer` | `root-beer` | In queue |
| `coconut-water` | `coconut-water` | In queue |
| `apple-juice` | `apple-juice` | In queue |
| `cranberry-juice` | `cranberry-juice` | In queue |
| `grape-juice` | `grape-juice` | In queue |
| `sports-drink` | — | No canonical; not in queue |
| `sparkling-water` | — | No separate ID |
| — | `juice-boxes` | Ordered fallback |
| — | `granola-bars` | Ordered fallback |
| — | `chips` | Fallback for `potato-chips` |
| — | `water` | Fallback for `bottled-water` |

No new canonicals added.

## Contact sheets

- `b6a-full-overview.png`
- `b6a-56pt-contact-sheet.png`
- `b6a-44pt-contact-sheet.png`
- Normalized cutouts: `full/`

## Per-product results

| Product ID | Result | Regens before pass | Notes |
|------------|--------|-------------------:|-------|
| `ginger-ale` | PASS | 1 | Pale-gold can + ginger cue |
| `root-beer` | PASS | 4 | Stout dark bottle; cream/brown label; no mug |
| `coconut-water` | PASS | 1 | Clear liquid + young green coconut; ≠ coconut milk can |
| `apple-juice` | PASS | 1 | Golden juice + apple slice; ≠ ACV sediment bottle |
| `cranberry-juice` | PASS | 1 | Ruby red + cranberries |
| `grape-juice` | PASS | 1 | Dark purple + grape cluster |
| `juice-boxes` | PASS | 3 | Two cartons + straws |
| `granola-bars` | PASS | 1 | Two oat bars, one broken |
| `chips` | PASS | 1 | Potato chips + generic yellow bag |
| `water` | PASS | 3 | Twin clear bottles; still water (no pink liquid) |

## Near-duplicates

- `product-apple-juice` ≈ `product-cranberry-juice` (ahash 7): **kept** — golden juice + apple slice vs ruby juice + cranberries; clearly distinct at 44pt.
- Prior pairs (`ground-turkey`/`frozen-vegetables`, `chicken-broth`/`coffee-creamer`, produce pairs) unchanged.

## Simulator

Not run (per batch instructions).
