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
  m = t.match(/^(.+?)\s+(\d+)$/);
  if (m && parseInt(m[2]) > 1 && parseInt(m[2]) < 100) return { qty: parseInt(m[2]), text: m[1].trim() };
  return { qty: 1, text: t };
}

const MAX_LINK_ITEMS = 50;

export function encodeList(items) {
  if (items.length > MAX_LINK_ITEMS) return null;
  const slim = items.map(({ text, qty, category, checked, store }) => {
    const o = { t: text };
    if (qty > 1) o.q = qty;
    if (category && category !== "misc") o.c = category;
    if (checked) o.k = 1;
    if (store) o.s = store;
    return o;
  });
  return btoa(unescape(encodeURIComponent(JSON.stringify(slim))));
}

export function decodeList(encoded) {
  try {
    const json = decodeURIComponent(escape(atob(encoded)));
    const slim = JSON.parse(json);
    if (!Array.isArray(slim)) return null;
    return slim.map(o => ({
      id: Date.now() + Math.random(),
      text: o.t || "",
      qty: o.q || 1,
      category: o.c || "misc",
      checked: !!o.k,
      store: o.s || null,
      icon: null,
    }));
  } catch { return null; }
}
