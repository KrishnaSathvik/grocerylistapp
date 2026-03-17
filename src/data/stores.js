export const DEFAULT_STORES = {
  costco:      { label: "Costco",        domain: "costco.com",              color: "#e31837" },
  walmart:     { label: "Walmart",       domain: "walmart.com",             color: "#0071dc" },
  target:      { label: "Target",        domain: "target.com",              color: "#cc0000" },
  traderjoes:  { label: "Trader Joe's",  domain: "traderjoes.com",          color: "#ba2026" },
  wholefoods:  { label: "Whole Foods",   domain: "wholefoodsmarket.com",    color: "#00674b" },
  kroger:      { label: "Kroger",        domain: "kroger.com",              color: "#2b2fee" },
  aldi:        { label: "ALDI",          domain: "aldi.us",                 color: "#00005f" },
  heb:         { label: "H-E-B",         domain: "heb.com",                 color: "#ee1c2e" },
  amazon:      { label: "Amazon Fresh",  domain: "amazon.com",              color: "#ff9900" },
  publix:      { label: "Publix",        domain: "publix.com",              color: "#3b8739" },
  gerbes:      { label: "Gerbes",        domain: "gerbes.com",              color: "#e21a2c" },
};

export function storeFavicon(domain) {
  return domain ? `https://www.google.com/s2/favicons?domain=${domain}&sz=32` : null;
}
