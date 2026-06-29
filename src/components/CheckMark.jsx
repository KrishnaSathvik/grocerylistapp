export default function CheckMark({ color, checked: c, justDone }) {
  return (
    <div className="g-check" style={{ width: 20, height: 20, borderRadius: "50%", border: `2px solid ${c ? color : "var(--check-unchecked)"}`, backgroundColor: c ? color : "transparent", display: "flex", alignItems: "center", justifyContent: "center", transition: "all .2s" }}>
      {c && <svg width="10" height="9" viewBox="0 0 10 8" fill="none" style={{ overflow: "visible" }}><path d="M1 4L3.5 6.5L9 1" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" className={justDone ? "check-draw" : ""} style={justDone ? {} : { strokeDasharray: "none" }} /></svg>}
    </div>
  );
}
