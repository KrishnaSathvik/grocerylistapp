#!/usr/bin/env python3
"""Normalize bundled category and product PNGs to consistent visible fill (matches store logos)."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "GroceryList" / "Assets.xcassets"
CANVAS = 1024
TARGET_FILL = 0.88

# Tall bottles/cartons: scale to badge width and center-crop (reads larger in square thumbnails).
TALL_CH_CW_THRESHOLD = 1.95
TALL_WIDTH_FILL = 0.58
TALL_WIDTH_FILL_EXTRA = 0.65  # spaghetti bundles and very narrow cartons
TALL_EXTRA_THRESHOLD = 3.5

MIN_FILL_CATEGORY = 0.50
MIN_FILL_PRODUCT = 0.35


def visible_fill(img: Image.Image) -> float:
    bbox = img.getbbox()
    if not bbox:
        return 0.0
    bw, bh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    w, h = img.size
    return (bw * bh) / (w * h)


def is_width_zoomed_product(cw: int, ch: int) -> bool:
    """Tall products already scaled to badge width — do not re-normalize."""
    if ch <= 0 or cw <= 0:
        return False
    return (
        ch >= CANVAS * 0.98
        and cw / CANVAS >= TALL_WIDTH_FILL * 0.85
        and ch / cw < TALL_CH_CW_THRESHOLD
    )


def uses_width_zoom(cw: int, ch: int) -> bool:
    if ch <= 0 or cw <= 0:
        return False
    return ch / cw > TALL_CH_CW_THRESHOLD


def width_fill_for(cw: int, ch: int) -> float:
    if ch / cw > TALL_EXTRA_THRESHOLD:
        return TALL_WIDTH_FILL_EXTRA
    return TALL_WIDTH_FILL


def normalize_standard(cropped: Image.Image) -> Image.Image:
    cw, ch = cropped.size
    scale = min(CANVAS * TARGET_FILL / cw, CANVAS * TARGET_FILL / ch)
    nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
    resized = cropped.resize((nw, nh), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ox = (CANVAS - nw) // 2
    oy = (CANVAS - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def normalize_width_zoom(cropped: Image.Image) -> Image.Image:
    cw, ch = cropped.size
    width_fill = width_fill_for(cw, ch)
    scale = (CANVAS * width_fill) / cw
    nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
    resized = cropped.resize((nw, nh), Image.LANCZOS)

    layer = Image.new("RGBA", (max(CANVAS, nw), max(CANVAS, nh)), (0, 0, 0, 0))
    ox = (layer.width - nw) // 2
    oy = (layer.height - nh) // 2
    layer.paste(resized, (ox, oy), resized)

    cx = (layer.width - CANVAS) // 2
    cy = (layer.height - CANVAS) // 2
    return layer.crop((cx, cy, cx + CANVAS, cy + CANVAS))


def normalize_png(path: Path) -> dict:
    img = Image.open(path).convert("RGBA")
    before = visible_fill(img)
    bbox = img.getbbox()
    if not bbox:
        raise RuntimeError(f"No visible content in {path.name}")

    cropped = img.crop(bbox)
    cw, ch = cropped.size

    if is_width_zoomed_product(cw, ch):
        return {"before": round(before, 3), "after": round(before, 3), "mode": "width-zoom-skip"}

    if uses_width_zoom(cw, ch):
        canvas = normalize_width_zoom(cropped)
        mode = "width-zoom"
    else:
        canvas = normalize_standard(cropped)
        mode = "standard"

    canvas.save(path, "PNG")
    after = visible_fill(Image.open(path))
    return {"before": round(before, 3), "after": round(after, 3), "mode": mode}


def collect_imagesets(prefix: str) -> list[Path]:
    return sorted(ASSETS.glob(f"{prefix}-*.imageset"))


def normalize_set(imagesets: list[Path], min_fill: float) -> list[str]:
    failures: list[str] = []
    for imageset in imagesets:
        pngs = sorted(imageset.glob("*.png"))
        if not pngs:
            print(f"SKIP {imageset.name}: no PNG")
            continue
        info = normalize_png(pngs[0])
        status = "OK" if info["after"] >= min_fill else "LOW"
        print(f"{status} {imageset.name} [{info['mode']}]: {info['before']} -> {info['after']}")
        if info["after"] < min_fill:
            failures.append(imageset.name)
    return failures


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--only",
        choices=("all", "category", "product"),
        default="all",
        help="Which asset groups to normalize",
    )
    args = parser.parse_args()

    failures: list[str] = []

    if args.only in ("all", "category"):
        categories = collect_imagesets("category")
        if not categories:
            raise SystemExit("No category imagesets found")
        print(f"Normalizing {len(categories)} category assets (target fill {TARGET_FILL})...")
        failures.extend(normalize_set(categories, MIN_FILL_CATEGORY))

    if args.only in ("all", "product"):
        products = collect_imagesets("product")
        if not products:
            raise SystemExit("No product imagesets found")
        print(f"\nNormalizing {len(products)} product assets...")
        failures.extend(normalize_set(products, MIN_FILL_PRODUCT))

    if failures:
        print(f"\nWarning: {len(failures)} asset(s) below minimum fill threshold:")
        for name in failures:
            print(f"  - {name}")
        raise SystemExit(1)

    print("\nAll assets normalized successfully.")


if __name__ == "__main__":
    main()
