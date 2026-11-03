"""Fundo pintado do Mar de Cinzas, em camadas de paralaxe (índices de paleta).

    python tools/gen_backdrop.py

  bd_sky.png   480x270  céu em faixas pontilhadas, sol com halo, véus de cinza
  bd_far.png   960x270  colossos em ruína (bem longe), repete na horizontal
  bd_mid.png   960x270  dunas com ruínas, crista iluminada
  bd_near.png  960x270  dunas escuras com árvores secas

Índices: 1-4 céu (topo -> horizonte) | 5 sol | 6-7 halo | 8-9 longe (corpo, borda
de luz) | 10-12 meio (corpo, crista, sombra) | 13-14 perto (corpo, crista) | 15 véu
"""
import math
import os
import random

from PIL import Image

from pixelrig import hexc, shade

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "previews")
W, H = 480, 270
LW = 960

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dith(x, y, t):
    return t * 16 > BAYER[y % 4][x % 4] + 0.5


def save(name, grid, w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        for x in range(w):
            i = grid[y][x]
            if i:
                px[x, y] = (i * 16 + 8, 0, 0, 255)
    img.save(os.path.join(OUT, name + ".png"))
    return img


def sky():
    g = [[1] * W for _ in range(H)]
    horizon = 205
    for y in range(H):
        t = min(y / horizon, 1.0) * 3.0          # 0..3 entre as 4 faixas
        band = int(t)
        frac = t - band
        for x in range(W):
            idx = 1 + band + (1 if band < 3 and dith(x, y, frac) else 0)
            g[y][x] = min(idx, 4)
    sx, sy = 338, 78
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - sx, (y - sy) * 1.05)
            if d <= 15:
                g[y][x] = 5
            elif d <= 16.5:
                g[y][x] = 6
            elif d <= 26 and dith(x, y, 0.55 - (d - 16) / 25):
                g[y][x] = 6
            elif d <= 44 and dith(x, y, 0.35 - (d - 26) / 60):
                g[y][x] = 7
    # véus de cinza atravessando o céu (e passando na frente do sol)
    rng = random.Random(11)
    for _ in range(7):
        cy = rng.randint(40, 170)
        cx = rng.randint(0, W)
        length = rng.randint(120, 260)
        thick = rng.randint(2, 5)
        for x in range(cx - length // 2, cx + length // 2):
            k = 1 - abs(x - cx) / (length / 2)
            wav = int(math.sin(x * 0.05 + cy) * 2)
            for dy in range(thick):
                y = cy + wav + dy
                xx = x % W
                if 0 <= y < H and dith(xx, y, 0.5 * k * (1 - dy / thick)):
                    g[y][xx] = 15
    return g


def rim(g, w, h, body, light, left_light=None):
    out = [row[:] for row in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] != body:
                continue
            up = g[y - 1][x] if y > 0 else 0
            right = g[y][(x + 1) % w]
            if up == 0 or (right == 0 and y > 0 and g[y - 1][x] in (0, body)):
                out[y][x] = light
            elif left_light and g[y][(x - 1) % w] == 0:
                out[y][x] = left_light
    return out


def fill_poly(g, pts, idx, w):
    ys = [p[1] for p in pts]
    for y in range(max(0, int(min(ys))), min(len(g), int(max(ys)) + 1)):
        py = y + 0.5
        xs = []
        for i in range(len(pts)):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % len(pts)]
            if (y0 <= py < y1) or (y1 <= py < y0):
                xs.append(x0 + (py - y0) * (x1 - x0) / (y1 - y0))
        xs.sort()
        for k in range(0, len(xs) - 1, 2):
            for x in range(int(round(xs[k])), int(round(xs[k + 1]))):
                g[y][x % w] = idx


def ellipse(g, cx, cy, rx, ry, idx, w):
    for y in range(int(cy - ry), int(cy + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            if 0 <= y < len(g) and ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                g[y][x % w] = idx


def far():
    g = [[0] * LW for _ in range(H)]
    base = 214
    B = 8
    # colosso ajoelhado, cabeça partida, segurando uma espada quebrada
    fill_poly(g, [(70, base), (78, 150), (96, 128), (130, 126), (146, 150), (152, base)], B, LW)
    fill_poly(g, [(98, 128), (100, 108), (112, 100), (126, 104), (128, 118), (122, 126)], B, LW)  # cabeça
    fill_poly(g, [(108, 100), (114, 92), (118, 99)], 0, LW)                                       # quebra
    fill_poly(g, [(140, 140), (176, 112), (182, 118), (148, 150)], B, LW)                          # braço
    fill_poly(g, [(176, 70), (184, 70), (186, 120), (178, 120)], B, LW)                            # lâmina
    fill_poly(g, [(170, 116), (192, 116), (192, 121), (170, 121)], B, LW)                          # guarda
    fill_poly(g, [(178, 70), (182, 62), (184, 70)], 0, LW)
    # mão gigante saindo da areia
    for i, (dx, tall) in enumerate(((0, 40), (12, 52), (24, 56), (36, 48), (-14, 26))):
        x0 = 330 + dx
        fill_poly(g, [(x0, base), (x0 + 1, base - tall + 4), (x0 + 5, base - tall),
                      (x0 + 9, base - tall + 4), (x0 + 10, base)], B, LW)
    fill_poly(g, [(318, base), (322, 186), (372, 180), (380, base)], B, LW)
    # arco partido
    fill_poly(g, [(520, base), (520, 120), (536, 120), (536, base)], B, LW)
    fill_poly(g, [(600, base), (600, 150), (616, 146), (616, base)], B, LW)
    for t in range(0, 61):
        a = math.pi * t / 60
        if 0.52 < t / 60 < 0.68:
            continue                      # o pedaço que caiu
        x = 568 - math.cos(a) * 40
        y = 128 - math.sin(a) * 34
        ellipse(g, x, y, 8, 6, B, LW)
    ellipse(g, 574, base - 6, 9, 6, B, LW)   # o pedaço no chão
    fill_poly(g, [(514, 118), (542, 118), (542, 124), (514, 124)], B, LW)
    # obelisco inclinado e uma cabeça de estátua rolada
    fill_poly(g, [(760, base), (790, 96), (800, 92), (806, 100), (784, base)], B, LW)
    ellipse(g, 868, base - 10, 24, 18, B, LW)
    fill_poly(g, [(856, base - 22), (884, base - 24), (882, base - 18), (858, base - 16)], 0, LW)
    # chão longe
    for x in range(LW):
        h = base + int(3 * math.sin(x * math.tau / LW * 3) + 2 * math.sin(x * math.tau / LW * 7))
        for y in range(h, H):
            g[y][x] = B
    return rim(g, LW, H, B, 9)


def dune_layer(base, amp, cycles, body, crest, shadow_idx, seed):
    rng = random.Random(seed)
    phases = [rng.random() * math.tau for _ in cycles]
    g = [[0] * LW for _ in range(H)]
    heights = []
    for x in range(LW):
        h = base
        for (c, a), ph in zip(zip(cycles, amp), phases):
            h -= a * math.sin(x * math.tau / LW * c + ph)
        heights.append(int(h))
    for x in range(LW):
        h = heights[x]
        slope = heights[(x + 1) % LW] - heights[x - 1]
        for y in range(max(h, 0), H):
            g[y][x] = body
            depth = y - h
            if shadow_idx and slope < 0 and depth < 30 and dith(x, y, min(1.0, -slope * 0.6) * (1 - depth / 30)):
                g[y][x] = shadow_idx
        if 0 <= h < H:
            g[h][x] = crest
            if slope > 0 and h + 1 < H:
                g[h + 1][x] = crest
    return g, heights


def mid():
    g, hs = dune_layer(226, (14, 6, 3), (2, 5, 11), 10, 11, 12, 5)
    # pilares quebrados enterrados
    for x0, tall in ((140, 34), (152, 20), (610, 28), (842, 40)):
        top = hs[x0] - tall
        fill_poly(g, [(x0, hs[x0] + 4), (x0, top + 3), (x0 + 3, top), (x0 + 10, top + 4), (x0 + 10, hs[x0] + 4)], 10, LW)
        for y in range(top + 4, hs[x0]):
            g[y][x0 + 8] = 12
    return rim(g, LW, H, 10, 11)


def near():
    g, hs = dune_layer(246, (10, 5), (3, 7), 13, 14, 0, 9)
    for x0 in (210, 700):
        y0 = hs[x0]
        for y in range(y0 - 34, y0):
            g[y][x0] = 13
            g[y][x0 + 1] = 13
        for i, (dy, dx) in enumerate(((-30, -9), (-24, 8), (-17, -7), (-12, 6))):
            y = y0 + dy
            for k in range(abs(dx)):
                xx = x0 + (k if dx > 0 else -k)
                g[y - (k // 3)][xx % LW] = 13
    return g


# --- Forja Rubra --------------------------------------------------------------------

def sky_forja():
    g = sky()
    # sem sol: o brilho vem de baixo (o fogo da forja); apaga o disco
    for y in range(H):
        for x in range(W):
            if g[y][x] in (5, 6, 7):
                t = min(y / 205, 1.0) * 3.0
                band = int(t)
                g[y][x] = min(1 + band + (1 if band < 3 and dith(x, y, t - band) else 0), 4)
    return g


def far_forja():
    g = [[0] * LW for _ in range(H)]
    base, B = 214, 8
    # chaminés com fumaça
    for x0, tall in ((60, 120), (96, 90), (520, 140), (560, 100)):
        fill_poly(g, [(x0, base), (x0 + 2, base - tall), (x0 + 16, base - tall), (x0 + 18, base)], B, LW)
        fill_poly(g, [(x0 - 3, base - tall), (x0 + 21, base - tall), (x0 + 21, base - tall - 6), (x0 - 3, base - tall - 6)], B, LW)
        for k in range(6):
            ellipse(g, x0 + 9 + k * 5, base - tall - 14 - k * 10, 8 + k, 5 + k * 0.6, 15, LW)
    # bigorna gigante
    fill_poly(g, [(250, base), (262, 160), (300, 160), (312, base)], B, LW)
    fill_poly(g, [(220, 160), (340, 160), (352, 148), (330, 140), (232, 140)], B, LW)
    # martelo cravado
    fill_poly(g, [(700, base), (706, 110), (714, 110), (718, base)], B, LW)
    fill_poly(g, [(684, 110), (736, 110), (736, 86), (684, 86)], B, LW)
    # engrenagem meio enterrada
    ellipse(g, 860, base - 10, 34, 34, B, LW)
    for k in range(10):
        a = k * math.tau / 10
        ellipse(g, 860 + math.cos(a) * 38, base - 10 + math.sin(a) * 38, 5, 5, B, LW)
    ellipse(g, 860, base - 10, 10, 10, 0, LW)
    for x in range(LW):
        hh = base + int(3 * math.sin(x * math.tau / LW * 4))
        for y in range(hh, H):
            g[y][x] = B
    return rim(g, LW, H, B, 9)


def mid_forja():
    g, hs = dune_layer(228, (10, 7, 3), (3, 6, 13), 10, 11, 12, 21)
    # canos e correntes saindo da escória
    for x0 in (120, 470, 790):
        top = hs[x0] - 40
        fill_poly(g, [(x0, hs[x0] + 4), (x0, top), (x0 + 6, top), (x0 + 6, hs[x0] + 4)], 10, LW)
        fill_poly(g, [(x0, top), (x0 + 30, top), (x0 + 30, top + 5), (x0, top + 5)], 10, LW)
    return rim(g, LW, H, 10, 11)


def near_forja():
    g, hs = dune_layer(246, (8, 4), (5, 9), 13, 14, 0, 33)
    for x0 in (300, 820):
        y0 = hs[x0]
        fill_poly(g, [(x0 - 10, y0 + 2), (x0 - 6, y0 - 14), (x0 + 8, y0 - 16), (x0 + 12, y0 + 2)], 13, LW)
    return g


# --- Salões do Último Inverno ------------------------------------------------------------

def sky_saloes():
    g = sky()
    # aurora: faixas onduladas no alto
    for band in range(3):
        for x in range(W):
            y0 = 30 + band * 14 + int(8 * math.sin(x * 0.02 + band * 1.3))
            for dy in range(6):
                if dith(x, y0 + dy, 0.45 * (1 - dy / 6)):
                    g[y0 + dy][x] = 15
    return g


def far_saloes():
    g = [[0] * LW for _ in range(H)]
    base, B = 214, 8
    # colunata de um salão gigante, metade caída
    for i, x0 in enumerate(range(30, 330, 60)):
        tall = 150 if i % 2 == 0 else 110
        fill_poly(g, [(x0, base), (x0, base - tall), (x0 + 18, base - tall), (x0 + 18, base)], B, LW)
        fill_poly(g, [(x0 - 4, base - tall), (x0 + 22, base - tall), (x0 + 22, base - tall - 6), (x0 - 4, base - tall - 6)], B, LW)
    fill_poly(g, [(26, 64), (210, 64), (210, 72), (26, 72)], B, LW)
    # gigante preso num bloco de gelo: o gelo é pontilhado claro, o gigante escuro
    block = [[0] * LW for _ in range(H)]
    fill_poly(block, [(500, base), (506, 96), (540, 66), (660, 62), (700, 100), (694, base)], 1, LW)
    giant = [[0] * LW for _ in range(H)]
    ellipse(giant, 566, 104, 13, 14, 1, LW)                                   # cabeça baixa
    fill_poly(giant, [(560, 116), (600, 100), (650, 118), (660, 170), (600, 182), (556, 150)], 1, LW)  # costas
    fill_poly(giant, [(560, 140), (548, 176), (560, 180), (578, 150)], 1, LW)  # braço
    fill_poly(giant, [(600, 176), (660, 168), (676, base), (596, base)], 1, LW)  # perna dobrada
    for y in range(H):
        for x in range(LW):
            if block[y][x]:
                if giant[y][x]:
                    g[y][x] = B
                else:
                    g[y][x] = 9 if dith(x, y, 0.5) else B
    for t in range(40):
        g[min(H - 1, 80 + t * 3)][560 + t * 2] = 9                             # rachadura no gelo
    # pinheiros congelados
    for x0 in (760, 800, 850, 900):
        for k in range(5):
            w = 4 + k * 4
            fill_poly(g, [(x0, base - 70 + k * 12), (x0 - w, base - 56 + k * 12), (x0 + w, base - 56 + k * 12)], B, LW)
        fill_poly(g, [(x0 - 2, base), (x0 - 2, base - 10), (x0 + 2, base - 10), (x0 + 2, base)], B, LW)
    for x in range(LW):
        hh = base + int(2 * math.sin(x * math.tau / LW * 5))
        for y in range(hh, H):
            g[y][x] = B
    return rim(g, LW, H, B, 9)


def mid_saloes():
    g, hs = dune_layer(224, (12, 5, 3), (2, 7, 12), 10, 11, 12, 41)
    for x0 in (180, 420, 700):
        y0 = hs[x0]
        fill_poly(g, [(x0, y0 + 4), (x0 + 4, y0 - 26), (x0 + 8, y0 + 4)], 11, LW)
        fill_poly(g, [(x0 + 10, y0 + 4), (x0 + 13, y0 - 16), (x0 + 16, y0 + 4)], 11, LW)
    return rim(g, LW, H, 10, 11)


def near_saloes():
    g, hs = dune_layer(244, (9, 4), (4, 8), 13, 14, 0, 51)
    for x0 in (150, 620):
        y0 = hs[x0]
        for k in range(4):
            w = 3 + k * 3
            fill_poly(g, [(x0, y0 - 40 + k * 9), (x0 - w, y0 - 28 + k * 9), (x0 + w, y0 - 28 + k * 9)], 13, LW)
    return g


SKIES = {
    "bd_forja": dict(sky0="#1a0c0c", sky1="#3a1612", glow="#b8401c", sun="#ffb050"),
    "bd_saloes": dict(sky0="#0c1220", sky1="#1c2a40", glow="#5a7aa0", sun="#dceaf4"),
}


SKY = dict(sky0="#291f21", sky1="#45332f", glow="#9e6b4c", sun="#f2d49e")


def backdrop_palette(s):
    s0, s1, glow, sun = (hexc(s[k]) for k in ("sky0", "sky1", "glow", "sun"))
    mixc = lambda a, b, t: tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    pal = [(0, 0, 0)] * 16
    pal[1], pal[2] = s0, mixc(s0, s1, 0.6)
    pal[3], pal[4] = mixc(s1, glow, 0.45), glow
    pal[5], pal[6], pal[7] = sun, mixc(sun, glow, 0.45), mixc(glow, sun, 0.25)
    far_body = mixc(s1, glow, 0.35)
    pal[8], pal[9] = far_body, mixc(far_body, sun, 0.25)
    mid_body = mixc(s1, s0, 0.15)
    pal[10], pal[11], pal[12] = mid_body, mixc(mid_body, glow, 0.5), shade(mid_body, -0.25)
    near_body = shade(s0, -0.35)
    pal[13], pal[14] = near_body, mixc(near_body, glow, 0.35)
    pal[15] = mixc(glow, sun, 0.15)
    return pal


def paint(img, pal):
    w, h = img.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src, op = img.load(), out.load()
    for y in range(h):
        for x in range(w):
            r, _, _, a = src[x, y]
            if a:
                op[x, y] = pal[r // 16] + (255,)
    return out


SETS = {
    "bd": (sky, far, mid, near),
    "bd_forja": (sky_forja, far_forja, mid_forja, near_forja),
    "bd_saloes": (sky_saloes, far_saloes, mid_saloes, near_saloes),
}

if __name__ == "__main__":
    import backdrop_dominios
    SKIES.update(backdrop_dominios.SKIES)
    SETS.update(backdrop_dominios.SETS)
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    SKIES["bd"] = SKY
    for prefix, fns in SETS.items():
        pal = backdrop_palette(SKIES[prefix])
        shot = Image.new("RGBA", (W, H))
        for part, fn in zip(("sky", "far", "mid", "near"), fns):
            g = fn()
            w = len(g[0])
            img = save("%s_%s" % (prefix, part), g, w, H)
            shot.alpha_composite(paint(img, pal).crop((420, 0, 420 + W, H)) if w > W else paint(img, pal))
        shot.convert("RGB").resize((W * 2, H * 2), Image.NEAREST).save(os.path.join(PREV, "backdrop_%s.png" % prefix))
    print("ok")
