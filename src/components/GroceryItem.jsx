import { CATEGORIES } from "../data/categories";
import { storeFavicon } from "../data/stores";
import { detectItemIcon } from "../itemIcons";
import SwipeRow from "./SwipeRow";
import CheckMark from "./CheckMark";

const LINE_H = 50;

export function UncheckedItem({ item, allStores, onToggle, onUpdateText, onKeyDown, onBlur, onDragStart, onDragOver, onDrop, onDragEnd, onDelete, dragId, dragOverId }) {
  return (
    <SwipeRow onDelete={() => onDelete(item.id)} height={LINE_H}>
      <div className={`g-item ${dragId === item.id ? "dragging" : ""} ${dragOverId === item.id ? "drag-over" : ""}`}
        style={{ display: "flex", alignItems: "center", gap: 6, height: LINE_H, borderBottom: "1px solid var(--line)", position: "relative" }}
        draggable onDragStart={() => onDragStart(item.id)} onDragOver={e => onDragOver(e, item.id)} onDrop={() => onDrop(item.id)} onDragEnd={onDragEnd}>
        <span className="g-drag" style={{ fontSize: 12, color: "var(--drag)", userSelect: "none", width: 12, textAlign: "center", flexShrink: 0, lineHeight: 1 }}>⠿</span>
        <button onClick={() => onToggle(item.id)} style={{ width: 22, height: 22, background: "transparent", border: "none", cursor: "pointer", padding: 0, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
          <CheckMark color={CATEGORIES[item.category]?.color || "#888"} checked={false} justDone={false} />
        </button>
        {item.qty > 1 && <span style={{ fontSize: 13, fontWeight: 700, color: "var(--badge-fg)", background: "var(--badge-bg)", borderRadius: 8, padding: "2px 6px", lineHeight: 1.3, fontFamily: "'DM Sans', sans-serif", flexShrink: 0, minWidth: 20, textAlign: "center" }}>{item.qty}×</span>}
        {(item.icon || detectItemIcon(item.text)) && <span style={{ fontSize: 20, lineHeight: 1, flexShrink: 0, userSelect: "none" }}>{item.icon || detectItemIcon(item.text)}</span>}
        <input className="g-edit" value={item.text} onChange={e => onUpdateText(item.id, e.target.value)} onKeyDown={onKeyDown} onBlur={() => onBlur(item.id)} spellCheck={false} />
        {item.store && allStores[item.store] && (
          <span style={{ display: "inline-flex", alignItems: "center", gap: 2, flexShrink: 0 }} title={allStores[item.store].label}>
            {allStores[item.store].domain ? <img src={storeFavicon(allStores[item.store].domain)} alt="" width={14} height={14} style={{ borderRadius: 2 }} onError={e => { e.target.style.display = "none"; }} /> : <span style={{ width: 14, height: 14, borderRadius: 2, background: allStores[item.store].color, color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: 8, fontWeight: 700 }}>{allStores[item.store].label[0]}</span>}
          </span>
        )}
        <span style={{ fontSize: 12, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .7, background: CATEGORIES[item.category]?.color + "18", color: CATEGORIES[item.category]?.color, padding: "3px 7px", borderRadius: 8, fontFamily: "'DM Sans', sans-serif", fontWeight: 600, whiteSpace: "nowrap" }} title={CATEGORIES[item.category]?.label}>{CATEGORIES[item.category]?.emoji} {CATEGORIES[item.category]?.label}</span>
      </div>
    </SwipeRow>
  );
}

export function CheckedItem({ item, allStores, justChecked, onToggle, onUpdateText, onKeyDown, onBlur, onDelete }) {
  const isJustChecked = justChecked.has(item.id);
  return (
    <SwipeRow onDelete={() => onDelete(item.id)} height={LINE_H}>
      <div className="g-item" style={{ display: "flex", alignItems: "center", gap: 6, height: LINE_H, borderBottom: "1px solid var(--line)", opacity: .45 }}>
        <span style={{ fontSize: 12, color: "var(--drag)", userSelect: "none", width: 12, textAlign: "center", flexShrink: 0, visibility: "hidden" }}>⠿</span>
        <button onClick={() => onToggle(item.id)} style={{ width: 22, height: 22, background: "transparent", border: "none", cursor: "pointer", padding: 0, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
          <CheckMark color={CATEGORIES[item.category]?.color || "#888"} checked={true} justDone={isJustChecked} />
        </button>
        {item.qty > 1 && <span style={{ fontSize: 13, fontWeight: 700, color: "var(--badge-fg)", background: "var(--badge-bg)", borderRadius: 8, padding: "2px 6px", lineHeight: 1.3, fontFamily: "'DM Sans', sans-serif", flexShrink: 0, opacity: .5 }}>{item.qty}×</span>}
        {(item.icon || detectItemIcon(item.text)) && <span style={{ fontSize: 20, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .6 }}>{item.icon || detectItemIcon(item.text)}</span>}
        <div style={{ flex: 1, position: "relative", height: LINE_H, display: "flex", alignItems: "center" }}>
          <input className="g-edit done" value={item.text} onChange={e => onUpdateText(item.id, e.target.value)} onKeyDown={onKeyDown} onBlur={() => onBlur(item.id)} spellCheck={false} style={{ textDecoration: "none" }} />
          <div className={isJustChecked ? "strike-anim" : ""} style={{ position: "absolute", left: 0, top: "50%", height: 1.5, background: "var(--strike)", transform: "rotate(-0.5deg)", width: isJustChecked ? undefined : "100%", pointerEvents: "none" }} />
        </div>
        {item.store && allStores[item.store] && (
          <span style={{ display: "inline-flex", alignItems: "center", gap: 2, flexShrink: 0, opacity: .6 }} title={allStores[item.store].label}>
            {allStores[item.store].domain ? <img src={storeFavicon(allStores[item.store].domain)} alt="" width={14} height={14} style={{ borderRadius: 2 }} onError={e => { e.target.style.display = "none"; }} /> : <span style={{ width: 14, height: 14, borderRadius: 2, background: allStores[item.store].color, color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: 8, fontWeight: 700 }}>{allStores[item.store].label[0]}</span>}
          </span>
        )}
        <span style={{ fontSize: 12, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .5, background: CATEGORIES[item.category]?.color + "18", color: CATEGORIES[item.category]?.color, padding: "3px 7px", borderRadius: 8, fontFamily: "'DM Sans', sans-serif", fontWeight: 600, whiteSpace: "nowrap" }} title={CATEGORIES[item.category]?.label}>{CATEGORIES[item.category]?.emoji} {CATEGORIES[item.category]?.label}</span>
      </div>
    </SwipeRow>
  );
}

