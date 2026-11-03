"""Fundos dos quatro domínios novos (usado por gen_backdrop.py)."""
import math
import random

from gen_backdrop import H, W, LW, dith, dune_layer, ellipse, fill_poly, rim, sky


def _no_sun(g):
    for y in range(H):
        for x in range(W):
            if g[y][x] in (5, 6, 7):
                t = min(y / 205, 1.0) * 3.0
                band = int(t)
                g[y][x] = min(1 + band + (1 if band < 3 and dith(x, y, t - band) else 0), 4)
    return g


def _ground(g, base, B, wobble=2, cycles=3):
    for x in range(LW):
        for y in range(base + int(wobble * math.sin(x * math.tau / LW * cycles)), H):
            g[y][x] = B


# --- Torre de Babel ---------------------------------------------------------------

def far_torre():
    g = [[0] * LW for _ in range(H)]
    base, B = 214, 8
    cx = 300
    tiers = 9
    for i in range(tiers):
        w = 150 - i * 15
        top = base - (i + 1) * 20
        fill_poly(g, [(cx - w, top + 20), (cx - w + 6, top), (cx + w - 6, top), (cx + w, top + 20)], B, LW)
        for k in range(-w + 10, w - 10, 14):
            fill_poly(g, [(cx + k, top + 6), (cx + k + 5, top + 6), (cx + k + 5, top + 14), (cx + k, top + 14)], 0, LW)
    fill_poly(g, [(cx - 6, base - tiers * 20), (cx + 8, base - tiers * 20 - 26), (cx + 12, base - tiers * 20)], B, LW)
    for x0 in (640, 760, 880):
        fill_poly(g, [(x0, base), (x0, base - 70), (x0 + 4, base - 70), (x0 + 4, base)], B, LW)
        fill_poly(g, [(x0 - 20, base - 60), (x0 + 24, base - 60), (x0 + 24, base - 56), (x0 - 20, base - 56)], B, LW)
    _ground(g, base, B)
    return rim(g, LW, H, B, 9)


def mid_torre():
    g, hs = dune_layer(226, (8, 5, 2), (3, 6, 11), 10, 11, 12, 61)
    for x0 in (90, 400, 720):
        y0 = hs[x0]
        for k in range(4):
            fill_poly(g, [(x0 + k * 6, y0 + 4), (x0 + k * 6, y0 - 10 - k * 8),
                          (x0 + 60 - k * 6, y0 - 10 - k * 8), (x0 + 60 - k * 6, y0 + 4)], 10, LW)
    return rim(g, LW, H, 10, 11)


def near_torre():
    g, hs = dune_layer(246, (7, 4), (4, 9), 13, 14, 0, 71)
    for x0 in (260, 780):
        y0 = hs[x0]
        fill_poly(g, [(x0, y0 + 2), (x0, y0 - 30), (x0 + 10, y0 - 34), (x0 + 12, y0 + 2)], 13, LW)
    return g


# --- Jardim Primordial --------------------------------------------------------------

def far_jardim():
    g = [[0] * LW for _ in range(H)]
    base, B = 214, 8
    for x0, tall, crown in ((120, 150, 70), (430, 170, 80), (760, 140, 64)):
        fill_poly(g, [(x0 - 14, base), (x0 - 8, base - tall), (x0 + 8, base - tall), (x0 + 16, base)], B, LW)
        for k in range(9):
            a = k * math.tau / 9
            ellipse(g, x0 + math.cos(a) * crown * 0.7, base - tall - 10 + math.sin(a) * crown * 0.35,
                    crown * 0.42, crown * 0.3, B, LW)
        for side in (-1, 1):
            fill_poly(g, [(x0, base - 6), (x0 + side * 40, base), (x0 + side * 12, base)], B, LW)
    _ground(g, base, B, 3, 4)
    return rim(g, LW, H, B, 9)


def mid_jardim():
    g, hs = dune_layer(226, (12, 6, 3), (2, 5, 9), 10, 11, 12, 81)
    for x0 in range(40, LW, 120):
        y0 = hs[x0]
        for k in range(5):
            a = -1.2 + k * 0.6
            for r in range(26):
                xx, yy = int(x0 + math.sin(a) * r), int(y0 - math.cos(a) * r * 1.3)
                if 0 <= yy < H:
                    g[yy][xx % LW] = 11 if r > 20 else 10
    return g


def near_jardim():
    g, hs = dune_layer(248, (6, 3), (5, 11), 13, 14, 0, 91)
    for x in range(0, LW, 3):
        y0 = hs[x]
        tall = 4 + (x * 7919) % 9
        for k in range(tall):
            if 0 <= y0 - k < H:
                g[y0 - k][(x + k // 3) % LW] = 13
    return g


# --- Carcosa ------------------------------------------------------------------------

def sky_carcosa():
    g = _no_sun(sky())
    # dois sóis negros com coroa amarela
    for sx, sy, r in ((150, 70, 18), (330, 96, 12)):
        for y in range(H):
            for x in range(W):
                d = math.hypot(x - sx, y - sy)
                if d <= r:
                    g[y][x] = 1
                elif d <= r + 2:
                    g[y][x] = 5
                elif d <= r + 14 and dith(x, y, 0.5 - (d - r) / 30):
                    g[y][x] = 6
    return g


def far_carcosa():
    g = [[0] * LW for _ in range(H)]
    base, B = 214, 8
    rng = random.Random(5)
    x = 0
    while x < LW - 30:
        w = rng.randint(14, 30)
        tall = rng.randint(50, 140)
        lean = rng.randint(-8, 8)
        fill_poly(g, [(x, base), (x + 2 + lean, base - tall), (x + w // 2 + lean, base - tall - 18),
                      (x + w - 2 + lean, base - tall), (x + w, base)], B, LW)
        x += w + rng.randint(4, 30)
    _ground(g, base, B, 0)
    return rim(g, LW, H, B, 9)


def mid_carcosa():
    g, hs = dune_layer(230, (6, 4), (3, 8), 10, 11, 12, 101)
    for x0 in (150, 520, 820):
        y0 = hs[x0]
        for t in range(41):
            a = math.pi * t / 40
            ellipse(g, x0 + 30 - math.cos(a) * 30, y0 - 40 - math.sin(a) * 26, 4, 4, 10, LW)
        fill_poly(g, [(x0 - 4, y0 + 4), (x0 - 4, y0 - 40), (x0 + 4, y0 - 40), (x0 + 4, y0 + 4)], 10, LW)
        fill_poly(g, [(x0 + 56, y0 + 4), (x0 + 56, y0 - 40), (x0 + 64, y0 - 40), (x0 + 64, y0 + 4)], 10, LW)
    return rim(g, LW, H, 10, 11)


def near_carcosa():
    g, hs = dune_layer(246, (8, 3), (4, 10), 13, 14, 0, 111)
    for x0 in range(30, LW, 90):
        y0 = hs[x0]
        fill_poly(g, [(x0, y0 + 2), (x0 + 3, y0 - 22), (x0 + 6, y0 + 2)], 13, LW)
    return g


# --- Observatório Celeste ---------------------------------------------------------------

def sky_observatorio():
    g = _no_sun(sky())
    rng = random.Random(9)
    for x in range(W):                     # faixa da galáxia
        yc = 40 + x * 0.25 + 10 * math.sin(x * 0.02)
        for dy in range(-12, 13):
            y = int(yc + dy)
            if 0 <= y < H and dith(x, y, 0.4 * (1 - abs(dy) / 12)):
                g[y][x] = 15
    for _ in range(160):
        x, y = rng.randrange(W), rng.randrange(170)
        g[y][x] = 5 if rng.random() < 0.3 else 6
    return g


def far_observatorio():
    g = [[0] * LW for _ in range(H)]
    base, B = 214, 8
    cx = 360
    fill_poly(g, [(cx - 90, base), (cx - 90, base - 70), (cx + 90, base - 70), (cx + 90, base)], B, LW)
    ellipse(g, cx, base - 70, 80, 64, B, LW)
    fill_poly(g, [(cx + 10, base - 110), (cx + 120, base - 190), (cx + 130, base - 178), (cx + 24, base - 98)], B, LW)
    fill_poly(g, [(cx - 2, base - 134), (cx + 2, base - 134), (cx + 2, base - 70), (cx - 2, base - 70)], 0, LW)
    for x0 in (700, 820):
        for t in range(61):
            a = math.tau * t / 60
            ellipse(g, x0 + math.cos(a) * 40, base - 70 + math.sin(a) * 40, 2.5, 2.5, B, LW)
        fill_poly(g, [(x0 - 3, base), (x0 - 3, base - 70), (x0 + 3, base - 70), (x0 + 3, base)], B, LW)
    _ground(g, base, B, 0)
    return rim(g, LW, H, B, 9)


def mid_observatorio():
    g, hs = dune_layer(228, (10, 4), (2, 7), 10, 11, 12, 121)
    return rim(g, LW, H, 10, 11)


def near_observatorio():
    g, hs = dune_layer(246, (9, 4), (3, 9), 13, 14, 0, 131)
    return g


SKIES = {
    "bd_torre": dict(sky0="#1a1630", sky1="#3a2e4a", glow="#c09a5a", sun="#f2dca0"),
    "bd_jardim": dict(sky0="#0e1a18", sky1="#1e3a2e", glow="#6aa06a", sun="#e8f0b0"),
    "bd_carcosa": dict(sky0="#120c10", sky1="#2a1a20", glow="#b8a040", sun="#f0e070"),
    "bd_observatorio": dict(sky0="#060814", sky1="#101a36", glow="#3a4a8a", sun="#e8f0ff"),
}

SETS = {
    "bd_torre": (sky, far_torre, mid_torre, near_torre),
    "bd_jardim": (sky, far_jardim, mid_jardim, near_jardim),
    "bd_carcosa": (sky_carcosa, far_carcosa, mid_carcosa, near_carcosa),
    "bd_observatorio": (sky_observatorio, far_observatorio, mid_observatorio, near_observatorio),
}
