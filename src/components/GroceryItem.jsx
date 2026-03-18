import { useState, useRef, useEffect } from "react";
import { CATEGORIES } from "../data/categories";
import { storeFavicon } from "../data/stores";
import { detectItemIcon } from "../itemIcons";
import SwipeRow from "./SwipeRow";
import CheckMark from "./CheckMark";
import ContentEditable from "./ContentEditable";

const LINE_H = 50;

function CategoryPicker({ currentCat, onSelect, onClose }) {
  const ref = useRef(null);
  useEffect(() => {
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) onClose(); };
    document.addEventListener("mousedown", handler);
    document.addEventListener("touchstart", handler);
    return () => { document.removeEventListener("mousedown", handler); document.removeEventListener("touchstart", handler); };
  }, [onClose]);

  return (
    <div ref={ref} style={{ position: "absolute", right: 0, top: LINE_H, zIndex: 30, background: "var(--paper)", border: "1.5px solid var(--line)", borderRadius: 10, boxShadow: "0 4px 16px rgba(0,0,0,.12)", padding: "4px 0", animation: "fadeIn .1s ease", maxHeight: 240, overflowY: "auto", minWidth: 180 }}>
      {Object.entries(CATEGORIES).map(([key, { label, emoji, color }]) => (
        <button key={key} onMouseDown={e => { e.preventDefault(); e.stopPropagation(); onSelect(key); }}
          style={{ display: "flex", alignItems: "center", gap: 8, width: "100%", padding: "6px 12px", border: "none", cursor: "pointer", fontFamily: "'DM Sans', sans-serif", fontSize: 13, fontWeight: 500, transition: "background .1s",
            background: key === currentCat ? color + "18" : "transparent", color: "var(--ink)" }}>
          <span style={{ fontSize: 16 }}>{emoji}</span>
          <span>{label}</span>
          {key === currentCat && <span style={{ marginLeft: "auto", fontSize: 11, color: color, fontWeight: 700 }}>✓</span>}
        </button>
      ))}
    </div>
  );
}

export function UncheckedItem({ item, allStores, onToggle, onUpdateText, onKeyDown, onBlur, onDragStart, onDragOver, onDrop, onDragEnd, onDelete, dragId, dragOverId, editStoreActive, editStoreMatches, editStoreAutoIdx, onEditStoreSelect, onUpdateCategory }) {
  const [showCatPicker, setShowCatPicker] = useState(false);

  return (
    <div style={{ position: "relative" }}>
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
          <ContentEditable className="g-edit" value={item.text} onChange={text => onUpdateText(item.id, text)} onKeyDown={e => onKeyDown(e, item.id)} onBlur={() => onBlur(item.id)} spellCheck={false} />
          {item.store && allStores[item.store] && (
            <span style={{ display: "inline-flex", alignItems: "center", gap: 2, flexShrink: 0 }} title={allStores[item.store].label}>
              {allStores[item.store].domain ? <img src={storeFavicon(allStores[item.store].domain)} alt="" width={14} height={14} style={{ borderRadius: 2 }} onError={e => { e.target.style.display = "none"; }} /> : <span style={{ width: 14, height: 14, borderRadius: 2, background: allStores[item.store].color, color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: 8, fontWeight: 700 }}>{allStores[item.store].label[0]}</span>}
            </span>
          )}
          <button onClick={() => setShowCatPicker(p => !p)} style={{ fontSize: 12, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .7, background: CATEGORIES[item.category]?.color + "18", color: CATEGORIES[item.category]?.color, padding: "3px 7px", borderRadius: 8, fontFamily: "'DM Sans', sans-serif", fontWeight: 600, whiteSpace: "nowrap", border: "none", cursor: "pointer", transition: "opacity .15s" }} title="Change category">{CATEGORIES[item.category]?.emoji} {CATEGORIES[item.category]?.label}</button>
        </div>
      </SwipeRow>
      {showCatPicker && (
        <CategoryPicker currentCat={item.category} onSelect={cat => { onUpdateCategory(item.id, cat); setShowCatPicker(false); }} onClose={() => setShowCatPicker(false)} />
      )}
      {editStoreActive && editStoreMatches.length > 0 && (
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
          <ContentEditable className="g-edit done" value={item.text} onChange={text => onUpdateText(item.id, text)} onKeyDown={e => onKeyDown(e, item.id)} onBlur={() => onBlur(item.id)} spellCheck={false} style={{ textDecoration: "none" }} />
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
