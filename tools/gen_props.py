"""Objetos de cenário com que se interage: Vigia, altar do fragmento, pedestal
de item, estela de inscrição, portal de saída e braseiro.

    python tools/gen_props.py

Quadros de 48x48, base em (24, 46). O que brilha ou se mexe (chama, cristal,
luz do portal) continua desenhado em código por cima.

Índices: 1 contorno | 2-4 pedra | 5-7 ferro | 8 ouro | 9-11 pano | 12 brilho
         13-14 madeira | 15 inscrição
"""
import json
import math
import os

from PIL import Image

from pixelrig import Canvas, OUTLINE, preview, hexc, shade

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "previews")
S = 48
STONE_HI, STONE, STONE_DK = 2, 3, 4
IRON_HI, IRON, IRON_DK = 5, 6, 7
GOLD = 8
CLOTH_HI, CLOTH, CLOTH_DK = 9, 10, 11
GLOW = 12
WOOD, WOOD_DK = 13, 14
INK = 15


def parts(c):
    return dict(
        stone=c.new_part(STONE, STONE_HI, STONE_DK),
        stone_dk=c.new_part(STONE_DK, STONE, OUTLINE),
        iron=c.new_part(IRON, IRON_HI, IRON_DK),
        cloth=c.new_part(CLOTH, CLOTH_HI, CLOTH_DK),
        cloth_dk=c.new_part(CLOTH_DK, CLOTH, OUTLINE),
        wood=c.new_part(WOOD, WOOD, WOOD_DK),
        gold=c.new_part(GOLD, GOLD, IRON_DK),
    )


def keeper(sway):
    """A Vigia: alta, sem rosto, capuz fundo, cajado com lanterna."""
    c = Canvas(S, S)
    p = parts(c)
    cx, fy = 24, 46
    c.limb((cx + 8, fy), (cx + 8 + sway * 0.5, fy - 36), 1.6, p["wood"])
    c.poly([(cx - 6, fy - 26), (cx + 5, fy - 26), (cx + 8, fy), (cx - 9 - sway, fy), (cx - 8, fy - 12)], p["cloth"])
    c.poly([(cx - 7, fy - 27), (cx + 6, fy - 27), (cx + 6, fy - 20), (cx - 8, fy - 19)], p["cloth_dk"])
    c.ellipse((cx, fy - 31), 5.5, 6.0, p["cloth"])
    c.poly([(cx - 3, fy - 36), (cx - 9, fy - 30), (cx - 4, fy - 26)], p["cloth"])
    c.rect(cx - 1, fy - 32, 5, 5, c.new_part(OUTLINE, OUTLINE, OUTLINE))
    c.limb((cx + 3, fy - 22), (cx + 8, fy - 17 + sway * 0.3), 2.6, p["cloth_dk"])
    for i in range(3):
        c.mark(cx - 3 + i * 3, fy - 8, GOLD)
    # lanterna pendurada no cajado
    lx, ly = cx + 8 + sway * 0.5, fy - 36
    c.limb((lx, ly), (lx + 4, ly - 2), 1.2, p["wood"])
    c.rect(lx + 3, ly + 1, 5, 6, p["iron"])
    c.rect(lx + 4, ly + 2, 3, 4, c.new_part(GLOW, GLOW, GLOW))
    c.finish()
    return c


def altar():
    c = Canvas(S, S)
    p = parts(c)
    cx, fy = 24, 46
    c.poly([(cx - 10, fy), (cx - 8, fy - 4), (cx + 8, fy - 4), (cx + 10, fy)], p["stone"])
    c.poly([(cx - 6, fy - 4), (cx - 5, fy - 14), (cx + 5, fy - 14), (cx + 6, fy - 4)], p["stone"])
    c.rect(cx - 9, fy - 17, 18, 3, p["stone"])
    c.rect(cx - 7, fy - 19, 14, 2, p["stone"])
    for i in range(3):
        c.mark(cx - 3 + i * 3, fy - 10, INK)
    c.mark(cx, fy - 8, INK)
    c.finish()
    return c


def pedestal():
    c = Canvas(S, S)
    p = parts(c)
    cx, fy = 24, 46
    c.poly([(cx - 8, fy), (cx - 7, fy - 3), (cx + 7, fy - 3), (cx + 8, fy)], p["stone"])
    c.rect(cx - 4, fy - 7, 8, 4, p["stone"])
    c.rect(cx - 7, fy - 9, 14, 2, p["stone"])
    c.finish()
    return c


def stele(lit):
    c = Canvas(S, S)
    p = parts(c)
    cx, fy = 24, 46
    c.poly([(cx - 7, fy), (cx - 7, fy - 20), (cx - 4, fy - 24), (cx + 4, fy - 24), (cx + 7, fy - 20), (cx + 7, fy)],
           p["stone"])
    c.poly([(cx + 3, fy - 24), (cx + 7, fy - 20), (cx + 7, fy - 14)], c.new_part(0, 0, 0))
    for row in range(4):
        y = fy - 19 + row * 4
        for k in range(3 + (row * 2) % 3):
            c.mark(cx - 4 + k * 2, y, INK if lit else STONE_DK)
    c.rect(cx - 9, fy - 2, 18, 2, p["stone_dk"])
    c.finish()
    return c


def gate(sealed):
    c = Canvas(S, S)
    p = parts(c)
    cx, fy = 24, 46
    for side in (-1, 1):
        x = cx + side * 11
        c.rect(x - 2.5, fy - 34, 5, 34, p["stone"])
        c.rect(x - 3.5, fy - 3, 7, 3, p["stone_dk"])
    for t in range(41):
        a = math.pi * t / 40
        c.ellipse((cx - math.cos(a) * 11, fy - 34 - math.sin(a) * 9), 2.8, 2.5, p["stone"])
    c.rect(cx - 2, fy - 45, 4, 3, p["gold"])
    if sealed:
        c.rect(cx - 8, fy - 38, 16, 38, p["stone_dk"])
        for y in range(fy - 34, fy, 6):
            c.rect(cx - 8, y, 16, 1, c.new_part(OUTLINE, OUTLINE, OUTLINE))
        c.rect(cx - 1, fy - 28, 2, 12, p["iron"])
        c.rect(cx - 4, fy - 23, 8, 2, p["iron"])
    c.finish()
    return c


def brazier():
    c = Canvas(S, S)
    p = parts(c)
    cx, fy = 24, 46
    c.limb((cx - 4, fy), (cx, fy - 8), 1.6, p["iron"])
    c.limb((cx + 4, fy), (cx, fy - 8), 1.6, p["iron"])
    c.limb((cx, fy - 2), (cx, fy - 10), 1.6, p["iron"])
    c.poly([(cx - 7, fy - 14), (cx + 7, fy - 14), (cx + 5, fy - 10), (cx - 5, fy - 10)], p["iron"])
    c.rect(cx - 6, fy - 15, 12, 1, c.new_part(GOLD, GOLD, GOLD))
    c.finish()
    return c


PROPS = {
    "keeper": [keeper(s) for s in (0, 1, 2, 1)],
    "altar": [altar()],
    "pedestal": [pedestal()],
    "stele": [stele(True), stele(False)],
    "gate": [gate(False), gate(True)],
    "brazier": [brazier()],
}

PALETTE = dict(stone="#6b5f58", iron="#3a3236", gold="#d9a93f", cloth="#2b2f3a", glow="#9fe8ff",
               wood="#5b3f2c", ink="#f2c14e")


def props_palette(c):
    pal = [(0, 0, 0)] * 16
    pal[1] = hexc("#0b0910")
    st, ir, cl = hexc(c["stone"]), hexc(c["iron"]), hexc(c["cloth"])
    pal[STONE_HI], pal[STONE], pal[STONE_DK] = shade(st, 0.25), st, shade(st, -0.35)
    pal[IRON_HI], pal[IRON], pal[IRON_DK] = shade(ir, 0.3), ir, shade(ir, -0.4)
    pal[GOLD] = hexc(c["gold"])
    pal[CLOTH_HI], pal[CLOTH], pal[CLOTH_DK] = shade(cl, 0.25), cl, shade(cl, -0.4)
    pal[GLOW] = hexc(c["glow"])
    pal[WOOD], pal[WOOD_DK] = hexc(c["wood"]), shade(hexc(c["wood"]), -0.4)
    pal[INK] = hexc(c["ink"])
    return pal


if __name__ == "__main__":
    rows, meta = [], {}
    for r, (name, frames) in enumerate(PROPS.items()):
        rows.append(frames)
        meta[name] = {"row": r, "frames": len(frames), "fps": 2, "hands": [[[0, 0]]] * len(frames)}
    cols = max(len(f) for f in rows)
    img = Image.new("RGBA", (cols * S, len(rows) * S), (0, 0, 0, 0))
    px = img.load()
    for r, row in enumerate(rows):
        for ci, cv in enumerate(row):
            for y in range(S):
                for x in range(S):
                    if cv.idx[y][x]:
                        px[ci * S + x, r * S + y] = (cv.idx[y][x] * 16 + 8, 0, 0, 255)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, "props.png"))
    with open(os.path.join(OUT, "props.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"size": S, "w": S, "h": S, "anims": meta}, f, indent=1)
    preview(img, [props_palette(PALETTE)], scale=4).save(os.path.join(PREV, "props.png"))
    print("ok")
