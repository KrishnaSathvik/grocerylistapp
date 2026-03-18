export const notepadStyles = `
  /* ═══ LIGHT THEME (default) ═══ */
  :root {
    --bg: linear-gradient(155deg, #ddd6ca 0%, #cfc7b8 50%, #c4baa8 100%);
    --paper: #faf8f4;
    --ink: #3a3429;
    --ink-soft: #7a6c5d;
    --ink-muted: #a89e90;
    --ink-faint: #b8b0a2;
    --line: #e4ddd3;
    --line-dash: #d4cec4;
    --margin: rgba(230,164,160,0.4);
    --hole: linear-gradient(135deg, #cfc7b8, #ddd6ca);
    --hole-shadow: inset 0 1px 2px rgba(0,0,0,.12);
    --shadow: 0 1px 3px rgba(0,0,0,.05), 0 8px 32px rgba(0,0,0,.10), 0 0 0 1px rgba(0,0,0,.03);
    --badge-bg: #3a3429;
    --badge-fg: #faf8f4;
    --border-btn: #d4cec4;
    --check-unchecked: #c4b8a8;
    --checked-text: #b0a89a;
    --strike: #b0a89a;
    --drag: #c4b8a8;
    --curl1: #e8e0d4;
    --curl2: #d6cdbf;
    --toast-bg: #3a3429;
    --toast-fg: #faf8f4;
    --focus-bg: rgba(74,124,89,0.035);
    --caret: #a63d40;
    --noise-opacity: 0.03;
  }

  /* ═══ DARK THEME ═══ */
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: linear-gradient(155deg, #0f1114 0%, #0c0e11 50%, #090a0d 100%);
      --paper: #1a1d23;
      --ink: #f0ede8;
      --ink-soft: #b8b0a4;
      --ink-muted: #908880;
      --ink-faint: #6a6258;
      --line: rgba(255,255,255,.08);
      --line-dash: rgba(255,255,255,.1);
      --margin: rgba(220,120,110,0.35);
      --hole: linear-gradient(135deg, #12141a, #0e1016);
      --hole-shadow: inset 0 1px 3px rgba(0,0,0,.7), inset 0 0 1px rgba(0,0,0,.4);
      --shadow: 0 2px 8px rgba(0,0,0,.4), 0 12px 40px rgba(0,0,0,.6), 0 0 0 1px rgba(255,255,255,.05);
      --badge-bg: rgba(255,255,255,.15);
      --badge-fg: #f0ede8;
      --border-btn: rgba(255,255,255,.18);
      --check-unchecked: #50505a;
      --checked-text: #706860;
      --strike: #706860;
      --drag: #50505a;
      --curl1: #252830;
      --curl2: #14161c;
      --toast-bg: #2a2d35;
      --toast-fg: #f0ede8;
      --focus-bg: rgba(74,124,89,0.15);
      --caret: #e88;
      --noise-opacity: 0.02;
    }
  }

  *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
  html,body{overflow-x:hidden;width:100%;-webkit-text-size-adjust:100%;-webkit-tap-highlight-color:transparent}
  body{overscroll-behavior-y:none}
  input,textarea,select,button{font-size:16px}
  input::placeholder{color:var(--ink-faint);font-style:italic}
  ::-webkit-scrollbar{width:5px}
  ::-webkit-scrollbar-thumb{background:var(--line-dash);border-radius:3px}

  /* Prevent iOS zoom on input focus — inputs must be >= 16px */
  @supports (-webkit-touch-callout: none) {
    input{font-size:max(16px, 21px)!important}
  }

  /* Desktop: restore notepad look */
  @media (min-width: 540px) {
    .notepad-outer { padding: 20px 8px 40px !important; }
    .notepad-wrap { border-radius: 2px !important; box-shadow: var(--shadow) !important; min-height: auto !important; }
  }
  /* Mobile: full width, comfortable padding */
  @media (max-width: 520px) {
    .notepad-wrap { padding-left: 44px !important; padding-right: 18px !important; }
  }
  @media (max-width: 380px) {
    .notepad-wrap { padding-left: 40px !important; padding-right: 14px !important; }
    .g-edit { font-size: 20px !important; }
  }
  @media (max-width: 320px) {
    .notepad-wrap { padding-left: 36px !important; padding-right: 10px !important; }
    .g-edit { font-size: 18px !important; }
  }

  @keyframes slideIn{from{opacity:0;transform:translateX(-8px)}to{opacity:1;transform:translateX(0)}}
  @keyframes fadeIn{from{opacity:0}to{opacity:1}}
  @keyframes drawCheck{from{stroke-dashoffset:20}to{stroke-dashoffset:0}}
  .check-draw{stroke-dasharray:20;stroke-dashoffset:20;animation:drawCheck .4s ease-out .05s forwards}
  @keyframes strikeAnim{from{width:0}to{width:100%}}
  .strike-anim::after{content:'';position:absolute;left:0;top:50%;height:1.5px;background:var(--strike);width:0;animation:strikeAnim .35s ease-out .15s forwards;transform:rotate(-0.5deg)}
  @keyframes toastIn{from{opacity:0;transform:translate(-50%,20px)}to{opacity:1;transform:translate(-50%,0)}}
  @keyframes sheetUp{from{transform:translateY(100%)}to{transform:translateY(0)}}

  .g-add:hover:not(:disabled){background:var(--ink)!important;color:var(--paper)!important;border-color:var(--ink)!important}
  .g-cat-dot:hover{transform:scale(1.15)}
  .g-clear:hover{opacity:1!important}
  .g-chip:hover{transform:translateY(-1px)}
  .g-share:hover{background:var(--ink)!important;color:var(--paper)!important}

  .g-item.dragging{opacity:.4}
  .g-item.drag-over{border-top:2px solid #4a7c59;margin-top:-2px}
  .g-drag{cursor:grab;opacity:.25;transition:opacity .15s}
  .g-item:hover .g-drag{opacity:.6}
  .g-drag:active{cursor:grabbing}

  .g-edit{
    flex:1;border:none;outline:none;
    font-size:24px;font-family:'Patrick Hand',cursive;font-weight:500;
    color:var(--ink);background:transparent;padding:0;
    line-height:50px;height:50px;
    letter-spacing:.2px;caret-color:var(--caret);min-width:0;
    white-space:nowrap;overflow:hidden;
  }
  .g-edit:focus{background:var(--focus-bg);border-radius:3px;padding:0 4px;margin:0 -4px}
  .g-edit.done{color:var(--checked-text)}

  /* Desktop delete button — visible on hover */
  .g-delete-btn{display:none!important}
  @media(min-width:768px){
    .g-item:hover .g-delete-btn{display:flex!important}
    .g-delete-btn:hover{color:#a63d40!important;background:rgba(166,61,64,.08)!important}
  }

  /* Checkbox hover on desktop */
  @media(min-width:768px){
    .g-check{transition:all .15s}
    button:hover .g-check:not([style*="background-color: transparent"]){filter:brightness(1.1)}
    button:hover .g-check{box-shadow:0 0 0 2px rgba(0,0,0,.06)}
  }

  /* Store name: hidden on mobile, shown on desktop only */
  .g-store-name{display:none!important}
  @media(min-width:768px){
    .g-store-name{display:inline!important}
  }

  /* Desktop: tighter item sizing */
  @media(min-width:768px){
    .g-edit{font-size:18px!important;line-height:42px!important;height:42px!important}
    .g-item-emoji{font-size:16px!important}
  }

  .notepad-wrap::after{
    content:'';position:absolute;bottom:0;right:0;width:40px;height:40px;
    background:linear-gradient(135deg,transparent 50%,var(--curl1) 50%,var(--curl2) 100%);
    box-shadow:-2px -2px 5px rgba(0,0,0,.05);border-top-left-radius:4px;
    transition:all .3s ease;z-index:5;
  }
  .notepad-wrap:hover::after{width:55px;height:55px}
  .notepad-wrap::before{
    content:'';position:absolute;inset:0;
    background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E");
    background-size:200px 200px;pointer-events:none;z-index:0;border-radius:2px;opacity:var(--noise-opacity);
  }
  @keyframes catPulse{0%{box-shadow:0 0 0 0 rgba(74,124,89,.4)}70%{box-shadow:0 0 0 8px rgba(74,124,89,0)}100%{box-shadow:0 0 0 0 rgba(74,124,89,0)}}
  .cat-detected{animation:catPulse .6s ease-out}

  /* Onboarding */
  .ob-backdrop{}
  .ob-backdrop.ob-exit{animation:obFadeOut .35s ease forwards}
  @keyframes obFadeOut{to{opacity:0;transform:scale(1.02)}}
  .ob-page{animation:obSlideIn .35s ease}
  @keyframes obSlideIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}

  /* Onboarding card — mobile-first (full screen) */
  .ob-card{
    width:100%;height:100dvh;
    background:var(--paper);
    padding:36px 16px 36px 48px;
    border-radius:0;box-shadow:none;
  }
  .ob-logo{width:80px;height:80px;border-radius:16px;margin-bottom:12px;object-fit:contain}
  .ob-emoji{font-size:52px;margin-bottom:10px;line-height:1}
  .ob-title{
    font-family:'Patrick Hand',cursive;font-size:34px;font-weight:700;
    color:var(--ink);margin-bottom:18px;line-height:1.1;
  }
  .ob-line{
    font-family:'Patrick Hand',cursive;font-size:22px;font-weight:500;
    color:var(--ink-soft);line-height:1.3;
  }
  .ob-btn:active{transform:scale(.96)}

  /* Onboarding — small phones */
  @media(max-width:380px){
    .ob-card{padding-left:42px;padding-right:12px}
    .ob-emoji{font-size:44px}
    .ob-title{font-size:30px}
    .ob-line{font-size:20px}
  }
  @media(max-width:320px){
    .ob-card{padding-left:38px;padding-right:10px}
    .ob-title{font-size:28px}
    .ob-line{font-size:18px}
  }

  /* Onboarding — tablet / desktop: centered card */
  @media(min-width:540px){
    .ob-backdrop{padding:20px 8px 40px}
    .ob-card{
      width:100%;max-width:480px;height:auto;min-height:460px;
      border-radius:6px;box-shadow:var(--shadow);
      padding:56px 32px 40px 56px;
    }
    .ob-logo{width:96px;height:96px;border-radius:20px}
    .ob-emoji{font-size:60px;margin-bottom:12px}
    .ob-title{font-size:40px;margin-bottom:20px}
    .ob-line{font-size:24px}
  }

  /* Onboarding — large desktop */
  @media(min-width:768px){
    .ob-card{max-width:520px;min-height:500px;padding:64px 40px 48px 64px}
    .ob-logo{width:108px;height:108px;border-radius:22px}
    .ob-emoji{font-size:64px}
    .ob-title{font-size:44px}
    .ob-line{font-size:26px}
  }
`;
