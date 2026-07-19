# B5B meat / seafood / frozen replacements — review notes

**Date:** 2026-07-18  
**Status:** Complete — installed into `Assets.xcassets`

## Selection / substitutions

| Requested | Selected | Reason |
|-----------|----------|--------|
| `whole-chicken` | `chicken-breast` | Missing; next meat queue entry |
| `turkey-breast` | `turkey-breast` | In queue |
| `lamb` … `scallops` (8 IDs) | — | Do not exist as canonicals |
| — | `ground-turkey` | Ordered fallback |
| — | `ground-beef` | Ordered fallback |
| — | `steak` | Fallback for `beef-steak` |
| — | `pork` | Fallback for `pork-chops` |
| — | `sausage` | Ordered fallback |
| — | `frozen-pizza` | Ordered fallback |
| — | `ice-cream` | Next frozen queue fill |
| — | `hummus` | Next deli queue fill |

No new canonicals added.

## Contact sheets

- `b5b-full-overview.png`
- `b5b-56pt-contact-sheet.png`
- `b5b-44pt-contact-sheet.png`
- Normalized cutouts: `full/`

## Per-product results

| Product ID | Result | Regens before pass | Notes |
|------------|--------|-------------------:|-------|
| `chicken-breast` | PASS | 1 | Two raw boneless fillets |
| `turkey-breast` | PASS | 1 | Raw pale lean portions (not deli) |
| `ground-turkey` | PASS | 1 | Pale strand mound |
| `ground-beef` | PASS | 1 | Deep-red strand mound |
| `steak` | PASS | 1 | Raw marbled beef steak |
| `pork` | PASS | 1 | Two bone-in pork chops |
| `sausage` | PASS | 1 | Four linked raw sausages |
| `frozen-pizza` | PASS | 1 | Whole pizza, no box |
| `ice-cream` | PASS | 3 | Twin scoops, magenta cutout |
| `hummus` | PASS | 1 | Open blank tub + oil swirl |

## Near-duplicates

- `product-ground-turkey` ≈ `product-frozen-vegetables` (ahash 5): **kept** — visually unrelated (pale ground meat vs colorful frosted veg).
- Prior `chicken-broth`/`coffee-creamer` and produce pairs unchanged.

## Simulator

Not run (per batch instructions).
