"""Tileset de pedra (blocos de 16x16) em índices de paleta: cada bioma pinta
com as próprias cores. Sai assets/sprites/tiles.png e uma prévia.

    python tools/gen_tiles.py

Linhas do atlas:
  0..15  rocha exposta, uma linha por "máscara" de lados abertos
         (bit 1 = em cima, 2 = direita, 4 = embaixo, 8 = esquerda), 4 variações
  16     rocha enterrada (fundo da parede), 8 variações
  17     prancha (plataforma), 4 variações

Índices: 1 rejunte | 2 luz | 3 topo | 4 pedra | 5 meio-escuro | 6 sombra
         7 fundo | 8 fundo escuro | 9 cinza | 10 cinza escura | 11 veio de vidro
         12 osso | 13-15 madeira (topo, base, escura)
"""
import os
import random

from PIL import Image

from pixelrig import preview, hexc, shade

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "previews")
T = 16
VARIANTS = 4

MORTAR, LIGHT, TOP, STONE, MID, SHADOW, DEEP, DEEP_DK, ASH, ASH_DK, VEIN, BONE, WTOP, WOOD, WDK = range(1, 16)


def blank():
    return [[0] * T for _ in range(T)]


def masonry(rng):
    """Blocos irregulares: duas fileiras de altura 7/9 ou 8/8, larguras variadas."""
    g = [[STONE] * T for _ in range(T)]
    split = rng.choice([7, 8, 8, 9])
    rows = [(0, split), (split, T - split)]
    for ri, (y0, hh) in enumerate(rows):
        x = -rng.randint(0, 6)
        while x < T:
            bw = rng.choice([6, 7, 8, 9, 10])
            tone = rng.choice([STONE, STONE, STONE, MID])
            for yy in range(y0, y0 + hh):
                for xx in range(max(x, 0), min(x + bw, T)):
                    g[yy][xx] = tone
            # luz no canto de cima/esquerda do bloco, sombra embaixo/direita
            for xx in range(max(x + 1, 0), min(x + bw - 1, T)):
                if 0 <= y0 + 1 < T:
                    g[y0 + 1][xx] = TOP if tone == STONE else STONE
                g[y0 + hh - 2][xx] = SHADOW if rng.random() < 0.7 else MID
            for yy in range(y0 + 1, y0 + hh - 1):
                if 0 <= x + 1 < T:
                    g[yy][x + 1] = TOP if tone == STONE and rng.random() < 0.6 else g[yy][x + 1]
                if 0 <= x + bw - 2 < T:
                    g[yy][x + bw - 2] = SHADOW if rng.random() < 0.6 else g[yy][x + bw - 2]
            # rejunte
            for yy in range(y0, y0 + hh):
                if 0 <= x + bw - 1 < T:
                    g[yy][x + bw - 1] = MORTAR
            for xx in range(max(x, 0), min(x + bw, T)):
                g[y0 + hh - 1][xx] = MORTAR
            # lasca no canto
            if rng.random() < 0.15:
                cxk = x + (1 if rng.random() < 0.5 else bw - 3)
                for dy in range(2):
                    for dx in range(2 - dy):
                        yy, xx = y0 + 1 + dy, cxk + dx
                        if 0 <= xx < T and 0 <= yy < T:
                            g[yy][xx] = SHADOW
            # rachadura
            if rng.random() < 0.12:
                xx, yy = x + rng.randint(2, max(2, bw - 3)), y0 + 2
                for _ in range(hh - 4):
                    if 0 <= xx < T and 0 <= yy < T:
                        g[yy][xx] = MORTAR
                    yy += 1
                    xx += rng.choice([-1, 0, 0, 1])
            x += bw
    # pontinhos de textura
    for _ in range(4):
        xx, yy = rng.randrange(T), rng.randrange(T)
        if g[yy][xx] in (STONE, MID):
            g[yy][xx] = MID if g[yy][xx] == STONE else STONE
    return g


def exposed(mask, rng):
    g = masonry(rng)
    up, right, down, left = bool(mask & 1), bool(mask & 2), bool(mask & 4), bool(mask & 8)
    if left:
        for y in range(T):
            g[y][0] = LIGHT if g[y][0] != MORTAR else TOP
            if g[y][1] == MORTAR:
                g[y][1] = SHADOW
    if right:
        for y in range(T):
            g[y][T - 1] = MORTAR
            g[y][T - 2] = SHADOW if g[y][T - 2] != MORTAR else MORTAR
    if down:
        for x in range(T):
            g[T - 1][x] = MORTAR
            g[T - 2][x] = SHADOW
            if rng.random() < 0.18:
                g[T - 3][x] = SHADOW
    if up:
        # camada de cinza assentada por cima, com bordas irregulares escorrendo
        for x in range(T):
            depth = 2 + (1 if rng.random() < 0.35 else 0) + (1 if rng.random() < 0.12 else 0)
            g[0][x] = LIGHT if rng.random() < 0.8 else ASH
            for y in range(1, depth):
                g[y][x] = ASH if y < depth - 1 else ASH_DK
            g[depth][x] = SHADOW if g[depth][x] != MORTAR else MORTAR
        for _ in range(2):
            x = rng.randrange(1, T - 1)
            g[0][x] = ASH
        if left:
            g[0][0] = TOP
        if right:
            g[0][T - 1] = ASH_DK
    return g


def buried(rng, k):
    g = [[DEEP] * T for _ in range(T)]
    for _ in range(12):
        x, y = rng.randrange(T), rng.randrange(T)
        g[y][x] = DEEP_DK
    # pedras grandes meio afundadas
    for _ in range(rng.randint(0, 1) + (1 if k % 3 == 0 else 0)):
        cx, cy = rng.randint(3, 12), rng.randint(3, 12)
        rx, ry = rng.randint(2, 4), rng.randint(2, 3)
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                if 0 <= x < T and 0 <= y < T and ((x - cx) / (rx + .5)) ** 2 + ((y - cy) / (ry + .5)) ** 2 <= 1:
                    edge_top = ((x - cx) / (rx + .5)) ** 2 + ((y - 1 - cy) / (ry + .5)) ** 2 > 1
                    edge_bot = ((x - cx) / (rx + .5)) ** 2 + ((y + 1 - cy) / (ry + .5)) ** 2 > 1
                    g[y][x] = SHADOW if edge_top else (MORTAR if edge_bot else MID if (x + y) % 3 else SHADOW)
    if k % 8 == 1:
        # osso enterrado
        y = rng.randint(4, 11)
        x0 = rng.randint(2, 6)
        for x in range(x0, x0 + 7):
            g[y][x] = BONE
        for dy in (-1, 1):
            g[y + dy][x0] = BONE
            g[y + dy][x0 + 6] = BONE
    if k % 8 == 2:
        # veio de vidro
        x, y = rng.randint(1, 5), rng.randint(2, 13)
        step = rng.choice([-1, 1])
        for _ in range(9):
            if 0 <= x < T and 0 <= y < T:
                g[y][x] = VEIN
            x += 1
            if rng.random() < 0.6:
                y += step
    return g


def plank(rng):
    g = blank()
    for x in range(T):
        g[0][x] = WTOP
        for y in range(1, 4):
            g[y][x] = WOOD
        g[4][x] = WDK
    for _ in range(3):
        g[rng.randint(1, 3)][rng.randrange(T)] = WDK
    if rng.random() < 0.6:
        x = rng.randint(2, 12)
        for y in range(5, 10):
            g[y][x] = WDK
            g[y][x + 1] = WOOD
    g[2][rng.randint(3, 12)] = MORTAR
    return g


def build():
    rng = random.Random(7)
    rows = []
    for mask in range(16):
        rows.append([exposed(mask, rng) for _ in range(VARIANTS)])
    rows.append([buried(rng, k) for k in range(8)])
    rows.append([plank(rng) for _ in range(VARIANTS)])
    cols = max(len(r) for r in rows)
    img = Image.new("RGBA", (cols * T, len(rows) * T), (0, 0, 0, 0))
    px = img.load()
    for r, row in enumerate(rows):
        for c, g in enumerate(row):
            for y in range(T):
                for x in range(T):
                    if g[y][x]:
                        px[c * T + x, r * T + y] = (g[y][x] * 16 + 8, 0, 0, 255)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, "tiles.png"))
    return img


# cores do Mar de Cinzas (as mesmas do biome.tres) para a prévia
ASHSEA = dict(light="#d1ba99", top="#9e856b", stone="#6b574a", shadow="#291f1c", deep="#332624",
              moss="#bfb8ad", vein="#bfe6ea", bone="#c8bca4", wood_top="#8c6647", wood="#5c402e", wood_dark="#38261a")


def tile_palette(c):
    stone = hexc(c["stone"])
    deep = hexc(c["deep"])
    ash = hexc(c["moss"])
    pal = [(0, 0, 0)] * 16
    pal[MORTAR] = shade(hexc(c["shadow"]), -0.3)
    pal[LIGHT], pal[TOP], pal[STONE] = hexc(c["light"]), hexc(c["top"]), stone
    pal[MID], pal[SHADOW] = shade(stone, -0.18), hexc(c["shadow"])
    pal[DEEP], pal[DEEP_DK] = deep, shade(deep, -0.3)
    pal[ASH], pal[ASH_DK] = ash, shade(ash, -0.3)
    pal[VEIN], pal[BONE] = hexc(c["vein"]), shade(hexc(c["bone"]), -0.35)
    pal[WTOP], pal[WOOD], pal[WDK] = hexc(c["wood_top"]), hexc(c["wood"]), hexc(c["wood_dark"])
    return pal


def demo_room(img, pal):
    """Monta uma sala de mentira com o atlas, para conferir os encaixes."""
    room = [
        "##########################",
        "#........................#",
        "#........................#",
        "#..........######........#",
        "#..........######........#",
        "#....====.........====...#",
        "#........................#",
        "##.......................#",
        "###..............#####...#",
        "####.............#####...#",
        "##########################",
        "##########################",
        "##########################",
    ]
    h, w = len(room), len(room[0])
    src = img.load()
    out = Image.new("RGB", (w * T, h * T), (60, 44, 40))
    op = out.load()
    rng = random.Random(3)

    def solid(x, y):
        return not (0 <= x < w and 0 <= y < h) or room[y][x] == "#"

    for y in range(h):
        for x in range(w):
            ch = room[y][x]
            if ch == "#":
                mask = (0 if solid(x, y - 1) else 1) | (0 if solid(x + 1, y) else 2) | \
                       (0 if solid(x, y + 1) else 4) | (0 if solid(x - 1, y) else 8)
                row = mask
                if mask == 0 and all(solid(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                    row, col = 16, rng.randrange(8)
                else:
                    col = rng.randrange(VARIANTS)
            elif ch == "=":
                row, col = 17, rng.randrange(VARIANTS)
            else:
                continue
            for ty in range(T):
                for tx in range(T):
                    r, _, _, a = src[col * T + tx, row * T + ty]
                    if a:
                        op[x * T + tx, y * T + ty] = pal[r // 16]
    return out.resize((w * T * 3, h * T * 3), Image.NEAREST)


if __name__ == "__main__":
    img = build()
    os.makedirs(PREV, exist_ok=True)
    pal = tile_palette(ASHSEA)
    preview(img, [pal], scale=4).save(os.path.join(PREV, "tiles.png"))
    demo_room(img, pal).save(os.path.join(PREV, "tiles_sala.png"))
    print("ok")
