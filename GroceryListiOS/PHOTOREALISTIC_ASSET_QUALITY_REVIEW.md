# Photorealistic asset quality review (B1/B2)

**Review date:** 2026-07-18

Strict visual audit of every newer B1/B2 product PNG at full 1024×1024 and at 44pt/56pt preview tiles. Assets were opened and inspected individually and via B1/B2-only contact sheets — not approved from filenames or catalog membership alone.

## Summary counts

| Metric | Count |
|--------|------:|
| Expected B1/B2 assets | 74 |
| Located on disk | 74 |
| Reviewed | 74 |
| **KEEP** | **64** |
| **REGENERATE_REQUIRED** | **10** |
| Technical near-dup pairs (ahash ≤ 8) among 74 | 3 (all reviewed as false positives or handled via regen) |
| Technical low fill (<35%) | 1 (`green-beans`) → regen |

## Priority tally (REGENERATE_REQUIRED only)

| Priority | Count | IDs |
|----------|------:|-----|
| P0 | 2 | `plantains`, `custard-apple` |
| P1 | 4 | `long-beans`, `dill`, `rosemary`, `thyme` |
| P2 | 4 | `green-beans`, `zucchini`, `mint`, `curry-leaves` |
| P3 | 0 | — |

## Contact sheets (evidence)

- `DesignReferences/asset-audit/b1-b2-quality-review/approved-b1-b2-full-resolution-contact-sheet.png`
- `DesignReferences/asset-audit/b1-b2-quality-review/approved-b1-b2-56pt-contact-sheet.png`
- `DesignReferences/asset-audit/b1-b2-quality-review/approved-b1-b2-44pt-contact-sheet.png`
- `DesignReferences/asset-audit/b1-b2-quality-review/b1-b2-regeneration-required-contact-sheet.png`

## REGENERATE_REQUIRED (detail)

### `custard-apple` — Custard Apple (B2) — **P0**

- Asset: `product-custard-apple.png`
- Product accuracy: **Fail**
- Photorealism: **Borderline**
- Small-size recognition: **Pass**
- Visual distinction: **Pass**
- Technical quality: **Pass**
- Final status: **REGENERATE_REQUIRED**
- Reason: Cut half shows white segmented flesh with no black seeds; real sitaphal segments contain large glossy black seeds. Interior reads artificial/seedless.
- Replacement direction: Whole bumpy green custard apple plus opened half with creamy segments and multiple large black seeds clearly visible.
- Suggested batch: B8

### `plantains` — Plantains (B1) — **P0**

- Asset: `product-plantains.png`
- Product accuracy: **Fail**
- Photorealism: **Pass**
- Small-size recognition: **Pass**
- Visual distinction: **Fail**
- Technical quality: **Pass**
- Final status: **REGENERATE_REQUIRED**
- Reason: Depicts thin curved green dessert bananas in a hand of fruit, not thicker/angular cooking plantains (plantain vs banana confusion).
- Replacement direction: Show thicker, longer, more angular green plantains (often with squared edges), clearly larger than dessert bananas; optional slight yellowing tip OK.
- Suggested batch: B8

### `dill` — Dill (B2) — **P1**

- Asset: `product-dill.png`
- Product accuracy: **Pass**
- Photorealism: **Borderline**
- Small-size recognition: **Borderline**
- Visual distinction: **Pass**
- Technical quality: **Fail**
- Final status: **REGENERATE_REQUIRED**
- Reason: Fine fronds dissolve into white-halo mist at edges; cutout fringe is visible and tips look fused/hazy rather than sharp dill leaflets.
- Replacement direction: Tied dill bunch with sharp feathery fronds, clean alpha edges, no white halo; keep distinct from fennel fronds if possible.
- Suggested batch: B8

### `long-beans` — Long Beans (B2) — **P1**

- Asset: `product-long-beans.png`
- Product accuracy: **Pass**
- Photorealism: **Fail**
- Small-size recognition: **Fail**
- Visual distinction: **Borderline**
- Technical quality: **Pass**
- Final status: **REGENERATE_REQUIRED**
- Reason: Coiled yardlong beans show fused/melted overlapping pods and overly smooth plastic surface; at 44pt reads as green rope/coil rather than vegetable pods.
- Replacement direction: Bundled or loosely looped yardlong beans with distinct tapered tips, visible seed bulges, natural texture; avoid melted coil mass.
- Suggested batch: B8

### `rosemary` — Rosemary (B2) — **P1**

- Asset: `product-rosemary.png`
- Product accuracy: **Pass**
- Photorealism: **Pass**
- Small-size recognition: **Fail**
- Visual distinction: **Borderline**
- Technical quality: **Fail**
- Final status: **REGENERATE_REQUIRED**
- Reason: Visible white halo/fringing around needle leaves from cutout; at 44pt collapses to tapered green blob easily confused with thyme.
- Replacement direction: Tied rosemary sprigs with crisp needle leaves, woody stems, clean alpha; emphasize longer needles vs thyme at thumb size.
- Suggested batch: B8

### `thyme` — Thyme (B2) — **P1**

- Asset: `product-thyme.png`
- Product accuracy: **Pass**
- Photorealism: **Pass**
- Small-size recognition: **Fail**
- Visual distinction: **Fail**
- Technical quality: **Fail**
- Final status: **REGENERATE_REQUIRED**
- Reason: White halo around fine leaves; at 44pt indistinguishable from rosemary (generic tied herb sprig).
- Replacement direction: Thyme bunch with many tiny oval leaves on thin woody stems, clean cutout; compose so leaf density differs clearly from rosemary needles.
- Suggested batch: B8

### `curry-leaves` — Curry Leaves (B2) — **P2**

- Asset: `product-curry-leaves.png`
- Product accuracy: **Pass**
- Photorealism: **Pass**
- Small-size recognition: **Fail**
- Visual distinction: **Borderline**
- Technical quality: **Fail**
- Final status: **REGENERATE_REQUIRED**
- Reason: Thin sprig with faint white halo; at 44pt becomes sparse green streak rather than recognizable curry-leaf compound leaflets.
- Replacement direction: Multiple curry-leaf sprigs with many small glossy leaflets filling frame; clean alpha; denser composition for thumb readability.
- Suggested batch: B8

### `green-beans` — Green Beans (B1) — **P2**

- Asset: `product-green-beans.png`
- Product accuracy: **Pass**
- Photorealism: **Pass**
- Small-size recognition: **Fail**
- Visual distinction: **Borderline**
- Technical quality: **Fail**
- Final status: **REGENERATE_REQUIRED**
- Reason: Lowest fill in set (~34.6%); at 44pt becomes indistinct green tied bundle easily confused with cluster-beans.
- Replacement direction: Larger fill pile or shorter snap-bean bundle with visible tips/seed bulges; keep distinct from cluster/long/flat beans.
- Suggested batch: B8

### `mint` — Mint (B2) — **P2**

- Asset: `product-mint.png`
- Product accuracy: **Pass**
- Photorealism: **Pass**
- Small-size recognition: **Fail**
- Visual distinction: **Fail**
- Technical quality: **Pass**
- Final status: **REGENERATE_REQUIRED**
- Reason: At 44pt collapses to green herb bunch nearly identical to basil; serrated leaf edges not readable at thumbnail.
- Replacement direction: Mint bunch emphasizing clear serrated leaf edges and brighter green; different orientation/crop than basil to stay distinct at 44pt.
- Suggested batch: B8

### `zucchini` — Zucchini (B1) — **P2**

- Asset: `product-zucchini.png`
- Product accuracy: **Pass**
- Photorealism: **Pass**
- Small-size recognition: **Fail**
- Visual distinction: **Fail**
- Technical quality: **Pass**
- Final status: **REGENERATE_REQUIRED**
- Reason: At 44pt nearly identical dark-green cylinder silhouette to cucumbers; mottling and pale stem ends disappear at app size.
- Replacement direction: Show zucchini with stronger pale blossom/stem ends and/or one cut showing pale seed cavity; emphasize thicker shape vs cucumber.
- Suggested batch: B8

## KEEP assets (passed full review)

| Product ID | Display name | Phase | Accuracy | Photorealism | 44pt | Distinction | Technical | Status | Notes |
|------------|--------------|-------|----------|--------------|------|-------------|-----------|--------|-------|
| `oranges` | Oranges | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `grapes` | Grapes | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `strawberries` | Strawberries | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `blueberries` | Blueberries | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `watermelon` | Watermelon | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `melon` | Melon | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `cherries` | Cherries | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `peaches` | Peaches | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `pears` | Pears | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `pineapple` | Pineapple | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `mangoes` | Mangoes | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | ahash near-dup vs sapota is false positive (yellow mango vs brown chikoo). |
| `kiwi` | Kiwi | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `coconut` | Coconut | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `pomegranate` | Pomegranate | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `papaya` | Papaya | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `carrots` | Carrots | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `sweet-potatoes` | Sweet Potatoes | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `corn` | Corn | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `broccoli` | Broccoli | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `cauliflower` | Cauliflower | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `cucumbers` | Cucumbers | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | Keep; cut face aids recognition. Pair with regenerated zucchini for clearer 44pt split. |
| `bell-peppers` | Bell Peppers | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `hot-peppers` | Hot Peppers | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `eggplant` | Eggplant | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `mushrooms` | Mushrooms | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `green-onions` | Green Onions | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `garlic` | Garlic | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `ginger` | Ginger | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `cabbage` | Cabbage | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `celery` | Celery | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `radishes` | Radishes | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `asparagus` | Asparagus | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `green-peas` | Green Peas | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `okra` | Okra | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `pumpkin` | Pumpkin | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `bottle-gourd` | Bottle Gourd | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | Keep; pale long lauki form distinct from cucumber/zucchini. |
| `chicken-drumsticks` | Chicken Drumsticks | B1 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `kale` | Kale | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `arugula` | Arugula | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | ahash vs bean-sprouts false positive (green leaves vs white sprouts). |
| `bok-choy` | Bok Choy | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `brussels-sprouts` | Brussels Sprouts | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `mixed-greens` | Mixed Greens | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | ahash vs bean-sprouts false positive; purple/red leaves help distinction. |
| `bean-sprouts` | Bean Sprouts | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | ahash vs arugula/mixed-greens false positive. |
| `leeks` | Leeks | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `fennel` | Fennel | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `parsnips` | Parsnips | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Fill ~38% but cream taper distinct from carrots. |
| `turnips` | Turnips | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `basil` | Basil | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Keep; cupped leaves clearer than mint at full size. Mint queued for regen for thumb distinction. |
| `parsley` | Parsley | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `fenugreek-leaves` | Fenugreek Leaves | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `mustard-greens` | Mustard Greens | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Minor fused-leaf AI softness (P3 polish only); still accurate frilly greens with pale ribs. |
| `bitter-gourd` | Bitter Gourd | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `ridge-gourd` | Ridge Gourd | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `ivy-gourd` | Ivy Gourd | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Keep; mottled oval tindora distinct from striped pointed gourd. |
| `pointed-gourd` | Pointed Gourd | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Fill ~38%; striped tapered shape distinct from ivy-gourd. |
| `taro` | Taro | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `cluster-beans` | Cluster Beans | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Fill ~35.5% borderline but variety shape/tips readable; monitor. |
| `flat-beans` | Flat Beans | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Fill ~39%; wide flat pods distinct. |
| `drumsticks-moringa` | Drumsticks (Moringa) | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Fill ~37.5%; clearly vegetable pods not chicken. |
| `jackfruit` | Jackfruit | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `guava` | Guava | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | — |
| `amla` | Amla | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Keep; chartreuse cluster with brown calyx — slight grape risk but stems/ribs help. |
| `sapota` | Sapota | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | ahash near-dup vs mangoes false positive; sandy brown skin + black seed OK. |
| `jamun` | Jamun | B2 | Pass | Pass | Pass | Pass | Pass | KEEP | Keep; oblong purple fruits — slight grape/olive risk at 44pt but calyx pits help. |

## Cross-asset similarity findings

| Pair | Finding | Disposition |
|------|---------|-------------|
| mangoes ≈ sapota (ahash 7) | Different colors/interiors (yellow mango vs brown chikoo) | Keep both |
| arugula / mixed-greens ≈ bean-sprouts (ahash 8) | Green leaves vs white sprouts | Keep all |
| cucumbers vs zucchini @44pt | Both dark green cylinders | Regenerate zucchini |
| basil vs mint @44pt | Both green tied bunches | Regenerate mint |
| rosemary vs thyme @44pt + halos | Fine-herb blobs + cutout fringe | Regenerate both |
| green-beans vs cluster-beans @44pt | Tied green bundles | Regenerate green-beans |
| ivy-gourd vs pointed-gourd | Oval mottled vs striped tapered | Keep both |
| jamun vs grapes (risk) | Oblong purple cluster | Keep jamun; note risk |

## Could not judge confidently

_None._ Every asset was opened at full resolution and reviewed via 44pt/56pt tiles and contact sheets.

## Confirmations

- No new product images were generated in this task.
- Failed B1/B2 PNGs were **not deleted** (remain on disk until future regen phase).
- No assets restored from Git.
- Nothing committed or pushed.
