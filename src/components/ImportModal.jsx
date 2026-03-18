export default function ImportModal({ itemCount, onAdd, onReplace, onCancel }) {
  return (
    <div onClick={onCancel} style={{
      position: "fixed", inset: 0, zIndex: 950,
      background: "rgba(0,0,0,.5)", display: "flex",
      alignItems: "center", justifyContent: "center",
      animation: "fadeIn .15s ease", padding: 20,
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        width: "100%", maxWidth: 340, background: "var(--paper)",
        borderRadius: 14, padding: "28px 24px 20px",
        boxShadow: "0 8px 32px rgba(0,0,0,.2)",
        animation: "fadeIn .2s ease", textAlign: "center",
      }}>
        <span style={{ fontSize: 40, display: "block", marginBottom: 8 }}>📥</span>
        <p style={{ fontSize: 16, fontWeight: 700, color: "var(--ink)", fontFamily: "'DM Sans', sans-serif", marginBottom: 6 }}>
          Incoming grocery list
        </p>
        <p style={{ fontSize: 13, color: "var(--ink-muted)", fontFamily: "'DM Sans', sans-serif", marginBottom: 20 }}>
          {itemCount} item{itemCount !== 1 ? "s" : ""} from a shared link
        </p>

        <button onClick={onAdd} style={btnStyle("#4a7c59", "#fff")}>
          Add to my list
        </button>
        <button onClick={onReplace} style={btnStyle("var(--ink)", "var(--paper)")}>
          Replace my list
        </button>
        <button onClick={onCancel} style={{
          width: "100%", padding: "10px", border: "none", cursor: "pointer",
          background: "transparent", color: "var(--ink-muted)",
          fontFamily: "'DM Sans', sans-serif", fontSize: 14, fontWeight: 500,
          marginTop: 4,
        }}>
          Cancel
        </button>
      </div>
    </div>
  );
}

function btnStyle(bg, fg) {
  return {
    width: "100%", padding: "11px", border: "none", cursor: "pointer",
    background: bg, color: fg, borderRadius: 10,
    fontFamily: "'DM Sans', sans-serif", fontSize: 14, fontWeight: 600,
    marginBottom: 8, transition: "opacity .15s",
  };
}
