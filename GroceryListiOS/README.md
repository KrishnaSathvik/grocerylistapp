# Grocery List — iOS

Native SwiftUI grocery list app for iPhone and iPad. Plan shopping runs, add items in natural language, browse by store or category, and share lists via QR codes or text — all offline, with no account required.

**Minimum deployment:** iOS 17.0  
**Bundle ID:** `com.grocerylist.app`  
**Display name:** Grocery List

---

## Table of contents

- [Features](#features)
- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [Design system](#design-system)
- [Data & persistence](#data--persistence)
- [Sharing & import](#sharing--import)
- [Testing](#testing)
- [Scripts & assets](#scripts--assets)
- [Related docs](#related-docs)

---

## Features

### Lists

- **Multiple named lists** with icon, tint color, and optional description
- **Active list** — one list is “current” for Store/Categories tabs and sharing
- **List detail** with quick-add bar, filter modes (All / Store / Category), and progress tracking
- **Starter templates** — one-tap list creation (Weekly Groceries, Costco Run, etc.)
- **List management** — create, rename, switch, delete (with confirmation), context menu actions
- **Selection mode** — multi-select items to assign, share, copy, or delete
- **Undo delete** — toast with undo after bulk or single delete
- **Clear completed** — remove checked-off items in one action
- **Show/hide completed** toggle in list header

### Smart item input

Natural-language parsing when you add items:

- **Quantity** — `2`, `2 lb`, `1 pack`, `500g`, `1 dozen`, `2 bags`, etc.
- **Store detection** — `milk from Costco`, `eggs at Walmart`
- **Category auto-detection** — keyword catalog + learned rules
- **Multi-item input** — comma- or newline-separated batches
- **Live detection preview** — shows parsed name, qty, category, and store while typing
- **Product imagery** — keyword → bundled product photo, with category illustration fallback

### Category intelligence

- **16 built-in categories** (Produce, Dairy, Meat, Seafood, Bakery, Deli, Frozen, Pantry, Snacks, Condiments, Drinks, Household, Health, Baby, Pet, Misc)
- **Keyword catalog** synced from the web app (`category_catalog.json`)
- **Learning dictionary** — when you manually change a category, the app remembers for future items (`CategoryLearningRule`)
- **Custom categories** — add your own with label and color
- **Custom category order** — drag to match your store route (Settings → Reorder Categories)
- **Category picker** — inline chips and full picker sheet on edit

### Store tagging

- **39 default stores** seeded on first launch (Costco, H Mart, Trader Joe's, etc.)
- **Custom stores** — add labels and optional brand colors
- **Store logos** — branded tiles where available, initials fallback
- **Store tab** — browse active list grouped by store with progress bars
- **Focused shopping by store** — drill into one store, items grouped by category

### Browse views (tabs)

| Tab | Purpose |
|-----|---------|
| **Lists** | All grocery lists; active list highlighted |
| **Store** | Active list grouped by store |
| **Categories** | Active list grouped by category |
| **More** | Settings, sharing, customization, help |

**Focused shopping mode** (`FocusedShoppingView`) opens from Store or Categories for a single store/category with contextual add bar, cross-grouping (store → by category, category → by store), and prefilled metadata.

### Sharing & backup

- **Share active list** — native share sheet with formatted text
- **QR code** — scannable encode of list payload (up to 50 items)
- **Import shared list** — scan QR, paste text, or open `#import=` web links
- **Web-compatible codec** (`ListCodec`) — `GLIST1:` payload + gzip, matches [smartgrocerylists.app](https://smartgrocerylists.app/)
- **Deep links** — `onOpenURL` import flow with add-or-replace confirmation
- **Local JSON backup & restore** — export/import all lists via Files

### Settings & customization

- **Haptic feedback** toggle
- **Appearance** — System / Light / Dark
- **Alternate app icons** — 6 options (Grocery Bag, Sage Bag, Navy Cart, Fresh Produce, Cream Minimal, Dark Mode)
- **Reorder categories**
- **Share / import** shortcuts
- **Send feedback** (Mail compose with optional diagnostics)
- **Rate app** prompt
- **Privacy policy** (Safari sheet)
- **About** — version info
- **Reset onboarding**

### Onboarding

Four full-screen pages with illustrations:

1. Shop smarter — automatic category sorting
2. Add naturally — quantity, store, and category detection
3. Every view you need — Lists, Store, Categories
4. Share anywhere — offline, no account

Skip, back/next navigation, page dots, spring animations (respects Reduce Motion).

### Accessibility & polish

- VoiceOver labels on rows, headers, and actions
- Dynamic Type support; metadata wraps at larger sizes
- Reduce Motion honored for transitions
- Haptics: check, add, delete, selection, navigation, import success
- Tab bar safe-area padding for scroll content
- Max content width 640pt on iPad

---

## Getting started

### Requirements

- Xcode 15+ (Swift 5, iOS 17 SDK)
- macOS for simulator or device builds

### Open & run

```bash
open GroceryListiOS/GroceryList.xcodeproj
```

1. Select the **GroceryList** scheme
2. Choose an iPhone simulator or connected device
3. **Product → Run** (⌘R)

On first launch, seed data bootstraps default stores and categories. SwiftData persists lists, items, stores, and learning rules locally.

### Sync catalog from web app (optional)

From the repo root:

```bash
node scripts/export-seed-data.mjs      # categories & stores JSON
node scripts/export-ios-catalog.mjs    # full product/category catalog
```

---

## Project structure

```
GroceryListiOS/
├── GroceryList/
│   ├── GroceryListApp.swift          # App entry, SwiftData container
│   ├── Models/                       # SwiftData @Model types
│   ├── Views/
│   │   ├── Root/                     # AppRootView, error recovery
│   │   ├── MainTabView.swift         # Tab bar shell
│   │   ├── Lists/                    # My Lists, list detail, grouping
│   │   ├── Store/                    # Store tab, store detail
│   │   ├── Categories/               # Categories tab, category detail
│   │   ├── Shopping/                 # FocusedShoppingView
│   │   ├── Items/                    # Add/edit item sheets, pickers
│   │   ├── Share/                    # QR, import/export, backup
│   │   ├── Settings/                 # More tab subpages
│   │   └── Onboarding/
│   ├── ViewModels/
│   │   ├── ListDetailViewModel.swift
│   │   └── FocusedShoppingViewModel.swift
│   ├── Components/                   # Reusable UI (rows, bars, chips)
│   ├── DesignSystem/                 # Tokens & shared chrome
│   ├── Services/                     # Business logic, parsers, codec
│   ├── Resources/                    # JSON catalogs & seed data
│   └── Assets.xcassets/              # Icons, illustrations, product photos
├── GroceryListTests/                 # Unit tests
├── scripts/                          # Screenshot capture, asset tools
├── AppIconConcept.md                 # Icon design direction
└── IMPLEMENTATION_PLAN.md            # Full product & architecture spec
```

---

## Design system

Design tokens live in `GroceryList/DesignSystem/`. Use these instead of hard-coded values in new UI.

### Philosophy

Clean native iOS grocery app. Warmth comes from **illustrations** (onboarding, empty states) and **soft category tints** — not paper textures or decorative fonts on list rows.

- **Headlines & CTAs:** SF Rounded (bold/semibold)
- **Body & metadata:** SF Pro (system default)
- **Navigation chrome:** configured globally in `AppAppearance`

### Colors (`AppColors`)

Adaptive light/dark via `Color(light:dark:)` hex initializers.

#### Core palette

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `backgroundPrimary` | `#FFFFFF` | `#111114` | Cards, elevated surfaces |
| `backgroundGrouped` | `#F5F5F7` | `#000000` | Screen backgrounds |
| `backgroundElevated` | `#FFFFFF` | `#1C1C1E` | Sheets, bars |
| `ink` | `#1A1F36` | `#F5F5F7` | Primary text, CTAs |
| `inkSecondary` | `#6B7280` | `#98989D` | Metadata, subtitles |
| `accentLink` | `#007AFF` | `#0A84FF` | Links, cancel/done |
| `accentPrimary` | `#1A1F36` | `#F5F5F7` | Primary buttons, tab selection |
| `accentSuccess` | `#4A7C59` | `#5E9A6E` | Checkmarks, progress |
| `accentDestructive` | `#FF3B30` | `#FF453A` | Delete actions |
| `filterSelected` | `#1A1F36` | `#F5F5F7` | Selected filter pill |
| `filterUnselected` | `#ECECF0` | `#2C2C2E` | Unselected filter pill |
| `addBarBackground` | `#FFFFFF` | `#1C1C1E` | Quick-add bar |
| `cardBorder` | `#E5E7EB` | `#38383A` | Card strokes |
| `cardShadow` | black @ 8% | black @ 8% | Card elevation |
| `heroGradientTop` | `#E8F5EC` | `#142118` | Top screen gradient |

#### Semantic helpers

- `AppColors.categoryTint(for:)` — soft background tint per category ID
- `AppColors.storeHeaderTint(for:)` — store section header backgrounds
- `AppColors.colorHex(_:)` — one-off hex colors

#### Category tint backgrounds (examples)

| Category | Light tint |
|----------|------------|
| Produce | `#E8F5E9` |
| Dairy | `#E8F4FD` |
| Meat | `#FDE8E8` |
| Pantry / Bakery | `#FFF3E0` |
| Snacks | `#FCE4EC` |
| Drinks | `#E0F2F1` |
| Household | `#ECEFF1` |
| Default | `#F3F4F6` |

### Typography (`AppTypography`)

| Token | Size | Weight | Design | Use |
|-------|------|--------|--------|-----|
| `largeScreenTitle` | 34 | Bold | Rounded | Tab screen titles (“My Lists”) |
| `screenTitle` | 30 | Bold | Rounded | Secondary hero titles |
| `navTitle` | 17 | Semibold | Rounded | Navigation bar titles |
| `cardTitle` | 17 | Semibold | Rounded | Card headings |
| `emptyStateTitle` | 22 | Bold | Rounded | Empty state headlines |
| `body` | 16 | Regular | Default | Body copy |
| `bodyMedium` | 16 | Medium | Default | Emphasized body |
| `itemTitle` | 16 | Semibold | Default | Grocery item names |
| `metadata` | 13 | Medium | Default | Subtitles, chips |
| `caption` | 12 | Medium | Default | Small labels |
| `sectionLabel` | 12 | Bold | Default | Uppercase section headers |
| `button` | 16 | Semibold | Default | Standard buttons |
| `largeButton` | 17 | Semibold | Default | Primary CTAs |
| `badge` | 11 | Bold | Default | Count badges |
| `tiny` | 10 | Bold | Default | Micro labels |
| `tabLabel` | 10 | Medium | Default | Tab bar labels |

#### Section label modifier

```swift
Text("Active")
    .appSectionLabel()  // sectionLabel font + inkSecondary + uppercase + 0.4 tracking
```

#### Onboarding typography

`OnboardingTheme.brandHeadline` — 30pt bold rounded (matches `screenTitle`).

### Spacing & layout (`AppSpacing`)

| Token | Value | Use |
|-------|-------|-----|
| `screenHorizontal` | 16pt | Standard horizontal inset |
| `screenHorizontalCompact` | 12pt | Tighter layouts |
| `topHeaderTopInset` | 8pt | Below status bar on tab screens |
| `topHeaderBottomSpacing` | 12pt | Header → content gap |
| `cardCornerRadius` | 16pt | Cards, grouped rows |
| `groupedSectionCornerRadius` | 18pt | Store/Category summary cards |
| `groupedNestedRowCornerRadius` | 12pt | Nested item rows |
| `buttonCornerRadius` | 14pt | Buttons, pills |
| `rowMinHeight` | 76pt | Minimum list row height |
| `addBarHeight` | 50pt | Quick-add bar |
| `thumbnailSize` | 44pt | Item thumbnails |
| `listIconSize` | 52pt | List card icons |
| `sectionSpacing` | 12pt | Vertical section gaps |
| `groupedSectionSpacing` | 12pt | Between grouped cards |
| `pillHeight` | 34pt | Filter/chip pills |
| `maxContentWidth` | 640pt | iPad content cap |

### Icons (`AppIcons`)

Centralized SF Symbol names for chrome:

`plus`, `square.and.arrow.up`, `line.3.horizontal`, `ellipsis.circle`, `pencil`, `storefront.fill`, `square.grid.2x2.fill`, `list.bullet`, `gearshape`, `chevron.right`, `checkmark.circle.fill`, `circle`, `qrcode`, `doc.on.clipboard`

`AppIcons.categorySymbol(for:)` maps category IDs to fallback SF Symbols when asset images are unavailable.

### Shared components & modifiers

| Component / modifier | File | Purpose |
|---------------------|------|---------|
| `appCard()` | `AppCardStyle` | White card with border + shadow |
| `AppScreenBackground` | `AppCardStyle` | Grouped bg + hero gradient |
| `TopLevelTabScreen` | `AppCardStyle` | Standard tab shell (header + content) |
| `TabScreenHeader` | `ListsHeaderView` | Large title + subtitle + optional action |
| `GroupedBrowseToolbar` | `AppCardStyle` | Section label + capsule action |
| `GroupedSummaryCard` | `AppCardStyle` | Store/Category preview card |
| `ImageEmptyStateHero` | `ImageEmptyStateHero` | Illustration + title + subtitle |
| `tabBarSafePadding()` | `TabBarSafeArea` | 72pt bottom inset for tab bar |
| `settingsSubpageStyle()` | `SettingsSubpageStyle` | Hide tab bar on pushed settings |

### Global appearance (`AppAppearance`)

Configured at launch in `GroceryListApp.init()`:

- **Navigation bar** — system chrome material blur, rounded semibold titles, `AppColors.ink`
- **Tab bar** — chrome material, primary tint for selected, secondary for unselected

### Motion

| Context | Animation |
|---------|-----------|
| Onboarding page change | `spring(response: 0.5, dampingFraction: 0.86)` |
| Onboarding content | `spring(response: 0.45, dampingFraction: 0.82)` |
| Page dots | `easeInOut(0.22)` |
| List interactions | Respects `@Environment(\.accessibilityReduceMotion)` |

### Product imagery priority

1. Keyword match from the **current item name** → bundled product photo (`ItemAssetResolver` / `product_catalog.json`)
2. Cached `imageAssetName` on `GroceryItem` only when the current name has no product match (auto-cache; there is no manual image picker)
3. Category illustration asset (`category-*` in Assets.xcassets)

Opening a list runs `GroceryItemService.reconcileImageAssets` so stale cached assets pick up newer specific products.

See `PRODUCT_ASSET_TRACKER.md` for live counts. Distinguish **catalog coverage** (canonical records) from **overall grocery coverage** (still incomplete beyond Phase B1 produce). Powdered forms such as `onion powder` do not resolve to fresh produce.

---

## Data & persistence

### SwiftData models

| Model | Key fields |
|-------|------------|
| `GroceryList` | name, icon, tint, sort order, items relationship |
| `GroceryItem` | name, qty, categoryId, storeId, completed, notes, image asset |
| `GroceryStore` | label, sort order, custom flag |
| `CategoryLearningRule` | normalized item name → categoryId, use count |

### User defaults (`AppSettings`)

- Onboarding completion
- Active list ID
- Default list filter mode (All / Store / Category)
- Category order & custom categories
- Haptics, appearance, show completed in store view

### Key services

| Service | Role |
|---------|------|
| `ItemInputParser` | Natural-language item parsing |
| `QuantityParserService` | Flexible quantity strings |
| `CategoryDetectionService` | Keyword-based category |
| `CategoryLearningService` | Learn & apply user corrections |
| `StoreDetectionService` | “from Costco” phrase parsing |
| `GroceryCatalog` | Load category/product JSON |
| `ItemAssetResolver` | Resolve thumbnail assets |
| `ListGroupingService` | Store/category group builders |
| `ListCodec` | Share/import encode & decode |
| `ListImportService` | Apply imported items |
| `BackupExportService` | Full JSON backup |
| `PersistenceService` | Centralized save with error logging |
| `HapticsService` | Feedback triggers |
| `AppIconService` | Alternate icon switching |

---

## Sharing & import

### Encode format

- **Prefix:** `GLIST1:`
- **Payload:** JSON list + items, optionally compressed
- **Web URL:** `https://smartgrocerylists.app/app?import=<payload>`
- **Limit:** 50 items per share link

### Import paths

1. QR scanner (`QRScannerScreen`)
2. Paste shared text
3. Universal `#import=` fragment / deep link
4. Backup `.json` file restore

Import confirmation offers **Add to list** or **Replace list**.

---

## Testing

Run unit tests in Xcode: **Product → Test** (⌘U)

| Test file | Coverage |
|-----------|----------|
| `ItemInputParserTests` | Natural-language parsing |
| `MultiItemInputParserTests` | Batch input |
| `QuantityParserServiceTests` | Quantity formats |
| `CategoryDetectionServiceTests` | Keyword detection |
| `CategoryLearningServiceTests` | Learning rules |
| `StoreDetectionServiceTests` | Store phrases |
| `ListCodecTests` | Share encode/decode round-trip |
| `ItemEmojiCatalogTests` | Emoji fallback catalog |
| `PersistenceServiceTests` | Save helpers |
| `V1PolishTests` | Integration polish checks |
| `AuditFixTests` | Regression fixes |

---

## Scripts & assets

| Script | Purpose |
|--------|---------|
| `scripts/capture_screenshots.sh` | Simulator screenshot QA |
| `scripts/normalize-catalog-assets.py` | Category + product normalization (0.88 fill; width-zoom for tall bottles) |
| `scripts/normalize-category-assets.py` | Category-only wrapper for the script above |
| `../scripts/export-seed-data.mjs` | Export web seed → iOS JSON |
| `../scripts/export-ios-catalog.mjs` | Export full product catalog + prompts |
| `../scripts/verify-product-resolution.mjs` | Assert name → product asset mappings |
| `../scripts/audit-product-assets.py` | Duplicate / fill / imageset audit |
| `../scripts/install-generated-product-assets.py` | Install staged 1024×1024 product art |
| `../scripts/generate-product-assets.py` | **Obsolete** 80×80 placeholders — do not use for production art |

Asset catalogs include category icons, product photos, onboarding illustrations, empty-state art, and alternate app icon previews.

---

## Related docs

- [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) — Full product scope, screen plans, and architecture decisions
- [`AppIconConcept.md`](AppIconConcept.md) — Target app icon direction (navy basket + sage checkmark)
- [Web app README](../README.md) — Shared catalog source and web companion

---

## License & privacy

Grocery list data stays on device. Sharing sends only what you explicitly share. Feedback email may include app version, iOS version, and device model — never list contents by default.

Contact: `grocerylistapp.support@gmail.com`

---

## App Store Connect

Use these URLs in App Store Connect (not a raw email address for Support URL):

| Field | URL |
|-------|-----|
| **Marketing URL** | `https://smartgrocerylists.app/` |
| **Support URL** | `https://smartgrocerylists.app/support` |
| **Privacy Policy URL** | `https://smartgrocerylists.app/privacy` |

### App Review notes (suggested)

```text
Groceries — Smart Lists is a local-first grocery list app. No account or login is required.

Support: https://smartgrocerylists.app/support
Privacy: https://smartgrocerylists.app/privacy
Support email: grocerylistapp.support@gmail.com

Camera permission is used only to scan QR codes when importing a shared list. You can also import by pasting text or opening a share link.

To test sharing: create a list, tap Share, and scan the QR code on another device or import the shared text from More → Import Shared List.
```

