#!/usr/bin/env node
/**
 * Exports web app taxonomy → iOS catalog JSON (source of truth).
 * Run: node scripts/export-ios-catalog.mjs
 */
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { CATEGORIES, CAT_KEYWORDS } from "../src/data/categories.js";
import { DEFAULT_STORES } from "../src/data/stores.js";
import { ITEM_ICONS } from "../src/itemIcons.js";
import { keywordMatches, categoryTokens } from "../src/detectCategory.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = join(__dirname, "../GroceryListiOS/GroceryList/Resources");

mkdirSync(outDir, { recursive: true });

/** Canonical products — roots used to attach ITEM_ICONS aliases. */
const CANONICAL_PRODUCTS = [
  { id: "milk-whole", displayName: "Milk", categoryId: "dairy", roots: ["milk", "whole milk", "2% milk", "skim milk", "buttermilk", "lactose free milk"] },
  { id: "milk-oat", displayName: "Oat Milk", categoryId: "drinks", roots: ["oat milk"] },
  { id: "milk-almond", displayName: "Almond Milk", categoryId: "drinks", roots: ["almond milk", "plant milk"] },
  { id: "milk-soy", displayName: "Soy Milk", categoryId: "drinks", roots: ["soy milk"] },
  { id: "eggs-white", displayName: "Eggs", categoryId: "dairy", roots: ["egg", "eggs", "egg whites", "dozen eggs", "anda"] },
  { id: "eggs-brown", displayName: "Brown Eggs", categoryId: "dairy", roots: ["brown egg", "brown eggs"] },
  { id: "butter", displayName: "Butter", categoryId: "dairy", roots: ["butter", "unsalted butter", "salted butter", "margarine", "makhan", "ghee"] },
  { id: "cheese", displayName: "Cheese", categoryId: "dairy", roots: ["cheese", "cheddar", "mozzarella", "parmesan", "shredded cheese", "cream cheese", "cottage cheese", "paneer"] },
  { id: "yogurt", displayName: "Yogurt", categoryId: "dairy", roots: ["yogurt", "greek yogurt", "yoghurt", "dahi", "curd"] },
  { id: "bananas", displayName: "Bananas", categoryId: "produce", roots: ["banana", "bananas"] },
  { id: "apples", displayName: "Apples", categoryId: "produce", roots: ["apple", "apples", "green apple"] },
  { id: "tomatoes", displayName: "Tomatoes", categoryId: "produce", roots: ["tomato", "tomatoes", "cherry tomato", "grape tomato"] },
  { id: "onions", displayName: "Onions", categoryId: "produce", roots: ["onion", "onions", "red onion", "green onion", "scallion", "shallot"] },
  { id: "potatoes", displayName: "Potatoes", categoryId: "produce", roots: ["potato", "potatoes", "sweet potato", "sweet potatoes", "aloo"] },
  { id: "cilantro", displayName: "Cilantro", categoryId: "produce", roots: ["cilantro", "dhaniya"] },
  { id: "spinach", displayName: "Spinach", categoryId: "produce", roots: ["spinach", "baby spinach", "palak"] },
  { id: "avocados", displayName: "Avocados", categoryId: "produce", roots: ["avocado", "avocados"] },
  { id: "lemons", displayName: "Lemons", categoryId: "produce", roots: ["lemon", "lemons", "lime", "limes"] },
  { id: "bread-loaf", displayName: "Bread", categoryId: "bakery", roots: ["bread", "white bread", "wheat bread", "whole wheat bread", "sourdough", "rye bread"] },
  { id: "bagels", displayName: "Bagels", categoryId: "bakery", roots: ["bagel", "bagels"] },
  { id: "tortillas", displayName: "Tortillas", categoryId: "bakery", roots: ["tortilla", "tortillas", "flour tortilla", "corn tortilla", "wrap", "wraps"] },
  { id: "naan", displayName: "Naan", categoryId: "bakery", roots: ["naan", "roti", "chapati", "paratha", "pita", "pita bread", "flatbread"] },
  { id: "chicken-breast", displayName: "Chicken", categoryId: "meat", roots: ["chicken", "chicken breast", "chicken thigh", "chicken wings", "murgh", "rotisserie chicken"] },
  { id: "ground-beef", displayName: "Ground Beef", categoryId: "meat", roots: ["ground beef", "beef stew"] },
  { id: "steak", displayName: "Steak", categoryId: "meat", roots: ["steak", "sirloin", "ribeye", "flank steak"] },
  { id: "bacon", displayName: "Bacon", categoryId: "meat", roots: ["bacon", "turkey bacon"] },
  { id: "pork", displayName: "Pork", categoryId: "meat", roots: ["pork", "pork chop", "pork chops", "pork loin"] },
  { id: "salmon", displayName: "Salmon", categoryId: "seafood", roots: ["salmon", "salmon fillet", "smoked salmon", "lox"] },
  { id: "shrimp", displayName: "Shrimp", categoryId: "seafood", roots: ["shrimp", "prawns", "jhinga"] },
  { id: "rice-basmati", displayName: "Basmati Rice", categoryId: "pantry", roots: ["basmati", "basmati rice"] },
  { id: "rice-white", displayName: "Rice", categoryId: "pantry", roots: ["rice", "white rice", "brown rice", "jasmine rice", "chawal"] },
  { id: "pasta", displayName: "Pasta", categoryId: "pantry", roots: ["pasta", "spaghetti", "penne", "macaroni", "linguine", "fettuccine"] },
  { id: "flour", displayName: "Flour", categoryId: "pantry", roots: ["flour", "all purpose flour", "atta", "maida", "bread flour"] },
  { id: "olive-oil", displayName: "Olive Oil", categoryId: "condiments", roots: ["olive oil", "extra virgin olive oil"] },
  { id: "gochujang", displayName: "Gochujang", categoryId: "condiments", roots: ["gochujang"] },
  { id: "kimchi", displayName: "Kimchi", categoryId: "deli", roots: ["kimchi"] },
  { id: "coffee", displayName: "Coffee", categoryId: "drinks", roots: ["coffee", "ground coffee", "coffee beans", "instant coffee", "espresso"] },
  { id: "tea", displayName: "Tea", categoryId: "drinks", roots: ["tea", "green tea", "black tea", "chai", "matcha", "chai patti"] },
  { id: "water", displayName: "Water", categoryId: "drinks", roots: ["water", "bottled water", "sparkling water"] },
  { id: "orange-juice", displayName: "Orange Juice", categoryId: "drinks", roots: ["orange juice", "juice"] },
  { id: "ice-cream", displayName: "Ice Cream", categoryId: "frozen", roots: ["ice cream", "gelato", "kulfi", "frozen yogurt"] },
  { id: "frozen-pizza", displayName: "Frozen Pizza", categoryId: "frozen", roots: ["frozen pizza", "pizza"] },
  { id: "chips", displayName: "Chips", categoryId: "snacks", roots: ["chips", "potato chips", "tortilla chips"] },
  { id: "paper-towels", displayName: "Paper Towels", categoryId: "household", roots: ["paper towel", "paper towels"] },
  { id: "toilet-paper", displayName: "Toilet Paper", categoryId: "household", roots: ["toilet paper", "bath tissue"] },
  { id: "dish-soap", displayName: "Dish Soap", categoryId: "household", roots: ["dish soap", "dishwashing liquid", "dawn"] },
  { id: "diapers", displayName: "Diapers", categoryId: "baby", roots: ["diaper", "diapers", "nappy", "pull-ups"] },
  { id: "dog-food", displayName: "Dog Food", categoryId: "pet", roots: ["dog food", "kibble", "dog kibble"] },
  // Tier A — high-frequency gaps
  { id: "flowers", displayName: "Flowers", categoryId: "floral", roots: ["flowers", "flower", "bouquet", "bouquets", "fresh flowers"] },
  { id: "cereal", displayName: "Cereal", categoryId: "pantry", roots: ["cereal", "corn flakes", "frosted flakes", "cheerios", "oatmeal"] },
  { id: "lettuce", displayName: "Lettuce", categoryId: "produce", roots: ["lettuce", "romaine", "iceberg lettuce", "spring mix"] },
  { id: "soup", displayName: "Soup", categoryId: "pantry", roots: ["soup", "canned soup", "chicken soup", "tomato soup"] },
  { id: "toothpaste", displayName: "Toothpaste", categoryId: "health", roots: ["toothpaste"] },
  { id: "shampoo", displayName: "Shampoo", categoryId: "health", roots: ["shampoo", "conditioner"] },
  { id: "sausage", displayName: "Sausage", categoryId: "meat", roots: ["sausage", "sausages", "italian sausage", "bratwurst", "kielbasa"] },
  { id: "cat-food", displayName: "Cat Food", categoryId: "pet", roots: ["cat food", "kitty food", "cat kibble"] },
  // Tier B — category balance
  { id: "peanut-butter", displayName: "Peanut Butter", categoryId: "pantry", roots: ["peanut butter", "almond butter"] },
  { id: "granola-bars", displayName: "Granola Bars", categoryId: "snacks", roots: ["granola bar", "granola bars", "cereal bar", "cereal bars", "protein bar", "protein bars"] },
  { id: "ground-turkey", displayName: "Ground Turkey", categoryId: "meat", roots: ["ground turkey", "turkey breast"] },
  { id: "beer", displayName: "Beer", categoryId: "drinks", roots: ["beer", "ipa", "lager", "ale", "stout", "craft beer"] },
  { id: "hummus", displayName: "Hummus", categoryId: "deli", roots: ["hummus"] },
  { id: "frozen-vegetables", displayName: "Frozen Vegetables", categoryId: "frozen", roots: ["frozen vegetables", "frozen veggies", "frozen peas", "frozen corn"] },
  { id: "baby-wipes", displayName: "Baby Wipes", categoryId: "baby", roots: ["baby wipes", "wet wipes"] },
];

function assignKeywordsToProducts() {
  const products = CANONICAL_PRODUCTS.map((p) => ({
    ...p,
    keywords: [...new Set(p.roots)],
  }));

  const iconKeys = Object.keys(ITEM_ICONS).sort((a, b) => b.length - a.length);

  for (const key of iconKeys) {
    let bestProduct = null;
    let bestLen = 0;
    const nameTokens = categoryTokens(key);

    for (const product of products) {
      for (const root of product.roots) {
        if (!keywordMatches(nameTokens, root)) continue;
        if (root.length > bestLen) {
          bestProduct = product;
          bestLen = root.length;
        }
      }
    }

    if (bestProduct && !bestProduct.keywords.includes(key)) {
      bestProduct.keywords.push(key);
    }
  }

  return products.map((p) => ({
    id: p.id,
    displayName: p.displayName,
    assetName: `product-${p.id}`,
    categoryId: p.categoryId,
    keywords: [...new Set(p.keywords)].sort((a, b) => b.length - a.length),
  }));
}

// ── Category catalog ────────────────────────────────────────────────────────

const categoryIds = Object.keys(CATEGORIES);
const categoryCatalog = categoryIds.map((id, index) => {
  const meta = CATEGORIES[id];
  return {
    id,
    displayName: meta.label,
    assetName: `category-${id}`,
    colorKey: id,
    colorHex: meta.color,
    sortOrder: (index + 1) * 10,
    keywords: CAT_KEYWORDS[id] ?? [],
  };
});

// ── Product catalog ─────────────────────────────────────────────────────────

const productCatalog = assignKeywordsToProducts();

// ── Legacy seed files (backward compatible) ─────────────────────────────────

const categoriesPayload = {
  categories: categoryIds.map((id) => ({
    id,
    label: CATEGORIES[id].label,
    color: CATEGORIES[id].color,
    emoji: CATEGORIES[id].emoji,
  })),
  keywords: CAT_KEYWORDS,
};

const storesPayload = {
  stores: Object.entries(DEFAULT_STORES).map(([id, meta]) => ({
    id,
    label: meta.label,
    domain: meta.domain,
    color: meta.color,
  })),
};

const emojiMap = Object.entries(ITEM_ICONS)
  .map(([keyword, emoji]) => ({ keyword, emoji }))
  .sort((a, b) => b.keyword.length - a.keyword.length);

// ── Asset manifest for image generation ─────────────────────────────────────

const CATEGORY_PROMPTS = {
  produce: "grouped fresh fruits and vegetables, soft 3D realistic illustration, transparent background",
  dairy: "milk carton, cheese wedge, and eggs grouped together, soft 3D illustration, transparent background",
  meat: "raw chicken breast and beef cuts grouped, soft 3D illustration, transparent background",
  seafood: "fish fillet and shrimp grouped, soft 3D illustration, transparent background",
  bakery: "loaf of bread, croissant, and bagel grouped, soft 3D illustration, transparent background",
  deli: "sliced deli meats and hummus grouped, soft 3D illustration, transparent background",
  frozen: "frozen vegetables and ice cream grouped, soft 3D illustration, transparent background",
  pantry: "rice bag, pasta box, and canned goods grouped, soft 3D illustration, transparent background",
  snacks: "chips bag, cookies, and popcorn grouped, soft 3D illustration, transparent background",
  condiments: "spice jars, hot sauce, and olive oil bottle grouped, soft 3D illustration, transparent background",
  drinks: "water bottle, juice carton, and coffee bag grouped, soft 3D illustration, transparent background",
  household: "paper towels, dish soap, and cleaning supplies grouped, soft 3D illustration, transparent background",
  health: "shampoo bottle, toothpaste, and vitamins grouped, soft 3D illustration, transparent background",
  baby: "diapers and baby formula grouped, soft 3D illustration, transparent background",
  pet: "dog food bag and pet treats grouped, soft 3D illustration, transparent background",
  floral: "fresh flower bouquet with roses and tulips grouped, soft 3D illustration, transparent background",
  misc: "generic grocery bag with mixed items, soft 3D illustration, transparent background",
};

const assetManifest = [
  ...categoryCatalog.map((c) => ({
    assetName: c.assetName,
    type: "category",
    categoryId: c.id,
    displayName: c.displayName,
    priority: 1,
    prompt: CATEGORY_PROMPTS[c.id] ?? `grouped ${c.displayName.toLowerCase()} groceries, soft 3D realistic illustration, transparent background, no text`,
  })),
  ...productCatalog.map((p, index) => ({
    assetName: p.assetName,
    type: "product",
    productId: p.id,
    categoryId: p.categoryId,
    displayName: p.displayName,
    priority: index < 20 ? 2 : 3,
    prompt: `${p.displayName.toLowerCase()}, single grocery product, soft 3D realistic illustration, transparent background, centered, no text, no brand`,
  })),
];

// ── Write files ─────────────────────────────────────────────────────────────

writeFileSync(join(outDir, "category_catalog.json"), JSON.stringify(categoryCatalog, null, 2) + "\n");
writeFileSync(join(outDir, "product_catalog.json"), JSON.stringify(productCatalog, null, 2) + "\n");
writeFileSync(join(outDir, "asset_manifest.json"), JSON.stringify(assetManifest, null, 2) + "\n");
writeFileSync(join(outDir, "category_keywords.json"), JSON.stringify(categoriesPayload, null, 2) + "\n");
writeFileSync(join(outDir, "default_stores.json"), JSON.stringify(storesPayload, null, 2) + "\n");
writeFileSync(join(outDir, "item_emoji_map.json"), JSON.stringify(emojiMap, null, 2) + "\n");

// Legacy product map for migration period
const legacyProductMap = productCatalog.flatMap((p) =>
  p.keywords.slice(0, 3).map((keyword) => ({ keyword, assetName: p.assetName }))
);
writeFileSync(join(outDir, "product_image_map.json"), JSON.stringify(legacyProductMap, null, 2) + "\n");

console.log(`Wrote category_catalog.json (${categoryCatalog.length} categories)`);
console.log(`Wrote product_catalog.json (${productCatalog.length} products)`);
console.log(`Wrote asset_manifest.json (${assetManifest.length} assets)`);
console.log(`Wrote category_keywords.json, default_stores.json, item_emoji_map.json`);
console.log(`Wrote product_image_map.json (${legacyProductMap.length} keyword mappings)`);
