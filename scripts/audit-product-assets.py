#!/usr/bin/env python3
"""Audit bundled product assets against product_catalog.json.

Run from repo root:
  python3 scripts/audit-product-assets.py

Writes:
  GroceryListiOS/PRODUCT_ASSET_AUDIT.md
  GroceryListiOS/DesignReferences/asset-audit/contact-sheet-44pt.png
  GroceryListiOS/DesignReferences/asset-audit/contact-sheet-56pt.png
"""
from __future__ import annotations

import hashlib
import json
import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
IOS = ROOT / "GroceryListiOS"
ASSETS = IOS / "GroceryList" / "Assets.xcassets"
CATALOG = IOS / "GroceryList" / "Resources" / "product_catalog.json"
REPORT = IOS / "PRODUCT_ASSET_AUDIT.md"
CONTACT_DIR = IOS / "DesignReferences" / "asset-audit"

MIN_FILL = 0.35
# 16×16 aHash + tight hamming keeps style-similar grocery art from flooding the report.
NEAR_DUP_HAMMING = 8
BLANK_ALPHA_RATIO = 0.995


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def average_hash(img: Image.Image, size: int = 16) -> int:
    gray = img.convert("L").resize((size, size), Image.Resampling.LANCZOS)
    pixels = list(gray.getdata())
    avg = sum(pixels) / len(pixels)
    bits = 0
    for i, px in enumerate(pixels):
        if px >= avg:
            bits |= 1 << i
    return bits


def hamming(a: int, b: int) -> int:
    return (a ^ b).bit_count()


def visible_fill(img: Image.Image) -> float:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    bbox = img.getbbox()
    if not bbox:
        return 0.0
    bw = bbox[2] - bbox[0]
    bh = bbox[3] - bbox[1]
    w, h = img.size
    return (bw * bh) / (w * h)


def alpha_blank_ratio(img: Image.Image) -> float:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.getchannel("A")
    hist = alpha.histogram()
    transparent = sum(hist[:16])
    return transparent / max(1, (img.width * img.height))


def load_catalog() -> list[dict]:
    return json.loads(CATALOG.read_text(encoding="utf-8"))


def imageset_png(asset_name: str) -> Path | None:
    folder = ASSETS / f"{asset_name}.imageset"
    contents = folder / "Contents.json"
    if not contents.exists():
        return None
    data = json.loads(contents.read_text(encoding="utf-8"))
    for entry in data.get("images", []):
        filename = entry.get("filename")
        if filename:
            path = folder / filename
            return path if path.exists() else path
    # fallback convention
    candidate = folder / f"{asset_name}.png"
    return candidate if candidate.exists() else None


def build_contact_sheet(entries: list[tuple[str, Path]], cell: int, label: str, out: Path) -> None:
    if not entries:
        return
    cols = 8
    rows = (len(entries) + cols - 1) // cols
    pad = 8
    label_h = 18
    tile_w = cell + pad * 2
    tile_h = cell + label_h + pad * 2
    sheet = Image.new("RGBA", (cols * tile_w, rows * tile_h), (245, 245, 247, 255))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 10)
    except OSError:
        font = ImageFont.load_default()

    for idx, (product_id, path) in enumerate(entries):
        r, c = divmod(idx, cols)
        x0 = c * tile_w + pad
        y0 = r * tile_h + pad
        try:
            img = Image.open(path).convert("RGBA").resize((cell, cell), Image.Resampling.LANCZOS)
        except OSError:
            img = Image.new("RGBA", (cell, cell), (220, 220, 220, 255))
        sheet.paste(img, (x0, y0), img)
        draw.text((x0, y0 + cell + 2), product_id[:18], fill=(40, 40, 40, 255), font=font)

    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"Wrote {out.relative_to(ROOT)} ({label})")


def main() -> int:
    products = load_catalog()
    missing_imagesets: list[str] = []
    missing_pngs: list[str] = []
    bad_size: list[str] = []
    no_alpha: list[str] = []
    blankish: list[str] = []
    low_fill: list[tuple[str, float]] = []
    present: list[tuple[str, Path, str, int, float]] = []

    catalog_asset_names = {p["assetName"] for p in products}
    product_imagesets = sorted(
        d.name for d in ASSETS.iterdir() if d.is_dir() and d.name.startswith("product-") and d.name.endswith(".imageset")
    )
    orphan_imagesets = [
        name for name in product_imagesets if name.removesuffix(".imageset") not in catalog_asset_names
    ]

    for product in products:
        asset = product["assetName"]
        png = imageset_png(asset)
        if png is None:
            missing_imagesets.append(asset)
            continue
        if not png.exists():
            missing_pngs.append(asset)
            continue
        try:
            img = Image.open(png)
        except OSError:
            missing_pngs.append(asset)
            continue

        if img.size != (1024, 1024):
            bad_size.append(f"{asset} ({img.size[0]}x{img.size[1]})")
        if img.mode not in ("RGBA", "LA") and "A" not in img.getbands():
            no_alpha.append(asset)

        rgba = img.convert("RGBA")
        fill = visible_fill(rgba)
        blank = alpha_blank_ratio(rgba)
        if blank >= BLANK_ALPHA_RATIO:
            blankish.append(asset)
        if fill < MIN_FILL:
            low_fill.append((asset, fill))

        digest = sha256_file(png)
        ahash = average_hash(rgba)
        present.append((asset, png, digest, ahash, fill))

    by_hash: dict[str, list[str]] = defaultdict(list)
    for asset, _png, digest, _ahash, _fill in present:
        by_hash[digest].append(asset)
    exact_dupes = {h: ids for h, ids in by_hash.items() if len(ids) > 1}

    near_dupes: list[tuple[str, str, int]] = []
    for i in range(len(present)):
        for j in range(i + 1, len(present)):
            a_asset, _, _, a_hash, _ = present[i]
            b_asset, _, _, b_hash, _ = present[j]
            dist = hamming(a_hash, b_hash)
            if dist <= NEAR_DUP_HAMMING:
                near_dupes.append((a_asset, b_asset, dist))

    # Contact sheets for products that have PNGs
    sheet_entries = [(asset.removeprefix("product-"), path) for asset, path, *_ in present]
    build_contact_sheet(sheet_entries, cell=44, label="44pt", out=CONTACT_DIR / "contact-sheet-44pt.png")
    build_contact_sheet(sheet_entries, cell=56, label="56pt", out=CONTACT_DIR / "contact-sheet-56pt.png")

    lines = [
        "# Product asset audit",
        "",
        f"Generated from `{CATALOG.relative_to(ROOT)}` and `Assets.xcassets`.",
        "",
        "## Summary",
        "",
        f"| Metric | Count |",
        f"|---|---:|",
        f"| Canonical products | {len(products)} |",
        f"| Bundled product imagesets | {len(product_imagesets)} |",
        f"| Products with usable PNG | {len(present)} |",
        f"| Missing imagesets | {len(missing_imagesets)} |",
        f"| Missing PNG files | {len(missing_pngs)} |",
        f"| Orphan imagesets | {len(orphan_imagesets)} |",
        f"| Wrong dimensions | {len(bad_size)} |",
        f"| Missing alpha | {len(no_alpha)} |",
        f"| Nearly blank | {len(blankish)} |",
        f"| Low visual fill (< {MIN_FILL:.0%}) | {len(low_fill)} |",
        f"| Exact duplicate groups | {len(exact_dupes)} |",
        f"| Near-duplicate pairs (ahash ≤ {NEAR_DUP_HAMMING}) | {len(near_dupes)} |",
        "",
    ]

    def section(title: str, items: list[str]) -> None:
        lines.append(f"## {title}")
        lines.append("")
        if not items:
            lines.append("_None._")
        else:
            for item in items:
                lines.append(f"- `{item}`")
        lines.append("")

    section("Missing imagesets", missing_imagesets)
    section("Missing PNG files", missing_pngs)
    section("Orphan product imagesets", orphan_imagesets)
    section("Wrong dimensions (expected 1024×1024)", bad_size)
    section("Missing alpha channel", no_alpha)
    section("Nearly blank images", blankish)
    lines.append("## Low visual fill")
    lines.append("")
    if not low_fill:
        lines.append("_None._")
    else:
        for asset, fill in sorted(low_fill, key=lambda x: x[1]):
            lines.append(f"- `{asset}` — fill {fill:.1%}")
    lines.append("")

    lines.append("## Exact duplicate file content")
    lines.append("")
    if not exact_dupes:
        lines.append("_None._")
    else:
        for digest, assets in exact_dupes.items():
            lines.append(f"- `{digest[:12]}…`: {', '.join(f'`{a}`' for a in assets)}")
    lines.append("")

    lines.append("## Near-duplicate artwork")
    lines.append("")
    if not near_dupes:
        lines.append("_None._")
    else:
        for a, b, dist in sorted(near_dupes, key=lambda t: t[2]):
            lines.append(f"- `{a}` ≈ `{b}` (hamming {dist})")
    lines.append("")

    lines.append("## Contact sheets")
    lines.append("")
    lines.append("- `DesignReferences/asset-audit/contact-sheet-44pt.png`")
    lines.append("- `DesignReferences/asset-audit/contact-sheet-56pt.png`")
    lines.append("")

    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {REPORT.relative_to(ROOT)}")

    print("\n=== Console summary ===")
    print(f"products={len(products)} present={len(present)} missing={len(missing_imagesets)} orphans={len(orphan_imagesets)}")
    print(f"exact_dup_groups={len(exact_dupes)} near_dup_pairs={len(near_dupes)} low_fill={len(low_fill)}")

    problems = (
        len(missing_imagesets)
        + len(missing_pngs)
        + len(orphan_imagesets)
        + len(bad_size)
        + len(no_alpha)
        + len(blankish)
        + len(low_fill)
        + len(exact_dupes)
    )
    # Near-dupes are warnings; missing artwork is expected mid-generation.
    return 0 if problems == len(missing_imagesets) or problems == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
