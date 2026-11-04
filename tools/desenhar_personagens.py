"""Personagens desenhados por código quando não existe arte pronta que case com a
história (ver docs/ACERVO_ARTE.md): a Mãe-Raiz e a Estrela Caída.

    python tools/desenhar_personagens.py

Mesmo formato das folhas de tools/importar_inimigos.py ("color": true, uma
linha por animação, pés no fundo da célula). Como fica no nível da arte pronta:
cada parte é uma máscara; o volume vem da distância até a borda (chanfro) e da
luz do alto à esquerda; a cor é quantizada na rampa do material; a casca ganha
veios; cada parte tem um traço escuro na borda e o todo um contorno.
"""
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(ROOT, "tools", "previews")


def hexc(h):
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def ramp(*hs):
    return np.stack([hexc(h) for h in hs])


BARK = ramp("1a120c", "2e1f14", "47301d", "634329", "80583a", "9b7350")
MOSS = ramp("0f1f0e", "1f3a17", "2f5520", "48722c", "6b9440", "93ba5a")
LEAF = ramp("0d2410", "1a3f1a", "2c5f25", "46852f", "6fae45", "a4d46a")
ROCK = ramp("120e10", "241d20", "3a2f32", "554549", "736065", "9a858a")
HOT = ramp("4a1a08", "a8400c", "f08a28", "ffd060", "fff4c0", "ffffff")
INK = hexc("0b0806")


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.rgb = np.zeros((h, w, 3), np.float32)
        self.a = np.zeros((h, w), bool)

    # --- máscaras -----------------------------------------------------------
    def blank(self):
        return Image.new("L", (self.w, self.h), 0)

    def ellipse(self, cx, cy, rx, ry):
        m = self.blank()
        ImageDraw.Draw(m).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
        return np.array(m) > 0

    def poly(self, pts):
        m = self.blank()
        ImageDraw.Draw(m).polygon([tuple(p) for p in pts], fill=255)
        return np.array(m) > 0

    def stroke(self, pts, r0, r1, steps=40):
        """Linha grossa que afina de r0 a r1 ao longo de uma polilinha."""
        m = self.blank()
        d = ImageDraw.Draw(m)
        segs = list(zip(pts[:-1], pts[1:]))
        total = sum(math.dist(a, b) for a, b in segs) or 1.0
        acc = 0.0
        for a, b in segs:
            L = math.dist(a, b)
            n = max(2, int(L))
            for i in range(n + 1):
                t = i / n
                x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                k = (acc + L * t) / total
                r = r0 + (r1 - r0) * k
                d.ellipse([x - r, y - r, x + r, y + r], fill=255)
            acc += L
        return np.array(m) > 0

    # --- pintura --------------------------------------------------------------
    def paint(self, mask, pal, bevel=4, light=0.0, grain=None, edge=True):
        """Pinta a máscara com volume: chanfro + luz do alto à esquerda."""
        if not mask.any():
            return
        d = np.zeros(mask.shape, np.float32)
        m = mask.copy()
        for _ in range(bevel):
            m = m & np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1)
            d += m
        hgt = d / bevel
        gy, gx = np.gradient(hgt)
        nx, ny, nz = -gx * 3.0, -gy * 3.0, np.ones_like(hgt)
        ln = np.sqrt(nx * nx + ny * ny + nz * nz)
        L = np.array([-0.55, -0.7, 0.45])
        L = L / np.linalg.norm(L)
        lum = (nx * L[0] + ny * L[1] + nz * L[2]) / ln
        lum = 0.15 + 0.85 * np.clip(lum, 0, 1) + 0.18 * hgt + light
        if grain is not None:
            lum = lum + grain
        idx = np.clip(np.round(lum * (len(pal) - 1)), 0, len(pal) - 1).astype(int)
        col = pal[idx]
        if edge:
            inner = mask & np.roll(mask, 1, 0) & np.roll(mask, -1, 0) & np.roll(mask, 1, 1) & np.roll(mask, -1, 1)
            col[mask & ~inner] = pal[0]
        self.rgb[mask] = col[mask]
        self.a |= mask

    def pixel(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.rgb[y, x] = hexc(c) if isinstance(c, str) else c
            self.a[y, x] = True

    def image(self, outline=True):
        a = self.a
        rgb = self.rgb.copy()
        if outline:
            ring = (np.roll(a, 1, 0) | np.roll(a, -1, 0) | np.roll(a, 1, 1) | np.roll(a, -1, 1)) & ~a
            rgb[ring] = INK
            a = a | ring
        out = np.zeros((self.h, self.w, 4), np.uint8)
        out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
        out[..., 3] = a * 255
        return Image.fromarray(out, "RGBA")


def bark_grain(c, seed):
    """Veios verticais da casca: faixas mais escuras que ondulam."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:c.h, 0:c.w]
    wave = np.sin(yy * 0.35 + rng.random() * 6) * 1.2
    g = np.where(((xx + wave).astype(int) % 5) == 0, -0.22, 0.0)
    g += rng.normal(0, 0.05, (c.h, c.w))
    return g.astype(np.float32)


# ============================================================ Mãe-Raiz
# "Tudo que cresce aqui nasceu dela." Um tronco ancestral que brota de uma
# massa de raízes, com rosto de casca entalhado (olhos verdes acesos), braços de
# galho com dedos de raiz, coroa de folhas e flores, musgo nos ombros.

MW, MH = 160, 150
BARK = ramp("140d09", "24170f", "382416", "4f3420", "6a462b", "8a6140", "a8805a")
VINE = ramp("0a1a0c", "143018", "1f4a22", "2e6630", "47883e")
SEED = ramp("0f3a1a", "2a8a3a", "6ae06a", "c8ffb0", "ffffff")


def jag(rng, n, amp):
    return [rng.uniform(-amp, amp) for _ in range(n)]


def trunk_poly(cx, base_y, top, sway, slump, rng):
    """Tronco torto: se abre na base, afina e verga; bordas irregulares."""
    left, right = [], []
    n = 14
    jl, jr = jag(rng, n + 1, 1.6), jag(rng, n + 1, 1.6)
    for k in range(n + 1):
        t = k / n                                   # 0 = base, 1 = topo
        y = base_y + (top[1] - base_y) * t
        bend = sway * t * t + math.sin(t * 3.0) * 3
        w = 13 + 11 * (1 - t) ** 3 + 3 * math.sin(t * 7.0) * (1 - t)
        left.append((cx + bend - w + jl[k], y))
        right.append((cx + bend + w * 0.92 + jr[k], y))
    return left + right[::-1]


def crack_lines(c, mask, rng, cx, x0, x1, y0, y1, n=7):
    """Rachaduras da casca: linha escura com crista clara do lado da luz."""
    for _ in range(n):
        x = rng.uniform(x0, x1)
        pts = []
        y = y1
        while y > y0:
            pts.append((x, y))
            y -= rng.uniform(5, 9)
            x += rng.uniform(-1.6, 1.6)
        for (ax, ay), (bx, by) in zip(pts[:-1], pts[1:]):
            steps = int(max(abs(by - ay), 1))
            for s_ in range(steps):
                tx = ax + (bx - ax) * s_ / steps
                ty = ay + (by - ay) * s_ / steps
                ix, iy = int(round(tx)), int(round(ty))
                if 0 <= iy < c.h and 0 <= ix < c.w and mask[iy, ix]:
                    c.rgb[iy, ix] = BARK[1]
                    if ix - 1 >= 0 and mask[iy, ix - 1]:
                        c.rgb[iy, ix - 1] = BARK[5] if tx < cx + 4 else BARK[4]


def mother(sway=0.0, arms=(0.0, 0.0), reach=0.0, root=0.0, glow=0.5, slump=0.0, spikes=0.0):
    c = Canvas(MW, MH)
    rng = np.random.default_rng(11)
    cx, gy = MW // 2, MH - 3
    # raízes: grossas perto do tronco, finas e tortas no chão
    for k, (dx, end) in enumerate([(-14, -66), (-9, -46), (-4, -24), (4, 22), (9, 44), (14, 68)]):
        wig = math.sin(root + k * 1.7) * 4
        p0 = (cx + dx, gy - 22)
        p1 = (cx + dx + end * 0.35, gy - 9 + wig * 0.3)
        p2 = (cx + dx + end * 0.75, gy - 2)
        p3 = (cx + end + wig, gy)
        c.paint(c.stroke([p0, p1, p2, p3], 8 - abs(k - 2.5) * 0.7, 1.2), BARK, bevel=3)
    top = (cx + sway, 52 + slump)
    # espinhos de raiz que rompem o chão (feitiço)
    if spikes > 0:
        for k, x in enumerate([-54, -34, 34, 56]):
            hgt = 10 + spikes * (16 + (k % 2) * 9)
            b = cx + x
            c.paint(c.poly([(b - 6, gy), (b + 6, gy), (b + 2, gy - hgt * 0.6), (b, gy - hgt), (b - 2, gy - hgt * 0.6)]), BARK, bevel=2)
    # tronco
    tm = c.poly(trunk_poly(cx, gy - 6, top, sway, slump, rng))
    c.paint(tm, BARK, bevel=7)
    crack_lines(c, tm, rng, cx, cx - 16, cx + 16, top[1] + 18, gy - 8)
    # cavidade no peito com a semente que pulsa: de onde tudo nasce
    sx, sy = cx + sway * 0.55, top[1] + 34
    cav = c.ellipse(sx, sy, 7, 9)
    c.paint(cav, BARK[:3], bevel=2, edge=False)
    pulse = 2.2 + glow * 1.8
    c.paint(c.ellipse(sx, sy + 1, pulse, pulse + 0.6), SEED, bevel=1, light=0.15 + glow * 0.3, edge=False)
    if glow > 0.6:
        for ang in range(0, 360, 60):
            a = math.radians(ang + root * 20)
            c.pixel(sx + math.cos(a) * (pulse + 3), sy + 1 + math.sin(a) * (pulse + 3), "6ae06a")
    # braços retorcidos com nós e dedos de raiz
    for side, ang in ((-1, arms[0]), (1, arms[1])):
        sh = (top[0] + side * 13, top[1] + 14)
        el = (sh[0] + side * (15 + reach * 10), sh[1] + 12 - ang * 26)
        knot = ((sh[0] + el[0]) / 2 + side * 1.5, (sh[1] + el[1]) / 2 - 2)
        hand = (el[0] + side * (11 + reach * 14), el[1] + 13 - ang * 30)
        c.paint(c.stroke([sh, knot, el, hand], 6.5, 3.2), BARK, bevel=3)
        c.paint(c.ellipse(el[0], el[1], 4, 3.5), BARK, bevel=2)       # nó do cotovelo
        for f in (-1, 0, 1):
            fa = math.atan2(hand[1] - el[1], hand[0] - el[0]) + f * 0.5
            tip = (hand[0] + math.cos(fa) * 14, hand[1] + math.sin(fa) * 14)
            mid = ((hand[0] + tip[0]) / 2 + f * 2.5, (hand[1] + tip[1]) / 2 + 2.5)
            c.paint(c.stroke([hand, mid, tip], 2.3, 0.6), BARK, bevel=1)
        c.paint(c.ellipse(sh[0] + side * 3, sh[1] - 3, 8, 4.5), MOSS, bevel=2)
    # cabeça: rosto de casca, mais estreito no queixo
    hx, hy = top[0], top[1] - 13
    head = c.poly([(hx - 13, hy - 8), (hx - 11, hy - 16), (hx, hy - 19), (hx + 11, hy - 16), (hx + 13, hy - 7),
                   (hx + 10, hy + 9), (hx + 4, hy + 17), (hx - 4, hy + 17), (hx - 10, hy + 9)])
    c.paint(head, BARK, bevel=5)
    crack_lines(c, head, rng, hx, hx - 9, hx + 9, hy - 14, hy + 15, n=3)
    # cabelo de cipós pendurado dos dois lados
    for k in range(9):
        side = -1 if k % 2 == 0 else 1
        x0 = hx + side * (8 + (k // 2) * 2.5)
        length = 26 + (k * 7) % 17
        sw = math.sin(root + k) * 2
        c.paint(c.stroke([(x0, hy - 12), (x0 + side * 4 + sw, hy + length * 0.5), (x0 + side * 3 + sw * 1.6, hy + length)], 2.0, 0.8), VINE, bevel=1)
    # copa: miolo escuro e muitos tufos com luz do alto
    c.paint(c.ellipse(hx, hy - 20, 22, 11), LEAF[:3], bevel=3)
    for k in range(16):
        a = math.pi + k / 15 * math.pi
        rr = 20 + (k % 3) * 3
        lx, ly = hx + math.cos(a) * rr, hy - 16 + math.sin(a) * rr * 0.55
        bob = math.sin(root * 0.7 + k) * 0.8
        r = 5 + (k * 3) % 3
        c.paint(c.ellipse(lx, ly + bob, r, r * 0.8), LEAF, bevel=3, light=0.05)
    # olhos fundos acesos e boca de fenda
    for ex in (-5, 5):
        c.paint(c.ellipse(hx + ex, hy - 1, 3.4, 2.2), BARK[:2], bevel=1, edge=False)
        g = 0.35 + glow * 0.65
        c.pixel(hx + ex, hy - 1, SEED[2] * g + SEED[0] * (1 - g))
        c.pixel(hx + ex + (1 if ex > 0 else -1), hy - 1, SEED[1])
        if glow > 0.7:
            c.pixel(hx + ex, hy - 2, "c8ffb0")
    c.paint(c.poly([(hx - 2.5, hy + 7), (hx + 2.5, hy + 7), (hx + 1, hy + 13), (hx - 1, hy + 13)]), BARK[:2], bevel=1, edge=False)
    # flores entre os tufos
    for fx, fy in ((-14, -24), (9, -30), (19, -18), (-4, -33), (-21, -12)):
        c.pixel(hx + fx, hy + fy, "ef9cc4")
        c.pixel(hx + fx + 1, hy + fy, "ffe0f0")
        c.pixel(hx + fx, hy + fy + 1, "c45a8a")
    return c.image()


MOTHER = {
    "idle": [dict(sway=math.sin(i / 6 * math.tau) * 2, arms=(0.1, 0.1), root=i / 6 * math.tau, glow=0.45 + 0.15 * math.sin(i)) for i in range(6)],
    "walk": [dict(sway=math.sin(i / 6 * math.tau) * 4, arms=(0.15 + 0.1 * math.sin(i), 0.15 - 0.1 * math.sin(i)),
                  root=i / 6 * math.tau * 2, glow=0.5) for i in range(6)],
    "windup": [dict(sway=-3, arms=(1.0, 1.0), glow=1.0, root=1.0)],
    "attack": [dict(sway=4, arms=(-0.4, -0.4), reach=1.0, glow=0.9, root=2.0)],
    "cast": [dict(sway=0, arms=(0.6, 0.6), reach=0.5, glow=1.0, root=k, spikes=0.6 + k * 0.4) for k in (0, 1)],
    "rest": [dict(sway=1, arms=(-0.3, -0.3), glow=0.2, slump=6, root=0.5)],
}


# ============================================================ Estrela Caída
# "Um nome que o deus esqueceu. Pisca antes de explodir." Um núcleo de estrela
# incandescente preso numa casca de rocha rachada que gira em volta.

SW, SH = 48, 48


def star(rot=0.0, flash=0.0, burst=0.0):
    c = Canvas(SW, SH)
    cx, cy = SW / 2, SH / 2 - 2
    # brilho em volta (só pixels claros, sem contorno)
    halo = Canvas(SW, SH)
    rad = 12 + flash * 4
    halo_m = halo.ellipse(cx, cy, rad, rad) & ~halo.ellipse(cx, cy, rad - 3, rad - 3)
    # núcleo: estrela de 6 pontas, mais clara no centro
    pts = []
    r_out, r_in = 9 + flash * 3, 4 + flash
    for k in range(12):
        a = rot + k * math.pi / 6
        r = r_out if k % 2 == 0 else r_in
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    core = c.poly(pts)
    yy, xx = np.mgrid[0:SH, 0:SW]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (r_out + 0.01)
    lum = np.clip(1.05 - dist + flash * 0.4, 0, 1)
    idx = np.clip(np.round(lum * (len(HOT) - 1)), 0, len(HOT) - 1).astype(int)
    c.rgb[core] = HOT[idx][core]
    c.a |= core
    # casca de rocha em cacos que giram; a borda virada para o núcleo acende
    for k in range(5):
        a = rot * 0.5 + k * math.tau / 5
        rr = 14 + burst * 5
        fx, fy = cx + math.cos(a) * rr, cy + math.sin(a) * rr
        shard = []
        for j in range(5):
            b = a + j * math.tau / 5 + 0.3
            sr = 4.5 if j % 2 else 3.2
            shard.append((fx + math.cos(b) * sr, fy + math.sin(b) * sr))
        m = c.poly(shard)
        c.paint(m, ROCK, bevel=2)
        # rachadura acesa e borda quente do lado do núcleo
        ix, iy = fx - math.cos(a) * 3, fy - math.sin(a) * 3
        c.pixel(ix, iy, "ffd060" if flash < 0.5 else "fff4c0")
        c.pixel(fx, fy, "a8400c" if flash < 0.5 else "f08a28")
    out = c.image()
    # halo por cima, sem contorno
    hal = np.zeros((SH, SW, 4), np.uint8)
    col = (np.array([255, 200, 90]) * (0.6 + 0.4 * flash)).astype(np.uint8)
    hal[halo_m] = [*col, int(90 + flash * 120)]
    ring = Image.fromarray(hal, "RGBA")
    base = Image.new("RGBA", (SW, SH))
    base.alpha_composite(ring)
    base.alpha_composite(out)
    return base


STAR = {
    "idle": [dict(rot=i * math.pi / 24, flash=0.1 * (i % 2)) for i in range(8)],
    "windup": [dict(rot=0.3, flash=1.0, burst=0.4), dict(rot=0.5, flash=0.4, burst=0.8)],
}


# ============================================================ saída

def sheet(name, anims, fn, w, h, fps=None, draw_scale=None):
    cols = max(len(v) for v in anims.values())
    im = Image.new("RGBA", (cols * w, len(anims) * h))
    meta = {"w": w, "h": h, "size": max(w, h), "color": True, "anims": {}}
    if draw_scale:
        meta["draw_scale"] = draw_scale
    for r, (anim, poses) in enumerate(anims.items()):
        for c, pose in enumerate(poses):
            im.alpha_composite(fn(**pose), (c * w, r * h))
        meta["anims"][anim] = {"row": r, "frames": len(poses), "fps": (fps or {}).get(anim, 6)}
    im.save(os.path.join(OUT, name + ".png"))
    json.dump(meta, open(os.path.join(OUT, name + ".json"), "w"), indent=1)
    prev = Image.new("RGBA", im.size, (40, 52, 40, 255))
    prev.alpha_composite(im)
    os.makedirs(PREV, exist_ok=True)
    prev.resize((im.width * 2, im.height * 2), Image.NEAREST).save(os.path.join(PREV, "desenho_" + name + ".png"))
    print("ok", name, im.size)


def main():
    sheet("mother_root", MOTHER, mother, MW, MH, {"walk": 8})
    sheet("star", STAR, star, SW, SH, {"idle": 10})


if __name__ == "__main__":
    main()
