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

function levenshteinDistance(lhs, rhs) {
  if (!lhs.length) return rhs.length;
  if (!rhs.length) return lhs.length;

  let previous = Array.from({ length: rhs.length + 1 }, (_, index) => index);
  let current = new Array(rhs.length + 1);

  for (let i = 0; i < lhs.length; i += 1) {
    current[0] = i + 1;
    for (let j = 0; j < rhs.length; j += 1) {
      const insertion = previous[j + 1] + 1;
      const deletion = current[j] + 1;
      const substitution = previous[j] + (lhs[i] === rhs[j] ? 0 : 1);
      current[j + 1] = Math.min(insertion, deletion, substitution);
    }
    [previous, current] = [current, previous];
  }

  return previous[rhs.length];
}

function fuzzyTokenDistance(token, keyword) {
  if (token.length < 4 || keyword.length < 4) return null;
  if (token[0] !== keyword[0]) return null;
  if (Math.abs(token.length - keyword.length) > 2) return null;

  const distance = levenshteinDistance(token, keyword);
  const maxLength = Math.max(token.length, keyword.length);
  let threshold = 1;
  if (maxLength >= 6 && maxLength <= 8) threshold = 2;
  else if (maxLength > 8) threshold = Math.max(2, Math.floor(maxLength / 4));

  if (distance <= 0 || distance > threshold) return null;
  return distance;
}

function fuzzyPhraseDistance(nameTokens, keyword) {
  const keywordTokens = categoryTokens(keyword);
  if (!keywordTokens.length || keywordTokens.length > nameTokens.length) return null;

  const maxStart = nameTokens.length - keywordTokens.length;
  let bestDistance = null;

  for (let start = 0; start <= maxStart; start += 1) {
    let phraseDistance = 0;
    let phraseMatches = true;

    for (let index = 0; index < keywordTokens.length; index += 1) {
      const nameToken = nameTokens[start + index];
      const keywordToken = keywordTokens[index];

      if (nameToken === keywordToken) continue;

      const tokenDistance = fuzzyTokenDistance(nameToken, keywordToken);
      if (tokenDistance == null) {
        phraseMatches = false;
        break;
      }
      phraseDistance += tokenDistance;
    }

    if (!phraseMatches) continue;
    bestDistance = bestDistance == null ? phraseDistance : Math.min(bestDistance, phraseDistance);
  }

  return bestDistance;
}

function bestFuzzyKeywordMatch(nameTokens, keywords) {
  let best = null;

  for (const [categoryId, categoryKeywords] of Object.entries(keywords)) {
    for (const keyword of categoryKeywords) {
      const distance = fuzzyPhraseDistance(nameTokens, keyword);
      if (distance == null) continue;

      const candidate = {
        categoryId,
        keywordLength: keyword.length,
        editDistance: distance,
      };

      if (
        !best
        || candidate.keywordLength > best.keywordLength
        || (candidate.keywordLength === best.keywordLength && candidate.editDistance < best.editDistance)
      ) {
        best = candidate;
      }
    }
  }

  return best?.categoryId ?? null;
}

/**
 * Detect category from item text using longest contiguous token-phrase match.
 *
 * Matching rules:
 * 1. Split item and keywords on non-alphanumeric boundaries (spaces, hyphens).
 * 2. A keyword matches only when its tokens appear as a contiguous run in the item.
 * 3. Among all matches, the longest keyword string wins (not first-found).
 * 4. If no exact match, allow small typos on tokens (same first letter, edit distance).
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

  if (bestCategory) return bestCategory;
  return bestFuzzyKeywordMatch(nameTokens, keywords) ?? "misc";
}
