import { UncheckedItem, CheckedItem } from "./GroceryItem";

const LINE_H = 50;

export default function ListView({ itemCount, pageUnchecked, pageChecked, blankLines, page, justChecked, allStores, onToggle, onUpdateText, onItemKeyDown, onItemBlur, onDragStart, onDragOver, onDrop, onDragEnd, onRemove, onClearChecked, onBlankTouchStart, onBlankTouchEnd, dragId, dragOverId, pageAnimClass }) {
  return (
    <div key={page} className={pageAnimClass} style={{ transformOrigin: "center center", position: "relative", zIndex: 1 }}>
      {itemCount === 0 && (
        <div style={{ textAlign: "center", padding: "36px 0", animation: "fadeIn .3s ease" }}>
          <span style={{ fontSize: 36, display: "block", marginBottom: 6 }}>📝</span>
          <p style={{ fontFamily: "'Caveat', cursive", fontSize: 24, color: "var(--ink-muted)", fontWeight: 600 }}>Start adding items</p>
          <p style={{ fontSize: 13, color: "var(--ink-faint)", marginTop: 4, fontStyle: "italic" }}>Try "2 milk" or "3 bananas" for quantities</p>
          <p style={{ fontSize: 13, color: "var(--ink-faint)", marginTop: 4, fontStyle: "italic" }}>Categories auto-detect · swipe left to delete</p>
        </div>
      )}

      {pageUnchecked.map(item => (
        <UncheckedItem key={item.id} item={item} allStores={allStores} onToggle={onToggle} onUpdateText={onUpdateText} onKeyDown={onItemKeyDown} onBlur={onItemBlur} onDragStart={onDragStart} onDragOver={onDragOver} onDrop={onDrop} onDragEnd={onDragEnd} onDelete={onRemove} dragId={dragId} dragOverId={dragOverId} />
      ))}

      {pageChecked.length > 0 && (
        <>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", height: LINE_H, borderBottom: "1px dashed var(--line-dash)" }}>
            <span style={{ fontSize: 12, color: "var(--ink-faint)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "1.2px" }}>picked up</span>
            {page === 0 && <button className="g-clear" onClick={onClearChecked} style={{ fontSize: 11, color: "#a63d40", background: "transparent", border: "none", cursor: "pointer", fontFamily: "'DM Sans', sans-serif", fontWeight: 600, opacity: .6, transition: "opacity .15s" }}>clear</button>}
          </div>
          {pageChecked.map(item => (
            <CheckedItem key={item.id} item={item} allStores={allStores} justChecked={justChecked} onToggle={onToggle} onUpdateText={onUpdateText} onKeyDown={onItemKeyDown} onBlur={onItemBlur} onDelete={onRemove} />
          ))}
        </>
      )}

      {Array.from({ length: blankLines }).map((_, i) => (
        <div key={`b${i}`} style={{ height: LINE_H, borderBottom: "1px solid var(--line)" }} onTouchStart={onBlankTouchStart} onTouchEnd={onBlankTouchEnd} />
      ))}
    </div>
  );
}
