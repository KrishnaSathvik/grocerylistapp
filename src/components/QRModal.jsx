import { useEffect, useRef } from "react";
import qrcode from "qrcode-generator";

export default function QRModal({ url, onClose }) {
  const canvasRef = useRef(null);

  useEffect(() => {
    if (!canvasRef.current) return;
    const qr = qrcode(0, "M");
    qr.addData(url);
    qr.make();
    const size = qr.getModuleCount();
    const canvas = canvasRef.current;
    const scale = Math.floor(220 / size);
    const realSize = size * scale;
    canvas.width = realSize;
    canvas.height = realSize;
    const ctx = canvas.getContext("2d");
    ctx.fillStyle = "#fff";
    ctx.fillRect(0, 0, realSize, realSize);
    ctx.fillStyle = "#000";
    for (let r = 0; r < size; r++) {
      for (let c = 0; c < size; c++) {
        if (qr.isDark(r, c)) ctx.fillRect(c * scale, r * scale, scale, scale);
      }
    }
  }, [url]);

  return (
    <div onClick={onClose} style={{
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
        <p style={{ fontSize: 16, fontWeight: 700, color: "var(--ink)", fontFamily: "'DM Sans', sans-serif", marginBottom: 4 }}>
          Scan to import
        </p>
        <p style={{ fontSize: 12, color: "var(--ink-muted)", fontFamily: "'DM Sans', sans-serif", marginBottom: 16 }}>
          Open on another device to add this list
        </p>

        <div style={{
          display: "inline-block", padding: 12, background: "#fff",
          borderRadius: 10, marginBottom: 16,
        }}>
          <canvas ref={canvasRef} style={{ display: "block", borderRadius: 4, width: 220, height: 220 }} />
        </div>

        <p style={{
          fontSize: 11, color: "var(--ink-faint)", fontFamily: "'DM Sans', sans-serif",
          marginBottom: 16, wordBreak: "break-all", lineHeight: 1.4,
          maxHeight: 44, overflow: "hidden",
        }}>
          {url}
        </p>

        <button onClick={onClose} style={{
          width: "100%", padding: "11px", border: "none", cursor: "pointer",
          background: "var(--ink)", color: "var(--paper)", borderRadius: 10,
          fontFamily: "'DM Sans', sans-serif", fontSize: 14, fontWeight: 600,
          transition: "opacity .15s",
        }}>
          Done
        </button>
      </div>
    </div>
  );
}
