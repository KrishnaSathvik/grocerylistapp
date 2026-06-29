# App Icon Concept — Grocery List

> Status: **Design reference only** — not yet implemented in `AppIcon.appiconset`  
> Target: iOS 17+ asset catalog (+ optional Icon Composer `.icon` for iOS 26)

## Direction: Navy basket + checklist

### Visual description

- **Background:** Rounded square, deep navy `#1A1F36` (matches primary CTA / ink)
- **Foreground:** Cream/off-white `#F5F0E8` grocery basket silhouette, centered, bold stroke weight
- **Accent:** Single sage green `#4A7C59` checkmark overlapping lower-right of basket (thick, not thin line art)
- **Optional:** 2–3 tiny cream dots inside basket suggesting items — only if legible at 60pt; omit if muddy

### Why it fits

- Navy = product identity already used in CTAs and typography
- Sage checkmark = “smart sorted list” + shopping completion
- Basket = instant grocery recognition without clip-art clipboard feel
- Cream on navy = high contrast on light and dark home screens

### Small-size risks (60pt / 40pt)

| Risk | Mitigation |
|------|------------|
| Checkmark merges with basket handle | Offset checkmark outside basket rim |
| Interior item dots blur | Use max 1–2 shapes or skip entirely |
| Basket handles disappear | Merge handles into single basket silhouette |
| Tinted/Clear iOS 26 modes | Design with Icon Composer layers; test Mono appearance |

## Alternate directions (not chosen)

1. **Smart sorted card** — navy card + 2 rows + category dot (can look like generic notes app)
2. **Paper bag + check** — warmer, matches empty-state illustration (slightly less distinct at small sizes)

## Implementation checklist

- [ ] Export 1024×1024 master SVG with 3 layers: background, basket, checkmark
- [ ] Build `.icon` in Icon Composer (Default / Dark / Tinted / Clear)
- [ ] Replace `AppIcon.appiconset/AppIcon.png`
- [ ] Verify on simulator home screen next to system apps
- [ ] Verify App Store Connect preview

## Current asset gap

The shipping icon remains a flat clipboard + leaf PNG. Replace before TestFlight / App Store submission.
