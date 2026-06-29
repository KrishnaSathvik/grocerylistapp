# Grocery List — Native iOS Implementation Plan

> **Status:** Phase 9 complete — share/import/export + web-compatible codec; Phase 10 next  
> **Web app:** Untouched — this lives in `GroceryListiOS/` only  
> **Last updated:** June 28, 2026  
> **Design references:** 20 screens in `DesignReferences/` — mapped in [Section 14](#14-design-references)  
> **Design status:** Approved direction (June 28, 2026)

---

## Table of Contents

1. [Repo Audit Summary](#1-repo-audit-summary)
2. [Current Web App Feature Map](#2-current-web-app-feature-map)
3. [Current Data Model and Storage](#3-current-data-model-and-storage)
4. [Category, Store, Quantity, and Sharing Logic](#4-category-store-quantity-and-sharing-logic)
5. [Current UI/UX and Design Review](#5-current-uiux-and-design-review)
6. [What Must Stay the Same](#6-what-must-stay-the-same)
7. [What Should Be Redesigned for iOS](#7-what-should-be-redesigned-for-ios)
8. [Reddit Feedback Incorporated](#8-reddit-feedback-incorporated)
9. [iOS V1 Product Scope](#9-ios-v1-product-scope)
10. [iOS V2 Roadmap](#10-ios-v2-roadmap)
11. [Recommended Native iOS Architecture](#11-recommended-native-ios-architecture)
12. [SwiftData Model Plan](#12-swiftdata-model-plan)
13. [Screen-by-Screen iOS Plan](#13-screen-by-screen-ios-plan)
14. [Design References](#14-design-references)
15. [Native iOS Design System Direction](#15-native-ios-design-system-direction)
16. [Sharing, Import, and Export Plan](#16-sharing-import-and-export-plan)
17. [Backend / Sync Recommendation](#17-backend--sync-recommendation)
18. [Web / Marketing Roadmap](#18-web--marketing-roadmap)
19. [Implementation Phases](#19-implementation-phases)
20. [Testing Plan](#20-testing-plan)
21. [Risks and Open Questions](#21-risks-and-open-questions)
22. [Files To Be Created or Changed](#22-files-to-be-created-or-changed)
23. [Final Recommendation](#23-final-recommendation)

---

## 1. Repo Audit Summary

### Tech stack (web)

| Layer | Source |
|-------|--------|
| UI | React 18 (`src/main.jsx`, `src/GroceryList.jsx`) |
| Build | Vite 6 (`vite.config.js`) |
| PWA | `vite-plugin-pwa` + Workbox |
| QR | `qrcode-generator` (`src/components/QRModal.jsx`) |
| Analytics | `@vercel/analytics` (`src/main.jsx`) |
| Styling | CSS variables in `src/notepadStyles.js` — no UI library |
| Deploy | Vercel SPA rewrites (`vercel.json`) |
| Fonts | Patrick Hand + DM Sans (`index.html`) |

### App purpose

Local-first, single-list grocery PWA: fast add, smart category/store tagging, check-off while shopping, share/import lists. Strong Indian/Asian grocery keyword coverage.

### Main screens / views (web)

| View | File |
|------|------|
| Home / List | `ListView.jsx`, `Header.jsx`, `InputBar.jsx` |
| Store grouped | `StoreView.jsx` |
| Onboarding | `Onboarding.jsx` |
| Share sheet | `ShareSheet.jsx` |
| QR modal | `QRModal.jsx` |
| Import modal | `ImportModal.jsx` |
| Toast (undo) | `Toast.jsx` |

**Note:** `Pagination.jsx` exists but is not imported anywhere (dead code).

### User flows (web)

1. First launch → onboarding → `onboarding-done` in localStorage
2. Add item → parse qty/store → auto category → append → persist
3. Check item → moves to “picked up” section (`checked: true`)
4. Swipe left → delete → 3.5s undo toast
5. Inline edit via `ContentEditable.jsx`; `@store` triggers autocomplete
6. Tap category badge → `CategoryPicker` in `GroceryItem.jsx`
7. Toggle List / By Store in header
8. Share → copy text / link / QR
9. Open `#import=` URL → decode → onboarding (new) or modal (returning) → add or replace

### localStorage keys

| Key | Content | Notes |
|-----|---------|-------|
| `grocery-items` | JSON array of items | Auto-saved on change |
| `grocery-stores` | Custom stores object | **`setCustomStores` never called** — infrastructure only |
| `onboarding-done` | `"1"` | First-launch flag |

### Limitations (from actual code)

- Single unnamed list (“Grocery List”)
- No category view, learning dictionary, or custom category order
- Quantity: integers 2–99 only — no `2 lb`, `1 pack`, `500g`
- Store view hides checked items
- Category not editable in store view
- Link share capped at 50 items
- Drag reorder not persisted
- Emoji-heavy UI throughout

---

## 2. Current Web App Feature Map

| Web feature | File / component | Current behavior | iOS equivalent | Keep / redesign |
|-------------|------------------|------------------|----------------|-----------------|
| Add grocery item | `GroceryList.jsx`, `InputBar.jsx` | Enter or + | `QuickAddBar` | Keep parsing; redesign UI |
| Parse quantity | `utils.js` `parseQty()` | `2 milk`, `2x`, `milk x2`, int 2–99 | `QuantityParserService` | Keep + extend units |
| Edit item text | `GroceryItem.jsx`, `ContentEditable.jsx` | Inline edit | Item edit sheet | Redesign — sheet primary |
| Check / uncheck | `toggleCheck()` | Toggles `checked` | Tap row / checkmark | Keep + haptic |
| Completed section | `ListView.jsx` | “picked up” + dimmed rows | Collapsible section | Keep |
| Clear checked | `clearChecked()` | Removes checked items | Settings + section action | Keep |
| Delete item | `removeItem()` | Immediate remove | Swipe + context menu | Keep |
| Undo delete | `Toast.jsx` | 3.5s undo | Banner / toast | Keep |
| Swipe-to-delete | `SwipeRow.jsx` | Touch swipe left | Native swipe actions | Keep |
| Drag reorder | Drag handlers in `GroceryList.jsx` | HTML5 DnD, list only | List `.onMove` | Keep + persist order |
| Category auto-detect | `utils.js`, `categories.js` | Longest keyword match | `CategoryDetectionService` | Port keywords |
| Editable category | `CategoryPicker` | Emoji dropdown | Sheet + SF Symbols | Redesign UI |
| Item emoji | `itemIcons.js`, `itemEmojis.js` | ~1,280 emoji mappings | SF Symbol mapping | Redesign |
| Store `@store` | `parseStoreTag()` | End-of-string tag | Text + picker | Keep |
| Store autocomplete | `InputBar.jsx` | Prefix match | Searchable menu | Keep |
| Store grouped view | `StoreView.jsx` | Unchecked only | Store segment | Keep; optional completed |
| List view | `ListView.jsx` | Active + completed | List segment | Keep |
| Onboarding | `Onboarding.jsx` | Tap anywhere | Swipe + Next/Back | Redesign |
| Import onboarding | `Onboarding.jsx` import branch | Preview + Add/Replace | Import welcome | Keep flow |
| Share as text | `shareAsText()` | Plain text + emojis | `ShareTextFormatter` | Keep format; fewer emojis |
| Share as link | `shareAsLink()` | base64 `#import=` | Copy link + QR | Keep codec |
| QR sharing | `QRModal.jsx` | Offline canvas | CoreImage QR | Keep |
| Import URL hash | Mount effect in `GroceryList.jsx` | Decode + clear hash | Paste / scan / deep link | Keep codec |
| Import add/replace | `ImportModal.jsx` | Merge or replace | Import sheet | Keep |
| Persistence | localStorage | Auto-save | SwiftData | Keep local-first |
| Dark mode | `notepadStyles.js` | System only | SwiftUI color scheme | Keep |
| Empty states | `ListView.jsx` | Emoji hints | `EmptyStateView` | Redesign |
| PWA / offline | `vite.config.js` | Service worker | N/A (native) | Drop for iOS |
| SEO / metadata | `index.html` | OG + JSON-LD | N/A in app | Web roadmap |
| **Named lists** | — | Not in web | `GroceryList` model | **New iOS v1** |
| **Category view** | — | Not in web | Category segment | **New iOS v1** |
| **Learning dictionary** | — | Not in web | `CategoryLearningRule` | **New iOS v1** |
| **Quantity stepper** | — | Not in web | `QuantityStepper` | **New iOS v1** |
| **Flexible qty text** | — | Not in web | Extended parser | **New iOS v1** |
| **Select → assign group** | — | Not in web | Edit mode | **New iOS v1** |
| **Long-press group share** | — | Not in web | Context menu | **New iOS v1** |
| **Custom category order** | — | Not in web | Category order screen | **New iOS v1** |

---

## 3. Current Data Model and Storage

### Web item shape (`GroceryList.jsx`)

```javascript
{
  id: number,           // Date.now() or Date.now() + Math.random()
  text: string,
  qty: number,          // default 1
  category: string,     // key into CATEGORIES (16 keys)
  checked: boolean,
  icon: string | null,  // emoji
  store: string | null  // key into DEFAULT_STORES (39 keys)
}
```

### Category keys (16)

`produce`, `dairy`, `meat`, `seafood`, `bakery`, `deli`, `frozen`, `pantry`, `snacks`, `condiments`, `drinks`, `household`, `health`, `baby`, `pet`, `misc`

Defined in `src/data/categories.js` with `label`, `color`, `emoji`, and `CAT_KEYWORDS`.

### Store keys (39)

Defined in `src/data/stores.js` — each has `label`, `domain`, `color`.

---

## 4. Category, Store, Quantity, and Sharing Logic

### Category detection (`utils.js`)

```
for each category → for each keyword:
  if (lower === kw || lower.includes(kw)) && kw.length > bestLen → best = cat
return best || null  →  falls back to "misc" on add
```

**iOS priority:** (1) learned mapping → (2) normalized learned → (3) keyword detect → (4) misc

### Quantity parsing (`utils.js`) — web today

| Pattern | Example |
|---------|---------|
| Prefix x | `2x milk` |
| Prefix x alt | `x2 milk` |
| Suffix x | `milk x2` |
| Leading number | `2 milk` (2–99) |
| Trailing number | `milk 2` (2–99) |

**iOS v1 adds:** `2 lb`, `1 pack`, `500g`, `1 dozen`, `2 bags`, `1 bottle`

### Store parsing

Regex `/@(\S*)$/` on input; resolved via key, label, or first autocomplete match.

### Share / import codec (`utils.js`)

**Encode (max 50 items):**

```javascript
{ t: text, q?: qty, c?: category, s?: store, k?: 1 if checked }
→ JSON → base64 → #import={payload}
```

**Base URL:** `https://grocerylistapp.vercel.app/`

**iOS must implement identical codec** for web link / QR compatibility.

### Share text format (web)

```
🛒 Grocery List
{weekday, month day}

📍 {Store}:
  ☐ {qty}x {text}

✓ Picked up:
  ✓ {text}

{N} items remaining
```

iOS: same structure; replace emoji headers with text or SF Symbol labels in UI (plain text for share).

---

## 5. Current UI/UX and Design Review

### Strengths

- Fast add flow, clear active vs completed separation
- Indian/Asian keyword coverage
- Offline QR, import add/replace, swipe + undo
- Store grouping useful for multi-store runs

### Weaknesses on iPhone

- Notepad layout wastes horizontal space (48px spiral gutter)
- Emoji overload (items, categories, share, empty states)
- Tap-only onboarding
- Store view drops completed items
- No multi-list support
- Handwritten font pretty but less scannable in bright stores
- Store favicons require network

### Spiral / paper motif — iOS decision

Use as **subtle brand accent** (onboarding, empty states, about) — **not** as permanent left gutter on the shopping screen.

---

## 6. What Must Stay the Same

- Local-first, no account (v1)
- Natural typing: qty + `@store`
- 16 categories + full keyword corpus
- 39 default stores
- Auto category + manual override
- Checked items visually below active items
- Undo delete (~3.5s)
- Share: text + encoded payload + QR
- Import: add vs replace
- List + store grouping
- Privacy: data on device

---

## 7. What Should Be Redesigned for iOS

| Area | Direction |
|------|-----------|
| Navigation | 4-tab bar (Lists / Store / Categories / More) + list detail with filter pills | Refs 04–06, 11 |
| Item rows | Thumbnail + title + `Category • Store` + inline qty stepper | Ref 04 |
| Input | Top search-style add bar; hide + when empty | Refs 04, 07 |
| Icons | SF Symbols — not emoji wall |
| Onboarding | Swipe cards + explicit Next / Back |
| Edit | Bottom sheet |
| Share | Native Share Sheet |
| Gestures | Swipe actions, context menus, long-press |
| Paper motif | Warm background; no spiral gutter |
| Typography | SF Pro primary; accent font sparingly |

---

## 8. Reddit Feedback Incorporated

| # | Feedback | Plan |
|---|----------|------|
| 1 | SF Symbols not emojis | Core UI + category icons |
| 2 | Custom domain | Web v2 |
| 3 | Landing page | Web v2 |
| 4 | Onboarding swipe/arrows | TabView + buttons |
| 5 | Hide add when empty | QuickAddBar |
| 6 | Spiral holes on mobile | Accent only |
| 7 | Real-time sync | v2 |
| 8 | Push notifications | v2 |
| 9 | Apple Watch | v2/v3 |
| 10 | Learning dictionary | v1 |
| 11 | Category grouped view | v1 |
| 12 | Custom category order | v1 |
| 13 | Translation | v2; localize prep in v1 |
| 14 | Select items → groups | v1 edit mode |
| 15 | Long-press group share | v1 context menu |
| 16 | Quantity stepper | v1 |
| 17 | Named groups/lists | v1 |
| 18 | Swipe delete | v1 native + undo |

---

## 9. iOS V1 Product Scope

### In scope

- [ ] Native SwiftUI app in `GroceryListiOS/`
- [ ] SwiftData persistence
- [x] Named grocery lists / groups
- [x] Add / edit / delete / check / undo
- [x] Quantity parsing (web patterns + units)
- [x] Quantity stepper in edit sheet
- [x] Category auto-detection (ported keywords)
- [x] Category manual edit + learning dictionary
- [x] Store tagging + 39 default stores + custom stores
- [x] Views: List / Store / Category
- [ ] Custom category ordering
- [ ] Multi-select → assign to list
- [ ] Long-press list actions + share
- [x] Native Share Sheet, copy text, QR
- [x] Import: paste / QR / web-compatible codec
- [x] Export local JSON backup
- [x] Onboarding with swipe + arrows
- [ ] Product photo catalog (~150–250 bundled assets) + category fallbacks
- [x] Empty states, light/dark mode, settings
- [x] XCTest: parsers, categories, codec, persistence

### Out of scope (v1)

Accounts, backend, sync, push, Watch, full localization, universal links, WebView wrapper

---

## 10. iOS V2 Roadmap

| Feature | Notes |
|---------|-------|
| Real-time family lists | Supabase Realtime or CloudKit |
| Push notifications | APNs + backend |
| Apple Watch | Shopping mode / check-off |
| Multi-language | String catalogs |
| Universal links | Custom domain + AASA |
| Marketing landing page | Separate from app |
| Cross-device conflict resolution | Required with sync |

**Recommendation:** v1 SwiftData local → **v2 Supabase** if cross-platform + web sharing matter; **CloudKit** if Apple-only + iCloud privacy-first.

---

## 11. Recommended Native iOS Architecture

```
GroceryListiOS/
├── GroceryListApp.swift
├── Models/
│   ├── GroceryList.swift
│   ├── GroceryItem.swift
│   ├── GroceryStore.swift
│   ├── CategoryLearningRule.swift
│   └── AppSettings.swift
├── Views/
│   ├── Onboarding/
│   ├── Home/
│   ├── Items/
│   ├── Lists/
│   ├── Categories/
│   ├── Share/
│   └── Settings/
├── Components/
│   ├── ItemRow.swift
│   ├── QuickAddBar.swift
│   ├── CategoryChip.swift
│   ├── StoreChip.swift
│   ├── QuantityStepper.swift
│   └── EmptyStateView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── ListsViewModel.swift
│   └── ShareViewModel.swift
├── Services/
│   ├── CategoryDetectionService.swift
│   ├── QuantityParserService.swift
│   ├── StoreDetectionService.swift
│   ├── ItemIconService.swift       # keyword → product photo or category fallback
│   ├── ProductImageCatalog.swift   # bundled asset name lookup
│   ├── ShareTextFormatter.swift
│   ├── ImportExportService.swift
│   └── HapticsService.swift
├── Persistence/
│   ├── ModelContainerSetup.swift
│   ├── SeedData.swift
│   └── Migrations/
├── DesignSystem/
│   ├── AppColors.swift
│   ├── AppTypography.swift
│   ├── AppSpacing.swift
│   └── AppIcons.swift
├── Resources/
│   ├── category_keywords.json    ← generated from src/data/categories.js
│   └── default_stores.json       ← generated from src/data/stores.js
├── Tests/
└── IMPLEMENTATION_PLAN.md        ← this file
```

**Stack:** Swift, SwiftUI, SwiftData, UserDefaults for small prefs, UIKit bridge for Share Sheet only.

---

## 12. SwiftData Model Plan

### GroceryList

| Field | Type | Purpose |
|-------|------|---------|
| id | UUID | |
| name | String | “Weekly Groceries”, “Costco Run”, etc. |
| createdAt, updatedAt | Date | |
| sortOrder | Int | Sidebar order |
| isArchived | Bool | |
| items | [GroceryItem] | Cascade delete |

Default on first launch: one list named **“Weekly Groceries”** (matches Ref 11 mocks).

### GroceryItem

| Field | Type | Purpose |
|-------|------|---------|
| id | UUID | |
| name | String | Display text |
| normalizedName | String | Learning + dedup |
| quantityValue | Int? | Stepper |
| quantityText | String? | “2 lb”, “1 pack” |
| categoryId | String | Seeded category key |
| storeId | String? | |
| listId | UUID | FK |
| isCompleted | Bool | |
| iconName | String? | SF Symbol or asset key for fallback |
| imageAssetName | String? | Bundled product photo key when matched |
| sortOrder | Int | Persist reorder |
| notes | String? | Optional |
| createdAt, completedAt | Date? | |

### GroceryStore

Seed 39 from `stores.js`; support user-added stores (fixes web gap where `customStores` is never written).

### CategoryLearningRule

| Field | Type |
|-------|------|
| normalizedItemName | String (unique) |
| categoryId | String |
| useCount | Int |
| updatedAt | Date |

### AppSettings (UserDefaults)

- `hasCompletedOnboarding`
- `defaultViewMode`: list | store | category
- `categoryOrder`: [String]
- `enableHaptics`
- `showCompletedInStoreView`
- `preferredColorScheme`: system | light | dark

Categories + keywords: seed from JSON (port of `CAT_KEYWORDS`), not SwiftData entities in v1.

---

## 13. Screen-by-Screen iOS Plan

> Each screen maps to a design reference in Section 14. Build order follows Section 19.

### App shell (Ref 04, 05, 06, 11)

| Element | Spec (from references) |
|---------|------------------------|
| **Tab bar (v1)** | **Lists** · **Store** · **Categories** · **More** — 4 tabs only |
| **Tab bar (refs show)** | Some mocks include Recipes / Meals — **v2, not v1** |
| **List detail nav** | Hamburger (lists/settings) · `{List name} ▾` · Share |
| **Filter pills** | `All` · `Store` · `Category` — below add/search bar |
| **Add bar** | Rounded search field `"Add item..."` + circular **+** (hidden/disabled when empty) |

### Screen inventory

| # | Screen | Ref | Key requirements |
|---|--------|-----|------------------|
| 1 | **Onboarding — Welcome** | 01 | Skip; illustration; 4 feature rows with tinted icon squares; **Next**; 4 dots |
| 2 | **Onboarding — Add naturally** | 02 | Example inputs in card; Back / **Next**; X close |
| 3 | **Onboarding — Stay organized** | 03 | Preview card with All Items / By Store / By Category; Back / **Get Started** |
| 4 | **Onboarding — (optional 4th)** | — | Share & check-off — combine into page 1 features or add 4th page if needed |
| 5 | **My Lists** | 11 | Large title; + button; list cards (icon, name, count, chevron); tab: Lists |
| 6 | **Home — All items** | 04 | To Get (n) + Select; item rows; Picked up (n) collapsible |
| 7 | **Home — Store view** | 05 | Colored section headers (Costco, H Mart, Unassigned); + Add Custom Store |
| 8 | **Home — Category view** | 06 | Tinted category cards; icon + name + count + chevron; expandable |
| 9 | **Add item (focused)** | 07 | Modal; live **Detected** cards (Qty, Item, Store, Category); Add Item CTA |
| 10 | **Edit item sheet** | 08 | Hero row; grouped form: Qty stepper, Category, Store, List, Notes; Delete |
| 11 | **Category picker** | 09 | Search; inset grouped list; checkmark selection; includes Asian |
| 12 | **Stores picker** | 10 | Popular Stores + All Stores; logos; + Add Custom Store |
| 13 | **Create / Edit list** | 12 | Name, description, color swatches, icon picker |
| 14 | **Selection mode** | 13 | N Selected; checkboxes; bottom toolbar: Assign, Share, Copy, Delete |
| 15 | **Assign to list** | 14 | Sheet; searchable lists; + Create New List |
| 16 | **List context menu** | 15 | Share, Copy, Duplicate, Rename, Change Color & Icon, Delete |
| 17 | **Share list** | 16 | List card; Share As row; preview; Share with Others |
| 18 | **Import / Export** | 17 | Paste, Scan QR, Import file; Export text, Export QR; info footer |
| 19 | **Category order** | 18 | Drag handles; Reset to Default |
| 20 | **Settings** | 19 | Preferences, Data, App sections (inset grouped) |
| 21 | **Empty state** | 20 | Illustration; Add Item; Import List |

### Item row spec (Refs 04, 05, 13)

```
[○ checkbox] [thumbnail]  Title (qty in name ok)
                          Category • Store          [− qty +]
                                                    [⋯ menu]
```

- **Thumbnail:** **Product photo** when keyword match hits bundled asset catalog; else category illustration in tinted rounded square (Ref 04)
- **Quantity stepper:** Inline pill on list rows (Ref 04) — not only in edit sheet
- **Completed:** Move to collapsible **Picked up (n)** section; reduced opacity + strikethrough
- **Select mode:** Checkbox replaces circle; light blue row tint when selected

### Import onboarding (web parity)

When import payload arrives on first launch: full-screen welcome (web `Onboarding.jsx` import branch) before main UI — reuse Ref 03 card layout with item preview + Add / Replace.

---

## 14. Design References

All **20 references** are in `GroceryListiOS/DesignReferences/`. Use **Ref ID** in tickets.

### Approved navigation model

```
TabView (4 tabs — v1)
├── Lists          → My Lists hub (Ref 11) → tap list → List detail (Refs 04–06)
├── Store          → Store-grouped view for active list (Ref 05)
├── Categories     → Category cards for active list (Ref 06)
└── More           → Settings (19), Import/Export (17), Category Order (18)

List detail (Lists tab → NavigationStack)
├── Nav: menu  {List name ▾}  Share
├── Add bar + filter pills (All | Store | Category)
├── Item list + Picked up section
└── Sheets: Add (07), Edit (08), Share (16), Select (13)
```

**Not in v1** (visible in some mocks): Recipes tab, Meal Plan tab → v2.

### Reference catalog

| Ref | Screen | File suffix | Borrow | Avoid |
|-----|--------|-------------|--------|-------|
| **01** | Onboarding — Welcome | `47_AM__1_` | Skip; feature rows; full-width Next; 4 dots | Tap-anywhere-only nav |
| **02** | Onboarding — Add naturally | `47_AM__2_` | Example input card; Back + Next | — |
| **03** | Onboarding — Stay organized | `47_AM__3_` | Segmented preview; Get Started | — |
| **04** | Home — All items | `47_AM__4_` | Add bar; filter pills; qty stepper; Category • Store | Recipes tab |
| **05** | Home — Store view | `47_AM__5_` | Tinted store headers; logos; + Add Custom Store | — |
| **06** | Home — Category view | `47_AM__6_` | Tinted category cards; counts; chevrons | Meal Plan tab |
| **07** | Add item (focused) | `47_AM__7_` | Live Detected grid (Qty, Item, Store, Category) | — |
| **08** | Edit item | `47_AM__8_` | Grouped form; stepper; chevron pickers; Delete | — |
| **09** | Category picker | `47_AM__9_` | Search; checkmark; Asian category | Emoji list |
| **10** | Stores picker | `47_AM__10_` | Popular stores + logos; Add Custom Store | Network-only favicons |
| **11** | My Lists | `53_AM__1_` | List cards; color icons; item counts | — |
| **12** | Create / Edit list | `53_AM__2_` | Name; description; color + icon pickers | — |
| **13** | Selection mode | `53_AM__3_` | Floating toolbar: Assign, Share, Copy, Delete | — |
| **14** | Assign to list | `53_AM__4_` | Search lists; Create New List | — |
| **15** | List context menu | `53_AM__5_` | Share, Copy, Duplicate, Rename, Color, Delete | — |
| **16** | Share list | `53_AM__6_` | Summary card; Share As; preview; Share with Others | Emoji share text |
| **17** | Import / Export | `53_AM__7_` | Paste, QR, file; export text/QR; info callout | — |
| **18** | Category order | `53_AM__8_` | Drag reorder; Reset to Default | — |
| **19** | Settings | `53_AM__9_` | Preferences / Data / App inset grouped | — |
| **20** | Empty state | `53_AM__10_` | Bag illustration; Add Item; Import List | Emoji empty state |

### Design decisions (resolved)

| Decision | Choice |
|----------|--------|
| Layout | 4-tab bar + list detail stack |
| Row density | Comfortable (~72pt) with thumbnail + stepper |
| Quick-add | Top inline search bar (Ref 04) |
| Category UI | `Category • Store` subtitle + tinted cards in category tab |
| Paper personality | **2/10** — white UI; illustrations on onboarding/empty only |
| Primary buttons | Dark navy `#1A1F36` |
| Success / produce | Web green `#4A7C59` |
| Thumbnails | **Product photos v1** — bundled assets + category fallback (see §15 Product imagery) |

### Reference → feature traceability

| Feature | Ref(s) |
|---------|--------|
| Natural input + detect preview | 02, 07 |
| Quantity stepper | 04, 08 |
| List / Store / Category views | 03–06 |
| Named lists + context menu | 11, 12, 15 |
| Multi-select + assign | 13, 14 |
| Share + import/export | 16, 17, 20 |
| Category order + settings | 18, 19 |
| Onboarding Back/Next | 01–03 |
| Asian / Indian support | 05, 06, 09, 11 |

---

## 15. Native iOS Design System Direction

> **Finalized** from 20 design references. Web notepad styling does **not** apply to main shopping UI.

### Personality

Clean native iOS grocery app. Warmth from **illustrations** (onboarding, empty) and **soft category tints** — not paper texture or handwritten fonts on list rows.

### Color palette

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `backgroundPrimary` | `#FFFFFF` | `#000000` | Main screens |
| `backgroundGrouped` | `#F2F2F7` | `#1C1C1E` | Settings, forms |
| `ink` | `#1A1F36` | `#F5F5F7` | Headlines, primary buttons |
| `inkSecondary` | `#6B7280` | `#98989D` | Metadata |
| `accentLink` | `#007AFF` | `#0A84FF` | Cancel, Done |
| `accentSuccess` | `#4A7C59` | `#5E9A6E` | Checkmarks, produce |
| `accentDestructive` | `#FF3B30` | `#FF453A` | Delete |
| `filterSelected` | `#1A1F36` | `#F5F5F7` | Selected pill |
| `filterUnselected` | `#F3F4F6` | `#3A3A3C` | Unselected pill |

### Category / store tints (cards & headers)

| Key | Light background |
|-----|------------------|
| Dairy | `#E8F4FD` |
| Produce | `#E8F5E9` |
| Pantry | `#FFF3E0` |
| Snacks | `#FCE4EC` |
| Asian | `#F3E5F5` |
| Household | `#ECEFF1` |
| Costco header | `#FDE8E8` |
| H Mart header | `#E8EAF6` |
| Unassigned | `#F3F4F6` |

### Typography

| Role | Spec |
|------|------|
| Large title | 34pt bold — "My Lists" |
| Item title | 17pt semibold |
| Metadata | 14pt — `Category • Store` |
| Onboarding title | 28–32pt bold |

SF Pro throughout. No Patrick Hand on shopping screens.

### Spacing & shape

| Token | Value |
|-------|-------|
| screenHorizontal | 16pt |
| cardCornerRadius | 16pt |
| rowMinHeight | 72pt |
| addBarHeight | 48pt |
| buttonCornerRadius | 14pt |

### Key components

- **Quick add bar (Ref 04):** `#F3F4F6` rounded field + circular `+` (hidden when empty)
- **Item row (Ref 04):** checkbox · 40×40 thumbnail · title + metadata · qty stepper pill
- **List card (Ref 11):** white card, 48×48 tinted icon, title, count, chevron
- **Selection toolbar (Ref 13):** floating `#1A1F36` capsule; Delete in red
- **Settings (Ref 19):** inset grouped Form with colored row icons

### Illustrations & product imagery (Assets.xcassets)

| Asset type | Count (v1 target) | Used on |
|------------|-------------------|---------|
| Onboarding / empty illustrations | 3 | Refs 01, 12, 20 |
| Category icons (tinted squares) | 16 | Fallback thumbnails, category tab |
| **Product photos** | **~150–250 curated** | Item rows (Ref 04), edit sheet hero (Ref 08) |

#### Product photo strategy (v1 — premium look)

Refs 04, 05, 08, 13 show **realistic product thumbnails**. Include them in v1 for the polished App Store feel.

**Display priority (offline, local-first):**

1. **Saved per-item override** — user picked/edited image (optional, rare)
2. **Keyword → bundled product photo** — longest match on normalized item name (same logic as web `itemIcons.js`, but photo assets instead of emoji)
3. **Category illustration** — tinted 40×40 rounded square (never a blank or generic gray box)

**Implementation:**

- Port keyword list from `src/itemIcons.js` / `itemEmojis.js` → `product_image_map.json` mapping normalized keywords to asset names
- Curate **~150–250 high-quality PNG/WebP** assets for common US + Indian/Asian items (milk, eggs, gochujang, basmati, paneer, kimchi, bananas, etc.)
- `ProductImageCatalog` resolves at add-time and caches `imageAssetName` on `GroceryItem`
- Assets grouped in Xcode: `Products/`, `Products-Asian/`, `Products-Indian/` for maintainability
- Target **~5–15 MB** total image payload — acceptable for a premium grocery app

**Do not use in v1:**

- Network image APIs while shopping (slow, offline breaks, privacy)
- 1,280 unique photos (web emoji scale) — diminishing returns; keyword match + category fallback covers the rest elegantly

**Fallback quality matters:** Category illustrations should match Ref 06 style (soft 3D-ish icons), not plain SF Symbols alone, so unknown items still look intentional.

| Marketing illustration | Ref |
|------------------------|-----|
| `illustration-onboarding-basket` | 01 |
| `illustration-create-list` | 12 |
| `illustration-empty-bag` | 20 |

### SF Symbols (chrome)

`plus`, `square.and.arrow.up`, `ellipsis.circle`, `line.3.horizontal`, `storefront`, `square.grid.2x2`, `list.bullet`, `gearshape`, `qrcode`, `doc.on.clipboard`, `checkmark.circle.fill`, `circle`

### Haptics & accessibility

- Haptics: check (light), add (medium), delete (medium), import (success)
- VoiceOver: full item context including qty, category, store, checked state
- Dynamic Type: metadata wraps at XL sizes

---

## 16. Sharing, Import, and Export Plan

### v1 channels

1. **Copy as text** — Share Sheet / clipboard
2. **Share link** — web-compatible `#import=` URL (50 item cap)
3. **QR code** — CoreImage; same URL as web
4. **Paste import** — detect base64 or full URL in clipboard
5. **JSON export** — full SwiftData backup (all lists, no 50 cap)

### Import flow

1. Decode payload (same as `decodeList` in `utils.js`)
2. Show preview sheet: item count, sample rows
3. Actions: **Add to current list** | **Replace current list** | Cancel
4. First-time users: full-screen import welcome (like web onboarding import branch)

### v2

- Universal links on custom domain
- Live shared lists via Supabase
- Share extension: “Add to Grocery List”

---

## 17. Backend / Sync Recommendation

| Version | Approach |
|---------|----------|
| **v1** | SwiftData only — no network required |
| **v2 primary** | **Supabase** — cross-platform, web parity, family lists, realtime |
| **v2 alt** | **CloudKit** — Apple-only, iCloud, no separate accounts |
| **v2 if push-first** | Firebase — realtime + push; weaker relational fit |

---

## 18. Web / Marketing Roadmap

Separate from iOS build; web app unchanged unless approved:

1. Custom domain
2. Marketing landing page + App Store link
3. App Store preview / privacy policy page
4. SEO landing (existing `index.html` stays as PWA demo)
5. Universal links (AASA)
6. “Try web demo” CTA before download

---

## 19. Implementation Phases

| Phase | Deliverable | Depends on |
|-------|-------------|------------|
| **1 — Audit** | This document | — |
| **2 — Design** | Reference mapping (§14) complete; tokens finalized (§15) | Done |
| **3 — Project setup** | Xcode project, SwiftData, seed JSON | Phase 2 tokens |
| **4 — Core items** | CRUD, check, undo, completed, sortOrder | Phase 3 |
| **5 — Parsing** | Quantity, store, category + tests | Phase 3 |
| **6 — Views** | List / Store / Category, lists management | Phase 4–5 |
| **7 — Learning dict** | Category overrides + detection priority | Phase 5 |
| **8 — Polish** | SF Symbols, haptics, swipe, onboarding, dark mode | Phase 2 design |
| **9 — Share / import** | Formatter, codec, QR, paste import | Phase 5 |
| **10 — Test & ship** | XCTest, TestFlight, App Store assets | All |
| **11 — V2 spec** | Supabase schema + sync UX | Post-launch |

**Suggested start:** Phase 3 (Xcode scaffold) → Phase 4–5 (core + parsers) → Phase 6 (views per Refs 04–06, 11).

---

## 20. Testing Plan

### Unit tests

- `QuantityParserService` — web patterns + unit strings
- `CategoryDetectionService` — paneer, gochujang, basmati, etc.
- Learning rules override keywords
- `ImportExportService` — round-trip vs web-encoded fixtures
- Store tag edge cases

### Integration tests

- SwiftData persistence across relaunch
- Import add vs replace counts

### UI smoke tests

- Onboarding → add → check → delete → undo
- Segment switching
- Share sheet presents

### Manual QA

- Dynamic Type XL, VoiceOver, light/dark
- Offline airplane mode
- QR scan from web-generated link

---

## 21. Risks and Open Questions

| Risk | Mitigation |
|------|------------|
| Keyword drift web ↔ iOS | Build script: `categories.js` → JSON |
| 50-item URL limit | Text / JSON for large lists |
| SF Symbol coverage for all items | Category + ~50 common items; default `cart` |
| Design references conflict | Priority order in §14 reference log |

### Open questions

1. Minimum iOS — recommend **iOS 17+**
2. ~~Default list name~~ — **Resolved:** “Weekly Groceries”
3. Import target — active list only or picker?
4. Home screen name — “Grocery List” vs “Groceries”?
5. Monetization — free v1 assumed?

---

## 22. Files To Be Created or Changed

### Created (iOS only)

```
GroceryListiOS/
  IMPLEMENTATION_PLAN.md          ← this file
  DesignReferences/               ← 20 approved UI mocks
  GroceryList.xcodeproj
  … (see §11)
```

### Web repo — untouched by default

No changes to `src/`, `index.html`, `vite.config.js`, `vercel.json`.

### Optional (with approval)

| File | Purpose |
|------|---------|
| `README.md` | Link to iOS project |
| `scripts/export-seed-data.mjs` | Export categories/stores for iOS seed |

---

## 23. Final Recommendation

1. ~~Share design references~~ → **Done** — 20 refs mapped in §14, tokens in §15  
2. **Scaffold** `GroceryListiOS/` Xcode project with SwiftData + DesignSystem from §15  
3. **Port logic first** (parsers, categories, codec) with tests  
4. **Build shell** — 4-tab bar + list detail (Refs 04, 11) then remaining screens  
5. **Ship v1 local-first**; plan Supabase v2 for shared lists + custom domain links  

The web app remains the **behavioral spec**. The iOS app follows the **approved native design references** with expanded v1 features (lists, category view, learning dictionary, stepper, custom category order).

---

*Document generated from full repository audit of [grocerylistapp](https://github.com/KrishnaSathvik/grocerylistapp). Design references added June 28, 2026.*
