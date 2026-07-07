export { detectCategory } from "./detectCategory.js";

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

export const APP_STORE_URL = "https://apps.apple.com/app/id6785659442";
export const SHARE_BASE_URL = "https://smartgrocerylists.app/app";
export const SHORT_SHARE_BASE_URL = "https://smartgrocerylists.app/s";

export function extractShortShareId(raw) {
  const text = String(raw || "").trim();
  if (!text) return null;
  try {
    const url = new URL(text);
    const match = url.pathname.match(/\/s\/([^/?#]+)/);
    if (match?.[1]) return match[1];
  } catch {
    // not a full URL
  }
  const match = text.match(/\/s\/([^/?#\s]+)/);
  return match?.[1] || null;
}

export async function fetchSharedListById(id) {
  const response = await fetch(`https://smartgrocerylists.app/api/share/${encodeURIComponent(id)}`);
  if (!response.ok) return null;
  const payload = await response.json();
  if (!payload?.items?.length) return null;
  return {
    listName: payload.name || "Imported List",
    items: payload.items.map((item) => ({
      id: Date.now() + Math.random(),
      text: item.name || "",
      qty: item.quantity || 1,
      category: item.categoryId || "misc",
      checked: !!item.completed,
      store: item.storeId || null,
      icon: null,
    })),
  };
}

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

export function buildShareURL(items) {
  const encoded = encodeList(items);
  if (!encoded) return null;
  return `${SHARE_BASE_URL}?import=${encodeURIComponent(encoded)}`;
}

export function extractImportPayload(search, hash) {
  const params = new URLSearchParams(search);
  const queryValue = params.get("import");
  if (queryValue) return queryValue;
  if (hash.startsWith("#import=")) return hash.slice(8);
  return null;
}
