import { CATEGORIES } from "../data/categories";
import { storeFavicon } from "../data/stores";
import { detectItemIcon } from "../itemIcons";
import SwipeRow from "./SwipeRow";
import CheckMark from "./CheckMark";

const LINE_H = 50;
const PER_PAGE = 10;

export default function StoreView({ storeGroups, allStores, page, pageStart, justChecked, onToggle, onUpdateText, onItemKeyDown, onItemBlur, onRemove, onBlankTouchStart, onBlankTouchEnd, pageAnimClass }) {
  // Build a flat list of renderable rows: headers + items
  const rows = [];
  storeGroups.forEach(([storeKey, storeItems]) => {
    const store = storeKey === "__none__" ? null : allStores[storeKey];
    if (storeItems.length === 0) return;
    rows.push({ type: "header", storeKey, store, count: storeItems.length });
    storeItems.forEach(item => rows.push({ type: "item", item }));
  });
  const storePageRows = rows.slice(pageStart, pageStart + PER_PAGE);
  const storeBlank = Math.max(0, PER_PAGE - storePageRows.length);

  return (
    <div key={`sp${page}`} className={pageAnimClass} style={{ transformOrigin: "center center", position: "relative", zIndex: 1 }}>
      {storePageRows.map((row, idx) => {
        if (row.type === "header") {
          const { store, count } = row;
          return (
            <div key={`h-${row.storeKey}`} style={{ display: "flex", alignItems: "center", gap: 8, height: LINE_H, borderBottom: "2px solid " + (store?.color || "var(--line-dash)"), paddingTop: 4 }}>
              {store?.domain ? <img src={storeFavicon(store.domain)} alt="" width={18} height={18} style={{ borderRadius: 3 }} onError={e => { e.target.style.display = "none"; }} /> : store ? <span style={{ width: 18, height: 18, borderRadius: 3, background: store.color, color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: 10, fontWeight: 700 }}>{store.label[0]}</span> : null}
              <span style={{ fontSize: 13, fontWeight: 700, color: store?.color || "var(--ink-muted)", fontFamily: "'DM Sans', sans-serif", letterSpacing: ".3px" }}>{store?.label || "Unassigned"}</span>
              <span style={{ fontSize: 11, color: "var(--ink-faint)", fontFamily: "'DM Sans', sans-serif" }}>({count})</span>
            </div>
          );
        }
        const { item } = row;
        return (
          <SwipeRow key={item.id} onDelete={() => onRemove(item.id)} height={LINE_H}>
            <div className="g-item" style={{ display: "flex", alignItems: "center", gap: 6, height: LINE_H, borderBottom: "1px solid var(--line)", position: "relative" }}>
              <span className="g-drag" style={{ fontSize: 12, color: "var(--drag)", userSelect: "none", width: 12, textAlign: "center", flexShrink: 0, lineHeight: 1 }}>⠿</span>
              <button onClick={() => onToggle(item.id)} style={{ width: 22, height: 22, background: "transparent", border: "none", cursor: "pointer", padding: 0, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                <CheckMark color={CATEGORIES[item.category]?.color || "#888"} checked={false} justDone={false} />
              </button>
              {item.qty > 1 && <span style={{ fontSize: 13, fontWeight: 700, color: "var(--badge-fg)", background: "var(--badge-bg)", borderRadius: 8, padding: "2px 6px", lineHeight: 1.3, fontFamily: "'DM Sans', sans-serif", flexShrink: 0, minWidth: 20, textAlign: "center" }}>{item.qty}×</span>}
              {(item.icon || detectItemIcon(item.text)) && <span style={{ fontSize: 20, lineHeight: 1, flexShrink: 0, userSelect: "none" }}>{item.icon || detectItemIcon(item.text)}</span>}
              <input className="g-edit" value={item.text} onChange={e => onUpdateText(item.id, e.target.value)} onKeyDown={onItemKeyDown} onBlur={() => onItemBlur(item.id)} spellCheck={false} />
              <span style={{ fontSize: 12, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .7, background: CATEGORIES[item.category]?.color + "18", color: CATEGORIES[item.category]?.color, padding: "3px 7px", borderRadius: 8, fontFamily: "'DM Sans', sans-serif", fontWeight: 600, whiteSpace: "nowrap" }} title={CATEGORIES[item.category]?.label}>{CATEGORIES[item.category]?.emoji} {CATEGORIES[item.category]?.label}</span>
            </div>
          </SwipeRow>
        );
      })}
      {Array.from({ length: storeBlank }).map((_, i) => (
        <div key={`sb${i}`} style={{ height: LINE_H, borderBottom: "1px solid var(--line)" }} onTouchStart={onBlankTouchStart} onTouchEnd={onBlankTouchEnd} />
      ))}
    </div>
  );
}
