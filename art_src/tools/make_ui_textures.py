"""UI textures for the "Workshop Tin" A+ hybrid style (art_reference/GUI_Style_Guide).

Run from the project root:  python art_src/tools/make_ui_textures.py
Writes palette-exact PNGs to assets/ui/tin/. They are 9-slice sources for StyleBoxTexture (margins are
listed next to each one and mirrored in art_src/tools/build_ui_theme.gd) or small tiling patterns.
Sizes are in 720p design pixels (the game's canvas); Godot draws them 1:1 and upscales with the window.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "ui", "tin")
FONT_TINY5 = os.path.join(ROOT, "assets", "fonts", "Tiny5.ttf")

DARK = "#0D1322"
PLATE = "#1A2438"
STEEL = "#5C77AB"
BAND = "#1F5A43"
BAND_SHADE = "#163F30"
SNOW = "#F4F8FF"
KNIT_RED = "#8E1F2E"
GOLD = "#F2B53B"

# rarity: (row fill, row line, tile fill, stamp frame)
RARITY = {
    "common": ("#263450", "#8FA9D1", "#24314D", "#D9343F"),
    "rare": ("#17425C", "#7FD6F2", "#1D4A66", "#3A8FBF"),
    "epic": ("#37204F", "#B47BE6", "#43265E", "#7B3FB0"),
    "evo": ("#4A3A12", "#F2B53B", "#5C4512", "#E0A22A"),
}
# button variant: (top bevel, face, lip, text is handled by the theme)
BUTTONS = {
    "default": ("#6A86BD", "#3A4D78", "#1C2742"),
    "primary": ("#FFE08F", "#F2B53B", "#A8742C"),
    "reroll": ("#9FD8F5", "#3D82B8", "#1F4C78"),
    "danger": ("#F28890", "#C42F3A", "#7A1C27"),
    "disabled": ("#3A4766", "#2A3550", "#1A2238"),
    "tab": ("#4A5F8C", "#2C3A5C", "#1A2440"),
}


def rgba(hex_color: str, a: int = 255) -> tuple:
    h = hex_color.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def brighten(hex_color: str, k: float) -> str:
    r, g, b, _ = rgba(hex_color)
    return "#%02X%02X%02X" % tuple(min(255, round(c * k)) for c in (r, g, b))


def save(img: Image.Image, name: str) -> None:
    img.save(os.path.join(OUT, name + ".png"))
    print("wrote", name, img.size)


def rect(d: ImageDraw.ImageDraw, x0, y0, x1, y1, color) -> None:
    """Filled rect, inclusive pixel coords."""
    d.rectangle([x0, y0, x1, y1], fill=rgba(color) if isinstance(color, str) else color)


def knit_pixel(x: int, y: int) -> float:
    """Knit V stitches, 14x16 period: +light on the left half of each V, -dark on the right half."""
    lx, ly = x % 14, y % 16
    left = abs((lx + 0.5) - (1 + 6 * (ly / 16) ** 0.6)) < 2.6 - ly / 16 and ly < 13
    right = abs((lx + 0.5) - (13 - 6 * (ly / 16) ** 0.6)) < 2.6 - ly / 16 and ly < 13
    return 0.07 if left else (-0.2 if right else 0.0)


def knit_fill(img: Image.Image, box, base: str, phase=(0, 0)) -> None:
    x0, y0, x1, y1 = box
    r, g, b, _ = rgba(base)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            k = knit_pixel(x - phase[0], y - phase[1])
            if k > 0:
                c = tuple(round(v + (255 - v) * k) for v in (r, g, b))
            elif k < 0:
                c = tuple(round(v * (1 + k)) for v in (r, g, b))
            else:
                c = (r, g, b)
            img.putpixel((x, y), c + (255,))


def rivet(img: Image.Image, cx: float, cy: float) -> None:
    """10 px brass rivet: highlight, gold body, dark brown rim (drawn 4x and downsampled)."""
    s = 4
    big = Image.new("RGBA", (12 * s, 12 * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    d.ellipse([0.6 * s, 0.6 * s, 11.4 * s, 11.4 * s], fill=rgba("#8A5A33"))
    d.ellipse([1.6 * s, 1.6 * s, 10.4 * s, 10.4 * s], fill=rgba(GOLD))
    d.ellipse([3.4 * s, 3.0 * s, 6.6 * s, 6.2 * s], fill=rgba("#FFE6A8"))
    small = big.resize((12, 12), Image.LANCZOS)
    img.alpha_composite(small, (round(cx - 6), round(cy - 6)))


# ---------------------------------------------------------------------------------------------
def plate(name: str, fill: str, line: str, knit: bool) -> None:
    """Riveted plate. 9-slice margins: 22 left/top/right, 29 bottom (7 px drop shadow below the frame).
    Frame from outside: 3 dark ring, 2 line, 2 gap (fill), 1 dark, then fill. Knit plates: 28x32 center."""
    w, h = 72, 22 + 32 + 22 + 7
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fh = h - 7  # frame height
    rect(d, 0, fh, w - 1, h - 1, rgba(DARK, 140))  # drop shadow
    rect(d, 0, 0, w - 1, fh - 1, DARK)
    rect(d, 3, 3, w - 4, fh - 4, line)
    rect(d, 5, 5, w - 6, fh - 6, fill)
    rect(d, 7, 7, w - 8, fh - 8, DARK)
    if knit:
        knit_fill(img, (8, 8, w - 9, fh - 9), fill)
    else:
        rect(d, 8, 8, w - 9, fh - 9, fill)
    for cx, cy in ((15, 15), (w - 16, 15), (15, fh - 16), (w - 16, fh - 16)):
        rivet(img, cx, cy)
    save(img, name)


def header_band() -> None:
    """Pine header band with the Fair Isle trim under it. 9-slice: left/right 2, top 2, bottom 34.
    Rows from the bottom: 2 steel, 3 dark, 18 trim (red, white camels/flakes), 3 dark, 3 shade, then pine.
    Width 30 = 2 + 26 (one motif period, tiled) + 2."""
    w, h = 30, 2 + 12 + 3 + 3 + 18 + 3 + 2 + 1
    img = Image.new("RGBA", (w, h), rgba(BAND))
    d = ImageDraw.Draw(img)
    y = h - 1
    rect(d, 0, y - 1, w - 1, y, STEEL); y -= 2
    rect(d, 0, y - 2, w - 1, y, DARK); y -= 3
    trim_top = y - 17
    trim = fair_isle(18)
    for x in (-24, 2, 28):  # phase so the tiled center (x 2..27) is exactly one period
        img.paste(trim, (x, trim_top))
    y = trim_top - 1
    rect(d, 0, y - 2, w - 1, y, DARK); y -= 3
    rect(d, 0, y - 2, w - 1, y, BAND_SHADE)
    save(img, "header_band")


CAMEL = ["...........XX.", "..XX..XX...XXX", ".XXXXXXXX..X..", "XXXXXXXXXXXX..", "XXXXXXXXXXX...",
         ".XXXXXXXXX....", ".X.X....X.X...", ".X.X....X.X..."]
FLAKE = ["..X..", ".X.X.", "X.X.X", ".X.X.", "..X.."]


def fair_isle(height: int, unit: int = 1) -> Image.Image:
    """One 26-unit period of the Fair Isle band on knit red: checker rows, a camel, a snowflake."""
    w = 26 * unit
    img = Image.new("RGBA", (w, height), rgba(KNIT_RED))
    knit_fill(img, (0, 0, w - 1, height - 1), KNIT_RED)
    oy = (height - 13 * unit) // 2
    px = []
    for x in range(0, 26, 2):
        px += [(x, 0), (x + 1, 12)]
    for yy, row in enumerate(CAMEL):
        px += [(xx + 2, yy + 2) for xx, c in enumerate(row) if c == "X"]
    for yy, row in enumerate(FLAKE):
        px += [(xx + 19, yy + 4) for xx, c in enumerate(row) if c == "X"]
    d = ImageDraw.Draw(img)
    for x, y in px:
        rect(d, x * unit, oy + y * unit, x * unit + unit - 1, oy + y * unit + unit - 1, SNOW)
    return img


def buttons() -> None:
    """Slab buttons. Each state image is 32x30. 9-slice: left/right 6, top 6 (normal) / 10 (pressed),
    bottom 14 (normal) / 6 (pressed). Theme expand margins: 3 left/top/right, 8 bottom."""
    for variant, (top, face, lip) in BUTTONS.items():
        for state, k in (("normal", 1.0), ("hover", 1.14)):
            if variant == "disabled" and state == "hover":
                continue
            img = Image.new("RGBA", (32, 30), (0, 0, 0, 0))
            d = ImageDraw.Draw(img)
            rect(d, 0, 25, 31, 29, DARK)  # 5 px drop
            slab(d, 0, 0, 31, 24, brighten(top, k), brighten(face, k), brighten(lip, k), 6)
            save(img, f"btn_{variant}_{state}")
        if variant == "disabled":
            continue
        img = Image.new("RGBA", (32, 30), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        rect(d, 0, 29, 31, 29, DARK)  # 1 px drop
        slab(d, 0, 4, 31, 28, top, face, lip, 2)
        save(img, f"btn_{variant}_pressed")


def slab(d, x0, y0, x1, y1, top, face, lip, lip_h) -> None:
    rect(d, x0, y0, x1, y1, DARK)  # 3 px ring
    rect(d, x0 + 3, y0 + 3, x1 - 3, y1 - 3, face)
    rect(d, x0 + 3, y0 + 3, x1 - 3, y0 + 5, top)
    rect(d, x0 + 3, y1 - 2 - lip_h, x1 - 3, y1 - 3, lip)
    for cx, cy in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):  # 3 px radius: knock out the corner pixel
        d.point((cx, cy), fill=(0, 0, 0, 0))


def tiles() -> None:
    """Icon tiles: 2 dark ring + 2 rarity line + fill. 16x16, 9-slice 5 all round (theme expands 2)."""
    for r, (_, line, fill, _) in RARITY.items():
        img = Image.new("RGBA", (16, 16), rgba(DARK))
        d = ImageDraw.Draw(img)
        rect(d, 2, 2, 13, 13, line)
        rect(d, 4, 4, 11, 11, fill)
        save(img, f"tile_{r}")
    img = Image.new("RGBA", (16, 16), rgba(DARK, 140))  # HUD slot: translucent, steel hairline
    d = ImageDraw.Draw(img)
    d.rectangle([2, 2, 13, 13], outline=rgba(STEEL, 130), width=2)
    save(img, "tile_hud")


def stamps() -> None:
    """Postage stamps: perforated paper edge (holes every 6 px), 3 px colored frame, light picture field.
    36x36, 9-slice 12 all round, edges tile (hole period divides the 12 px edge strip)."""
    for r, (_, _, _, frame) in RARITY.items():
        s = 4
        big = Image.new("RGBA", (36 * s, 36 * s), (0, 0, 0, 0))
        d = ImageDraw.Draw(big)
        d.rectangle([0, 0, 36 * s - 1, 36 * s - 1], fill=rgba(SNOW))
        for k in range(6):
            c = (3 + 6 * k) * s
            for cx, cy in ((c, 0), (c, 36 * s), (0, c), (36 * s, c)):
                d.ellipse([cx - 2.4 * s, cy - 2.4 * s, cx + 2.4 * s, cy + 2.4 * s], fill=(0, 0, 0, 0))
        d.rectangle([5 * s, 5 * s, 31 * s - 1, 31 * s - 1], fill=rgba(frame))
        d.rectangle([8 * s, 8 * s, 28 * s - 1, 28 * s - 1], fill=rgba("#DCE6F5"))
        save(big.resize((36, 36), Image.LANCZOS), f"stamp_{r}")


def airmail() -> None:
    """Airmail border: 2 px dark ring + 10 px red/paper/blue/paper stripes at 45°, paper center.
    64x64, 9-slice 12 all round; stripes repeat every 40 px so the 40 px edge strips tile."""
    img = Image.new("RGBA", (64, 64), rgba(SNOW))
    for y in range(64):
        for x in range(64):
            if 2 <= x < 62 and 2 <= y < 62 and not (12 <= x < 52 and 12 <= y < 52):
                t = (x + y) % 40
                c = "#D9343F" if t < 12 else SNOW if t < 20 else "#3A5B9C" if t < 32 else SNOW
                img.putpixel((x, y), rgba(c))
            elif not (2 <= x < 62 and 2 <= y < 62):
                img.putpixel((x, y), rgba(DARK))
    save(img, "airmail")


def luggage_tag() -> None:
    """Paper tag with a notched left point and a punched hole. 44x28, 9-slice: left 20, right/top/bottom 5."""
    s = 4
    big = Image.new("RGBA", (44 * s, 28 * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    d.polygon([(12 * s, 0), (44 * s, 0), (44 * s, 28 * s), (12 * s, 28 * s), (0, 14 * s)], fill=rgba(SNOW))
    d.ellipse([10 * s, 10 * s, 18 * s, 18 * s], fill=rgba("#8A5A33"))
    d.ellipse([12 * s, 12 * s, 16 * s, 16 * s], fill=rgba(BAND))
    save(big.resize((44, 28), Image.LANCZOS), "luggage_tag")


def sweater_button(size: int, angle: float = 0.0) -> Image.Image:
    """Sewn wooden sweater button: rim, face, four holes, white thread cross (rotated by angle)."""
    s = 8
    n = size * s
    big = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    d.ellipse([0, 0, n - 1, n - 1], fill=rgba(DARK))
    d.ellipse([2 * s, 2 * s, n - 1 - 2 * s, n - 1 - 2 * s], fill=rgba("#C98F55"))
    inner = n * 0.18
    d.ellipse([inner, inner, n - 1 - inner, n - 1 - inner], fill=rgba("#8A5A33"))
    inner2 = n * 0.24
    d.ellipse([inner2, inner2, n - 1 - inner2, n - 1 - inner2], fill=rgba("#D9A56A"))
    c = n / 2
    off = n * 0.13
    hole = n * 0.07
    pts = []
    for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        a = math.radians(angle)
        x, y = sx * off, sy * off
        pts.append((c + x * math.cos(a) - y * math.sin(a), c + x * math.sin(a) + y * math.cos(a)))
    thread = max(2, round(n * 0.055))
    d.line([pts[0], pts[3]], fill=rgba(SNOW), width=thread)
    d.line([pts[1], pts[2]], fill=rgba(SNOW), width=thread)
    for x, y in pts:
        d.ellipse([x - hole, y - hole, x + hole, y + hole], fill=rgba("#3E2619"))
    d.line([pts[0], pts[3]], fill=rgba(SNOW, 230), width=max(1, thread // 2))
    d.line([pts[1], pts[2]], fill=rgba(SNOW, 230), width=max(1, thread // 2))
    return big.resize((size, size), Image.LANCZOS)


def knobs_and_toggles() -> None:
    save(sweater_button(32), "knob_slider")
    for on in (False, True):
        img = Image.new("RGBA", (62, 34), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        rect(d, 0, 0, 61, 33, DARK)
        if on:
            knit_fill(img, (2, 2, 59, 31), "#2E8A4A")
        else:
            rect(d, 2, 2, 59, 31, DARK)
            d.rectangle([2, 2, 59, 31], outline=rgba(STEEL, 150), width=1)
        knob = sweater_button(24, 90.0 if on else 0.0)
        img.alpha_composite(knob, (33 if on else 5, 5))
        save(img, "toggle_on" if on else "toggle_off")
    img = Image.new("RGBA", (18, 14), (0, 0, 0, 0))  # yarn stripes for the slider fill (tiles in x)
    for y in range(14):
        for x in range(18):
            t = (x + y * 0.47) % 9
            img.putpixel((x, y), rgba("#D9343F" if t < 6 else SNOW))
    save(img, "yarn_fill")


def knit_tiles() -> None:
    img = Image.new("RGBA", (14, 16), (0, 0, 0, 0))  # overlay: draw over any color
    for y in range(16):
        for x in range(14):
            k = knit_pixel(x, y)
            if k > 0:
                img.putpixel((x, y), (255, 255, 255, round(255 * k)))
            elif k < 0:
                img.putpixel((x, y), (0, 0, 0, round(255 * -k)))
    save(img, "knit_overlay")
    img = Image.new("RGBA", (14, 16), rgba(KNIT_RED))
    knit_fill(img, (0, 0, 13, 15), KNIT_RED)
    save(img, "knit_red")
    save(fair_isle(30, 2).resize((52, 30), Image.NEAREST), "fair_isle_big")


def postmarks() -> None:
    """White cancellation marks (tint with modulate): round 128 px and round + waves 256x128."""
    s = 2
    for wavy in (False, True):
        w = 256 if wavy else 128
        big = Image.new("RGBA", (w * s, 128 * s), (0, 0, 0, 0))
        d = ImageDraw.Draw(big)
        c = 64 * s
        d.ellipse([c - 59 * s, c - 59 * s, c + 59 * s, c + 59 * s], outline=(255, 255, 255, 255), width=4 * s)
        d.ellipse([c - 38 * s, c - 38 * s, c + 38 * s, c + 38 * s], outline=(255, 255, 255, 255), width=3 * s)
        font = ImageFont.truetype(FONT_TINY5, 14 * s)
        arc_text(big, "NORTH POLE", c, c, 47 * s, font, top=True)
        arc_text(big, "CAMEL POST", c, c, 47 * s, font, top=False)
        fmid = ImageFont.truetype(FONT_TINY5, 17 * s)
        d.text((c, c - 8 * s), "DEC 25", font=fmid, fill=(255, 255, 255, 255), anchor="mm")
        d.text((c, c + 11 * s), "90° N", font=ImageFont.truetype(FONT_TINY5, 13 * s), fill=(255, 255, 255, 255), anchor="mm")
        if wavy:
            for yy in (40, 64, 88):
                pts = [(x * s, (yy + 7 * math.sin((x - 126) / 16 * math.pi)) * s) for x in range(126, 256)]
                d.line(pts, fill=(255, 255, 255, 255), width=4 * s)
        save(big.resize((w, 128), Image.LANCZOS), "postmark_wavy" if wavy else "postmark")


def arc_text(img: Image.Image, text: str, cx: float, cy: float, r: float, font, top: bool) -> None:
    """Letters along a circle: over the top (reading left to right) or under the bottom (upright)."""
    widths = [font.getlength(ch) for ch in text]
    total = sum(widths) + 3 * len(text)
    ang = total / r
    a = (-math.pi / 2 - ang / 2) if top else (math.pi / 2 + ang / 2)
    for ch, w in zip(text, widths):
        step = (w + 3) / r
        mid = a + (step / 2 if top else -step / 2)
        x, y = cx + r * math.cos(mid), cy + r * math.sin(mid)
        glyph = Image.new("RGBA", (int(w + 40), int(font.size * 2)), (0, 0, 0, 0))
        ImageDraw.Draw(glyph).text((glyph.width / 2, glyph.height / 2), ch, font=font, fill=(255, 255, 255, 255), anchor="mm")
        rot = -math.degrees(mid + math.pi / 2) if top else -math.degrees(mid - math.pi / 2)
        glyph = glyph.rotate(rot, resample=Image.BICUBIC, expand=True)
        img.alpha_composite(glyph, (round(x - glyph.width / 2), round(y - glyph.height / 2)))
        a += step if top else -step


def rays() -> None:
    """Soft gold rays for the level-up backdrop (rotate slowly)."""
    n = 512
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    c = n / 2
    for y in range(n):
        for x in range(n):
            dx, dy = x - c, y - c
            dist = math.hypot(dx, dy) / c
            if dist > 1:
                continue
            a = (math.degrees(math.atan2(dy, dx)) % 22) < 7
            fade = max(0.0, 1 - dist) ** 1.3
            if a:
                img.putpixel((x, y), (242, 181, 59, round(70 * fade)))
    save(img, "rays")


def yarn_ball() -> None:
    """Cream yarn ball with diagonal wraps (the intro rolls it across the screen)."""
    s = 4
    n = 64 * s
    big = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    mask = Image.new("L", (n, n), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, n - 1, n - 1], fill=255)
    stripes = Image.new("RGBA", (n, n), rgba("#F4E6D4"))
    d = ImageDraw.Draw(stripes)
    for k in range(-n, 2 * n, 7 * s):
        d.line([(k, 0), (k + n * 0.58, n)], fill=rgba("#D9C3A8"), width=3 * s)
    big.paste(stripes, (0, 0), mask)
    shade = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    ImageDraw.Draw(shade).ellipse([n * 0.18, n * 0.18, n * 1.3, n * 1.3], fill=(0, 0, 0, 40))
    big.alpha_composite(Image.composite(shade, Image.new("RGBA", (n, n), (0, 0, 0, 0)), mask))
    save(big.resize((64, 64), Image.LANCZOS), "yarn_ball")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    plate("plate", PLATE, STEEL, knit=False)
    for r, (fill, line, _, _) in RARITY.items():
        plate(f"row_{r}", fill, line, knit=True)
        plate(f"row_{r}_hover", brighten(fill, 1.25), brighten(line, 1.1), knit=True)
    plate("plate_knit", PLATE, STEEL, knit=True)
    plate("plate_pine", BAND, STEEL, knit=False)  # intro subtitle plate
    header_band()
    buttons()
    tiles()
    stamps()
    airmail()
    luggage_tag()
    knobs_and_toggles()
    knit_tiles()
    postmarks()
    rays()
    yarn_ball()
