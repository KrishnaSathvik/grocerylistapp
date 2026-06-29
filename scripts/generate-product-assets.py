#!/usr/bin/env python3
"""Generate placeholder product PNGs and Assets.xcassets entries for Phase 3."""
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "GroceryListiOS" / "GroceryList" / "Assets.xcassets"

PRODUCTS = [
    ("product-milk", (232, 244, 253)),
    ("product-eggs", (255, 248, 225)),
    ("product-banana", (255, 243, 224)),
    ("product-bread", (239, 224, 203)),
    ("product-chicken", (255, 235, 238)),
    ("product-rice", (255, 255, 255)),
    ("product-gochujang", (243, 229, 245)),
    ("product-paneer", (232, 244, 253)),
    ("product-kimchi", (252, 228, 236)),
    ("product-basmati", (255, 243, 224)),
]


def png_bytes(width: int, height: int, rgb: tuple[int, int, int]) -> bytes:
    r, g, b = rgb
    row = bytes([0, r, g, b] * width)
    raw = row * height
    compressed = zlib.compress(raw, 9)

    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", compressed)
        + chunk(b"IEND", b"")
    )


def write_imageset(name: str, rgb: tuple[int, int, int]) -> None:
    folder = ROOT / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    png_path = folder / f"{name}.png"
    png_path.write_bytes(png_bytes(80, 80, rgb))
    contents = {
        "images": [{"filename": png_path.name, "idiom": "universal", "scale": "1x"}],
        "info": {"author": "xcode", "version": 1},
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)

    (ROOT / "Contents.json").write_text(
        json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n"
    )

    app_icon = ROOT / "AppIcon.appiconset"
    app_icon.mkdir(exist_ok=True)
    (app_icon / "Contents.json").write_text(
        json.dumps(
            {
                "images": [{"idiom": "universal", "platform": "ios", "size": "1024x1024"}],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
        )
        + "\n"
    )

    accent = ROOT / "AccentColor.colorset"
    accent.mkdir(exist_ok=True)
    (accent / "Contents.json").write_text(
        json.dumps(
            {
                "colors": [
                    {
                        "color": {
                            "color-space": "srgb",
                            "components": {
                                "alpha": "1.000",
                                "blue": "0.212",
                                "green": "0.122",
                                "red": "0.102",
                            },
                        },
                        "idiom": "universal",
                    }
                ],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
        )
        + "\n"
    )

    for name, rgb in PRODUCTS:
        write_imageset(name, rgb)

    print(f"Created {len(PRODUCTS)} product imagesets in {ROOT}")


if __name__ == "__main__":
    main()
