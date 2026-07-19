# Product assets to regenerate

Master replacement queue after 2026-07-18 cleanup + B1/B2/B8 + B3A + B4A + B5A + B5B + B6A + B6B + B7A + B7B + B7C + **B7D**.

`PRODUCT_ASSETS_TO_REGENERATE.md` is the **single replacement queue**. Do not maintain a competing legacy-only list.

## Summary

| Metric | Count |
|--------|------:|
| Total canonical products | **182** |
| Approved photorealistic assets | **182** |
| Awaiting first / replacement photorealistic asset | **0** |
| B1/B2 failed still pending | **0** (B8 complete) |

## Suggested batch sequence

| Batch | Scope | Status |
|-------|-------|--------|
| B8 correction | 10 failed B1/B2 produce regenerations | **Complete** |
| B3A | Dairy/refrigerated subset (10) | **Complete** |
| B4A | Pantry/sauces/oils subset (10) | **Complete** |
| B5A | Meat/seafood/frozen subset (10) | **Complete** |
| B5B | Meat/seafood/frozen subset (10) | **Complete** |
| B6A | Beverages/snacks subset (10) | **Complete** |
| B3B | Remaining dairy/bakery/eggs | Superseded by B7D |
| B4B | Remaining pantry, grains, sauces, canned | Superseded by B7D |
| B6B | Remaining beverages and snacks (10) | **Complete** |
| B7A | Household/care/health/baby subset (10) | **Complete** |
| B7B | Remaining household, pet, floral + queue fills (10) | **Complete** |
| B7C | Next 10 remaining queue entries | **Complete** |
| B7D | Final 18 remaining queue entries | **Complete** |
| B8 remaining | Remaining produce without photoreal assets | **Complete** (via B7D) |

## A) Failed B1/B2 assets

_None remaining — all 10 installed and approved in B8 on 2026-07-18._

## B) Legacy / missing photoreal assets (PNG absent; category fallback)

_None remaining — final 18 installed and approved in B7D on 2026-07-18._

## Removed from queue (completed)

### B8 correction (2026-07-18)

`plantains`, `custard-apple`, `long-beans`, `dill`, `rosemary`, `thyme`, `green-beans`, `zucchini`, `mint`, `curry-leaves`

### B3A dairy/refrigerated (2026-07-18)

`milk-coconut`, `milk-condensed`, `milk-evaporated`, `ghee`, `cream-cheese`, `cottage-cheese`, `paneer`, `coffee-creamer`

Also newly catalogued and approved (not previously in queue): `heavy-cream`, `sour-cream`

### B4A pantry/sauces/oils (2026-07-18)

`apple-cider-vinegar`, `tomato-sauce`, `tomato-paste`, `canned-tomatoes`, `pasta-sauce`, `rice-noodles`, `rice-vinegar`, `rice-cakes`, `avocado-oil`, `almond-butter`

### B5A meat/seafood/frozen (2026-07-18)

`chicken-wings`, `chicken-thighs`, `rotisserie-chicken`, `chicken-broth`, `tuna-steak`, `salmon`, `shrimp`, `frozen-vegetables`, `pizza-rolls`, `bacon`

Substitutions vs requested wishlist: `tuna`→`tuna-steak`; `fish-sticks`→`salmon`; `french-fries`→`shrimp`; `chicken-nuggets`→`bacon` (missing canonicals not created).

### B5B meat/seafood/frozen (2026-07-18)

`chicken-breast`, `turkey-breast`, `ground-turkey`, `ground-beef`, `steak`, `pork`, `sausage`, `frozen-pizza`, `ice-cream`, `hummus`

Substitutions vs requested wishlist: `whole-chicken`→`chicken-breast`; missing lamb/goat/meatballs/burger-patties/ham/ribs/hot-dogs/scallops filled via ordered fallbacks + next frozen/deli queue (`ice-cream`, `hummus`). No new canonicals.

### B6A beverages/snacks (2026-07-18)

`ginger-ale`, `root-beer`, `coconut-water`, `apple-juice`, `cranberry-juice`, `grape-juice`, `juice-boxes`, `granola-bars`, `chips`, `water`

Substitutions vs requested wishlist: missing `cola`, `lemon-lime-soda`, `sports-drink`, `sparkling-water` (no separate canonicals) filled via ordered fallbacks `juice-boxes`, `granola-bars`, `chips` (potato-chips), `water` (bottled-water). No new canonicals.

### B6B snacks / remaining beverages (2026-07-18)

`cereal`, `peanut-butter`, `tea`, `coffee`, `beer`, `orange-juice`, `milk-almond`, `milk-oat`, `milk-soy`, `soup`

All priority snack IDs (energy-drink, popcorn, crackers, pretzels, nuts, trail-mix, candy, chocolate, cookies, protein-bars) missing from catalog. Selected via ordered fallbacks + remaining drinks/pantry queue fills. No new canonicals.

### B7A household / care / health / baby (2026-07-18)

`dish-soap`, `disinfecting-wipes`, `toilet-paper`, `paper-towels`, `shampoo`, `conditioner`, `toothpaste`, `diapers`, `baby-wipes`, `diaper-cream`

Missing priority IDs: laundry-detergent, all-purpose-cleaner, trash-bags, hand-soap, body-wash. Filled via ordered fallbacks. No new canonicals.

### B7B remaining household / pet / floral + queue fills (2026-07-18)

`dog-food`, `cat-food`, `pet-shampoo`, `flowers`, `bagels`, `banana-bread`, `bread-loaf`, `butter`, `cheese`, `egg-noodles`

All priority household IDs (deodorant, toothbrush, mouthwash, razors, tissues, aluminum-foil, plastic-wrap, storage-bags, sponges, pain-reliever) missing from catalog. Selected via ordered fallbacks + remaining B7 floral + bakery/dairy/pantry queue fills. No new canonicals.

### B7C next remaining queue replacements (2026-07-18)

`apples`, `avocados`, `bananas`, `cilantro`, `eggs-brown`, `eggs-white`, `flour`, `gochujang`, `kimchi`, `lemons`

Selected as the first 10 entries in regeneration-queue order. No substitutions. No new canonicals.

### B7D final remaining queue replacements (2026-07-18)

`lettuce`, `limes`, `milk-whole`, `naan`, `olive-oil`, `onions`, `paratha`, `pasta`, `pita`, `potatoes`, `rice-basmati`, `rice-white`, `roti`, `shallots`, `spinach`, `tomatoes`, `tortillas`, `yogurt`

All remaining regeneration-queue entries. No substitutions. No new canonicals.
