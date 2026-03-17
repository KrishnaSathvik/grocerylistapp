import { useState, useRef } from "react";

export default function SwipeRow({ children, onDelete, height }) {
  const [offset, setOffset] = useState(0);
  const [swiping, setSwiping] = useState(false);
  const [deleted, setDeleted] = useState(false);
  const startX = useRef(0), startY = useRef(0), locked = useRef(false);
  const TH = 80, DEL = 120;
  const onTS = e => { startX.current = e.touches[0].clientX; startY.current = e.touches[0].clientY; locked.current = false; setSwiping(true); };
  const onTM = e => {
    if (!swiping) return;
    const dx = e.touches[0].clientX - startX.current, dy = e.touches[0].clientY - startY.current;
    if (!locked.current && (Math.abs(dx) > 8 || Math.abs(dy) > 8)) { locked.current = true; if (Math.abs(dy) > Math.abs(dx)) { setSwiping(false); setOffset(0); return; } }
    if (!locked.current) return;
    setOffset(Math.min(0, Math.max(-DEL - 20, dx)));
  };
  const onTE = () => { setSwiping(false); if (offset < -DEL) { setDeleted(true); setTimeout(onDelete, 280); } else setOffset(0); };
  const prog = Math.min(1, Math.abs(offset) / TH), ready = Math.abs(offset) >= TH;
  return (
    <div style={{ position: "relative", overflow: "hidden", height: deleted ? 0 : height, opacity: deleted ? 0 : 1, transition: deleted ? "height .28s ease, opacity .2s ease" : "none" }}>
      <div style={{ position: "absolute", right: 0, top: 0, bottom: 0, width: Math.abs(offset) + 1,
        background: ready ? "linear-gradient(90deg,#c0392b,#e74c3c)" : `rgba(163,61,64,${prog * .85})`,
        display: "flex", alignItems: "center", justifyContent: "center", transition: swiping ? "none" : "all .25s ease", borderBottom: "1px solid rgba(255,255,255,.15)" }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
          style={{ opacity: prog, transform: `scale(${.6 + prog * .4})`, transition: swiping ? "none" : "all .2s" }}>
          <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/>
        </svg>
      </div>
      <div onTouchStart={onTS} onTouchMove={onTM} onTouchEnd={onTE}
        style={{ transform: `translateX(${offset}px)`, transition: swiping ? "none" : "transform .25s cubic-bezier(.25,.46,.45,.94)",
          position: "relative", zIndex: 1, background: "var(--paper)" }}>
        {children}
      </div>
    </div>
  );
}
