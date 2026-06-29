import { CAT_KEYWORDS } from "./data/categories.js";

/** Split on non-alphanumeric boundaries (hyphens, spaces, punctuation). */
export function categoryTokens(value) {
  return value
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter(Boolean);
}

/** True when keyword tokens appear as a contiguous run inside name tokens. */
export function keywordMatches(nameTokens, keyword) {
  const keywordTokens = categoryTokens(keyword);
  if (!keywordTokens.length || keywordTokens.length > nameTokens.length) return false;
  if (keywordTokens.length === nameTokens.length) {
    return keywordTokens.every((token, index) => token === nameTokens[index]);
  }
  const maxStart = nameTokens.length - keywordTokens.length;
  for (let start = 0; start <= maxStart; start += 1) {
    const candidate = nameTokens.slice(start, start + keywordTokens.length);
    if (candidate.every((token, index) => token === keywordTokens[index])) {
      return true;
    }
  }
  return false;
}

/**
 * Detect category from item text using longest contiguous token-phrase match.
 *
 * Matching rules:
 * 1. Split item and keywords on non-alphanumeric boundaries (spaces, hyphens).
 * 2. A keyword matches only when its tokens appear as a contiguous run in the item.
 * 3. Among all matches, the longest keyword string wins (not first-found).
 *
 * This avoids raw-substring bugs: "corn" ≠ "cornflakes", "rose" ≠ "roses",
 * "plant" ≠ "plantain", "wipes" beaten by "disinfecting wipes".
 */
export function detectCategory(text, keywords = CAT_KEYWORDS) {
  const nameTokens = categoryTokens(text.trim());
  if (!nameTokens.length) return "misc";

  let bestCategory = null;
  let bestLength = 0;

  for (const [categoryId, categoryKeywords] of Object.entries(keywords)) {
    for (const keyword of categoryKeywords) {
      if (!keywordMatches(nameTokens, keyword)) continue;
      if (keyword.length > bestLength) {
        bestCategory = categoryId;
        bestLength = keyword.length;
      }
    }
  }

  return bestCategory ?? "misc";
}
