# Product asset audit

Generated from `GroceryListiOS/GroceryList/Resources/product_catalog.json` and `Assets.xcassets`.

## Summary

| Metric | Count |
|---|---:|
| Canonical products | 146 |
| Bundled product imagesets | 146 |
| Products with usable PNG | 146 |
| Missing imagesets | 0 |
| Missing PNG files | 0 |
| Orphan imagesets | 0 |
| Wrong dimensions | 0 |
| Missing alpha | 0 |
| Nearly blank | 0 |
| Low visual fill (< 35%) | 0 |
| Exact duplicate groups | 0 |
| Near-duplicate pairs (ahash ≤ 8) | 7 |

## Missing imagesets

_None._

## Missing PNG files

_None._

## Orphan product imagesets

_None._

## Wrong dimensions (expected 1024×1024)

_None._

## Missing alpha channel

_None._

## Nearly blank images

_None._

## Low visual fill

_None._

## Exact duplicate file content

_None._

## Near-duplicate artwork

- `product-milk-oat` ≈ `product-conditioner` (hamming 1)
- `product-water` ≈ `product-orange-juice` (hamming 2)
- `product-milk-oat` ≈ `product-shampoo` (hamming 3)
- `product-egg-noodles` ≈ `product-rice-noodles` (hamming 4)
- `product-shampoo` ≈ `product-conditioner` (hamming 4)
- `product-toothpaste` ≈ `product-diaper-cream` (hamming 5)
- `product-pasta` ≈ `product-conditioner` (hamming 8)

## Contact sheets

- `DesignReferences/asset-audit/contact-sheet-44pt.png`
- `DesignReferences/asset-audit/contact-sheet-56pt.png`

## Manual near-duplicate review (Phase B1)

Reviewed source PNGs and the 44pt contact sheet. ahash flags are not treated as proof of reuse.

| Pair | Verdict | Action |
|------|---------|--------|
| `milk-oat` ≈ `conditioner` | False positive — carton with oat graphic vs lavender hair bottle | Kept |
| `cottage-cheese` ≈ `yogurt` | Was a real 44pt problem (both foil tubs) | **Replaced `yogurt`** with strawberry-swirl ramekin |
| `egg-noodles` ≈ `rice-noodles` | Same bundle composition; color (yellow vs white) is enough at 44pt | Kept |
| `water` ≈ `orange-juice` | Both bottles; clear vs opaque orange liquid | Kept |
| `milk-oat` ≈ `shampoo` | Silhouette noise; forms differ | Kept |
| `shampoo` ≈ `conditioner` | Related personal-care bottles; color/graphic differ | Kept |
| `toothpaste` ≈ `diaper-cream` | Tube family; acceptable for now | Kept |
| `pasta` ≈ `conditioner` | Weak ahash hit; visually unrelated | Kept |

Cottage-cheese vs yogurt no longer appears in the automated near-duplicate list after the yogurt replacement.

