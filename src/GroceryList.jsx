import { useState, useRef, useCallback, useEffect } from "react";
import { detectItemIcon } from "./itemIcons";
import { CATEGORIES } from "./data/categories";
import { DEFAULT_STORES, storeFavicon } from "./data/stores";
import { getItemEmoji } from "./data/itemEmojis";
import { detectCategory, parseQty } from "./utils";
import { notepadStyles } from "./notepadStyles";

import Header from "./components/Header";
import InputBar from "./components/InputBar";
import ListView from "./components/ListView";
import StoreView from "./components/StoreView";
import Pagination from "./components/Pagination";
import Toast from "./components/Toast";
import Onboarding from "./components/Onboarding";

const LINE_H = 50;
const PER_PAGE = 12;

export default function GroceryList() {
  const [items, setItems] = useState(() => {
    try { const s = localStorage.getItem("grocery-items"); return s ? JSON.parse(s) : []; }
    catch { return []; }
  });
  const [input, setInput] = useState("");
  const selectedCat = "pantry";
  const [autoDetectedCat, setAutoDetectedCat] = useState(null);

  const [page, setPage] = useState(0);
  const [flipDir, setFlipDir] = useState(null);
  const [animating, setAnimating] = useState(false);
  const [justChecked, setJustChecked] = useState(new Set());
  const [toast, setToast] = useState(null);
  const [undoItem, setUndoItem] = useState(null);
  const [dragId, setDragId] = useState(null);
  const [dragOverId, setDragOverId] = useState(null);
  const [viewMode, setViewMode] = useState("list");
  const [customStores, setCustomStores] = useState(() => {
    try { const s = localStorage.getItem("grocery-stores"); return s ? JSON.parse(s) : {}; } catch { return {}; }
  });
  const [showOnboarding, setShowOnboarding] = useState(() => !localStorage.getItem("onboarding-done"));
  const inputRef = useRef(null);
  const undoTimer = useRef(null);

  const allStores = { ...DEFAULT_STORES, ...customStores };

  useEffect(() => { try { localStorage.setItem("grocery-items", JSON.stringify(items)); } catch {} }, [items]);
  useEffect(() => { try { localStorage.setItem("grocery-stores", JSON.stringify(customStores)); } catch {} }, [customStores]);

  // Parse @store from input
  const parseStoreTag = (raw) => {
    const m = raw.match(/@(\S*)$/);
    if (!m) return { query: null, clean: raw };
    return { query: m[1].toLowerCase(), clean: raw.slice(0, m.index).trim() };
  };
  const { query: storeQuery, clean: inputClean } = parseStoreTag(input);
  const storeMatches = storeQuery !== null ? Object.entries(allStores).filter(([k, s]) => k.startsWith(storeQuery) || s.label.toLowerCase().startsWith(storeQuery)) : [];
  const [storeAutoIdx, setStoreAutoIdx] = useState(0);
  useEffect(() => setStoreAutoIdx(0), [storeQuery]);

  useEffect(() => { const t = inputClean.trim(); if (!t) { setAutoDetectedCat(null); return; } setAutoDetectedCat(detectCategory(parseQty(t).text)); }, [inputClean]);
  const totalLeft = items.filter(i => !i.checked).length;
  const filteredLeft = totalLeft;

  // Group items by store for store view
  const storeGroups = (() => {
    if (viewMode !== "store") return null;
    const groups = {};
    items.forEach(item => {
      if (item.checked) return;
      const key = item.store || "__none__";
      if (!groups[key]) groups[key] = [];
      groups[key].push(item);
    });
    const ordered = [];
    Object.keys(allStores).forEach(k => { if (groups[k]) ordered.push([k, groups[k]]); });
    if (groups.__none__) ordered.push(["__none__", groups.__none__]);
    return ordered;
  })();

  const storeRowCount = storeGroups ? storeGroups.reduce((sum, [, si]) => sum + 1 + si.length, 0) : 0;
  // Combined list: unchecked first, then checked
  const sortedItems = [...items.filter(i => !i.checked), ...items.filter(i => i.checked)];
  const totalPages = Math.max(1, Math.ceil((viewMode === "store" ? storeRowCount : sortedItems.length) / PER_PAGE));

  useEffect(() => { if (page >= totalPages) setPage(Math.max(0, totalPages - 1)); }, [totalPages, page]);

  const pageStart = page * PER_PAGE;
  const pageItems = sortedItems.slice(pageStart, pageStart + PER_PAGE);
  const pageUnchecked = pageItems.filter(i => !i.checked);
  const pageChecked = pageItems.filter(i => i.checked);
  const blankLines = Math.max(0, PER_PAGE - pageItems.length);

  const selectStoreAutoComplete = (key) => {
    const before = input.replace(/@\S*$/, "@" + key + " ");
    setInput(before);
    inputRef.current?.focus();
  };

  const goToPage = (t, d) => { if (animating || t === page) return; setFlipDir(d); setAnimating(true); setTimeout(() => { setPage(t); setFlipDir(null); setAnimating(false); }, 300); };
  const prevPage = () => page > 0 && goToPage(page - 1, "prev");
  const nextPage = () => page < totalPages - 1 && goToPage(page + 1, "next");
  const pageAnimClass = flipDir === "next" ? "pg-out-l" : flipDir === "prev" ? "pg-out-r" : "pg-in";

  const addItem = () => {
    const raw = input.trim(); if (!raw) return;
    const { query: sq, clean } = parseStoreTag(raw);
    const resolvedStore = sq ? (Object.entries(allStores).find(([k, s]) => k === sq || s.label.toLowerCase() === sq)?.[0] || (storeMatches.length > 0 ? storeMatches[0][0] : null)) : null;
    const { qty, text } = parseQty(clean || raw);
    const cat = autoDetectedCat || selectedCat;
    setItems(prev => {
      const icon = detectItemIcon(text);
      const next = [...prev, { id: Date.now(), text, qty, category: cat, checked: false, icon, store: resolvedStore }];
      const lp = Math.max(1, Math.ceil(next.length / PER_PAGE)) - 1;
      if (lp > page) goToPage(lp, "next");
      return next;
    });
    setInput(""); setAutoDetectedCat(null); inputRef.current?.focus();
  };

  const toggleCheck = id => {
    setJustChecked(p => { const n = new Set(p); if (items.find(i => i.id === id && !i.checked)) n.add(id); return n; });
    setTimeout(() => setJustChecked(p => { const n = new Set(p); n.delete(id); return n; }), 600);
    setItems(p => p.map(i => i.id === id ? { ...i, checked: !i.checked } : i));
  };

  const removeItem = id => {
    const d = items.find(i => i.id === id); if (!d) return;
    setItems(p => p.filter(i => i.id !== id));
    if (undoTimer.current) clearTimeout(undoTimer.current);
    setUndoItem(d); setToast(`Deleted "${d.text}"`);
    undoTimer.current = setTimeout(() => { setUndoItem(null); setToast(null); }, 3500);
  };
  const handleUndo = () => { if (!undoItem) return; setItems(p => [...p, undoItem]); setUndoItem(null); setToast(null); if (undoTimer.current) clearTimeout(undoTimer.current); };

  const updateText = useCallback((id, t) => setItems(p => p.map(i => i.id === id ? { ...i, text: t } : i)), []);
  const handleItemKeyDown = e => { if (e.key === "Enter") { e.preventDefault(); e.target.blur(); inputRef.current?.focus(); } };
  const handleItemBlur = id => setItems(p => { const it = p.find(i => i.id === id); return it && !it.text.trim() ? p.filter(i => i.id !== id) : p; });
  const clearChecked = () => setItems(p => p.filter(i => !i.checked));

  const shareList = async () => {
    const unc = items.filter(i => !i.checked), chk = items.filter(i => i.checked);
    let t = "🛒 Grocery List\n" + new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" }) + "\n\n";
    const storeMap = {};
    unc.forEach(i => { const k = i.store || "__none__"; if (!storeMap[k]) storeMap[k] = []; storeMap[k].push(i); });
    const hasStores = Object.keys(storeMap).some(k => k !== "__none__");
    if (hasStores) {
      Object.entries(storeMap).forEach(([k, list]) => {
        if (k === "__none__") return;
        t += `📍 ${allStores[k]?.label || k}:\n`;
        list.forEach(i => { t += `  ☐ ${i.qty > 1 ? i.qty + "x " : ""}${i.text}\n`; });
        t += "\n";
      });
      if (storeMap.__none__) { t += "📍 Other:\n"; storeMap.__none__.forEach(i => { t += `  ☐ ${i.qty > 1 ? i.qty + "x " : ""}${i.text}\n`; }); t += "\n"; }
    } else {
      unc.forEach(i => { t += `☐ ${i.qty > 1 ? i.qty + "x " : ""}${i.text}\n`; });
    }
    if (chk.length) { t += "\n✓ Picked up:\n"; chk.forEach(i => { t += `  ✓ ${i.text}\n`; }); }
    t += `\n${unc.length} item${unc.length !== 1 ? "s" : ""} remaining`;
    if (navigator.share) { try { await navigator.share({ title: "Grocery List", text: t }); return; } catch {} }
    try { await navigator.clipboard.writeText(t); setToast("Copied!"); setTimeout(() => setToast(null), 2200); } catch { setToast("Couldn't copy"); setTimeout(() => setToast(null), 2200); }
  };

  const handleDragStart = id => setDragId(id);
  const handleDragOver = (e, id) => { e.preventDefault(); setDragOverId(id); };
  const handleDrop = tid => {
    if (dragId == null || dragId === tid) { setDragId(null); setDragOverId(null); return; }
    setItems(p => { const a = [...p], f = a.findIndex(i => i.id === dragId), t = a.findIndex(i => i.id === tid); if (f < 0 || t < 0) return p; const [m] = a.splice(f, 1); a.splice(t, 0, m); return a; });
    setDragId(null); setDragOverId(null);
  };
  const handleDragEnd = () => { setDragId(null); setDragOverId(null); };

  const blankTouch = useRef({ x: 0, y: 0 });
  const onBTS = e => { blankTouch.current = { x: e.touches[0].clientX, y: e.touches[0].clientY }; };
  const onBTE = e => { const dx = e.changedTouches[0].clientX - blankTouch.current.x, dy = e.changedTouches[0].clientY - blankTouch.current.y; if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 60) { dx < 0 ? nextPage() : prevPage(); } };

  const handleInputKeyDown = e => {
    if (storeQuery !== null && storeMatches.length > 0) {
      if (e.key === "ArrowDown") { e.preventDefault(); setStoreAutoIdx(i => Math.min(i + 1, storeMatches.length - 1)); return; }
      if (e.key === "ArrowUp") { e.preventDefault(); setStoreAutoIdx(i => Math.max(i - 1, 0)); return; }
      if (e.key === "Tab" || (e.key === "Enter" && storeQuery !== "")) { e.preventDefault(); selectStoreAutoComplete(storeMatches[storeAutoIdx][0]); return; }
    }
    if (e.key === "Enter") addItem();
  };

  const finishOnboarding = () => {
    localStorage.setItem("onboarding-done", "1");
    setShowOnboarding(false);
  };

  return (
    <div className="notepad-outer" style={{ minHeight: "100dvh", background: "var(--bg)", display: "flex", justifyContent: "center", padding: "0", fontFamily: "'DM Sans', sans-serif", position: "relative", overflowX: "hidden", width: "100%" }}>
      <style>{notepadStyles}</style>

      {showOnboarding && <Onboarding onDone={finishOnboarding} />}

      <div className="notepad-wrap" style={{ width: "100%", maxWidth: 520, minHeight: "100dvh", background: "var(--paper)", borderRadius: 0, boxShadow: "none", position: "relative", paddingLeft: 48, paddingRight: 16, paddingBottom: 18, overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 38, top: 0, bottom: 0, width: 2, background: "var(--margin)", zIndex: 1 }} />
        <div style={{ position: "absolute", left: 0, top: 16, bottom: 16, width: 24, display: "flex", flexDirection: "column", gap: 22, alignItems: "center", zIndex: 2 }}>
          {Array.from({ length: 18 }).map((_, i) => <div key={i} style={{ width: 10, height: 10, borderRadius: "50%", background: "var(--hole)", boxShadow: "var(--hole-shadow)", flexShrink: 0 }} />)}
        </div>

        <Header itemCount={items.length} filteredLeft={filteredLeft} viewMode={viewMode}
          onToggleView={() => { setViewMode(viewMode === "list" ? "store" : "list"); setPage(0); }}
          onShare={shareList} />

        <InputBar input={input} onInputChange={setInput} onAddItem={addItem} onKeyDown={handleInputKeyDown}
          inputRef={inputRef} autoDetectedCat={autoDetectedCat} inputClean={inputClean}
          storeQuery={storeQuery} storeMatches={storeMatches} storeAutoIdx={storeAutoIdx}
          onSelectStore={selectStoreAutoComplete} />

        <div style={{ minHeight: PER_PAGE * LINE_H, position: "relative", perspective: "800px", overflow: "hidden", touchAction: "pan-y" }}>
          {viewMode === "store" && items.length > 0 && storeGroups && (
            <StoreView storeGroups={storeGroups} allStores={allStores} page={page} pageStart={pageStart}
              justChecked={justChecked} onToggle={toggleCheck} onUpdateText={updateText}
              onItemKeyDown={handleItemKeyDown} onItemBlur={handleItemBlur} onRemove={removeItem}
              onBlankTouchStart={onBTS} onBlankTouchEnd={onBTE} pageAnimClass={pageAnimClass} />
          )}

          {viewMode === "list" && (
            <ListView itemCount={items.length} pageUnchecked={pageUnchecked} pageChecked={pageChecked}
              blankLines={blankLines} page={page} justChecked={justChecked} allStores={allStores}
              onToggle={toggleCheck} onUpdateText={updateText} onItemKeyDown={handleItemKeyDown}
              onItemBlur={handleItemBlur} onDragStart={handleDragStart} onDragOver={handleDragOver}
              onDrop={handleDrop} onDragEnd={handleDragEnd} onRemove={removeItem}
              onClearChecked={clearChecked} onBlankTouchStart={onBTS} onBlankTouchEnd={onBTE}
              dragId={dragId} dragOverId={dragOverId} pageAnimClass={pageAnimClass} />
          )}

          {viewMode === "store" && items.length === 0 && (
            <div style={{ textAlign: "center", padding: "36px 0", animation: "fadeIn .3s ease" }}>
              <span style={{ fontSize: 36, display: "block", marginBottom: 6 }}>📝</span>
              <p style={{ fontFamily: "'Caveat', cursive", fontSize: 24, color: "var(--ink-muted)", fontWeight: 600 }}>Start adding items</p>
              <p style={{ fontSize: 13, color: "var(--ink-faint)", marginTop: 4, fontStyle: "italic" }}>Select a store, then add items</p>
            </div>
          )}
        </div>

        <Pagination page={page} totalPages={totalPages} animating={animating}
          onPrev={prevPage} onNext={nextPage} onGoTo={goToPage} />
      </div>

      <Toast toast={toast} undoItem={undoItem} onUndo={handleUndo} />
    </div>
  );
}
