import { useRef, useEffect, useCallback } from "react";

export default function ContentEditable({ value, onChange, onKeyDown, onBlur, innerRef, placeholder, className, style, spellCheck }) {
  const elRef = useRef(null);

  useEffect(() => {
    if (!innerRef) return;
    if (typeof innerRef === "function") innerRef(elRef.current);
    else innerRef.current = elRef.current;
  });

  const handleChange = useCallback((e) => {
    onChange(e.target.value);
  }, [onChange]);

  const handleKeyDown = useCallback((e) => {
    if (e.key === "Enter") e.preventDefault();
    if (onKeyDown) onKeyDown(e);
  }, [onKeyDown]);

  const handlePaste = useCallback((e) => {
    const text = (e.clipboardData || window.clipboardData).getData("text/plain");
    if (text.includes("\n") || text.includes("\r")) {
      e.preventDefault();
      const clean = text.replace(/[\n\r]/g, " ");
      const input = e.target;
      const start = input.selectionStart;
      const end = input.selectionEnd;
      const newValue = input.value.slice(0, start) + clean + input.value.slice(end);
      onChange(newValue);
      requestAnimationFrame(() => {
        input.selectionStart = input.selectionEnd = start + clean.length;
      });
    }
  }, [onChange]);

  return (
    <input
      ref={elRef}
      type="text"
      value={value}
      onChange={handleChange}
      onKeyDown={handleKeyDown}
      onPaste={handlePaste}
      onBlur={onBlur}
      placeholder={placeholder}
      className={className}
      style={style}
      spellCheck={spellCheck}
    />
  );
}
