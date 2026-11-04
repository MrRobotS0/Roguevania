"""Fundos em cor cheia, um conjunto por domínio, em camadas de paralaxe.

    python tools/pintar_fundos.py            todos
    python tools/pintar_fundos.py saloes     só um

Grava assets/sprites/<prefixo>_cor_{sky,far,mid,near}.png (o jogo prefere
estas às silhuetas antigas) e tools/previews/fundo_<prefixo>.png com as
camadas montadas.

Como cada camada é pintada:
  1. formas em máscara (polígonos, elipses) — o desenho do domínio;
  2. luz: borda acesa do lado do sol, sombra do lado oposto, degradê de
     cima para baixo dentro da forma, textura de ruído e detalhes (tijolo,
     janela, galho);
  3. névoa: quanto mais longe, mais a cor vira a cor do horizonte;
  4. pontilhado ordenado (Bayer) com poucos tons por canal: o acabamento de
     pixel art, sem degradê liso.
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "previews")
W, H, LW = 480, 270, 960

BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 - 0.47


def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=float) / 255.0


def mix(a, b, t):
    return a + (b - a) * t


# --- ruído ------------------------------------------------------------------------

def noise(w, h, cell, seed, wrap=True):
    rng = np.random.default_rng(seed)
    gw, gh = max(2, w // cell + 2), max(2, h // cell + 2)
    g = rng.random((gh, gw))
    if wrap:
        g[:, -2:] = g[:, :2]
    img = Image.fromarray((g * 255).astype(np.uint8)).resize(((gw - 1) * cell, (gh - 1) * cell), Image.BICUBIC)
    return np.asarray(img, dtype=float)[:h, :w] / 255.0


def fbm(w, h, seed, base=64, octaves=4):
    out = np.zeros((h, w))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        out += noise(w, h, max(2, base >> o), seed + o * 17) * amp
        total += amp
        amp *= 0.5
    return out / total


# --- máscaras ---------------------------------------------------------------------

class Layer:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.rgb = np.zeros((h, w, 3))
        self.a = np.zeros((h, w))

    def mask(self):
        return Image.new("L", (self.w, self.h), 0)

    def paint(self, m, color, alpha=1.0):
        m = np.asarray(m, dtype=float) / 255.0 if not isinstance(m, np.ndarray) else m
        m = m * alpha
        self.rgb = self.rgb * (1 - m[..., None]) + np.broadcast_to(color, self.rgb.shape) * m[..., None]
        self.a = np.maximum(self.a, m)

    def paint_rgb(self, m, rgb):
        m = m[..., None]
        self.rgb = self.rgb * (1 - m) + rgb * m
        self.a = np.maximum(self.a, m[..., 0])


def wrap_draw(d, w, fn):
    """Desenha 3 vezes (x-w, x, x+w): a camada repete sem costura."""
    for off in (-w, 0, w):
        fn(d, off)


def shaded(layer, m_img, base, light, shadow, sun_dx, texture=None, grad=0.25, rim_w=1):
    """Pinta a forma com luz de um lado, sombra do outro e degradê vertical."""
    m = np.asarray(m_img, dtype=float) / 255.0
    if m.max() == 0:
        return m
    h, w = m.shape
    ys = np.linspace(0, 1, h)[:, None]
    body = np.broadcast_to(base, (h, w, 3)).copy()
    body *= (1.0 - grad * ys)[..., None]
    if texture is not None:
        body *= (0.85 + 0.3 * texture)[..., None]
    side = int(math.copysign(1, sun_dx)) if sun_dx else 1
    lit = m.copy()
    for k in range(1, rim_w + 1):
        lit = lit * np.roll(m, side * k, axis=1)
    up = m * np.roll(m, 1, axis=0)
    rim = np.clip(m - lit * up, 0, 1)
    dark = np.clip(m - m * np.roll(m, -side * 2, axis=1), 0, 1)
    body = body * (1 - dark[..., None] * 0.6) + shadow * dark[..., None] * 0.6
    body = body * (1 - rim[..., None]) + light * rim[..., None]
    layer.paint_rgb(m, body)
    return m


def haze(layer, color, amount, top_fade=0.0):
    """Névoa: puxa tudo para a cor do horizonte; mais forte embaixo."""
    h = layer.h
    ys = np.linspace(0, 1, h)[:, None, None]
    t = amount + top_fade * (1 - ys)
    layer.rgb = mix(layer.rgb, color, np.clip(t, 0, 1))


def fog_band(layer, y, thick, color, alpha, seed):
    n = noise(layer.w, layer.h, 24, seed)
    ys = np.arange(layer.h)[:, None]
    band = np.exp(-((ys - y) / thick) ** 2) * alpha * (0.6 + 0.6 * n)
    band = np.clip(band, 0, 1)
    layer.rgb = layer.rgb * (1 - band[..., None]) + color * band[..., None]
    layer.a = np.maximum(layer.a, band * 0.9)


def finish(layer, levels=10):
    """Acabamento de pixel art: tons contados e pontilhado ordenado."""
    h, w = layer.h, layer.w
    t = np.tile(BAYER, (h // 4 + 1, w // 4 + 1))[:h, :w][..., None]
    q = np.floor(np.clip(layer.rgb, 0, 1) * (levels - 1) + 0.5 + t * 0.9) / (levels - 1)
    a = (layer.a > 0.5).astype(float)
    out = np.dstack([np.clip(q, 0, 1), a])
    return Image.fromarray((out * 255).astype(np.uint8), "RGBA")


# --- céu --------------------------------------------------------------------------

def sky(p, seed):
    s = Layer(W, H)
    ys = np.linspace(0, 1, H)[:, None]
    top, mid, hor = p["sky0"], p["sky1"], p["glow"]
    y3 = ys[..., None]
    grad = np.where(y3 < 0.55, mix(top, mid, y3 / 0.55), mix(mid, hor, (y3 - 0.55) / 0.45))
    s.rgb = np.broadcast_to(grad, (H, W, 3)).copy()
    s.a[:] = 1
    sx, sy = p["sun_at"]
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.hypot(xx - sx, (yy - sy) * 1.1)
    if p.get("rays"):
        ang = np.arctan2(yy - sy, xx - sx)
        rays = (np.sin(ang * 13 + seed) * 0.5 + 0.5) ** 6 * np.clip(1 - d / 300, 0, 1) * 0.22
        s.rgb = s.rgb + (p["sun"] - s.rgb) * rays[..., None]
    halo = np.clip(1 - d / p.get("halo", 90), 0, 1) ** 2
    s.rgb = mix(s.rgb, p["sun"], halo[..., None] * 0.55)
    # nuvens: ruído recortado, com a borda de cima acesa
    if p.get("clouds", 0) > 0:
        n = fbm(W, H, seed + 3, 96)
        band = np.exp(-((ys - p.get("cloud_y", 0.3)) / 0.16) ** 2)
        c = np.clip((n * band - (1 - p["clouds"]) * 0.55) * 4, 0, 1)
        lit = np.clip(c - np.roll(c, 2, axis=0), 0, 1)
        cloud_col = mix(p["sky1"], p["glow"], 0.35)
        s.rgb = mix(s.rgb, cloud_col, c[..., None] * 0.75)
        s.rgb = mix(s.rgb, p["sun"], lit[..., None] * 0.45)
    if p.get("stars"):
        rng = np.random.default_rng(seed)
        for _ in range(p["stars"]):
            x, y = rng.integers(0, W), rng.integers(0, int(H * 0.75))
            b = rng.random()
            s.rgb[y, x] = mix(s.rgb[y, x], np.array([1.0, 1.0, 1.0]), 0.4 + 0.6 * b)
            if b > 0.93 and 1 <= x < W - 1 and 1 <= y < H - 1:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    s.rgb[y + dy, x + dx] = mix(s.rgb[y + dy, x + dx], np.array([1.0, 1.0, 1.0]), 0.45)
    disk = d < p.get("sun_r", 14)
    if p.get("black_sun"):
        ring = (d < p["sun_r"] + 2) & ~disk
        s.rgb[ring] = p["sun"]
        s.rgb[disk] = p["sky0"] * 0.4
        d2 = np.hypot(xx - sx + 120, (yy - sy + 25) * 1.1)
        s.rgb[(d2 < 9) & (d2 >= 7)] = p["sun"]
        s.rgb[d2 < 7] = p["sky0"] * 0.4
    elif p.get("sun_r", 14) > 0:
        s.rgb[disk] = mix(p["sun"], np.array([1.0, 1.0, 1.0]), 0.3)
    return s


# --- motivos por domínio ------------------------------------------------------------

def dunes(layer, base_y, amp, seed, col, light, shadow, sun_dx, tex=0.4):
    m = layer.mask()
    d = ImageDraw.Draw(m)
    rng = random.Random(seed)
    phase = [rng.random() * 6 for _ in range(3)]
    pts = []
    for x in range(0, layer.w + 1, 4):
        t = x / layer.w * math.tau
        y = base_y + amp * (0.6 * math.sin(t * 2 + phase[0]) + 0.3 * math.sin(t * 5 + phase[1]) + 0.15 * math.sin(t * 11 + phase[2]))
        pts.append((x, y))
    d.polygon(pts + [(layer.w, layer.h), (0, layer.h)], fill=255)
    shaded(layer, m, col, light, shadow, sun_dx, fbm(layer.w, layer.h, seed, 32) if tex else None)


def building_detail(layer, m, color, every=5, seed=0):
    """Fiadas de tijolo e juntas: linhas escuras dentro da forma."""
    arr = np.asarray(m, dtype=float) / 255.0
    rows = np.zeros_like(arr)
    rows[::every] = 1
    rng = np.random.default_rng(seed)
    cols = np.zeros_like(arr)
    for y in range(0, layer.h, every):
        off = rng.integers(0, 8)
        cols[y:y + every, off::9] = 1
    lines = np.clip(rows + cols, 0, 1) * arr * 0.45
    layer.rgb = layer.rgb * (1 - lines[..., None]) + color * lines[..., None]


def windows(layer, rects, color, seed):
    rng = random.Random(seed)
    for (x, y, w, h) in rects:
        for _ in range(int(w * h / 90)):
            wx, wy = x + rng.randint(2, max(2, w - 3)), y + rng.randint(3, max(3, h - 5))
            if 0 <= wx < layer.w - 1 and 0 <= wy < layer.h - 2 and layer.a[wy, wx] > 0.5:
                layer.rgb[wy:wy + 2, wx] = color


def motif_mar(L, p, which):
    sun_dx = 1
    if which == "far":
        # o deus sentado: um colosso em ruínas, sem cabeça, braço ainda erguido
        m = L.mask()
        d = ImageDraw.Draw(m)
        def god(d, o):
            x = 300 + o
            d.polygon([(x - 70, 200), (x - 60, 120), (x - 40, 95), (x + 40, 95), (x + 60, 120), (x + 70, 200)], fill=255)
            d.polygon([(x + 40, 100), (x + 58, 70), (x + 62, 30), (x + 70, 28), (x + 66, 75), (x + 52, 110)], fill=255)
            d.polygon([(x - 40, 98), (x - 75, 140), (x - 80, 175), (x - 68, 176), (x - 62, 142), (x - 34, 118)], fill=255)
            d.rectangle([x - 18, 82, x + 14, 96], fill=255)
            d.polygon([(x - 95, 200), (x - 85, 185), (x + 85, 185), (x + 95, 200)], fill=255)
            for k in range(4):
                d.rectangle([x + 140 + k * 26, 150 - k * 6, x + 148 + k * 26, 200], fill=255)
            d.arc([x - 230, 120, x - 160, 200], 180, 360, fill=255, width=8)
            d.rectangle([x - 230, 160, x - 222, 200], fill=255)
        wrap_draw(d, L.w, god)
        shaded(L, m, mix(p["sky1"], p["glow"], 0.4), mix(p["sun"], p["glow"], 0.4), p["sky0"], sun_dx,
               fbm(L.w, L.h, 5, 16), rim_w=2)
        building_detail(L, m, mix(p["sky1"], p["sky0"], 0.5), 6, 3)
        dunes(L, 205, 8, 11, mix(p["sky1"], p["glow"], 0.3), mix(p["sun"], p["glow"], 0.5), p["sky0"], sun_dx)
    elif which == "mid":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def ruins(d, o):
            # colunatas quebradas: alturas diferentes, topo partido em diagonal
            for k, x in enumerate((40, 250, 520, 760)):
                x += o
                for c in range(3):
                    hh = 40 + ((k * 3 + c) * 23) % 45
                    cx = x + c * 22
                    d.polygon([(cx, 215), (cx, 215 - hh), (cx + 10, 215 - hh - 6 + (c % 2) * 10), (cx + 10, 215)], fill=255)
                    d.rectangle([cx - 2, 211, cx + 12, 215], fill=255)
                d.rectangle([x - 4, 215 - 52, x + 34, 215 - 47], fill=255)
        wrap_draw(d, L.w, ruins)
        shaded(L, m, mix(p["sky1"], p["sky0"], 0.3), p["glow"], p["sky0"], sun_dx, fbm(L.w, L.h, 9, 8))
        building_detail(L, m, p["sky0"], 5, 9)
        dunes(L, 218, 10, 21, mix(p["sky1"], p["sky0"], 0.4), mix(p["glow"], p["sun"], 0.3), p["sky0"], sun_dx)
    else:
        dunes(L, 236, 12, 31, p["sky0"] * 0.8, mix(p["glow"], p["sky1"], 0.5), p["sky0"] * 0.5, sun_dx)
        m = L.mask()
        d = ImageDraw.Draw(m)
        rng = random.Random(4)
        def trees(d, o):
            for x in (120, 430, 690):
                x += o
                d.line([(x, 250), (x + 2, 205)], fill=255, width=3)
                for k in range(5):
                    y = 210 + k * 7
                    s = rng.choice((-1, 1))
                    d.line([(x + 1, y), (x + 1 + s * (16 - k * 2), y - 8)], fill=255, width=1)
        wrap_draw(d, L.w, trees)
        shaded(L, m, p["sky0"] * 0.6, p["glow"], p["sky0"] * 0.4, sun_dx)


def motif_saloes(L, p, which):
    sun_dx = 1
    if which == "far":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def giant(d, o):
            x = 240 + o
            # gigante congelado dentro de um bloco de gelo
            d.polygon([(x - 90, 205), (x - 80, 70), (x - 30, 55), (x + 70, 62), (x + 95, 90), (x + 90, 205)], fill=255)
            for k in range(6):
                cx = 560 + k * 60 + o
                d.polygon([(cx - 12, 205), (cx, 150 - (k * 13) % 30), (cx + 12, 205)], fill=255)
        wrap_draw(d, L.w, giant)
        ice = shaded(L, m, mix(p["glow"], p["sky1"], 0.4), p["sun"], p["sky0"], sun_dx, fbm(L.w, L.h, 7, 20), rim_w=2)
        # a sombra do gigante lá dentro
        g = L.mask()
        gd = ImageDraw.Draw(g)
        def inside(d, o):
            x = 240 + o
            d.ellipse([x - 40, 80, x - 10, 108], fill=255)
            d.polygon([(x - 50, 105), (x + 10, 100), (x + 40, 190), (x - 60, 190)], fill=255)
            d.polygon([(x + 5, 105), (x + 55, 75), (x + 62, 82), (x + 15, 120)], fill=255)
        wrap_draw(gd, L.w, inside)
        gm = np.asarray(g, dtype=float) / 255.0 * 0.55
        L.rgb = L.rgb * (1 - gm[..., None]) + mix(p["sky0"], p["sky1"], 0.5) * gm[..., None]
        dunes(L, 208, 5, 12, mix(p["glow"], p["sun"], 0.3), p["sun"], p["sky1"], sun_dx)
    elif which == "mid":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def pines(d, o):
            rng = random.Random(8)
            for x in range(0, LW, 22):
                hh = rng.randint(35, 60)
                xx = x + o + rng.randint(-5, 5)
                for t in range(4):
                    w = 14 - t * 3
                    y = 222 - t * hh / 4
                    d.polygon([(xx - w, y), (xx, y - hh / 3), (xx + w, y)], fill=255)
        wrap_draw(d, L.w, pines)
        shaded(L, m, mix(p["sky1"], p["sky0"], 0.2), mix(p["sun"], p["glow"], 0.5), p["sky0"], sun_dx, fbm(L.w, L.h, 3, 6))
        dunes(L, 220, 6, 22, mix(p["sky1"], p["glow"], 0.3), p["sun"], p["sky0"], sun_dx)
    else:
        dunes(L, 238, 10, 32, mix(p["sky0"], p["sky1"], 0.4), mix(p["sun"], p["glow"], 0.4), p["sky0"] * 0.6, sun_dx)


def motif_forja(L, p, which):
    sun_dx = -1
    if which == "far":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def city(d, o):
            rng = random.Random(2)
            x = 0
            while x < LW:
                w, h = rng.randint(30, 70), rng.randint(40, 110)
                d.rectangle([x + o, 210 - h, x + w + o, 210], fill=255)
                if rng.random() < 0.6:
                    d.rectangle([x + o + w // 3, 210 - h - rng.randint(30, 70), x + o + w // 3 + 8, 210], fill=255)
                x += w + rng.randint(4, 20)
        wrap_draw(d, L.w, city)
        shaded(L, m, mix(p["sky1"], p["sky0"], 0.3), p["accent"], p["sky0"], sun_dx, fbm(L.w, L.h, 4, 12))
        building_detail(L, m, p["sky0"], 6, 4)
        windows(L, [(x, 100, 60, 110) for x in range(0, LW, 60)], p["accent"], 6)
        # fumaça acesa por baixo
        n = fbm(L.w, L.h, 13, 48)
        yy = np.linspace(0, 1, L.h)[:, None]
        smoke = np.clip((n - 0.45) * 3, 0, 1) * np.clip(1.4 - yy * 2.0, 0, 1)
        col = mix(p["sky1"], p["glow"], yy[..., None] * 0.8)
        L.rgb = L.rgb * (1 - smoke[..., None] * (1 - L.a[..., None])) + col * smoke[..., None] * (1 - L.a[..., None])
        L.a = np.maximum(L.a, smoke * 0.7)
    elif which == "mid":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def works(d, o):
            for x in (80, 330, 620, 860):
                x += o
                d.rectangle([x, 120, x + 14, 220], fill=255)
                d.rectangle([x - 4, 116, x + 18, 124], fill=255)
            for x in (200, 720):
                x += o
                d.ellipse([x - 30, 160, x + 30, 220], fill=255)
                for k in range(10):
                    a = k / 10 * math.tau
                    d.rectangle([x + math.cos(a) * 32 - 4, 190 + math.sin(a) * 32 - 4, x + math.cos(a) * 32 + 4, 190 + math.sin(a) * 32 + 4], fill=255)
        wrap_draw(d, L.w, works)
        shaded(L, m, mix(p["sky1"], p["sky0"], 0.5), p["sun"], p["sky0"] * 0.6, sun_dx, fbm(L.w, L.h, 8, 8))
        dunes(L, 222, 6, 23, p["sky0"] * 1.1, p["accent"], p["sky0"] * 0.5, sun_dx)
    else:
        dunes(L, 238, 9, 33, p["sky0"] * 0.7, p["accent"], p["sky0"] * 0.4, sun_dx)


def motif_torre(L, p, which):
    sun_dx = 1
    if which == "far":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def tower(d, o):
            x = 330 + o
            # a Torre em espiral: andares cada vez menores, um degrau de cada lado
            for k in range(9):
                w = 110 - k * 11
                y = 205 - k * 19
                d.rectangle([x - w // 2, y - 19, x + w // 2, y], fill=255)
                d.rectangle([x - w // 2 - 3, y - 3, x + w // 2 + 3, y], fill=255)
            d.rectangle([x - 6, 20, x + 6, 40], fill=255)
            for k in range(5):
                cx = 70 + k * 40 + o + (k % 2) * 900
                d.ellipse([cx, 90 + k * 12, cx + 14 + k * 2, 100 + k * 12], fill=255)
        wrap_draw(d, L.w, tower)
        shaded(L, m, mix(p["sky1"], p["glow"], 0.35), p["sun"], p["sky0"], sun_dx, fbm(L.w, L.h, 2, 10), rim_w=2)
        building_detail(L, m, mix(p["sky0"], p["sky1"], 0.5), 4, 2)
        windows(L, [(270, 40, 120, 160)], p["accent"], 3)
        dunes(L, 210, 4, 14, mix(p["sky1"], p["glow"], 0.3), p["sun"], p["sky0"], sun_dx)
    elif which == "mid":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def stairs(d, o):
            for x in (40, 500):
                x += o
                for k in range(8):
                    d.rectangle([x + k * 16, 220 - k * 10, x + 140 - k * 4, 222 - k * 10 + 10], fill=255)
            for x in (300, 780):
                x += o
                d.rectangle([x, 120, x + 4, 222], fill=255)
                d.rectangle([x - 18, 128, x + 22, 132], fill=255)
        wrap_draw(d, L.w, stairs)
        shaded(L, m, mix(p["sky1"], p["sky0"], 0.3), p["glow"], p["sky0"], sun_dx, fbm(L.w, L.h, 6, 8))
        building_detail(L, m, p["sky0"], 5, 7)
        dunes(L, 224, 4, 24, mix(p["sky1"], p["sky0"], 0.5), p["glow"], p["sky0"], sun_dx)
    else:
        dunes(L, 240, 8, 34, p["sky0"] * 0.8, p["glow"], p["sky0"] * 0.5, sun_dx)


def motif_jardim(L, p, which):
    sun_dx = 1
    if which == "far":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def trees(d, o):
            for k, x in enumerate((120, 520, 820)):
                x += o
                d.polygon([(x - 18, 215), (x - 10, 60), (x + 10, 60), (x + 22, 215)], fill=255)
                for b in range(7):
                    a = -math.pi / 2 + (b - 3) * 0.45
                    r = 55 + (b * 13) % 25
                    cx, cy = x + math.cos(a) * r, 60 + math.sin(a) * r * 0.6
                    d.ellipse([cx - 34, cy - 22, cx + 34, cy + 22], fill=255)
        wrap_draw(d, L.w, trees)
        shaded(L, m, mix(p["sky1"], p["glow"], 0.3), mix(p["sun"], p["accent"], 0.5), p["sky0"], sun_dx, fbm(L.w, L.h, 5, 10), rim_w=2)
        # feixes de luz entre as copas
        yy, xx = np.mgrid[0:L.h, 0:L.w]
        beams = np.clip(np.sin((xx - yy * 0.45) / 13.0) - 0.82, 0, 1) * 5.0 * np.clip((yy - 40) / 160, 0, 1)
        beams *= (1 - L.a)
        L.rgb = mix(L.rgb, p["sun"], beams[..., None] * 0.35)
        L.a = np.maximum(L.a, beams * 0.45)
        dunes(L, 212, 6, 15, mix(p["sky1"], p["glow"], 0.25), p["accent"], p["sky0"], sun_dx)
    elif which == "mid":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def shrooms(d, o):
            rng = random.Random(5)
            for x in range(20, LW, 70):
                xx, h = x + o + rng.randint(-10, 10), rng.randint(25, 60)
                d.rectangle([xx - 3, 222 - h, xx + 3, 222], fill=255)
                d.pieslice([xx - 22, 222 - h - 16, xx + 22, 222 - h + 14], 180, 360, fill=255)
        wrap_draw(d, L.w, shrooms)
        shaded(L, m, mix(p["sky1"], p["sky0"], 0.3), p["accent"], p["sky0"], sun_dx, fbm(L.w, L.h, 3, 6))
        dunes(L, 224, 7, 25, mix(p["sky1"], p["sky0"], 0.4), p["accent"], p["sky0"], sun_dx)
        rng = np.random.default_rng(3)
        for _ in range(60):
            x, y = rng.integers(0, L.w), rng.integers(60, 220)
            L.rgb[y, x] = p["accent"]
            L.a[y, x] = 1
    else:
        dunes(L, 238, 10, 35, p["sky0"] * 0.9, p["accent"], p["sky0"] * 0.5, sun_dx)
        m = L.mask()
        d = ImageDraw.Draw(m)
        def ferns(d, o):
            for x in range(10, LW, 45):
                x += o
                for k in range(6):
                    a = math.pi + k * 0.35 + 0.2
                    d.line([(x, 250), (x + math.cos(a) * 26 * (1 if k < 3 else -1), 250 + math.sin(a) * 20)], fill=255, width=2)
        wrap_draw(d, L.w, ferns)
        shaded(L, m, p["sky0"] * 0.7, p["glow"], p["sky0"] * 0.4, sun_dx)


def motif_carcosa(L, p, which):
    sun_dx = 1
    if which == "far":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def spires(d, o):
            rng = random.Random(9)
            x = 0
            while x < LW:
                w, h = rng.randint(10, 22), rng.randint(70, 170)
                xx = x + o
                d.polygon([(xx, 210), (xx + 2, 210 - h + 20), (xx + w // 2, 210 - h), (xx + w - 2, 210 - h + 20), (xx + w, 210)], fill=255)
                x += w + rng.randint(6, 26)
        wrap_draw(d, L.w, spires)
        shaded(L, m, mix(p["sky1"], p["glow"], 0.25), p["sun"], p["sky0"], sun_dx, fbm(L.w, L.h, 7, 10), rim_w=1)
        windows(L, [(x, 60, 40, 150) for x in range(0, LW, 40)], p["sun"], 12)
        dunes(L, 212, 4, 16, mix(p["sky1"], p["glow"], 0.2), p["sun"], p["sky0"], sun_dx)
    elif which == "mid":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def arches(d, o):
            for x in range(0, LW, 120):
                xx = x + o
                d.rectangle([xx, 150, xx + 70, 224], fill=255)
                d.ellipse([xx + 15, 165, xx + 55, 205], fill=0)
                d.rectangle([xx + 15, 185, xx + 55, 224], fill=0)
                d.polygon([(xx + 75, 224), (xx + 78, 120), (xx + 84, 110), (xx + 90, 120), (xx + 92, 224)], fill=255)
                d.polygon([(xx + 84, 112), (xx + 104, 118), (xx + 100, 128), (xx + 86, 124)], fill=255)
        wrap_draw(d, L.w, arches)
        shaded(L, m, mix(p["sky1"], p["sky0"], 0.4), p["glow"], p["sky0"], sun_dx, fbm(L.w, L.h, 3, 6))
        building_detail(L, m, p["sky0"], 6, 1)
        dunes(L, 226, 5, 26, mix(p["sky1"], p["sky0"], 0.5), p["glow"], p["sky0"], sun_dx)
    else:
        dunes(L, 240, 9, 36, p["sky0"] * 0.8, p["accent"], p["sky0"] * 0.4, sun_dx)


def motif_observatorio(L, p, which):
    sun_dx = -1
    if which == "far":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def dome(d, o):
            x = 260 + o
            d.pieslice([x - 80, 110, x + 80, 270], 180, 360, fill=255)
            d.rectangle([x - 80, 190, x + 80, 215], fill=255)
            d.polygon([(x + 10, 120), (x + 120, 40), (x + 130, 52), (x + 26, 132)], fill=255)
            for k in range(3):
                r = 26 + k * 10
                cx = 700 + o
                d.ellipse([cx - r, 120 - r * 0.35, cx + r, 120 + r * 0.35], outline=255, width=2)
            d.ellipse([694 + o, 114, 706 + o, 126], fill=255)
            d.rectangle([698 + o, 126, 702 + o, 210], fill=255)
        wrap_draw(d, L.w, dome)
        shaded(L, m, mix(p["sky1"], p["glow"], 0.3), p["accent"], p["sky0"], sun_dx, fbm(L.w, L.h, 4, 12), rim_w=1)
        # frestas de luz da cúpula
        windows(L, [(180, 140, 160, 60)], p["accent"], 8)
        dunes(L, 214, 3, 17, mix(p["sky1"], p["glow"], 0.2), p["accent"], p["sky0"], sun_dx)
    elif which == "mid":
        m = L.mask()
        d = ImageDraw.Draw(m)
        def rocks(d, o):
            rng = random.Random(6)
            for x in range(30, LW, 110):
                xx, y = x + o, rng.randint(110, 170)
                # ilha de pedra: topo achatado, fundo arredondado que pinga
                d.ellipse([xx - 30, y - 6, xx + 30, y + 8], fill=255)
                d.pieslice([xx - 24, y - 20, xx + 24, y + 26], 0, 180, fill=255)
                d.polygon([(xx - 6, y + 22), (xx + 4, y + 22), (xx, y + 34)], fill=255)
        wrap_draw(d, L.w, rocks)
        shaded(L, m, mix(p["sky1"], p["sky0"], 0.2), p["accent"], p["sky0"], sun_dx, fbm(L.w, L.h, 2, 6))
        dunes(L, 228, 4, 27, mix(p["sky1"], p["sky0"], 0.5), p["accent"], p["sky0"], sun_dx)
    else:
        dunes(L, 242, 7, 37, p["sky0"] * 0.9, p["accent"], p["sky0"] * 0.4, sun_dx)


SETS = {
    # prefixo das camadas: (domínio, motivo, extras do céu)
    "bd": ("mar_de_cinzas", motif_mar, dict(sun_at=(340, 78), halo=110, rays=True, clouds=0.55, cloud_y=0.35)),
    "bd_saloes": ("saloes", motif_saloes, dict(sun_at=(390, 60), halo=80, clouds=0.4, cloud_y=0.2, stars=120, aurora=True)),
    "bd_forja": ("forja_rubra", motif_forja, dict(sun_at=(120, 210), halo=170, rays=True, clouds=0.7, cloud_y=0.25, sun_r=0)),
    "bd_torre": ("torre_babel", motif_torre, dict(sun_at=(400, 70), halo=120, rays=True, clouds=0.5, cloud_y=0.4)),
    "bd_jardim": ("jardim_primordial", motif_jardim, dict(sun_at=(330, 30), halo=140, rays=True, clouds=0.3, cloud_y=0.15)),
    "bd_carcosa": ("carcosa", motif_carcosa, dict(sun_at=(300, 70), halo=70, black_sun=True, sun_r=16, clouds=0.45, cloud_y=0.3)),
    "bd_observatorio": ("observatorio", motif_observatorio, dict(sun_at=(80, 50), halo=60, stars=420, sun_r=6, nebula=True)),
}


def biome_colors(bid):
    import re
    t = open(os.path.join(ROOT, "content", "biomes", bid, "biome.tres"), encoding="utf-8").read()
    block = re.search(r"sky = \{(.*?)\}\n", t, re.S).group(1)
    out = {}
    for k, r, g, b in re.findall(r'"(\w+)": Color\(([\d.]+), ([\d.]+), ([\d.]+)', block):
        out[k] = np.array([float(r), float(g), float(b)])
    return out


def aurora(s, p, seed):
    yy, xx = np.mgrid[0:H, 0:W]
    wave = 60 + 18 * np.sin(xx / 47.0 + seed) + 8 * np.sin(xx / 13.0)
    band = np.exp(-((yy - wave) / 14.0) ** 2) * (0.5 + 0.5 * np.sin(xx / 7.0))
    col = np.array([0.45, 1.0, 0.8])
    s.rgb = mix(s.rgb, col, band[..., None] * 0.35)


def nebula(s, p, seed):
    n = fbm(W, H, seed + 40, 80)
    yy, xx = np.mgrid[0:H, 0:W]
    lane = np.exp(-(((yy - 40) - (xx - 100) * 0.35) / 50.0) ** 2)
    neb = np.clip((n - 0.4) * 2.5, 0, 1) * lane
    s.rgb = mix(s.rgb, np.array([0.55, 0.35, 0.85]), neb[..., None] * 0.45)
    s.rgb = mix(s.rgb, p["accent"], (neb ** 3)[..., None] * 0.4)


def paint(prefix):
    bid, motif, extra = SETS[prefix]
    p = biome_colors(bid)
    p.update(extra)
    sk = sky(p, len(prefix))
    if extra.get("aurora"):
        aurora(sk, p, 3)
    if extra.get("nebula"):
        nebula(sk, p, 5)
    horizon = mix(p["glow"], p["sky1"], 0.35)
    layers = {"sky": finish(sk, 12)}
    for which, fog, fogcol in (("far", 0.45, horizon), ("mid", 0.22, mix(horizon, p["sky0"], 0.4)), ("near", 0.05, p["sky0"])):
        L = Layer(LW, H)
        motif(L, p, which)
        haze(L, fogcol, fog, top_fade=0.15 if which == "far" else 0.0)
        if which != "near":
            fog_band(L, 206 if which == "far" else 222, 10, mix(fogcol, p["sun"], 0.15), 0.55, len(prefix) + len(which))
        layers[which] = finish(L, 10)
    for k, im in layers.items():
        im.save(os.path.join(OUT, "%s_cor_%s.png" % (prefix, k)))
    comp = layers["sky"].copy()
    for k in ("far", "mid", "near"):
        comp.alpha_composite(layers[k].crop((0, 0, W, H)))
    os.makedirs(PREV, exist_ok=True)
    comp.resize((W * 2, H * 2), Image.NEAREST).save(os.path.join(PREV, "fundo_%s.png" % prefix))
    return comp


if __name__ == "__main__":
    want = sys.argv[1:]
    for prefix, (bid, _, _) in SETS.items():
        if want and bid not in want and prefix not in want:
            continue
        paint(prefix)
        print("ok", prefix)
