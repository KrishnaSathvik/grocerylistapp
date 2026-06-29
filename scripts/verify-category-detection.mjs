#!/usr/bin/env node
/**
 * Verifies category detection: P0 fixes + collision edge cases.
 * Run: npm run verify-category-detection
 */
import { detectCategory } from "../src/detectCategory.js";

const cases = [
  // Floral
  ["flowers", "floral"],
  ["bouquet", "floral"],
  ["tulips", "floral"],
  ["roses", "floral"],
  ["succulent", "floral"],
  ["potted plant", "floral"],
  // Drinks vs floral rose collision
  ["rosé wine", "drinks"],
  ["rose wine", "drinks"],
  // Pantry breakfast
  ["corn flakes", "pantry"],
  ["frosted flakes", "pantry"],
  ["maple syrup", "pantry"],
  ["half-and-half", "dairy"],
  // Household vs baby wipes
  ["dishwasher pods", "household"],
  ["disinfecting wipes", "household"],
  ["baby wipes", "baby"],
  // Pet / snacks / condiments / frozen
  ["poop bags", "pet"],
  ["protein bars", "snacks"],
  ["gum", "snacks"],
  ["curry paste", "condiments"],
  ["tahini", "condiments"],
  ["smoothie blends", "frozen"],
  ["mozzarella sticks", "frozen"],
  ["veggie burgers", "frozen"],
  // Longest-phrase / token-boundary collisions (merge gate)
  ["plant-based burger", "frozen"],
  ["plantain", "produce"],
  ["almond milk", "drinks"],
  ["oat milk", "drinks"],
  ["soy milk", "drinks"],
  ["plant milk", "drinks"],
  ["2% milk", "dairy"],
  ["waffles", "bakery"],
  ["frozen waffles", "frozen"],
  ["cauliflower", "produce"],
  ["sunflower seeds", "pantry"],
  ["sunflowers", "floral"],
];

let failed = 0;
for (const [input, expected] of cases) {
  const actual = detectCategory(input);
  const ok = actual === expected;
  if (!ok) {
    failed += 1;
    console.error(`FAIL  ${JSON.stringify(input)} -> ${actual} (expected ${expected})`);
  } else {
    console.log(`ok    ${JSON.stringify(input)} -> ${actual}`);
  }
}

if (failed > 0) {
  console.error(`\n${failed} case(s) failed`);
  process.exit(1);
}

console.log(`\nAll ${cases.length} cases passed.`);
