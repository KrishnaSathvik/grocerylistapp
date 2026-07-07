#!/usr/bin/env python3
"""Regenerate favicons from the current marketing app icon."""

from __future__ import annotations

import base64
import io
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ICON_PATH = ROOT / "public" / "marketing" / "images" / "app-icon.png"
PUBLIC = ROOT / "public"
IOS_BRAND_ICON = (
    ROOT
    / "GroceryListiOS"
    / "GroceryList"
    / "Assets.xcassets"
    / "app-brand-icon.imageset"
    / "app-brand-icon.png"
)

SIZES = {
    "favicon-16x16.png": 16,
    "favicon-32x32.png": 32,
    "apple-touch-icon.png": 180,
    "android-chrome-192x192.png": 192,
    "android-chrome-512x512.png": 512,
}


def save_png(image: Image.Image, size: int, path: Path) -> None:
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(path, format="PNG", optimize=True)


def save_ico(image: Image.Image, path: Path) -> None:
    sizes = [16, 32, 48]
    frames = [image.resize((size, size), Image.Resampling.LANCZOS) for size in sizes]
    frames[0].save(
        path,
        format="ICO",
        sizes=[(size, size) for size in sizes],
        append_images=frames[1:],
    )


def save_svg(image: Image.Image, path: Path) -> None:
    png_bytes = io.BytesIO()
    image.resize((64, 64), Image.Resampling.LANCZOS).save(png_bytes, format="PNG", optimize=True)
    encoded = base64.b64encode(png_bytes.getvalue()).decode("ascii")
    path.write_text(
        "\n".join(
            [
                '<?xml version="1.0" encoding="UTF-8"?>',
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">',
                f'  <image width="64" height="64" href="data:image/png;base64,{encoded}"/>',
                "</svg>",
                "",
            ]
        ),
        encoding="utf-8",
    )


def main() -> None:
    if not ICON_PATH.exists():
        raise SystemExit(f"Missing source icon: {ICON_PATH}")

    source = Image.open(ICON_PATH).convert("RGBA")

    for filename, size in SIZES.items():
        save_png(source, size, PUBLIC / filename)

    save_ico(source, PUBLIC / "favicon.ico")
    save_svg(source, PUBLIC / "favicon.svg")
    save_png(source, 1024, IOS_BRAND_ICON)
    save_png(source, 512, PUBLIC / "logo.png")

    print("Generated favicons from", ICON_PATH.name)


if __name__ == "__main__":
    main()
