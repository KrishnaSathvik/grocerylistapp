#!/usr/bin/env node
/**
 * Writes GroceryListiOS/PRODUCT_MAPPING_AUDIT.md from the generated catalog.
 * Run: node scripts/write-product-mapping-audit.mjs
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { ITEM_ICONS } from "../src/itemIcons.js";
import { keywordMatches, categoryTokens } from "../src/detectCategory.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const catalogPath = join(__dirname, "../GroceryListiOS/GroceryList/Resources/product_catalog.json");
const outPath = join(__dirname, "../GroceryListiOS/PRODUCT_MAPPING_AUDIT.md");
const products = JSON.parse(readFileSync(catalogPath, "utf8"));

const DANGEROUS_ROOTS = [
  "milk", "egg", "apple", "tomato", "onion", "potato", "lemon", "bread",
  "chicken", "steak", "rice", "pasta", "coffee", "tea", "water", "juice",
  "pizza", "shampoo", "butter", "beer",
];

const SUPERSEDED = {
  "milk-coconut": { from: "milk-whole", aliases: ["coconut milk", "lite coconut milk"] },
  "milk-condensed": { from: "milk-whole", aliases: ["condensed milk", "sweetened condensed milk"] },
  "milk-evaporated": { from: "milk-whole", aliases: ["evaporated milk"] },
  "egg-noodles": { from: "eggs-white", aliases: ["egg noodles", "egg noodle"] },
  "ghee": { from: "butter", aliases: ["ghee", "clarified butter"] },
  "cream-cheese": { from: "cheese", aliases: ["cream cheese"] },
  "cottage-cheese": { from: "cheese", aliases: ["cottage cheese"] },
  "paneer": { from: "cheese", aliases: ["paneer"] },
  "banana-bread": { from: "bananas", aliases: ["banana bread"] },
  "apple-juice": { from: "apples", aliases: ["apple juice"] },
  "apple-cider-vinegar": { from: "apples", aliases: ["apple cider vinegar"] },
  "tomato-sauce": { from: "tomatoes", aliases: ["tomato sauce", "marinara"] },
  "tomato-paste": { from: "tomatoes", aliases: ["tomato paste"] },
  "canned-tomatoes": { from: "tomatoes", aliases: ["canned tomatoes", "diced tomatoes", "crushed tomatoes"] },
  "green-onions": { from: "onions", aliases: ["green onion", "green onions", "scallion", "scallions"] },
  "shallots": { from: "onions", aliases: ["shallot", "shallots"] },
  "sweet-potatoes": { from: "potatoes", aliases: ["sweet potato", "sweet potatoes"] },
  "avocado-oil": { from: "avocados", aliases: ["avocado oil"] },
  "limes": { from: "lemons", aliases: ["lime", "limes"] },
  "roti": { from: "naan", aliases: ["roti", "chapati", "flatbread"] },
  "paratha": { from: "naan", aliases: ["paratha"] },
  "pita": { from: "naan", aliases: ["pita", "pita bread"] },
  "rotisserie-chicken": { from: "chicken-breast", aliases: ["rotisserie chicken", "rotisserie"] },
  "chicken-broth": { from: "chicken-breast", aliases: ["chicken broth", "chicken stock"] },
  "chicken-wings": { from: "chicken-breast", aliases: ["chicken wings", "chicken drumsticks"] },
  "chicken-thighs": { from: "chicken-breast", aliases: ["chicken thighs"] },
  "turkey-breast": { from: "ground-turkey", aliases: ["turkey breast"] },
  "tuna-steak": { from: "steak", aliases: ["tuna steak", "ahi tuna"] },
  "rice-noodles": { from: "rice-white", aliases: ["rice noodles"] },
  "rice-vinegar": { from: "rice-white", aliases: ["rice vinegar"] },
  "rice-cakes": { from: "rice-white", aliases: ["rice cakes", "rice cake"] },
  "pasta-sauce": { from: "pasta", aliases: ["pasta sauce", "pizza sauce"] },
  "coconut-water": { from: "water", aliases: ["coconut water"] },
  "cranberry-juice": { from: "orange-juice", aliases: ["cranberry juice"] },
  "grape-juice": { from: "orange-juice", aliases: ["grape juice"] },
  "juice-boxes": { from: "orange-juice", aliases: ["juice box", "juice boxes"] },
  "ginger-ale": { from: "beer", aliases: ["ginger ale"] },
  "root-beer": { from: "beer", aliases: ["root beer"] },
  "pizza-rolls": { from: "frozen-pizza", aliases: ["pizza rolls"] },
  "conditioner": { from: "shampoo", aliases: ["conditioner"] },
  "pet-shampoo": { from: "shampoo", aliases: ["pet shampoo"] },
  "diaper-cream": { from: "diapers", aliases: ["diaper cream"] },
  "disinfecting-wipes": { from: "baby-wipes", aliases: ["disinfecting wipes", "wet wipes"] },
  "almond-butter": { from: "peanut-butter", aliases: ["almond butter"] },
  "coffee-creamer": { from: "coffee", aliases: ["coffee creamer", "creamer"] },
};

function rootsFor(product) {
  // roots are the shorter seed phrases; approximate as keywords that equal known roots
  // by taking keywords that are not only auto-attached long phrases — use first keywords
  // that appear as contiguous product-defining phrases. Export stores merged keywords.
  return product.keywords;
}

function autoAttached(product) {
  const iconKeys = Object.keys(ITEM_ICONS);
  const attached = [];
  for (const key of iconKeys) {
    const nameTokens = categoryTokens(key);
    let bestLen = 0;
    let bestId = null;
    for (const candidate of products) {
      for (const kw of candidate.keywords) {
        // Approximate attachment using keyword membership + longest match on tokens of roots-like keywords
        if (!keywordMatches(nameTokens, kw)) continue;
        if (kw.length > bestLen) {
          bestLen = kw.length;
          bestId = candidate.id;
        }
      }
    }
    if (bestId === product.id && !product.keywords.includes(key) === false) {
      // key is already in keywords; mark as auto if not an exact short root-like seed
      if (product.keywords.includes(key)) attached.push(key);
    }
  }
  return [...new Set(attached)].sort((a, b) => b.length - a.length);
}

function misleadingAliases(product) {
  const dangerousHits = [];
  for (const root of DANGEROUS_ROOTS) {
    if (product.keywords.some((k) => k === root) && SUPERSEDED[product.id]) {
      // skip
    }
    // Flag if a short dangerous root lives on this product while a more specific product exists
    if (product.keywords.includes(root)) {
      const stealers = Object.entries(SUPERSEDED)
        .filter(([, meta]) => meta.from === product.id)
        .map(([id]) => id);
      if (stealers.length) {
        dangerousHits.push(`${root} (specific products split off: ${stealers.join(", ")})`);
      }
    }
  }
  return dangerousHits;
}

const lines = [];
lines.push("# Product mapping audit");
lines.push("");
lines.push("Generated by `node scripts/write-product-mapping-audit.mjs`.");
lines.push("");
lines.push(`Canonical products: **${products.length}**`);
lines.push("");

lines.push("## Dangerous generic-root collisions");
lines.push("");
lines.push("These short roots remain on broad products. Longer specific phrases must win.");
lines.push("");
for (const root of DANGEROUS_ROOTS) {
  const owners = products.filter((p) => p.keywords.includes(root));
  const owner = owners.map((p) => p.id).join(", ") || "(none)";
  const splits = Object.entries(SUPERSEDED)
    .filter(([, meta]) => meta.from === owners[0]?.id)
    .map(([id]) => id);
  lines.push(`- \`${root}\` → \`${owner}\`${splits.length ? ` — split to: ${splits.map((s) => `\`${s}\``).join(", ")}` : ""}`);
}
lines.push("");

lines.push("## Aliases moved to new canonical products");
lines.push("");
for (const [id, meta] of Object.entries(SUPERSEDED)) {
  lines.push(`- \`${meta.aliases.join("`, `")}\`: \`${meta.from}\` → \`${id}\``);
}
lines.push("");

lines.push("## Per-product mapping");
lines.push("");

for (const product of products) {
  const attached = autoAttached(product);
  const moved = SUPERSEDED[product.id];
  const misleading = misleadingAliases(product);
  const positives = product.keywords.slice(0, 4);
  const negatives = moved
    ? [`must not resolve via stale ${moved.from}`]
    : [];

  lines.push(`### \`${product.id}\``);
  lines.push("");
  lines.push(`- **asset**: \`${product.assetName}\``);
  lines.push(`- **category**: \`${product.categoryId}\``);
  lines.push(`- **keywords / roots** (${product.keywords.length}): ${product.keywords.slice(0, 20).map((k) => `\`${k}\``).join(", ")}${product.keywords.length > 20 ? ", …" : ""}`);
  lines.push(`- **ITEM_ICONS aliases attached**: ${attached.slice(0, 15).map((k) => `\`${k}\``).join(", ") || "_n/a_"}${attached.length > 15 ? ", …" : ""}`);
  if (misleading.length) {
    lines.push(`- **potentially misleading**: ${misleading.join("; ")}`);
  } else {
    lines.push("- **potentially misleading**: _none flagged_");
  }
  if (moved) {
    lines.push(`- **aliases moved here from** \`${moved.from}\`: ${moved.aliases.map((a) => `\`${a}\``).join(", ")}`);
  }
  lines.push(`- **positive tests**: ${positives.map((k) => `\`${k}\``).join(", ")}`);
  if (negatives.length) {
    lines.push(`- **negative tests**: ${negatives.join("; ")}`);
  }
  lines.push("");
}

writeFileSync(outPath, lines.join("\n") + "\n");
console.log(`Wrote ${outPath} (${products.length} products)`);
