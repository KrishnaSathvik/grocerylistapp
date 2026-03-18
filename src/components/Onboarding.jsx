import { useState } from "react";
import { CATEGORIES } from "../data/categories";

const pages = [
  {
    logo: true,
    title: "Welcome!",
    lines: [
      "Your smart grocery list",
      "that feels like paper.",
    ],
  },
  {
    emoji: "✨",
    title: "Just type naturally",
    lines: [
      '"2 milk" → detects quantity',
      '"eggs @costco" → tags a store',
      "1,300+ items auto-categorized",
    ],
  },
  {
    emoji: "📝",
    title: "Simple gestures",
    lines: [
      "Tap to check off items",
      "Swipe left to delete",
      "Drag the grip to reorder",
    ],
  },
];

export default function Onboarding({ onDone, importData, onImportAccept }) {
  const [step, setStep] = useState(0);
  const [exiting, setExiting] = useState(false);

  const hasImport = importData && importData.length > 0;

  // If importing, show a single-page welcome with the items
  if (hasImport) {
    const exit = (action) => {
      setExiting(true);
      setTimeout(() => {
        if (action === "add") onImportAccept("add");
        else if (action === "replace") onImportAccept("replace");
        onDone();
      }, 350);
    };

    return (
      <div
        className={`ob-backdrop ${exiting ? "ob-exit" : ""}`}
        style={{
          position: "fixed", inset: 0, zIndex: 1000,
          background: "var(--bg)",
          display: "flex", justifyContent: "center", alignItems: "center",
        }}
      >
        <div className="ob-card" style={{ position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
          {/* Margin line */}
          <div style={{ position: "absolute", left: 38, top: 0, bottom: 0, width: 2, background: "var(--margin)", zIndex: 1 }} />

          {/* Hole punches */}
          <div className="ob-holes" style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 24, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 28, zIndex: 2 }}>
            {Array.from({ length: 12 }).map((_, i) => (
              <div key={i} style={{ width: 10, height: 10, borderRadius: "50%", background: "var(--hole)", boxShadow: "var(--hole-shadow)", flexShrink: 0 }} />
            ))}
          </div>

          {/* Content */}
          <div style={{
            display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
            position: "relative", zIndex: 1, flex: 1,
          }}>
            <div className="ob-page" style={{ textAlign: "center", padding: "0 8px", width: "100%" }}>
              <img src="/logo.png" alt="Grocery List" className="ob-logo" />
              <h2 className="ob-title">Welcome!</h2>
              <p className="ob-line" style={{ marginBottom: 16 }}>
                Someone shared {importData.length} item{importData.length !== 1 ? "s" : ""} with you
              </p>

              {/* Item preview list */}
              <div style={{
                textAlign: "left", width: "100%", maxHeight: 220, overflowY: "auto",
                borderRadius: 10, background: "var(--paper)", border: "1px solid var(--line)",
                padding: "4px 0", marginBottom: 8,
              }}>
                {importData.slice(0, 15).map((item, i) => {
                  const cat = CATEGORIES[item.category];
                  return (
                    <div key={i} style={{
                      display: "flex", alignItems: "center", gap: 8,
                      padding: "7px 14px", fontSize: 14,
                      fontFamily: "'DM Sans', sans-serif", color: "var(--ink)",
                      borderBottom: i < Math.min(importData.length, 15) - 1 ? "1px solid var(--line)" : "none",
                    }}>
                      <span style={{ fontSize: 16 }}>{item.icon || cat?.emoji || "📦"}</span>
                      <span style={{ flex: 1 }}>
                        {item.qty > 1 && <span style={{ fontWeight: 700, fontSize: 12, background: "var(--badge-bg)", color: "var(--badge-fg)", borderRadius: 6, padding: "1px 5px", marginRight: 6 }}>{item.qty}x</span>}
                        {item.text}
                      </span>
                      <span style={{ fontSize: 11, color: cat?.color || "var(--ink-faint)", fontWeight: 600, opacity: .7 }}>
                        {cat?.emoji} {cat?.label || "Misc"}
                      </span>
                    </div>
                  );
                })}
                {importData.length > 15 && (
                  <p style={{ padding: "6px 14px", fontSize: 12, color: "var(--ink-faint)", fontStyle: "italic", fontFamily: "'DM Sans', sans-serif" }}>
                    + {importData.length - 15} more items
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* Action buttons */}
          <div style={{ textAlign: "center", paddingBottom: 8, position: "relative", zIndex: 1 }}>
            <button
              onClick={() => exit("add")}
              className="ob-btn"
              style={{
                fontFamily: "'DM Sans', sans-serif", fontSize: 15, fontWeight: 600,
                background: "#4a7c59", color: "#fff",
                border: "none", borderRadius: 24, padding: "12px 32px",
                cursor: "pointer", transition: "transform .15s",
                marginBottom: 10, width: "80%",
              }}
            >
              Add {importData.length} item{importData.length !== 1 ? "s" : ""} to my list
            </button>
            <button
              onClick={() => exit("replace")}
              className="ob-btn"
              style={{
                fontFamily: "'DM Sans', sans-serif", fontSize: 13, fontWeight: 500,
                background: "transparent", color: "var(--ink-muted)",
                border: `1.5px solid var(--border-btn)`, borderRadius: 24, padding: "9px 24px",
                cursor: "pointer", transition: "transform .15s",
                display: "block", margin: "0 auto",
              }}
            >
              Replace my current list
            </button>
          </div>

          {/* Paper texture */}
          <div style={{
            position: "absolute", inset: 0, pointerEvents: "none", zIndex: 0,
            backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E")`,
            backgroundSize: "200px 200px",
            opacity: "var(--noise-opacity)",
          }} />

          {/* Page curl */}
          <div style={{
            position: "absolute", bottom: 0, right: 0, width: 35, height: 35,
            background: "linear-gradient(135deg, transparent 50%, var(--curl1) 50%, var(--curl2) 100%)",
            boxShadow: "-2px -2px 5px rgba(0,0,0,.05)", borderTopLeftRadius: 4, zIndex: 5,
          }} />
        </div>
      </div>
    );
  }

  // Normal onboarding (no import)
  const isLast = step === pages.length - 1;

  const advance = () => {
    if (isLast) {
      setExiting(true);
      setTimeout(onDone, 350);
    } else {
      setStep(s => s + 1);
    }
  };

  const skip = (e) => {
    e.stopPropagation();
    setExiting(true);
    setTimeout(onDone, 350);
  };

  const p = pages[step];

  return (
    <div
      className={`ob-backdrop ${exiting ? "ob-exit" : ""}`}
      onClick={advance}
      style={{
        position: "fixed", inset: 0, zIndex: 1000,
        background: "var(--bg)",
        display: "flex", justifyContent: "center", alignItems: "center",
        cursor: "pointer",
      }}
    >
      <div className="ob-card" style={{ position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
        {/* Margin line */}
        <div style={{ position: "absolute", left: 38, top: 0, bottom: 0, width: 2, background: "var(--margin)", zIndex: 1 }} />

        {/* Hole punches */}
        <div className="ob-holes" style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 24, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 28, zIndex: 2 }}>
          {Array.from({ length: 12 }).map((_, i) => (
            <div key={i} style={{ width: 10, height: 10, borderRadius: "50%", background: "var(--hole)", boxShadow: "var(--hole-shadow)", flexShrink: 0 }} />
          ))}
        </div>

        {/* Skip button */}
        {!isLast && (
          <button
            onClick={skip}
            style={{
              position: "absolute", top: 16, right: 16, zIndex: 3,
              fontFamily: "'DM Sans', sans-serif", fontSize: 13, fontWeight: 500,
              color: "var(--ink-faint)", background: "none", border: "none",
              cursor: "pointer", padding: "4px 8px",
            }}
          >
            Skip
          </button>
        )}

        {/* Centered content area */}
        <div style={{
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
          position: "relative", zIndex: 1, flex: 1,
        }}>
          <div key={step} className="ob-page" style={{ textAlign: "center", padding: "0 8px" }}>
            {p.logo
              ? <img src="/logo.png" alt="Grocery List" className="ob-logo" />
              : <div className="ob-emoji">{p.emoji}</div>
            }
            <h2 className="ob-title">{p.title}</h2>
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {p.lines.map((line, i) => (
                <p key={i} className="ob-line">{line}</p>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom area */}
        <div style={{ textAlign: "center", paddingBottom: 8, position: "relative", zIndex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, marginBottom: 20 }}>
            {pages.map((_, i) => (
              <div key={i} style={{
                width: i === step ? 20 : 7, height: 7, borderRadius: 4,
                background: i === step ? "var(--ink)" : "var(--line-dash)",
                transition: "all .3s ease",
              }} />
            ))}
          </div>
          {isLast ? (
            <button
              onClick={advance}
              className="ob-btn"
              style={{
                fontFamily: "'DM Sans', sans-serif", fontSize: 15, fontWeight: 600,
                background: "var(--ink)", color: "var(--paper)",
                border: "none", borderRadius: 24, padding: "12px 40px",
                cursor: "pointer", transition: "transform .15s",
              }}
            >
              Get Started
            </button>
          ) : (
            <p style={{
              fontFamily: "'DM Sans', sans-serif", fontSize: 12,
              color: "var(--ink-faint)", fontStyle: "italic",
            }}>
              tap anywhere to continue
            </p>
          )}
        </div>

        {/* Paper texture */}
        <div style={{
          position: "absolute", inset: 0, pointerEvents: "none", zIndex: 0,
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E")`,
          backgroundSize: "200px 200px",
          opacity: "var(--noise-opacity)",
        }} />

        {/* Page curl */}
        <div style={{
          position: "absolute", bottom: 0, right: 0, width: 35, height: 35,
          background: "linear-gradient(135deg, transparent 50%, var(--curl1) 50%, var(--curl2) 100%)",
          boxShadow: "-2px -2px 5px rgba(0,0,0,.05)", borderTopLeftRadius: 4, zIndex: 5,
        }} />
      </div>
    </div>
  );
}
