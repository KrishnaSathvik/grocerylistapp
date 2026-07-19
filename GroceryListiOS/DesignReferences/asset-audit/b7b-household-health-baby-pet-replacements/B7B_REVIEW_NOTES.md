# B7B household / pet / floral + queue fills — review notes

**Date:** 2026-07-18  
**Status:** Complete — installed into `Assets.xcassets`

## Exact 10

`dog-food`, `cat-food`, `pet-shampoo`, `flowers`, `bagels`, `banana-bread`, `bread-loaf`, `butter`, `cheese`, `egg-noodles`

All priority household IDs missing. Fallbacks: dog-food, cat-food, pet-shampoo. Remaining B7: flowers. Queue fills: bagels, banana-bread, bread-loaf, butter, cheese, egg-noodles.

No new canonicals.

## Per-product results

| Product ID | Result | Regens | Notes |
|------------|--------|-------:|-------|
| dog-food | PASS | 4 | Blank kraft bag + large kibble; rejected text/brand labels |
| cat-food | PASS | 4 | Smaller pale bag + fine kibble; rejected text/fish art |
| pet-shampoo | PASS | 3 | Short amber bottle; distinct from tall blue shampoo |
| flowers | PASS | 1 | Rose/tulip bouquet in kraft wrap |
| bagels | PASS | 1 | Three plain bagels with holes |
| banana-bread | PASS | 1 | Loaf + slices + banana cue |
| bread-loaf | PASS | 1 | Sliced white sandwich loaf |
| butter | PASS | 1 | Stick in blank parchment |
| cheese | PASS | 1 | Cheddar wedge |
| egg-noodles | PASS | 1 | Dry yellow nest |

## Near-dup

`egg-noodles` ≈ `ground-turkey` (ahash) — visual false positive; kept.

## Simulator

Not run.
