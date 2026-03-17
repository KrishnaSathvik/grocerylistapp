import { CAT_KEYWORDS } from "./data/categories";

export function detectCategory(text) {
  const lower = text.toLowerCase().trim();
  let best = null, bestLen = 0;
  for (const [cat, keywords] of Object.entries(CAT_KEYWORDS)) {
    for (const kw of keywords) {
      if ((lower === kw || lower.includes(kw)) && kw.length > bestLen) { best = cat; bestLen = kw.length; }
    }
  }
  return best;
}

export function parseQty(raw) {
  const t = raw.trim();
  let m = t.match(/^(\d+)\s*[xX]\s+(.+)$/);
  if (m) return { qty: parseInt(m[1]), text: m[2].trim() };
  m = t.match(/^[xX](\d+)\s+(.+)$/);
  if (m) return { qty: parseInt(m[1]), text: m[2].trim() };
  m = t.match(/^(.+?)\s+[xX](\d+)$/);
  if (m) return { qty: parseInt(m[2]), text: m[1].trim() };
  m = t.match(/^(\d+)\s+(.+)$/);
  if (m && parseInt(m[1]) > 1 && parseInt(m[1]) < 100) return { qty: parseInt(m[1]), text: m[2].trim() };
  return { qty: 1, text: t };
}
