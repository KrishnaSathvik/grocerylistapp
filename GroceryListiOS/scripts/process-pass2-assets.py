#!/usr/bin/env python3
"""Post-process Pass 2 generated assets: remove bg, center, 1024x1024 RGBA."""
from __future__ import annotations

import io
import sys
from pathlib import Path

from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "GroceryList" / "Assets.xcassets"
SRC = Path(
    "/Users/krishnasathvikmantripragada/.cursor/projects/"
    "Users-krishnasathvikmantripragada-grocery-list-app/assets"
)

PASS2 = [
    "product-eggs-white",
    "product-milk-whole",
    "product-yogurt",
    "product-gochujang",
    "product-dog-food",
]

CANVAS = 1024
TARGET_FILL = 0.68  # subject fills ~68% of canvas


def strip_and_center(src: Path, dst: Path) -> dict:
    raw = src.read_bytes()
    cutout = remove(raw)
    img = Image.open(io.BytesIO(cutout)).convert("RGBA")

    bbox = img.getbbox()
    if not bbox:
        raise RuntimeError(f"No visible content in {src.name}")

    cropped = img.crop(bbox)
    cw, ch = cropped.size
    scale = min(CANVAS * TARGET_FILL / cw, CANVAS * TARGET_FILL / ch)
    nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
    resized = cropped.resize((nw, nh), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ox = (CANVAS - nw) // 2
    oy = (CANVAS - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    canvas.save(dst, "PNG")

    # validate
    out = Image.open(dst)
    corners = [out.getpixel(p) for p in [(0, 0), (CANVAS - 1, 0), (0, CANVAS - 1), (CANVAS - 1, CANVAS - 1)]]
    corner_alpha = sum(c[3] for c in corners) / 4
    has_checker = any(
        abs(r - g) < 8 and abs(g - b) < 8 and 180 < r < 245 and a > 200
        for r, g, b, a in corners
    )

    return {
        "size": out.size,
        "mode": out.mode,
        "corner_alpha": round(corner_alpha, 1),
        "has_checkerboard_corners": has_checker,
        "fill_ratio": round((nw * nh) / (CANVAS * CANVAS), 3),
    }


def main() -> None:
    results = []
    for name in PASS2:
        src = SRC / f"pass2-{name}.png"
        if not src.exists():
            print(f"MISSING source: {src}", file=sys.stderr)
            sys.exit(1)
        dst = ASSETS / f"{name}.imageset" / f"{name}.png"
        info = strip_and_center(src, dst)
        info["name"] = name
        results.append(info)
        status = "OK" if info["corner_alpha"] < 32 and not info["has_checkerboard_corners"] else "WARN"
        print(f"{status} {name}: {info}")

    failed = [r for r in results if r["corner_alpha"] >= 32 or r["has_checkerboard_corners"]]
    if failed:
        print("\nTransparency validation warnings:", failed, file=sys.stderr)
        sys.exit(1)
    print(f"\nProcessed {len(results)} assets successfully.")


if __name__ == "__main__":
    main()
