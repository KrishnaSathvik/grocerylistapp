#!/usr/bin/env python3
"""Install staged product PNGs into Assets.xcassets with rembg cutout + normalize.

Usage:
  python3 scripts/install-generated-product-assets.py \\
    --src /path/to/staged \\
    --only milk-coconut,ghee

Staged files may be named:
  product-<id>.png  OR  <id>.png
"""
from __future__ import annotations

import argparse
import io
import json
import sys
from pathlib import Path

from PIL import Image

try:
    from rembg import remove
except ImportError:
    remove = None  # type: ignore

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "GroceryListiOS" / "GroceryList" / "Assets.xcassets"
CANVAS = 1024
TARGET_FILL = 0.88

CONTENTS = {
    "images": [
        {"idiom": "universal", "scale": "1x", "filename": None},
        {"idiom": "universal", "scale": "2x"},
        {"idiom": "universal", "scale": "3x"},
    ],
    "info": {"author": "xcode", "version": 1},
}


def normalize(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    bbox = img.getbbox()
    if not bbox:
        raise RuntimeError("No visible content after cutout")
    cropped = img.crop(bbox)
    cw, ch = cropped.size
    scale = min(CANVAS * TARGET_FILL / cw, CANVAS * TARGET_FILL / ch)
    nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(resized, ((CANVAS - nw) // 2, (CANVAS - nh) // 2), resized)
    return canvas


def process(src: Path) -> Image.Image:
    raw = src.read_bytes()
    img = Image.open(io.BytesIO(raw)).convert("RGBA")
    # Already transparent enough?
    corners = [img.getpixel(p) for p in [(0, 0), (img.width - 1, 0), (0, img.height - 1), (img.width - 1, img.height - 1)]]
    if all(c[3] < 16 for c in corners):
        return normalize(img)
    if remove is None:
        raise RuntimeError("rembg is required to cut out opaque backgrounds; pip install rembg")
    cut = remove(raw)
    return normalize(Image.open(io.BytesIO(cut)).convert("RGBA"))


def install(product_id: str, src: Path, backup: bool) -> None:
    asset = f"product-{product_id}"
    folder = ASSETS / f"{asset}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    dst = folder / f"{asset}.png"
    if dst.exists() and backup:
        bak = folder / f"{asset}.png.bak"
        bak.write_bytes(dst.read_bytes())
    img = process(src)
    img.save(dst, "PNG")
    contents = json.loads(json.dumps(CONTENTS))
    contents["images"][0]["filename"] = f"{asset}.png"
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")
    print(f"OK {asset} from {src.name} fill≈{((img.getbbox()[2]-img.getbbox()[0])*(img.getbbox()[3]-img.getbbox()[1]))/(CANVAS*CANVAS):.2f}")


def find_src(src_dir: Path, product_id: str) -> Path | None:
    for name in (f"product-{product_id}.png", f"{product_id}.png"):
        path = src_dir / name
        if path.exists():
            return path
    # fuzzy: any file containing the id
    matches = sorted(src_dir.glob(f"*{product_id}*.png"))
    return matches[0] if matches else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", type=Path, required=True)
    parser.add_argument("--only", type=str, default="")
    parser.add_argument("--backup", action="store_true", default=True)
    args = parser.parse_args()
    if not args.src.is_dir():
        print(f"Source dir missing: {args.src}", file=sys.stderr)
        return 1

    if args.only:
        ids = [x.strip() for x in args.only.split(",") if x.strip()]
    else:
        ids = []
        for path in sorted(args.src.glob("*.png")):
            stem = path.stem
            ids.append(stem.removeprefix("product-"))

    failed = 0
    for product_id in ids:
        src = find_src(args.src, product_id)
        if src is None:
            print(f"MISSING source for {product_id}", file=sys.stderr)
            failed += 1
            continue
        try:
            install(product_id, src, backup=args.backup)
        except Exception as exc:  # noqa: BLE001
            print(f"FAIL {product_id}: {exc}", file=sys.stderr)
            failed += 1
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
