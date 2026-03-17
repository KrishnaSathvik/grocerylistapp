import { CATEGORIES } from "../data/categories";
import { getItemEmoji } from "../data/itemEmojis";
import { storeFavicon } from "../data/stores";

const INPUT_H = 56;

export default function InputBar({ input, onInputChange, onAddItem, onKeyDown, inputRef, autoDetectedCat, inputClean, storeQuery, storeMatches, storeAutoIdx, onSelectStore }) {
  return (
    <>
      <div style={{ display: "flex", alignItems: "center", gap: 8, height: INPUT_H, borderBottom: "2px solid var(--line)", position: "relative", zIndex: 1, marginBottom: 2 }}>
        <input ref={inputRef} value={input} onChange={e => onInputChange(e.target.value)} onKeyDown={onKeyDown}
          placeholder='Add item... (try "2 milk @costco")'
          style={{ flex: 1, border: "none", outline: "none", fontSize: 26, fontFamily: "'Caveat', cursive", fontWeight: 500, color: "var(--ink)", background: "transparent", padding: 0, height: INPUT_H, lineHeight: `${INPUT_H}px`, letterSpacing: ".2px", caretColor: "var(--caret)", minWidth: 0, WebkitAppearance: "none", borderRadius: 0 }} />
        {inputClean.trim() && getItemEmoji(inputClean.trim()) && <span style={{ fontSize: 22, lineHeight: 1, flexShrink: 0, userSelect: "none", animation: "fadeIn .2s ease" }}>{getItemEmoji(inputClean.trim())}</span>}
        {autoDetectedCat && inputClean.trim() && <span style={{ fontSize: 10, fontWeight: 600, color: "#4a7c59", textTransform: "uppercase", letterSpacing: ".8px", whiteSpace: "nowrap", opacity: .65, fontFamily: "'DM Sans', sans-serif" }}>{CATEGORIES[autoDetectedCat].label}</span>}
        <button onClick={onAddItem} className="g-add" style={{ width: 36, height: 36, borderRadius: "50%", border: `1.5px solid ${input.trim() ? "var(--ink)" : "var(--border-btn)"}`, background: input.trim() ? "var(--ink)" : "transparent", color: input.trim() ? "var(--paper)" : "var(--ink-faint)", fontSize: 22, cursor: input.trim() ? "pointer" : "default", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, transition: "all .15s", lineHeight: 1, opacity: input.trim() ? 1 : 0.4 }} disabled={!input.trim()}>+</button>
      </div>

      {storeQuery !== null && storeMatches.length > 0 && (
        <div style={{ background: "var(--paper)", border: "1.5px solid var(--line)", borderRadius: 10, boxShadow: "0 4px 16px rgba(0,0,0,.1)", padding: "4px 0", animation: "fadeIn .1s ease", position: "relative", zIndex: 10, marginTop: -1 }}>
          {storeMatches.map(([key, { label, domain, color }], i) => (
            <button key={key} onClick={() => onSelectStore(key)}
              style={{ display: "flex", alignItems: "center", gap: 8, width: "100%", padding: "6px 12px", border: "none", cursor: "pointer", fontFamily: "'DM Sans', sans-serif", fontSize: 13, fontWeight: 500, transition: "background .1s",
                background: i === storeAutoIdx ? "var(--line)" : "transparent", color: "var(--ink)" }}>
              {domain ? <img src={storeFavicon(domain)} alt="" width={16} height={16} style={{ borderRadius: 3 }} onError={e => { e.target.style.display = "none"; }} /> : <span style={{ width: 16, height: 16, borderRadius: 3, background: color, color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: 9, fontWeight: 700 }}>{label[0]}</span>}
              <span>{label}</span>
              <span style={{ fontSize: 11, color: "var(--ink-faint)", marginLeft: "auto" }}>@{key}</span>
            </button>
          ))}
        </div>
      )}
    </>
  );
}
