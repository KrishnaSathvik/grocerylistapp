export default function Header({ itemCount, filteredLeft, viewMode, onToggleView, onShare }) {
  return (
    <div style={{ paddingTop: 24, paddingBottom: 10, position: "relative", zIndex: 1 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <img src="/logo.png" alt="" width={36} height={36} style={{ borderRadius: 8, flexShrink: 0 }} />
        <h1 style={{ fontFamily: "'Patrick Hand', cursive", fontSize: 38, fontWeight: 700, color: "var(--ink)", lineHeight: 1.1 }}>Grocery List</h1>
        {itemCount > 0 && <span style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", minWidth: 20, height: 20, borderRadius: 10, background: "var(--badge-bg)", color: "var(--badge-fg)", fontSize: 12, fontWeight: 600, padding: "0 6px" }}>{filteredLeft}</span>}
        {itemCount > 0 && (
          <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6 }}>
            <button onClick={onToggleView}
              style={{ height: 26, borderRadius: 13, cursor: "pointer", flexShrink: 0, transition: "all .15s", display: "flex", alignItems: "center", justifyContent: "center", gap: 4, padding: "0 10px",
                backgroundColor: viewMode === "store" ? "var(--ink)" : "transparent", color: viewMode === "store" ? "var(--paper)" : "var(--ink-soft)", border: `1.5px solid ${viewMode === "store" ? "var(--ink)" : "var(--border-btn)"}`,
                fontSize: 11, fontWeight: 600, fontFamily: "'DM Sans', sans-serif" }}
              title={viewMode === "list" ? "Group by store" : "Back to list"}>
              {viewMode === "list" ? "By Store" : "List View"}
            </button>
            <button className="g-share" onClick={onShare} style={{ width: 28, height: 28, borderRadius: "50%", border: `1.5px solid var(--border-btn)`, background: "transparent", color: "var(--ink-soft)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", transition: "all .15s", padding: 0, flexShrink: 0 }} title="Share">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12v8a2 2 0 002 2h12a2 2 0 002-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>
            </button>
          </div>
        )}
      </div>
      <p style={{ fontSize: 14, color: "var(--ink-muted)", marginTop: 2, fontStyle: "italic" }}>{new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" })}</p>
    </div>
  );
}
