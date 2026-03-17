export const DEFAULT_STORES = {
  costco:      { label: "Costco",        domain: "costco.com",              color: "#e31837" },
  walmart:     { label: "Walmart",       domain: "walmart.com",             color: "#0071dc" },
  target:      { label: "Target",        domain: "target.com",              color: "#cc0000" },
  traderjoes:  { label: "Trader Joe's",  domain: "traderjoes.com",          color: "#ba2026" },
  wholefoods:  { label: "Whole Foods Market", domain: "wholefoodsmarket.com", color: "#00674b" },
  kroger:      { label: "Kroger",        domain: "kroger.com",              color: "#2b2fee" },
  aldi:        { label: "ALDI",          domain: "aldi.us",                 color: "#00005f" },
  heb:         { label: "H-E-B",         domain: "heb.com",                 color: "#ee1c2e" },
  amazon:      { label: "Amazon Fresh",  domain: "amazon.com",              color: "#ff9900" },
  publix:      { label: "Publix",        domain: "publix.com",              color: "#3b8739" },
  gerbes:      { label: "Gerbes",        domain: "gerbes.com",              color: "#e21a2c" },
  samsclub:    { label: "Sam's Club",    domain: "samsclub.com",            color: "#0060a9" },
  indianbazaar:{ label: "Indian Bazaar", domain: "indiabazaarusa.com",     color: "#e87722" },
  panasia:     { label: "Pan Asia Supermarket", domain: "panasiasupermarket.com", color: "#c62828" },
  patelbros:   { label: "Patel Brothers",domain: "patelbros.com",          color: "#e53935" },
  hmart:       { label: "H Mart",        domain: "hmart.com",              color: "#e12229" },
  ranch99:     { label: "99 Ranch Market",domain:"99ranch.com",            color: "#d32f2f" },
  sprouts:     { label: "Sprouts Farmers Market", domain: "sprouts.com",  color: "#3e7d1a" },
};

export function storeFavicon(domain) {
  return domain ? `https://www.google.com/s2/favicons?domain=${domain}&sz=32` : null;
}
