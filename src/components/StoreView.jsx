import { CATEGORIES } from "../data/categories";
import { storeFavicon } from "../data/stores";
import { detectItemIcon } from "../itemIcons";
import SwipeRow from "./SwipeRow";
import CheckMark from "./CheckMark";
import ContentEditable from "./ContentEditable";

const LINE_H = 50;

export default function StoreView({ storeGroups, allStores, justChecked, onToggle, onUpdateText, onItemKeyDown, onItemBlur, onRemove, editStoreItemId, editStoreMatches, editStoreAutoIdx, onEditStoreSelect, onUpdateCategory }) {
  return (
    <div style={{ position: "relative", zIndex: 1 }}>
      {storeGroups.map(([storeKey, storeItems]) => {
        const store = storeKey === "__none__" ? null : allStores[storeKey];
        if (storeItems.length === 0) return null;
        return (
          <div key={storeKey}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, height: LINE_H, borderBottom: "2px solid " + (store?.color || "var(--line-dash)"), paddingTop: 4 }}>
              {store?.domain ? <img src={storeFavicon(store.domain)} alt="" width={18} height={18} style={{ borderRadius: 3 }} onError={e => { e.target.style.display = "none"; }} /> : store ? <span style={{ width: 18, height: 18, borderRadius: 3, background: store.color, color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: 10, fontWeight: 700 }}>{store.label[0]}</span> : null}
              <span style={{ fontSize: 13, fontWeight: 700, color: store?.color || "var(--ink-muted)", fontFamily: "'DM Sans', sans-serif", letterSpacing: ".3px" }}>{store?.label || "Unassigned"}</span>
              <span style={{ fontSize: 11, color: "var(--ink-faint)", fontFamily: "'DM Sans', sans-serif" }}>({storeItems.length})</span>
            </div>
            {storeItems.map(item => {
              const storeActive = editStoreItemId === item.id;
              return (
                <div key={item.id} style={{ position: "relative" }}>
                  <SwipeRow onDelete={() => onRemove(item.id)} height={LINE_H}>
                    <div className="g-item" style={{ display: "flex", alignItems: "center", gap: 6, height: LINE_H, borderBottom: "1px solid var(--line)", position: "relative" }}>
                      <span className="g-drag" style={{ fontSize: 12, color: "var(--drag)", userSelect: "none", width: 12, textAlign: "center", flexShrink: 0, lineHeight: 1 }}>⠿</span>
                      <button onClick={() => onToggle(item.id)} style={{ width: 22, height: 22, background: "transparent", border: "none", cursor: "pointer", padding: 0, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                        <CheckMark color={CATEGORIES[item.category]?.color || "#888"} checked={false} justDone={false} />
                      </button>
                      {item.qty > 1 && <span style={{ fontSize: 13, fontWeight: 700, color: "var(--badge-fg)", background: "var(--badge-bg)", borderRadius: 8, padding: "2px 6px", lineHeight: 1.3, fontFamily: "'DM Sans', sans-serif", flexShrink: 0, minWidth: 20, textAlign: "center" }}>{item.qty}×</span>}
                      {(item.icon || detectItemIcon(item.text)) && <span style={{ fontSize: 20, lineHeight: 1, flexShrink: 0, userSelect: "none" }}>{item.icon || detectItemIcon(item.text)}</span>}
                      <ContentEditable className="g-edit" value={item.text} onChange={text => onUpdateText(item.id, text)} onKeyDown={e => onItemKeyDown(e, item.id)} onBlur={() => onItemBlur(item.id)} spellCheck={false} />
                      <span style={{ fontSize: 12, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .7, background: CATEGORIES[item.category]?.color + "18", color: CATEGORIES[item.category]?.color, padding: "3px 7px", borderRadius: 8, fontFamily: "'DM Sans', sans-serif", fontWeight: 600, whiteSpace: "nowrap" }} title={CATEGORIES[item.category]?.label}>{CATEGORIES[item.category]?.emoji} {CATEGORIES[item.category]?.label}</span>
                    </div>
                  </SwipeRow>
                  {storeActive && editStoreMatches.length > 0 && (
                    <div style={{ position: "absolute", left: 0, right: 0, top: LINE_H, zIndex: 20, background: "var(--paper)", border: "1.5px solid var(--line)", borderRadius: 10, boxShadow: "0 4px 16px rgba(0,0,0,.1)", padding: "4px 0", animation: "fadeIn .1s ease" }}>
                      {editStoreMatches.map(([key, { label, domain, color }], i) => (
                        <button key={key} onMouseDown={e => { e.preventDefault(); onEditStoreSelect(item.id, key); }}
                          style={{ display: "flex", alignItems: "center", gap: 8, width: "100%", padding: "6px 12px", border: "none", cursor: "pointer", fontFamily: "'DM Sans', sans-serif", fontSize: 13, fontWeight: 500, transition: "background .1s",
                            background: i === editStoreAutoIdx ? "var(--line)" : "transparent", color: "var(--ink)" }}>
                          {domain ? <img src={storeFavicon(domain)} alt="" width={16} height={16} style={{ borderRadius: 3 }} onError={e => { e.target.style.display = "none"; }} /> : <span style={{ width: 16, height: 16, borderRadius: 3, background: color, color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: 9, fontWeight: 700 }}>{label[0]}</span>}
                          <span>{label}</span>
                          <span style={{ fontSize: 11, color: "var(--ink-faint)", marginLeft: "auto" }}>@{key}</span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        );
      })}
    </div>
  );
}
