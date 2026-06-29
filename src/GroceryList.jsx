import { useState, useRef, useCallback, useEffect } from "react";
import { detectItemIcon } from "./itemIcons";
import { CATEGORIES } from "./data/categories";
import { DEFAULT_STORES, storeFavicon } from "./data/stores";
import { getItemEmoji } from "./data/itemEmojis";
import { detectCategory, parseQty, encodeList, decodeList } from "./utils";
import { notepadStyles } from "./notepadStyles";

import Header from "./components/Header";
import InputBar from "./components/InputBar";
import ListView from "./components/ListView";
import StoreView from "./components/StoreView";
import Toast from "./components/Toast";
import Onboarding from "./components/Onboarding";
import ShareSheet from "./components/ShareSheet";
import ImportModal from "./components/ImportModal";
import QRModal from "./components/QRModal";

const BASE_URL = "https://grocerylistapp.vercel.app/";

export default function GroceryList() {
  const [items, setItems] = useState(() => {
    try { const s = localStorage.getItem("grocery-items"); return s ? JSON.parse(s) : []; }
    catch { return []; }
  });
  const [input, setInput] = useState("");
  const selectedCat = "misc";
  const [autoDetectedCat, setAutoDetectedCat] = useState(null);

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
  const [editStoreItemId, setEditStoreItemId] = useState(null);
  const [editStoreQuery, setEditStoreQuery] = useState("");
  const [editStoreAutoIdx, setEditStoreAutoIdx] = useState(0);
  const [showShareSheet, setShowShareSheet] = useState(false);
  const [showQR, setShowQR] = useState(false);
  const [qrUrl, setQrUrl] = useState("");
  const [importData, setImportData] = useState(null);
  const inputRef = useRef(null);
  const undoTimer = useRef(null);

  const allStores = { ...DEFAULT_STORES, ...customStores };

  useEffect(() => { try { localStorage.setItem("grocery-items", JSON.stringify(items)); } catch {} }, [items]);
  useEffect(() => { try { localStorage.setItem("grocery-stores", JSON.stringify(customStores)); } catch {} }, [customStores]);

  // Check for import hash on mount
  useEffect(() => {
    const hash = window.location.hash;
    if (!hash.startsWith("#import=")) return;
    const encoded = hash.slice(8);
    const decoded = decodeList(encoded);
    if (decoded && decoded.length > 0) {
      // Assign icons to imported items
      decoded.forEach(item => { item.icon = detectItemIcon(item.text); });
      setImportData(decoded);
    }
    // Clear hash without triggering navigation
    history.replaceState(null, "", window.location.pathname + window.location.search);
  }, []);

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

  const editStoreMatches = editStoreItemId !== null ? Object.entries(allStores).filter(([k, s]) => k.startsWith(editStoreQuery) || s.label.toLowerCase().startsWith(editStoreQuery)) : [];
  useEffect(() => setEditStoreAutoIdx(0), [editStoreQuery]);

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

  const uncheckedItems = items.filter(i => !i.checked);
  const checkedItems = items.filter(i => i.checked);

  const selectStoreAutoComplete = (key) => {
    const before = input.replace(/@\S*$/, "@" + key + " ");
    setInput(before);
    inputRef.current?.focus();
  };

  const addItem = () => {
    const raw = input.trim(); if (!raw) return;
    const { query: sq, clean } = parseStoreTag(raw);
    const resolvedStore = sq ? (Object.entries(allStores).find(([k, s]) => k === sq || s.label.toLowerCase() === sq)?.[0] || (storeMatches.length > 0 ? storeMatches[0][0] : null)) : null;
    const { qty, text } = parseQty(clean || raw);
    const cat = autoDetectedCat || selectedCat;
    setItems(prev => {
      const icon = detectItemIcon(text);
      return [...prev, { id: Date.now(), text, qty, category: cat, checked: false, icon, store: resolvedStore }];
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

  const updateText = (id, t) => {
    setItems(p => p.map(i => i.id === id ? { ...i, text: t } : i));
    const { query } = parseStoreTag(t);
    if (query !== null) { setEditStoreItemId(id); setEditStoreQuery(query); }
    else if (editStoreItemId === id) { setEditStoreItemId(null); setEditStoreQuery(""); }
  };
  const handleEditStoreSelect = (itemId, storeKey) => {
    setItems(p => p.map(i => {
      if (i.id !== itemId) return i;
      const cleanText = i.text.replace(/@\S*$/, "").trim();
      return { ...i, text: cleanText, store: storeKey };
    }));
    setEditStoreItemId(null); setEditStoreQuery(""); setEditStoreAutoIdx(0);
  };
  const handleItemKeyDown = (e, itemId) => {
    if (editStoreItemId === itemId && editStoreMatches.length > 0) {
      if (e.key === "ArrowDown") { e.preventDefault(); setEditStoreAutoIdx(i => Math.min(i + 1, editStoreMatches.length - 1)); return; }
      if (e.key === "ArrowUp") { e.preventDefault(); setEditStoreAutoIdx(i => Math.max(i - 1, 0)); return; }
      if (e.key === "Tab" || (e.key === "Enter" && editStoreQuery !== "")) { e.preventDefault(); handleEditStoreSelect(itemId, editStoreMatches[editStoreAutoIdx][0]); return; }
      if (e.key === "Escape") { e.preventDefault(); setEditStoreItemId(null); setEditStoreQuery(""); return; }
    }
    if (e.key === "Enter") { e.preventDefault(); e.target.blur(); inputRef.current?.focus(); }
  };
  const handleItemBlur = id => {
    setItems(p => { const it = p.find(i => i.id === id); return it && !it.text.trim() ? p.filter(i => i.id !== id) : p; });
    if (editStoreItemId === id) { setEditStoreItemId(null); setEditStoreQuery(""); }
  };
  const clearChecked = () => setItems(p => p.filter(i => !i.checked));
  const updateCategory = (id, cat) => setItems(p => p.map(i => i.id === id ? { ...i, category: cat } : i));
  const updateStore = (id, store) => setItems(p => p.map(i => i.id === id ? { ...i, store } : i));

  // Share: copy as text
  const shareAsText = async () => {
    setShowShareSheet(false);
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

  // Share: as link
  const shareAsLink = async () => {
    setShowShareSheet(false);
    const encoded = encodeList(items);
    if (!encoded) {
      // List too large, fall back to text
      setToast("List too large for link — copied as text instead");
      setTimeout(() => setToast(null), 2800);
      shareAsText();
      return;
    }
    const url = `${BASE_URL}#import=${encoded}`;
    if (navigator.share) { try { await navigator.share({ title: "Grocery List", url }); return; } catch {} }
    try { await navigator.clipboard.writeText(url); setToast("Link copied!"); setTimeout(() => setToast(null), 2200); } catch { setToast("Couldn't copy"); setTimeout(() => setToast(null), 2200); }
  };

  // Share: show QR
  const shareAsQR = () => {
    setShowShareSheet(false);
    const encoded = encodeList(items);
    if (!encoded) {
      setToast("List too large for QR code");
      setTimeout(() => setToast(null), 2200);
      return;
    }
    setQrUrl(`${BASE_URL}#import=${encoded}`);
    setShowQR(true);
  };

  // Import handlers
  const handleImportAdd = () => {
    if (!importData) return;
    // Give each item a unique id
    const withIds = importData.map(i => ({ ...i, id: Date.now() + Math.random() }));
    setItems(p => [...p, ...withIds]);
    setImportData(null);
    setToast(`Added ${withIds.length} items`);
    setTimeout(() => setToast(null), 2200);
  };
  const handleImportReplace = () => {
    if (!importData) return;
    const withIds = importData.map(i => ({ ...i, id: Date.now() + Math.random() }));
    setItems(withIds);
    setImportData(null);
    setToast(`Loaded ${withIds.length} items`);
    setTimeout(() => setToast(null), 2200);
  };
  const handleImportCancel = () => setImportData(null);

  const handleDragStart = id => setDragId(id);
  const handleDragOver = (e, id) => { e.preventDefault(); setDragOverId(id); };
  const handleDrop = tid => {
    if (dragId == null || dragId === tid) { setDragId(null); setDragOverId(null); return; }
    setItems(p => { const a = [...p], f = a.findIndex(i => i.id === dragId), t = a.findIndex(i => i.id === tid); if (f < 0 || t < 0) return p; const [m] = a.splice(f, 1); a.splice(t, 0, m); return a; });
    setDragId(null); setDragOverId(null);
  };
  const handleDragEnd = () => { setDragId(null); setDragOverId(null); };

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

      {showOnboarding && <Onboarding onDone={finishOnboarding} importData={importData} onImportAccept={(action) => {
        if (action === "add") handleImportAdd();
        else if (action === "replace") handleImportReplace();
      }} />}

      <div className="notepad-wrap" style={{ width: "100%", maxWidth: 520, minHeight: "100dvh", background: "var(--paper)", borderRadius: 0, boxShadow: "none", position: "relative", paddingLeft: 48, paddingRight: 16, paddingBottom: 18, overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 38, top: 0, bottom: 0, width: 2, background: "var(--margin)", zIndex: 1 }} />
        <div className="notepad-holes" style={{ position: "absolute", left: 0, top: 16, bottom: 16, width: 24, display: "flex", flexDirection: "column", justifyContent: "space-evenly", alignItems: "center", zIndex: 2 }}>
          {Array.from({ length: 18 }).map((_, i) => <div key={i} style={{ width: 10, height: 10, borderRadius: "50%", background: "var(--hole)", boxShadow: "var(--hole-shadow)", flexShrink: 0 }} />)}
        </div>

        <Header itemCount={items.length} filteredLeft={filteredLeft} viewMode={viewMode}
          onToggleView={() => setViewMode(viewMode === "list" ? "store" : "list")}
          onShare={() => setShowShareSheet(true)} />

        <InputBar input={input} onInputChange={setInput} onAddItem={addItem} onKeyDown={handleInputKeyDown}
          inputRef={inputRef} autoDetectedCat={autoDetectedCat} inputClean={inputClean}
          storeQuery={storeQuery} storeMatches={storeMatches} storeAutoIdx={storeAutoIdx}
          onSelectStore={selectStoreAutoComplete} />

        <div style={{ position: "relative" }}>
          {viewMode === "store" && items.length > 0 && storeGroups && (
            <StoreView storeGroups={storeGroups} allStores={allStores}
              justChecked={justChecked} onToggle={toggleCheck} onUpdateText={updateText}
              onItemKeyDown={handleItemKeyDown} onItemBlur={handleItemBlur} onRemove={removeItem}
              editStoreItemId={editStoreItemId} editStoreMatches={editStoreMatches}
              editStoreAutoIdx={editStoreAutoIdx} onEditStoreSelect={handleEditStoreSelect}
              onUpdateCategory={updateCategory} onUpdateStore={updateStore} />
          )}

          {viewMode === "list" && (
            <ListView itemCount={items.length} uncheckedItems={uncheckedItems} checkedItems={checkedItems}
              justChecked={justChecked} allStores={allStores}
              onToggle={toggleCheck} onUpdateText={updateText} onItemKeyDown={handleItemKeyDown}
              onItemBlur={handleItemBlur} onDragStart={handleDragStart} onDragOver={handleDragOver}
              onDrop={handleDrop} onDragEnd={handleDragEnd} onRemove={removeItem}
              onClearChecked={clearChecked}
              dragId={dragId} dragOverId={dragOverId}
              editStoreItemId={editStoreItemId} editStoreMatches={editStoreMatches}
              editStoreAutoIdx={editStoreAutoIdx} onEditStoreSelect={handleEditStoreSelect}
              onUpdateCategory={updateCategory} onUpdateStore={updateStore} />
          )}

          {viewMode === "store" && items.length === 0 && (
            <div style={{ textAlign: "center", padding: "36px 0", animation: "fadeIn .3s ease" }}>
              <span style={{ fontSize: 36, display: "block", marginBottom: 6 }}>📝</span>
              <p style={{ fontFamily: "'Patrick Hand', cursive", fontSize: 24, color: "var(--ink-muted)", fontWeight: 600 }}>Start adding items</p>
              <p style={{ fontSize: 13, color: "var(--ink-faint)", marginTop: 4, fontStyle: "italic" }}>Select a store, then add items</p>
            </div>
          )}
        </div>
      </div>

      {showShareSheet && (
        <ShareSheet onCopyText={shareAsText} onShareLink={shareAsLink} onShowQR={shareAsQR} onClose={() => setShowShareSheet(false)} />
      )}

      {showQR && <QRModal url={qrUrl} onClose={() => setShowQR(false)} />}

      {importData && !showOnboarding && (
        <ImportModal itemCount={importData.length} onAdd={handleImportAdd} onReplace={handleImportReplace} onCancel={handleImportCancel} />
      )}

      <Toast toast={toast} undoItem={undoItem} onUndo={handleUndo} />
    </div>
  );
}
