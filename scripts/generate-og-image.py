#!/usr/bin/env python3
"""Generate a 1200x630 Open Graph image for Groceries — Smart Lists."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ICON_PATH = ROOT / "public" / "marketing" / "images" / "app-icon.png"
OUT_PATH = ROOT / "public" / "og-image.png"

W, H = 1200, 630

# Brand palette
CREAM = (247, 244, 238)
SAGE = (74, 124, 89)
SAGE_DARK = (45, 90, 62)
INK = (26, 31, 54)
INK_MUTED = (100, 108, 125)
WHITE = (255, 255, 255)
GOLD = (232, 196, 104)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def gradient_background() -> Image.Image:
    img = Image.new("RGB", (W, H), CREAM)
    px = img.load()
    for y in range(H):
        for x in range(W):
            t = (x / W) * 0.55 + (y / H) * 0.45
            r = lerp(232, 248, t)
            g = lerp(245, 250, t)
            b = lerp(236, 244, t)
            px[x, y] = (r, g, b)
    return img


def draw_blob(canvas: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int, int]) -> None:
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(radius=radius // 3))
    canvas.alpha_composite(layer)


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def rounded_rect(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], radius: int, fill: tuple[int, int, int, int]) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def add_shadow(icon: Image.Image, offset: tuple[int, int] = (0, 18), blur: int = 28, opacity: int = 70) -> Image.Image:
    shadow = Image.new("RGBA", icon.size, (0, 0, 0, 0))
    alpha = icon.split()[3]
    shadow.putalpha(alpha.point(lambda p: min(p, opacity)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new("RGBA", (icon.width + 80, icon.height + 80), (0, 0, 0, 0))
    sx = 40 + offset[0]
    sy = 40 + offset[1]
    out.alpha_composite(shadow, (sx, sy))
    out.alpha_composite(icon, (40, 40))
    return out


def draw_checklist_accent(draw: ImageDraw.ImageDraw, origin: tuple[int, int]) -> None:
    x0, y0 = origin
    for i in range(4):
        y = y0 + i * 34
        draw.rounded_rectangle((x0, y, x0 + 18, y + 18), radius=4, outline=(*SAGE, 120), width=2)
        if i < 2:
            draw.line((x0 + 4, y + 9, x0 + 8, y + 13, x0 + 14, y + 5), fill=SAGE, width=2)
        draw.line((x0 + 28, y + 9, x0 + 120, y + 9), fill=(180, 188, 176), width=3)


def main() -> None:
    base = gradient_background().convert("RGBA")
    draw = ImageDraw.Draw(base)

    # Atmospheric shapes — fill the frame
    draw_blob(base, (180, 120), 220, (*SAGE, 42))
    draw_blob(base, (980, 520), 280, (*GOLD, 38))
    draw_blob(base, (1050, 90), 160, (*SAGE_DARK, 28))

    # Subtle grid dots
    dot_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dot_draw = ImageDraw.Draw(dot_layer)
    for gx in range(0, W, 36):
        for gy in range(0, H, 36):
            dot_draw.ellipse((gx, gy, gx + 2, gy + 2), fill=(120, 140, 120, 18))
    base.alpha_composite(dot_layer)

    # Left hero icon
    icon = Image.open(ICON_PATH).convert("RGBA")
    icon_size = 430
    icon = icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    icon = add_shadow(icon)
    ix = 72
    iy = (H - icon.height) // 2
    base.alpha_composite(icon, (ix, iy))

    # Right content panel
    text_x = 560
    title_font = load_font(62, bold=True)
    dash_font = load_font(62, bold=True)
    subtitle_font = load_font(30)
    pill_font = load_font(22, bold=True)

    # Accent card behind text
    card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    card_draw = ImageDraw.Draw(card)
    rounded_rect(card_draw, (text_x - 36, 96, W - 48, H - 96), 28, (255, 255, 255, 188))
    card = card.filter(ImageFilter.GaussianBlur(0.5))
    base.alpha_composite(card)

    draw = ImageDraw.Draw(base)
    draw.text((text_x, 118), "Groceries", font=title_font, fill=INK)
    draw.text((text_x, 188), "Smart Lists", font=dash_font, fill=SAGE_DARK)

    # Decorative line
    draw.line((text_x, 272, text_x + 220, 272), fill=(*SAGE, 180), width=4)

    draw.text(
        (text_x, 296),
        "Plan, shop, and share grocery lists",
        font=subtitle_font,
        fill=INK_MUTED,
    )
    draw.text(
        (text_x, 338),
        "without clutter or complicated setup.",
        font=subtitle_font,
        fill=INK_MUTED,
    )

    pills = ["iOS app", "No account", "Private by design"]
    pill_x = text_x
    pill_y = 418
    for label in pills:
        bbox = pill_font.getbbox(label)
        pw = bbox[2] - bbox[0] + 28
        ph = 40
        rounded_rect(draw, (pill_x, pill_y, pill_x + pw, pill_y + ph), 20, (*SAGE, 28))
        draw.text((pill_x + 14, pill_y + 8), label, font=pill_font, fill=SAGE_DARK)
        pill_x += pw + 12

    draw_checklist_accent(draw, (text_x, 500))

    # Export
    final = base.convert("RGB")
    final.save(OUT_PATH, format="PNG", optimize=True)
    print(f"Wrote {OUT_PATH} ({W}x{H})")


if __name__ == "__main__":
    main()
