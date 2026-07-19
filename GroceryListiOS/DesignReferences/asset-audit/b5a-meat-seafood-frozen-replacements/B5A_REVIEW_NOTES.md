# B5A meat / seafood / frozen replacements — review notes

**Date:** 2026-07-18  
**Status:** Complete — installed into `Assets.xcassets`

## Selection / substitutions

Requested wishlist vs actual queue entries:

| Requested | Resolved / substituted | Reason |
|-----------|------------------------|--------|
| `chicken-wings` | `chicken-wings` | In queue |
| `chicken-thighs` | `chicken-thighs` | In queue |
| `rotisserie-chicken` | `rotisserie-chicken` | In queue |
| `chicken-broth` | `chicken-broth` | In queue |
| `tuna` | `tuna-steak` | No `tuna` ID; catalog aliases are fresh steak (`tuna steak`, `ahi tuna`, `tuna fillet`) |
| `fish-sticks` | `salmon` | Canonical does not exist; next seafood queue entry |
| `frozen-vegetables` | `frozen-vegetables` | In queue |
| `pizza-rolls` | `pizza-rolls` | In queue |
| `french-fries` | `shrimp` | Canonical does not exist; next seafood queue entry |
| `chicken-nuggets` | `bacon` | Canonical does not exist; next meat queue entry |

No new canonicals added.

## Contact sheets

- `b5a-full-overview.png`
- `b5a-56pt-contact-sheet.png`
- `b5a-44pt-contact-sheet.png`
- Normalized cutouts: `full/`

## Per-product results

| Product ID | Result | Regens before pass | Notes |
|------------|--------|-------------------:|-------|
| `chicken-wings` | PASS | 1 | Drumettes + flats; distinct from drumsticks |
| `chicken-thighs` | PASS | 1 | Broad rounded thighs |
| `rotisserie-chicken` | PASS | 1 | Whole golden cooked bird, no tray label |
| `chicken-broth` | PASS | 1 | Cream/yellow carton + chicken silhouette, no text |
| `tuna-steak` | PASS | 1 | Deep red raw steak (fresh tuna canonical) |
| `salmon` | PASS | 1 | Orange-pink fillet; distinct from tuna |
| `shrimp` | PASS | 3 | Raw grayish shell-on cluster (v3) |
| `frozen-vegetables` | PASS | 1 | Frosted peas/carrots/corn/beans |
| `pizza-rolls` | PASS | 1 | Pillow rolls + cheese/tomato interior cue |
| `bacon` | PASS | 1 | Raw pink/white striped strips |

## Near-duplicates

Audit flagged `product-chicken-broth` ≈ `product-coffee-creamer` (ahash hamming 6). Visually distinct at full/44pt: broth is tall cream/yellow carton with chicken silhouette; creamer is plastic bottle. **Kept both.**

## Simulator

Not run (per batch instructions).
