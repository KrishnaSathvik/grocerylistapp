# Stage 1 ItemRow — Candidate B revision (visual gate)

**Date:** 2026-07-18  
**Status:** Awaiting visual review — **Stage 2 paused**  
**Prior:** Stage 1 optional/RTL closure was green; Candidate B composition then revised.

## Design change

Removed the old Candidate B (stepper on an isolated full-width third row).

### Candidate definitions (revised)

| Candidate | Structure |
|---|---|
| **A** | `checkbox \| thumb \| title/category \| stepper \| edit` (fully inline) |
| **B** | `checkbox \| thumb \| title \| edit` / `category \| stepper` on the secondary line |
| **C** | `checkbox \| thumb \| title/category` / `stepper \| edit` (extreme only) |

B keeps the row compact: product name first, category under it, quantity trailing on that same lower line, edit on the title row.

### Implementation notes

- `AdaptiveItemRowLayout.planSplitStepper` places stepper on the metadata line (trailing), not below the text block.
- `candidateBMinHeight` matches `rowMinHeight` (no forced 108-pt tall B cards).
- `QuantityStepper` reports compact capsule height (`Chrome.stepperVisualHeight` = 28) while keeping 44×44 button frames; width remains 88.
- Geometry selection still content-fit (`ItemRowFitGeometry`); floor **68** unchanged.
- Stage 2 helper extraction is **paused** until this visual gate is accepted.

## Capture matrix (default Large, light)

Harness: `-Stage1ItemRowReview -Stage1ReviewScene=breview`

| Device | File |
|---|---|
| iPhone 17 | `candidateb-iphone17-candidate-b-review.png` |
| iPhone 17 Pro Max | `candidateb-iphone17promax-candidate-b-review.png` |
| iPhone 16e | `candidateb-iphone16e-candidate-b-review.png` |

Alias: `stage1-candidate-b-review.png` ← iPhone 17 copy.

Acceptance set in harness: Butter, Eggs, Watermelon, Strawberries, Chicken drumsticks (+ narrow forced-B column).

## Acceptance checklist (for reviewer)

| Check | Expected |
|---|---|
| Watermelon | No isolated floating stepper; Produce and `− 1 +` share secondary line |
| Butter / Eggs | Compact; A when width allows; height close to B one-line rows |
| Strawberries | Same B structure as Watermelon when B wins |
| Chicken drumsticks | Proportionate; quantity still on metadata line |
| Controls | Usable; 44-pt tap targets retained |
| Geometry tests | Pass (30 focused tests, 2026-07-18) |

## Tests

```text
ItemRowFitGeometryTests + DynamicTypeLayoutTests → 30 tests, 0 failures
```

## Script

```bash
./GroceryListiOS/scripts/review-stage1-optional-simulator.sh
# includes -Stage1ReviewScene=breview when DEVICE_SLUG set
```

## Gate

**Do not resume Stage 2 / Stage 3 until Candidate B screenshots are accepted.**  
No commits or pushes from this revision.
