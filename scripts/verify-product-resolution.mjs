#!/usr/bin/env node
/**
 * Verifies product thumbnail resolution via catalog keywords.
 * Run: npm run verify-product-resolution
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const catalogPath = join(
  __dirname,
  "../GroceryListiOS/GroceryList/Resources/product_catalog.json"
);
const products = JSON.parse(readFileSync(catalogPath, "utf8"));

function tokens(value) {
  return value
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter(Boolean);
}

function keywordMatches(nameTokens, keyword) {
  const keywordTokens = tokens(keyword);
  if (!keywordTokens.length || keywordTokens.length > nameTokens.length) return false;
  if (keywordTokens.length === nameTokens.length) {
    return keywordTokens.every((t, i) => t === nameTokens[i]);
  }
  const maxStart = nameTokens.length - keywordTokens.length;
  for (let start = 0; start <= maxStart; start += 1) {
    const candidate = nameTokens.slice(start, start + keywordTokens.length);
    if (candidate.every((t, i) => t === keywordTokens[i])) return true;
  }
  return false;
}

const PRODUCE_FORM_BLOCK_TOKENS = new Set([
  "powder",
  "seasoning",
  "spice",
  "extract",
  "seeds",
  "seed",
  "mix",
  "sauce",
  "paste",
  "chutney",
  "pesto",
  "chips",
]);

function resolveProduct(itemName) {
  const nameTokens = tokens(itemName.trim());
  if (!nameTokens.length) return null;
  const nameHasProduceFormBlock = nameTokens.some((t) => PRODUCE_FORM_BLOCK_TOKENS.has(t));

  let best = null;
  let bestLen = 0;
  for (const product of products) {
    for (const keyword of product.keywords) {
      const keywordTokens = tokens(keyword);
      if (
        nameHasProduceFormBlock &&
        product.categoryId === "produce" &&
        !keywordTokens.some((t) => PRODUCE_FORM_BLOCK_TOKENS.has(t))
      ) {
        continue;
      }
      if (!keywordMatches(nameTokens, keyword)) continue;
      if (keyword.length > bestLen) {
        best = product;
        bestLen = keyword.length;
      }
    }
  }
  return best?.assetName ?? null;
}

const cases = [
  // Legacy / tier coverage
  ["flowers", "product-flowers"],
  ["bouquet", "product-flowers"],
  ["corn flakes", "product-cereal"],
  ["lettuce", "product-lettuce"],
  ["canned soup", "product-soup"],
  ["toothpaste", "product-toothpaste"],
  ["shampoo", "product-shampoo"],
  ["italian sausage", "product-sausage"],
  ["cat food", "product-cat-food"],
  ["peanut butter", "product-peanut-butter"],
  ["granola bars", "product-granola-bars"],
  ["protein bars", "product-granola-bars"],
  ["ground turkey", "product-ground-turkey"],
  ["ipa", "product-beer"],
  ["hummus", "product-hummus"],
  ["frozen vegetables", "product-frozen-vegetables"],
  ["baby wipes", "product-baby-wipes"],
  ["dog food", "product-dog-food"],
  ["milk", "product-milk-whole"],
  ["flour", "product-flour"],
  ["flowers", "product-flowers"],
  // Phase B1 — essential produce
  ["oranges", "product-oranges"],
  ["mandarin", "product-oranges"],
  ["grapes", "product-grapes"],
  ["strawberries", "product-strawberries"],
  ["blueberries", "product-blueberries"],
  ["watermelon", "product-watermelon"],
  ["cantaloupe", "product-melon"],
  ["cherries", "product-cherries"],
  ["peach", "product-peaches"],
  ["nectarine", "product-peaches"],
  ["pear", "product-pears"],
  ["pineapple", "product-pineapple"],
  ["mango", "product-mangoes"],
  ["aam", "product-mangoes"],
  ["kiwi", "product-kiwi"],
  ["coconut", "product-coconut"],
  ["pomegranate", "product-pomegranate"],
  ["anaar", "product-pomegranate"],
  ["papaya", "product-papaya"],
  ["carrots", "product-carrots"],
  ["sweet potatoes", "product-sweet-potatoes"],
  ["corn on the cob", "product-corn"],
  ["broccoli", "product-broccoli"],
  ["cauliflower", "product-cauliflower"],
  ["gobi", "product-cauliflower"],
  ["cucumber", "product-cucumbers"],
  ["zucchini", "product-zucchini"],
  ["bell pepper", "product-bell-peppers"],
  ["capsicum", "product-bell-peppers"],
  ["jalapeno", "product-hot-peppers"],
  ["green chili", "product-hot-peppers"],
  ["eggplant", "product-eggplant"],
  ["baingan", "product-eggplant"],
  ["mushrooms", "product-mushrooms"],
  ["green onions", "product-green-onions"],
  ["garlic", "product-garlic"],
  ["ginger", "product-ginger"],
  ["green beans", "product-green-beans"],
  ["cabbage", "product-cabbage"],
  ["celery", "product-celery"],
  ["radishes", "product-radishes"],
  ["asparagus", "product-asparagus"],
  ["green peas", "product-green-peas"],
  ["matar", "product-green-peas"],
  ["okra", "product-okra"],
  ["bhindi", "product-okra"],
  ["pumpkin", "product-pumpkin"],
  ["plantain", "product-plantains"],
  ["raw banana", "product-plantains"],
  ["bottle gourd", "product-bottle-gourd"],
  ["lauki", "product-bottle-gourd"],
  ["chicken drumsticks", "product-chicken-drumsticks"],

  // Phase B2 — herbs, greens, Indian produce
  ["kale", "product-kale"],
  ["arugula", "product-arugula"],
  ["bok choy", "product-bok-choy"],
  ["brussels sprouts", "product-brussels-sprouts"],
  ["mixed greens", "product-mixed-greens"],
  ["spring mix", "product-mixed-greens"],
  ["salad greens", "product-mixed-greens"],
  ["bean sprouts", "product-bean-sprouts"],
  ["mung bean sprouts", "product-bean-sprouts"],
  ["leeks", "product-leeks"],
  ["leek", "product-leeks"],
  ["fennel", "product-fennel"],
  ["parsnips", "product-parsnips"],
  ["turnips", "product-turnips"],
  ["basil", "product-basil"],
  ["mint", "product-mint"],
  ["pudina", "product-mint"],
  ["parsley", "product-parsley"],
  ["dill", "product-dill"],
  ["rosemary", "product-rosemary"],
  ["thyme", "product-thyme"],
  ["curry leaves", "product-curry-leaves"],
  ["kadi patta", "product-curry-leaves"],
  ["fenugreek leaves", "product-fenugreek-leaves"],
  ["methi", "product-fenugreek-leaves"],
  ["mustard greens", "product-mustard-greens"],
  ["sarson ka saag", "product-mustard-greens"],
  ["bitter gourd", "product-bitter-gourd"],
  ["karela", "product-bitter-gourd"],
  ["ridge gourd", "product-ridge-gourd"],
  ["turai", "product-ridge-gourd"],
  ["ivy gourd", "product-ivy-gourd"],
  ["tendli", "product-ivy-gourd"],
  ["pointed gourd", "product-pointed-gourd"],
  ["parwal", "product-pointed-gourd"],
  ["taro", "product-taro"],
  ["arbi", "product-taro"],
  ["cluster beans", "product-cluster-beans"],
  ["gavar", "product-cluster-beans"],
  ["long beans", "product-long-beans"],
  ["chawli", "product-long-beans"],
  ["flat beans", "product-flat-beans"],
  ["sem", "product-flat-beans"],
  ["drumstick", "product-drumsticks-moringa"],
  ["moringa", "product-drumsticks-moringa"],
  ["jackfruit", "product-jackfruit"],
  ["kathal", "product-jackfruit"],
  ["guava", "product-guava"],
  ["amla", "product-amla"],
  ["custard apple", "product-custard-apple"],
  ["sitaphal", "product-custard-apple"],
  ["sapota", "product-sapota"],
  ["chikoo", "product-sapota"],
  ["jamun", "product-jamun"],

  // New specific products — positives
  ["coconut milk", "product-milk-coconut"],
  ["sweetened condensed milk", "product-milk-condensed"],
  ["evaporated milk", "product-milk-evaporated"],
  ["egg noodles", "product-egg-noodles"],
  ["paneer", "product-paneer"],
  ["ghee", "product-ghee"],
  ["cream cheese", "product-cream-cheese"],
  ["cottage cheese", "product-cottage-cheese"],
  ["apple cider vinegar", "product-apple-cider-vinegar"],
  ["apple juice", "product-apple-juice"],
  ["tomato sauce", "product-tomato-sauce"],
  ["tomato paste", "product-tomato-paste"],
  ["canned tomatoes", "product-canned-tomatoes"],
  ["green onions", "product-green-onions"],
  ["shallots", "product-shallots"],
  ["sweet potatoes", "product-sweet-potatoes"],
  ["lime", "product-limes"],
  ["avocado oil", "product-avocado-oil"],
  ["banana bread", "product-banana-bread"],
  ["roti", "product-roti"],
  ["paratha", "product-paratha"],
  ["pita bread", "product-pita"],
  ["rotisserie chicken", "product-rotisserie-chicken"],
  ["chicken broth", "product-chicken-broth"],
  ["chicken wings", "product-chicken-wings"],
  ["chicken thighs", "product-chicken-thighs"],
  ["turkey breast", "product-turkey-breast"],
  ["tuna steak", "product-tuna-steak"],
  ["rice noodles", "product-rice-noodles"],
  ["rice vinegar", "product-rice-vinegar"],
  ["rice cakes", "product-rice-cakes"],
  ["pasta sauce", "product-pasta-sauce"],
  ["coconut water", "product-coconut-water"],
  ["cranberry juice", "product-cranberry-juice"],
  ["grape juice", "product-grape-juice"],
  ["juice boxes", "product-juice-boxes"],
  ["root beer", "product-root-beer"],
  ["ginger ale", "product-ginger-ale"],
  ["pizza rolls", "product-pizza-rolls"],
  ["conditioner", "product-conditioner"],
  ["diaper cream", "product-diaper-cream"],
  ["disinfecting wipes", "product-disinfecting-wipes"],
  ["almond butter", "product-almond-butter"],
  ["pet shampoo", "product-pet-shampoo"],
  ["coffee creamer", "product-coffee-creamer"],
  ["heavy cream", "product-heavy-cream"],
  ["whipping cream", "product-heavy-cream"],
  ["sour cream", "product-sour-cream"],
  ["ghee", "product-ghee"],
  ["cream cheese", "product-cream-cheese"],
  ["cottage cheese", "product-cottage-cheese"],
  ["evaporated milk", "product-milk-evaporated"],

  // Separation / negatives (must not equal broad asset)
  ["egg noodles", { not: "product-eggs-white" }],
  ["coconut milk", { not: "product-milk-whole" }],
  ["apple cider vinegar", { not: "product-apples" }],
  ["tomato sauce", { not: "product-tomatoes" }],
  ["tuna steak", { not: "product-steak" }],
  ["rice noodles", { not: "product-rice-white" }],
  ["root beer", { not: "product-beer" }],
  ["chicken broth", { not: "product-chicken-breast" }],
  ["disinfecting wipes", { not: "product-baby-wipes" }],
  ["ginger ale", { not: "product-beer" }],
  ["wet wipes", { not: "product-baby-wipes" }],
  ["conditioner", { not: "product-shampoo" }],
  ["corn flakes", "product-cereal"],
  ["banana bread", "product-banana-bread"],
  ["coconut milk", "product-milk-coconut"],
  ["ginger ale", "product-ginger-ale"],
  ["apple juice", "product-apple-juice"],
  ["tomato sauce", "product-tomato-sauce"],
  ["onion powder", null],
  ["onion powder", { not: "product-onions" }],
  ["garlic powder", { not: "product-garlic" }],
  ["eggplant", { not: "product-eggs-white" }],
  ["chicken drumsticks", { not: "product-chicken-wings" }],
  ["drumstick", { not: "product-chicken-drumsticks" }],
  ["curry powder", { not: "product-curry-leaves" }],
  ["fenugreek seeds", { not: "product-fenugreek-leaves" }],
  ["mint chutney", { not: "product-mint" }],
  ["basil pesto", { not: "product-basil" }],
  ["mustard sauce", { not: "product-mustard-greens" }],
  ["jackfruit chips", { not: "product-jackfruit" }],
  ["gulab jamun mix", { not: "product-jamun" }],
  ["green beans", "product-green-beans"],
];

let failed = 0;
for (const [input, expected] of cases) {
  const actual = resolveProduct(input);
  let ok;
  let expectedLabel;
  if (expected && typeof expected === "object" && expected.not) {
    ok = actual !== expected.not;
    expectedLabel = `not ${expected.not}`;
  } else {
    ok = actual === expected;
    expectedLabel = String(expected);
  }
  if (!ok) {
    failed += 1;
    console.error(
      `FAIL  ${JSON.stringify(input)} -> ${actual} (expected ${expectedLabel})`
    );
  } else {
    console.log(`ok    ${JSON.stringify(input)} -> ${actual}`);
  }
}

if (failed > 0) {
  console.error(`\n${failed} case(s) failed`);
  process.exit(1);
}

console.log(`\nAll ${cases.length} cases passed.`);
