#!/usr/bin/env python3
"""Download and bundle grocery store logos into Assets.xcassets."""
from __future__ import annotations

import json
import ssl
import urllib.error
import urllib.request
from io import BytesIO
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "GroceryList" / "Assets.xcassets"
STORES_JSON = ROOT / "GroceryList" / "Resources" / "default_stores.json"
CANVAS = 512
TARGET_FILL = 0.88
BADGE_BACKGROUND = (255, 255, 255, 255)

# Prefer crisp Wikimedia marks for major retailers (Clearbit adds cyan halos).
LOGO_OVERRIDES: dict[str, list[str]] = {
    "costco": [
        "https://upload.wikimedia.org/wikipedia/commons/thumb/5/59/Costco_Wholesale_logo_2010-10-26.svg/330px-Costco_Wholesale_logo_2010-10-26.svg.png",
    ],
    "walmart": [
        "https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Walmart_spark_%282025%29.svg/330px-Walmart_spark_%282025%29.svg.png",
    ],
    "target": [
        "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Target_logo.svg/330px-Target_logo.svg.png",
    ],
    "raleys": [
        "https://upload.wikimedia.org/wikipedia/en/thumb/8/8e/Raley%27s_logo.svg/330px-Raley%27s_logo.svg.png",
    ],
    "frys": [
        "https://upload.wikimedia.org/wikipedia/en/thumb/4/4f/Fry%27s_Food_and_Drug_logo.svg/330px-Fry%27s_Food_and_Drug_logo.svg.png",
    ],
    "kingsoopers": [
        "https://upload.wikimedia.org/wikipedia/en/thumb/8/8a/King_Soopers_logo.svg/330px-King_Soopers_logo.svg.png",
    ],
    "fredmeyer": [
        "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Fred_Meyer_logo.svg/330px-Fred_Meyer_logo.svg.png",
    ],
    "marianos": [
        "https://upload.wikimedia.org/wikipedia/en/thumb/1/1d/Mariano%27s_logo.svg/330px-Mariano%27s_logo.svg.png",
    ],
    "jewelosco": [
        "https://upload.wikimedia.org/wikipedia/en/thumb/1/1e/Jewel-Osco_logo.svg/330px-Jewel-Osco_logo.svg.png",
    ],
    "ingles": [
        "https://upload.wikimedia.org/wikipedia/en/thumb/5/5a/Ingles_logo.svg/330px-Ingles_logo.svg.png",
    ],
}

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


def fetch_bytes(url: str, timeout: float = 20.0) -> bytes | None:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "GroceryList-Asset-Script/1.0"},
    )
    context = ssl.create_default_context()
    try:
        with urllib.request.urlopen(request, timeout=timeout, context=context) as response:
            data = response.read()
            if len(data) < 200:
                return None
            return data
    except (urllib.error.URLError, TimeoutError, ValueError):
        return None


def download_logo(domain: str, store_id: str) -> Image.Image | None:
    override_urls = LOGO_OVERRIDES.get(store_id, [])
    sources = override_urls + [
        f"https://logo.clearbit.com/{domain}",
        f"https://www.google.com/s2/favicons?domain={domain}&sz=256",
        f"https://icons.duckduckgo.com/ip3/{domain}.ico",
    ]
    seen: set[str] = set()
    for url in sources:
        if url in seen:
            continue
        seen.add(url)
        raw = fetch_bytes(url)
        if not raw:
            continue
        try:
            image = Image.open(BytesIO(raw)).convert("RGBA")
            if image.width < 16 or image.height < 16:
                continue
            return image
        except OSError:
            continue
    return None


def defringe_logo(image: Image.Image) -> Image.Image:
    """Remove Clearbit's cyan halo on white badges without touching saturated brand colors."""
    px = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = px[x, y]
            if a < 20:
                px[x, y] = (255, 255, 255, 255)
                continue

            saturation = max(r, g, b) - min(r, g, b)
            if saturation > 55:
                continue

            if g > 205 and b > 205 and 145 < r < 245:
                px[x, y] = (255, 255, 255, 255)

    return image


def normalize_logo(image: Image.Image) -> Image.Image:
    image = defringe_logo(image.convert("RGBA"))
    bbox = image.getbbox()
    if not bbox:
        raise RuntimeError("logo has no visible pixels")

    cropped = image.crop(bbox)
    cw, ch = cropped.size
    scale = min(CANVAS * TARGET_FILL / cw, CANVAS * TARGET_FILL / ch)
    nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
    resized = cropped.resize((nw, nh), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), BADGE_BACKGROUND)
    ox = (CANVAS - nw) // 2
    oy = (CANVAS - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def reprocess_existing(path: Path) -> None:
    """Re-normalize an existing bundled logo onto a white badge background."""
    image = Image.open(path).convert("RGBA")
    flattened = Image.new("RGBA", image.size, BADGE_BACKGROUND)
    flattened.paste(image, (0, 0), image)
    normalized = normalize_logo(flattened)
    normalized.save(path, "PNG")


def write_imageset(store_id: str, image: Image.Image) -> None:
    imageset = ASSETS / f"store-{store_id}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    filename = f"store-{store_id}.png"
    image.save(imageset / filename, "PNG")
    contents = CONTENTS_JSON.replace("{filename}", filename)
    (imageset / "Contents.json").write_text(contents, encoding="utf-8")


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reprocess-only",
        action="store_true",
        help="Flatten and re-normalize existing store-*.png assets (no download)",
    )
    args = parser.parse_args()

    if args.reprocess_only:
        imagesets = sorted(ASSETS.glob("store-*.imageset"))
        for imageset in imagesets:
            pngs = sorted(imageset.glob("*.png"))
            if not pngs:
                continue
            reprocess_existing(pngs[0])
            print(f"OK {imageset.name}")
        print(f"\nReprocessed {len(imagesets)} store logos.")
        return

    stores = json.loads(STORES_JSON.read_text(encoding="utf-8"))["stores"]
    ok: list[str] = []
    failed: list[str] = []

    for store in stores:
        store_id = store["id"]
        domain = store.get("domain")
        if not domain:
            failed.append(store_id)
            print(f"FAIL {store_id}: missing domain")
            continue

        raw = download_logo(domain, store_id)
        if raw is None:
            failed.append(store_id)
            print(f"FAIL {store_id}: could not download from {domain}")
            continue

        try:
            normalized = normalize_logo(raw)
            write_imageset(store_id, normalized)
            ok.append(store_id)
            print(f"OK store-{store_id} ({domain})")
        except RuntimeError as error:
            failed.append(store_id)
            print(f"FAIL {store_id}: {error}")

    print(f"\nDownloaded {len(ok)}/{len(stores)} store logos.")
    if failed:
        print("Failed:", ", ".join(failed))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
