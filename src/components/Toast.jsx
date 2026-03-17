export default function Toast({ toast, undoItem, onUndo }) {
  if (!toast) return null;
  return (
    <div style={{ position: "fixed", bottom: 28, left: "50%", transform: "translateX(-50%)", background: "var(--toast-bg)", color: "var(--toast-fg)", padding: "8px 16px", borderRadius: 20, fontSize: 13, fontWeight: 500, boxShadow: "0 4px 20px rgba(0,0,0,.3)", animation: "toastIn .3s ease-out", zIndex: 100, fontFamily: "'DM Sans', sans-serif", display: "flex", alignItems: "center", gap: 10, maxWidth: "calc(100vw - 32px)", width: "auto" }}>
      <span style={{ flex: 1 }}>{toast}</span>
      {undoItem && <button onClick={onUndo} style={{ background: "transparent", border: "1px solid rgba(128,128,128,.35)", color: "var(--toast-fg)", fontSize: 12, fontWeight: 600, padding: "3px 12px", borderRadius: 12, cursor: "pointer", fontFamily: "'DM Sans', sans-serif", whiteSpace: "nowrap" }}>Undo</button>}
    </div>
  );
}
