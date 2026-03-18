export default function ShareSheet({ onCopyText, onShareLink, onShowQR, onClose }) {
  return (
    <div onClick={onClose} style={{
      position: "fixed", inset: 0, zIndex: 900,
      background: "rgba(0,0,0,.4)", display: "flex",
      alignItems: "flex-end", justifyContent: "center",
      animation: "fadeIn .15s ease",
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        width: "100%", maxWidth: 520, background: "var(--paper)",
        borderRadius: "16px 16px 0 0", padding: "20px 24px 28px",
        animation: "sheetUp .25s ease",
      }}>
        <p style={{ fontSize: 15, fontWeight: 600, color: "var(--ink)", fontFamily: "'DM Sans', sans-serif", marginBottom: 16 }}>Share your list</p>

        <button onClick={onCopyText} style={optionStyle}>
          <span style={{ fontSize: 20 }}>📋</span>
          <div>
            <span style={labelStyle}>Copy as text</span>
            <span style={descStyle}>Plain text with checkmarks</span>
          </div>
        </button>

        <button onClick={onShareLink} style={optionStyle}>
          <span style={{ fontSize: 20 }}>🔗</span>
          <div>
            <span style={labelStyle}>Share as link</span>
            <span style={descStyle}>Anyone with the link can import</span>
          </div>
        </button>

        <button onClick={onShowQR} style={optionStyle}>
          <span style={{ fontSize: 20 }}>📱</span>
          <div>
            <span style={labelStyle}>Show QR code</span>
            <span style={descStyle}>Scan to import on another device</span>
          </div>
        </button>

        <button onClick={onClose} style={{
          width: "100%", padding: "12px", border: "none", cursor: "pointer",
          background: "transparent", color: "var(--ink-muted)",
          fontFamily: "'DM Sans', sans-serif", fontSize: 14, fontWeight: 600,
          marginTop: 8, borderTop: "1px solid var(--line)",
        }}>
          Cancel
        </button>
      </div>
    </div>
  );
}

const optionStyle = {
  display: "flex", alignItems: "center", gap: 12, width: "100%",
  padding: "12px 8px", border: "none", cursor: "pointer",
  background: "transparent", borderRadius: 10,
  transition: "background .1s", textAlign: "left",
  fontFamily: "'DM Sans', sans-serif",
};

const labelStyle = {
  display: "block", fontSize: 14, fontWeight: 600, color: "var(--ink)",
};

const descStyle = {
  display: "block", fontSize: 12, color: "var(--ink-muted)", marginTop: 1,
};
