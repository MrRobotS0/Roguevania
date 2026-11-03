"""Monta um quadro de mentira do jogo (480x270) só com os assets gerados,
para avaliar a arte sem abrir o Godot:

    python tools/mock_frame.py  ->  tools/previews/quadro.png

Mesma conta de luz do jogo: cor do mundo x (penumbra + soma das luzes).
O fundo não recebe luz (fica noutra camada) e é escurecido como no main.gd.
"""
import math
import os
import random

from PIL import Image

import gen_backdrop as bd
import gen_enemies as en
import gen_sprites as hero
import gen_tiles as tiles

HERE = os.path.dirname(__file__)
SPR = os.path.join(HERE, "..", "assets", "sprites")
W, H = 480, 270
AMBIENT = (0.56, 0.52, 0.6)
BACKDROP_TINT = (0.7, 0.66, 0.72)

ROOM = [
    "..............................",
    "..............................",
    "..............................",
    "..............................",
    "......................#####...",
    "......................#####...",
    "..............................",
    "........=====.................",
    "..............................",
    "..............................",
    "..............................",
    "#................####.........",
    "##...............####.........",
    "##############################",
    "##############################",
    "##############################",
    "##############################",
    "##############################",
]


def painted(path, pal):
    img = Image.open(path).convert("RGBA")
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src, op = img.load(), out.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, _, _, a = src[x, y]
            if a:
                op[x, y] = tuple(pal[r // 16]) + (255,)
    return out


def frame(sheet_img, meta, anim, i, w, h):
    a = meta["anims"][anim]
    return sheet_img.crop((i * w, a["row"] * h, (i + 1) * w, (a["row"] + 1) * h))


def main():
    import json
    pal_bd = bd.backdrop_palette(bd.SKY)
    back = Image.new("RGBA", (W, H))
    back.alpha_composite(painted(os.path.join(SPR, "bd_sky.png"), pal_bd))
    for name, off in (("bd_far", 60), ("bd_mid", 200), ("bd_near", 330)):
        layer = painted(os.path.join(SPR, name + ".png"), pal_bd)
        back.alpha_composite(layer.crop((off, 0, off + W, H)))
    back = Image.eval(back.convert("RGB"), lambda v: v)
    bp = back.load()
    for y in range(H):
        for x in range(W):
            r, g, b = bp[x, y]
            bp[x, y] = (int(r * BACKDROP_TINT[0]), int(g * BACKDROP_TINT[1]), int(b * BACKDROP_TINT[2]))

    world = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    atlas = Image.open(os.path.join(SPR, "tiles.png")).convert("RGBA").load()
    tpal = tiles.tile_palette(tiles.ASHSEA)
    rng = random.Random(4)
    rows, cols = len(ROOM), len(ROOM[0])
    solid = lambda x, y: not (0 <= x < cols and 0 <= y < rows) or ROOM[y][x] == "#"
    wp = world.load()
    for y in range(rows):
        for x in range(cols):
            ch = ROOM[y][x]
            if ch == "#":
                mask = (0 if solid(x, y - 1) else 1) | (0 if solid(x + 1, y) else 2) | \
                       (0 if solid(x, y + 1) else 4) | (0 if solid(x - 1, y) else 8)
                if mask == 0 and all(solid(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                    row, col = 16, rng.randrange(8)
                else:
                    row, col = mask, rng.randrange(4)
            elif ch == "=":
                row, col = 17, rng.randrange(4)
            else:
                continue
            for ty in range(16):
                for tx in range(16):
                    r, _, _, a = atlas[col * 16 + tx, row * 16 + ty]
                    X, Y = x * 16 + tx, y * 16 + ty
                    if a and X < W and Y < H:
                        wp[X, Y] = tuple(tpal[r // 16]) + (255,)

    floor = 13 * 16
    hero_meta = json.load(open(os.path.join(SPR, "hero.json")))
    hero_img = painted(os.path.join(SPR, "hero.png"), hero.hero_palette(*hero.SKIN_PREVIEWS["andarilho"]))
    world.alpha_composite(frame(hero_img, hero_meta, "run", 2, 32, 32), (150 - 16, floor - 30))
    for name, anim, i, x, y in (("guard", "windup", 0, 250, floor), ("archer", "aim_lock", 0, 300, 11 * 16),
                                ("pilgrim", "ignite", 1, 400, floor), ("penitent", "walk", 1, 60, 11 * 16 + 16)):
        _, w, h = en.SHEETS[name]
        meta = json.load(open(os.path.join(SPR, name + ".json")))
        img = painted(os.path.join(SPR, name + ".png"), en.enemy_palette(*en.ENEMY_PALETTES[name]))
        world.alpha_composite(frame(img, meta, anim, i, w, h), (x - w // 2, y - h + 2))

    # braseiro simples (o jogo desenha em código)
    bx, by = 205, floor
    for yy in range(by - 13, by):
        wp[bx, yy] = (42, 34, 32, 255)
    for xx in range(bx - 6, bx + 6):
        for yy in range(by - 14, by - 10):
            wp[xx, yy] = (42, 34, 32, 255)
        for yy in range(by - 22, by - 14):
            if (xx + yy) % 3:
                wp[xx, yy] = (255, 154, 60, 255)

    lights = [((150, floor - 12), (1.0, 0.86, 0.68), 136, 0.8),
              ((bx, by - 14), (1.0, 0.62, 0.3), 96, 0.9),
              ((400, floor - 12), (1.0, 0.6, 0.24), 70, 1.2)]
    out = back.copy()
    op = out.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = wp[x, y]
            if not a:
                continue
            lit = list(AMBIENT)
            for (lx, ly), col, rad, en_ in lights:
                d = math.hypot(x - lx, y - ly) / rad
                if d < 1:
                    k = (1 - d) if d > 0.45 else 1 - d * 0.55 / 0.45 * 1.0
                    k = max(0.0, min(1.0, (1 - d) * (1.0 if d > 0.45 else 1.0)))
                    for c in range(3):
                        lit[c] += col[c] * en_ * k * 0.6
            op[x, y] = tuple(min(255, int(v * l)) for v, l in zip((r, g, b), lit))
    out.resize((W * 2, H * 2), Image.NEAREST).save(os.path.join(HERE, "previews", "quadro.png"))
    print("ok")


if __name__ == "__main__":
    main()
