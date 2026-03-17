export default function Pagination({ page, totalPages, animating, onPrev, onNext, onGoTo }) {
  if (totalPages <= 1) return null;
  return (
    <>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 14, paddingTop: 12, paddingBottom: 4, position: "relative", zIndex: 1 }}>
        <button className="g-nav" onClick={onPrev} disabled={page === 0 || animating} style={{ width: 34, height: 34, borderRadius: "50%", border: `1.5px solid var(--border-btn)`, background: "transparent", color: "var(--ink-soft)", fontSize: 20, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", transition: "all .15s", fontFamily: "system-ui", lineHeight: 1, padding: 0 }}>‹</button>
        <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
          {Array.from({ length: totalPages }).map((_, i) => (
            <button key={i} className="g-dot" onClick={() => i !== page && onGoTo(i, i > page ? "next" : "prev")}
              style={{ width: i === page ? 9 : 7, height: i === page ? 9 : 7, borderRadius: "50%", background: i === page ? "var(--ink)" : "var(--line-dash)", border: "none", cursor: "pointer", padding: 0, transition: "all .2s" }} />
          ))}
        </div>
        <button className="g-nav" onClick={onNext} disabled={page === totalPages - 1 || animating} style={{ width: 34, height: 34, borderRadius: "50%", border: `1.5px solid var(--border-btn)`, background: "transparent", color: "var(--ink-soft)", fontSize: 20, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", transition: "all .15s", fontFamily: "system-ui", lineHeight: 1, padding: 0 }}>›</button>
      </div>
      <p style={{ textAlign: "center", fontSize: 11, color: "var(--ink-faint)", fontStyle: "italic", paddingTop: 3, fontFamily: "'DM Sans', sans-serif", position: "relative", zIndex: 1 }}>page {page + 1} of {totalPages}</p>
    </>
  );
}
