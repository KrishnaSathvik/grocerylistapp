#!/usr/bin/env python3
"""Process raw product PNGs: rembg, center on 1024 canvas, write to Assets.xcassets."""
from __future__ import annotations

import io
import json
import sys
from pathlib import Path

from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "GroceryList" / "Assets.xcassets"
SOURCES = Path(__file__).resolve().parent.parent.parent / ".product-sources"
CANVAS = 1024
TARGET_FILL = 0.88
TALL_CH_CW_THRESHOLD = 1.95
TALL_WIDTH_FILL = 0.58

CONTENTS_JSON = """{
  "images" : [
    {
      "filename" : "{filename}",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""


def uses_width_zoom(cw: int, ch: int) -> bool:
    return ch > 0 and cw > 0 and ch / cw > TALL_CH_CW_THRESHOLD


def process_image(raw: bytes) -> Image.Image:
    cutout = remove(raw)
    img = Image.open(io.BytesIO(cutout)).convert("RGBA")
    bbox = img.getbbox()
    if not bbox:
        raise RuntimeError("no visible pixels after background removal")
    cropped = img.crop(bbox)
    cw, ch = cropped.size

    if uses_width_zoom(cw, ch):
        scale = (CANVAS * TALL_WIDTH_FILL) / cw
        nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
        resized = cropped.resize((nw, nh), Image.LANCZOS)
        layer = Image.new("RGBA", (max(CANVAS, nw), max(CANVAS, nh)), (0, 0, 0, 0))
        ox = (layer.width - nw) // 2
        oy = (layer.height - nh) // 2
        layer.paste(resized, (ox, oy), resized)
        cx = (layer.width - CANVAS) // 2
        cy = (layer.height - CANVAS) // 2
        return layer.crop((cx, cy, cx + CANVAS, cy + CANVAS))

    scale = min(CANVAS * TARGET_FILL / cw, CANVAS * TARGET_FILL / ch)
    nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
    resized = cropped.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(resized, ((CANVAS - nw) // 2, (CANVAS - nh) // 2), resized)
    return canvas


def write_imageset(product_id: str, image: Image.Image) -> None:
    asset_name = f"product-{product_id}"
    imageset = ASSETS / f"{asset_name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    filename = f"{asset_name}.png"
    image.save(imageset / filename, "PNG")
    (imageset / "Contents.json").write_text(
        CONTENTS_JSON.replace("{filename}", filename),
        encoding="utf-8",
    )


def main() -> None:
    if not SOURCES.exists():
        raise SystemExit(f"Missing source folder: {SOURCES}")

    sources = sorted(SOURCES.glob("*.png"))
    if not sources:
        raise SystemExit(f"No PNG files in {SOURCES}")

    ok: list[str] = []
    for src in sources:
        product_id = src.stem.removeprefix("product-")
        try:
            processed = process_image(src.read_bytes())
            write_imageset(product_id, processed)
            ok.append(product_id)
            print(f"OK product-{product_id}")
        except Exception as error:  # noqa: BLE001
            print(f"FAIL product-{product_id}: {error}", file=sys.stderr)

    if len(ok) != len(sources):
        raise SystemExit(1)
    print(f"\nProcessed {len(ok)} product assets.")


if __name__ == "__main__":
    main()
