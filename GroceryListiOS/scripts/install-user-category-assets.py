#!/usr/bin/env python3
"""Install user-provided category PNGs into Assets.xcassets."""
from __future__ import annotations

import io
import shutil
from pathlib import Path

from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "GroceryList" / "Assets.xcassets"
SRC = Path(
    "/Users/krishnasathvikmantripragada/.cursor/projects/"
    "Users-krishnasathvikmantripragada-grocery-list-app/assets"
)

MAPPING = {
    "category-drinks": "ChatGPT_Image_Jun_29__2026__12_17_51_AM__1_-11ba135b-1604-4822-abeb-3568586f45e6.png",
    "category-dairy": "ChatGPT_Image_Jun_29__2026__12_17_51_AM__2_-24b0c9b1-0dea-4e04-86bf-bb2b4a123e10.png",
    "category-frozen": "ChatGPT_Image_Jun_29__2026__12_17_51_AM__3_-4aafc1b1-b5b5-4006-be5e-11c8a8514d99.png",
    "category-snacks": "ChatGPT_Image_Jun_29__2026__12_17_51_AM__4_-64063b8e-75f9-470c-9926-c9003e9504d7.png",
    "category-pantry": "ChatGPT_Image_Jun_29__2026__12_17_52_AM__5_-3c6b7440-91c4-4169-98b1-99f6597f3b6e.png",
    "category-misc": "ChatGPT_Image_Jun_29__2026__12_17_52_AM__6_-46e28932-2ef0-42e9-a03d-41b448a79489.png",
}

CANVAS = 1024
TARGET_FILL = 0.72


def strip_and_center(src: Path, dst: Path) -> dict:
    cutout = remove(src.read_bytes())
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

    out = Image.open(dst)
    corners = [out.getpixel(p) for p in [(0, 0), (CANVAS - 1, 0), (0, CANVAS - 1), (CANVAS - 1, CANVAS - 1)]]
    return {
        "size": out.size,
        "mode": out.mode,
        "corner_alpha": round(sum(c[3] for c in corners) / 4, 1),
        "fill_ratio": round((nw * nh) / (CANVAS * CANVAS), 3),
    }


def main() -> None:
    archive = SRC / "user-categories-source"
    archive.mkdir(exist_ok=True)
    for name, filename in MAPPING.items():
        src = SRC / filename
        if not src.exists():
            raise SystemExit(f"Missing source: {src}")
        shutil.copy2(src, archive / f"{name}-source.png")
        dst = ASSETS / f"{name}.imageset" / f"{name}.png"
        info = strip_and_center(src, dst)
        print(f"OK {name}: {info}")


if __name__ == "__main__":
    main()
