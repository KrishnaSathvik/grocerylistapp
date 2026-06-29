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

function resolveProduct(itemName) {
  const nameTokens = tokens(itemName.trim());
  if (!nameTokens.length) return null;

  let best = null;
  let bestLen = 0;
  for (const product of products) {
    for (const keyword of product.keywords) {
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
  ["disinfecting wipes", null],
  ["dog food", "product-dog-food"],
  ["milk", "product-milk-whole"],
  ["eggplant", null],
];

let failed = 0;
for (const [input, expected] of cases) {
  const actual = resolveProduct(input);
  const ok = actual === expected;
  if (!ok) {
    failed += 1;
    console.error(
      `FAIL  ${JSON.stringify(input)} -> ${actual} (expected ${expected})`
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
