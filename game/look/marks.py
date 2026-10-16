#!/usr/bin/env python3
"""Draws marks.png, the maker's marks atlas (docs/art-direction.md, "Maker's marks").

A column per mark, a row per era: yours (new), surface, deep. Red is the mark's
own ink, green a hand-mixed daub. Blurred a little, so the wear shader cuts each
edge where its noise says and the mark wears ragged rather than pixelated.
    python3 game/look/marks.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

CELL = (256, 128)
COLS = 5
ROWS = 3
HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, "..", "..", "assets", "fonts", "GeistMono-Regular.ttf")
# A stencil can't hold a letter's middle in place: these get a bridge.
SPLIT = {"O": 0.5, "0": 0.5, "D": 0.5, "Q": 0.5, "R": 0.36, "P": 0.36, "B": 0.36}


def stencil(draw, text, centre, cap, weight=0.16, track=0.22):
    """Block letters as a stencil cuts them, `cap` pixels tall, centred."""
    font = ImageFont.truetype(FONT, int(cap * 1.38))
    stroke = max(1, int(cap * weight * 0.5))
    boxes = [font.getbbox(ch, stroke_width=stroke) if ch != " " else None for ch in text]
    widths = [b[2] - b[0] if b else cap * 0.45 for b in boxes]
    total = sum(widths) + cap * track * (len(text) - 1)
    x = centre[0] - total / 2
    for ch, box, w in zip(text, boxes, widths):
        if box:
            top = centre[1] - (box[3] - box[1]) / 2
            draw.text((x - box[0], top - box[1]), ch, font=font, fill=255, stroke_width=stroke, stroke_fill=255)
            if ch in SPLIT:
                cut = x + w * SPLIT[ch]
                gap = max(2, cap * 0.07)
                low = top + (box[3] - box[1]) * (0.62 if ch in "RP" else 1.0)
                draw.rectangle([cut - gap / 2, top - 2, cut + gap / 2, low + 2], fill=0)
        x += w + cap * track


def brush(draw, points, width, rng, wobble=2.5):
    """A hand-painted stroke: it wanders and swells as a brush does."""
    phase = rng.uniform(0, 6.28)
    dense = []
    for a, b in zip(points, points[1:]):
        steps = max(2, int(math.dist(a, b) / 1.5))
        for i in range(steps):
            t = i / steps
            dense.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    dense.append(points[-1])
    for i, (x, y) in enumerate(dense):
        s = i / max(1, len(dense) - 1)
        r = width * 0.5 * (0.75 + 0.25 * math.sin(s * 9.0 + phase) + rng.uniform(-0.08, 0.08))
        # Thinner where the brush lifts off.
        r *= min(1.0, 0.45 + s * 4.0, 0.45 + (1.0 - s) * 3.0)
        jx = wobble * math.sin(s * 5.3 + phase)
        jy = wobble * math.cos(s * 4.1 + phase * 1.7)
        draw.ellipse([x + jx - r, y + jy - r, x + jx + r, y + jy + r], fill=255)


def arc(cx, cy, r, a0, a1, n=40):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def contractor(ink, daub, rng):
    """The Remote Moon Contractor's tag: a notched plate round its letters."""
    w, h = CELL
    n = 12
    plate = [(14 + n, 16), (w - 14 - n, 16), (w - 14, 16 + n), (w - 14, h - 16 - n), (w - 14 - n, h - 16),
             (14 + n, h - 16), (14, h - 16 - n), (14, 16 + n), (14 + n, 16)]
    ink.line(plate, fill=255, width=7, joint="curve")
    # The plate's border is a stencil too: bridged top and bottom.
    for y in (16, h - 16):
        ink.rectangle([w / 2 - 4, y - 6, w / 2 + 4, y + 6], fill=0)
    stencil(ink, "RMC", (w / 2, h / 2), 56)


def shield_maker(ink, daub, rng):
    """The common shield's maker: the bubble on its ground, the emitter beneath."""
    w, h = CELL
    cx, base = w / 2, 88
    ink.arc([cx - 46, base - 50, cx + 46, base + 42], 196, 344, fill=255, width=12)
    ink.rectangle([cx - 54, base + 4, cx + 54, base + 14], fill=255)
    ink.ellipse([cx - 11, base - 22, cx + 11, base], fill=255)


def wind_maker(ink, daub, rng):
    """The wind turbines' maker: three vanes in a ring."""
    w, h = CELL
    cx, cy, r = w / 2, h / 2, 50
    ink.ellipse([cx - r, cy - r, cx + r, cy + r], outline=255, width=8)
    for k in range(3):
        a = math.radians(k * 120 - 90)
        pts = []
        for i in range(16):
            t = 0.18 + 0.62 * i / 15
            ang = a + 0.9 * t
            pts.append((cx + r * t * math.cos(ang), cy + r * t * math.sin(ang)))
        ink.line(pts, fill=255, width=11, joint="curve")
    ink.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=255)


def consignment(row):
    """A crate's label, by era: who it went to, once; later, a copy from memory."""
    def draw(ink, daub, rng):
        w, h = CELL
        if row == 2:
            # Deep: the operator's consignment stencil, routed by the sector code.
            stencil(ink, "TILG", (w / 2, 44), 44)
            stencil(ink, "XN 0217", (w / 2, 96), 24, track=0.3)
        elif row == 1:
            # Surface: the code daubed back on by hand, the X said and written as a Z.
            brush(daub, [(58, 30), (108, 30), (60, 92), (110, 92)], 15, rng)
            brush(daub, [(134, 94), (136, 30), (184, 94), (186, 30)], 15, rng)
            brush(daub, [(50, 110), (120, 106), (200, 112)], 9, rng, wobble=1.5)
        else:
            # Yours: a recent, cheap make's batch number.
            stencil(ink, "LOT 3127", (w / 2, h / 2), 26, track=0.3)
    return draw


def skimmer_crew(ink, daub, rng):
    """A skimmer crew's patch, painted by hand: the giant, a dive across it, a tally."""
    w, h = CELL
    cx, cy = 96, 64
    rim = [(x + rng.uniform(-2.5, 2.5), y + rng.uniform(-2.5, 2.5)) for x, y in arc(cx, cy, 40, 0, 360, 36)]
    daub.polygon(rim, fill=255)
    brush(daub, rim, 7, rng, wobble=1.0)
    brush(ink, arc(cx + 6, cy + 74, 96, 236, 300, 20), 9, rng, wobble=1.5)
    for k in range(3):
        brush(ink, [(170 + k * 16, 44), (166 + k * 16, 88)], 8, rng, wobble=1.0)


MARKS = [contractor, shield_maker, wind_maker, None, skimmer_crew]


def main():
    rng = random.Random(7)
    red = Image.new("L", (CELL[0] * COLS, CELL[1] * ROWS))
    green = Image.new("L", red.size)
    for row in range(ROWS):
        for col in range(COLS):
            ink_cell = Image.new("L", CELL)
            daub_cell = Image.new("L", CELL)
            mark = MARKS[col] or consignment(row)
            mark(ImageDraw.Draw(ink_cell), ImageDraw.Draw(daub_cell), rng)
            red.paste(ink_cell, (col * CELL[0], row * CELL[1]))
            green.paste(daub_cell, (col * CELL[0], row * CELL[1]))
    soft = ImageFilter.GaussianBlur(1.6)
    out = Image.merge("RGB", (red.filter(soft), green.filter(soft), Image.new("L", red.size)))
    out.save(os.path.join(HERE, "marks.png"), optimize=True)


if __name__ == "__main__":
    main()
