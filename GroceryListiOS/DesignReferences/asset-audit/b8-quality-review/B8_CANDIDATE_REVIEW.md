# B8 correction batch — candidate review

**Date:** 2026-07-18  
**Status:** **Complete — installed into `Assets.xcassets` and approved**

All 10 candidates passed visual review at 1024 / 56pt / 44pt and replaced demoted B1/B2 PNGs.

See `APPROVED_PHOTOREALISTIC_PRODUCT_ASSETS.md` (B8 section).

## Paths

| Role | Path |
|------|------|
| Raw staged gens | `../staged-b8/` |
| Normalized 1024 cutouts | `full/` |
| 56pt thumbs | `thumbs-56/` |
| 44pt thumbs | `thumbs-44/` |
| Contact sheets | `b8-candidates-*-contact-sheet.png`, `b8-candidates-full-overview.png` |

## Candidate status (pre-approval)

| Product ID | Pri | Fix targeted | Candidate notes | Pass? |
|------------|-----|--------------|-----------------|-------|
| `plantains` | P0 | Banana→plantain confusion | v2: three thick angular cooking plantains side-by-side | Pending visual sign-off |
| `custard-apple` | P0 | Seedless interior | Whole + half with visible glossy black seeds | Pending visual sign-off |
| `long-beans` | P1 | Melted coil | Distinct pods with tips/seed bulges | Pending visual sign-off |
| `dill` | P1 | White halo | Magenta-chroma regen + key; recheck fringe at 44pt | Pending visual sign-off |
| `rosemary` | P1 | Halo + thyme confuse | Magenta-chroma regen; longer needles vs thyme | Pending visual sign-off |
| `thyme` | P1 | Halo + rosemary confuse | Magenta-chroma regen; tiny oval leaves | Pending visual sign-off |
| `green-beans` | P2 | Low fill / weak thumb | Dense snap-bean pile; fill ~0.65 | Pending visual sign-off |
| `zucchini` | P2 | Cucumber confuse | Pale stem ends + cut seed cavity | Pending visual sign-off |
| `mint` | P2 | Basil confuse | Serrated leaves, denser crop | Pending visual sign-off |
| `curry-leaves` | P2 | Sparse/halo | Multiple glossy compound sprigs | Pending visual sign-off |

## Gate before install

Do **not** run `install-generated-product-assets.py` until each candidate passes:

1. Product accuracy at 1024
2. Clean alpha (no white/magenta fringe) on checkerboard + dark UI
3. Recognizable at 56pt and 44pt
4. Distinct from nearest neighbors (banana/cucumber/basil/rosemary/thyme/cluster-beans)

After all 10 pass:

```bash
.venv-assets/bin/python scripts/install-generated-product-assets.py \
  --src GroceryListiOS/DesignReferences/asset-audit/b8-quality-review/full \
  --only plantains,custard-apple,long-beans,dill,rosemary,thyme,green-beans,zucchini,mint,curry-leaves
```

Then update `APPROVED_PHOTOREALISTIC_PRODUCT_ASSETS.md` (64 → 74) and shrink the A) section of `PRODUCT_ASSETS_TO_REGENERATE.md`.

## Explicitly out of scope for this batch

- B3 dairy/bakery
- B4 pantry
- B5 meat/seafood/frozen
- B6 drinks/snacks
- B7 household/health/baby/pet
- Remaining B8 legacy produce without photoreal assets
