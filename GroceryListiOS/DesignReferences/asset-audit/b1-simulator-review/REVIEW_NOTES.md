# Phase B1 interactive simulator review

Captured 2026-07-17 on iPhone 17 Pro Simulator via `scripts/review-b1-produce-simulator.sh`  
Seed: launch argument `-B1ProduceReview` → list **B1 Produce Review** (20 items, 2 completed).

## Captures

| File | Mode | View |
|------|------|------|
| `b1-01-light-list-top.png` | Light / large | Main list rows |
| `b1-03-light-store.png` | Light / large | Stores tab |
| `b1-04-light-categories.png` | Light / large | Categories tab |
| `b1-05-dark-list.png` | Dark / large | Main list rows |
| `b1-06-dark-store.png` | Dark / large | Stores tab |
| `b1-07-dark-categories.png` | Dark / large | Categories tab |
| `b1-08-a11y-large-list.png` | Light / accessibility-large | Main list rows |
| `b1-09-a11y-large-store.png` | Light / accessibility-large | Stores tab |
| `b1-10-a11y-large-categories.png` | Light / accessibility-large | Categories tab |

## Findings

### Main list (primary thumbnail surface) — pass

- Dedicated produce assets render for Orange, Grapes, Strawberries, Watermelon, Cucumber, Zucchini, Broccoli, Cauliflower, Sweet potatoes, Bell peppers, Green chilies, Eggplant, Mushrooms, Cabbage, etc.
- Cucumber vs zucchini, broccoli vs cauliflower, bell peppers vs hot peppers are visually distinct at row size.
- Transparent cutouts read clearly on light cards and dark cards; no “disappearing” against tinted rows.
- No asset looked too small for the fixed ~38pt thumbnail — **no crop/fill normalization changes required**.
- Completed items: seed marks 2 picked up (`TO GET (18)`); completed treatment uses reduced opacity/saturation by design in `ItemRow`.

### Stores / Categories tabs — by design, not an asset failure

- Nested grouped rows (`GroupedItemRow` with `.nested`) **intentionally hide** product thumbnails; only store/category headers show logos/illustrations.
- Store grouping correctly splits Costco / Walmart / Indian Bazaar.
- Category grouping correctly places produce under Produce and chicken drumsticks under Meat & Poultry.

### Larger Dynamic Type — layout note (pre-existing)

- At `accessibility-large`, item titles hyphenate aggressively (`Or-ange`, `Straw-berries`) because title width is constrained by checkbox + thumbnail + stepper.
- Product thumbnails remain visible and correctly mapped; this is typography/layout pressure, not incorrect or undersized artwork.
- Not blocking for B1 asset release; optional follow-up is title layout, not asset regeneration.

## Verdict

**Ready to commit from an asset / resolution standpoint.** Interactive review confirms the original user-visible problem is fixed on the main shopping list in light and dark mode.
