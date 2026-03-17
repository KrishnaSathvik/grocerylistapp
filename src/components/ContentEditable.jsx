import { useRef, useEffect, useCallback } from "react";

function setCursorToEnd(el) {
  const sel = window.getSelection();
  const range = document.createRange();
  range.selectNodeContents(el);
  range.collapse(false);
  sel.removeAllRanges();
  sel.addRange(range);
}

export default function ContentEditable({ value, onChange, onKeyDown, onBlur, innerRef, placeholder, className, style, spellCheck }) {
  const elRef = useRef(null);

  useEffect(() => {
    if (!innerRef) return;
    if (typeof innerRef === "function") innerRef(elRef.current);
    else innerRef.current = elRef.current;
  });

  useEffect(() => {
    const el = elRef.current;
    if (!el || el.textContent === value) return;
    el.textContent = value;
    if (document.activeElement === el) setCursorToEnd(el);
  }, [value]);

  const handleInput = useCallback((e) => {
    const el = e.currentTarget;
    const text = el.textContent || "";
    if (!text && el.firstChild) el.textContent = "";
    onChange(text);
  }, [onChange]);

  const handlePaste = useCallback((e) => {
    e.preventDefault();
    const text = (e.clipboardData || window.clipboardData).getData("text/plain").replace(/[\n\r]/g, " ");
    document.execCommand("insertText", false, text);
  }, []);

  const handleKeyDown = useCallback((e) => {
    if (e.key === "Enter") e.preventDefault();
    if (onKeyDown) onKeyDown(e);
  }, [onKeyDown]);

  return (
    <div
      ref={elRef}
      contentEditable="plaintext-only"
      role="textbox"
      onInput={handleInput}
      onKeyDown={handleKeyDown}
      onPaste={handlePaste}
      onBlur={onBlur}
      data-placeholder={placeholder}
      className={className}
      style={style}
      spellCheck={spellCheck}
      suppressContentEditableWarning
    />
  );
}
