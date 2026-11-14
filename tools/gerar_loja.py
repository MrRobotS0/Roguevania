"""Prévias da loja (site/img/loja): lâminas, rastros e filtros.

Lê as cores de scripts/combat/cosmetics.gd e desenha:
  lamina_<id>.png  o herói (img/skins/andarilho.png) com o arco do golpe na cor da lâmina
  rastro_<id>.png  o herói com as silhuetas da rolagem e as partículas na cor do rastro
  filtro_<id>.png  uma cena do jogo (tools/loja/cena.png) com o filtro, igual ao shader de post_fx.gd

    python tools/gerar_loja.py
"""
import math
import os
import random
import re

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "site", "img", "loja")
HERO = os.path.join(ROOT, "site", "img", "skins", "andarilho.png")
SCENE = os.path.join(ROOT, "tools", "loja", "cena.png")
W, H = 120, 90        # prévia em pixels do jogo (o site mostra ampliado, sem suavizar)


def cosmetics():
    src = open(os.path.join(ROOT, "scripts", "combat", "cosmetics.gd"), encoding="utf-8").read()
    out = {}
    for block in ("BLADES", "TRAILS", "FILTERS"):
        body = src.split("const %s := {" % block)[1].split("\n}")[0]
        for m in re.finditer(r'"(\w+)": \{([^}]*)\}', body):
            fields = dict(re.findall(r'"(\w+)": "?([^",]+)"?', m.group(2)))
            out.setdefault(block, {})[m.group(1)] = fields
    return out


def rgb(h):
    h = h.strip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def stage():
    """Fundo escuro com chão, como no card da loja."""
    im = Image.new("RGBA", (W, H), (14, 10, 18, 255))
    d = ImageDraw.Draw(im)
    for y in range(H):
        k = y / H
        d.line([(0, y), (W, y)], fill=(int(26 - 12 * k), int(18 - 8 * k), int(32 - 14 * k), 255))
    d.rectangle([0, H - 12, W, H], fill=(42, 29, 24, 255))
    d.line([(0, H - 12), (W, H - 12)], fill=(90, 62, 42, 255))
    return im


def hero():
    h = Image.open(HERO).convert("RGBA")
    return h.resize((h.width // 2, h.height // 2), Image.NEAREST)   # a prévia vem em 2x


def silhouette(img, color, alpha):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    px, src = out.load(), img.load()
    for y in range(img.height):
        for x in range(img.width):
            if src[x, y][3] > 0:
                px[x, y] = color + (alpha,)
    return out


def blade(fx):
    im = stage()
    hr = hero()
    hx, hy = 30, H - 12 - hr.height
    im.alpha_composite(hr, (hx, hy))
    c, spark = rgb(fx["color"]), rgb(fx["spark"])
    d = ImageDraw.Draw(im)
    cx, cy = hx + hr.width // 2 + 4, hy + hr.height // 2
    # arco em pixels: várias camadas, mais grossa no meio, some nas pontas
    for r in range(22, 34):
        for a in range(-70, 71, 2):
            t = 1 - abs(a) / 70
            if (r - 22) / 12 > t + 0.15:
                continue
            x = cx + r * math.cos(math.radians(a))
            y = cy + r * math.sin(math.radians(a)) * 0.9
            k = (r - 22) / 12
            col = tuple(int(c[i] + (255 - c[i]) * (0.55 if r > 31 else 0.0)) for i in range(3))
            d.point((round(x), round(y)), fill=col + (int(255 * (0.45 + 0.55 * t) * (1 - k * 0.3)),))
    random.seed(fx["color"])
    for _ in range(14):
        a = math.radians(random.uniform(-60, 60))
        r = random.uniform(30, 44)
        d.point((round(cx + r * math.cos(a)), round(cy + r * math.sin(a))), fill=spark + (255,))
    return im


def trail(fx, kind):
    im = stage()
    hr = hero()
    base_x, hy = 64, H - 12 - hr.height
    c, p = rgb(fx["color"]), rgb(fx["particle"])
    for i, alpha in ((3, 50), (2, 85), (1, 125)):
        im.alpha_composite(silhouette(hr, c, alpha), (base_x - i * 13, hy))
    im.alpha_composite(hr, (base_x, hy))
    d = ImageDraw.Draw(im)
    random.seed(fx["color"] + kind)
    for _ in range(26):
        x = random.uniform(8, base_x + 4)
        if kind == "sobe":
            y = random.uniform(hy - 6, H - 14)
        elif kind == "cai":
            y = random.uniform(hy, H - 13)
        else:
            y = random.uniform(hy + 4, H - 18)
        d.point((round(x), round(y)), fill=p + (random.randint(150, 255),))
        if kind == "brilha" and random.random() < 0.3:
            d.point((round(x) + 1, round(y)), fill=p + (120,))
            d.point((round(x) - 1, round(y)), fill=p + (120,))
            d.point((round(x), round(y) + 1), fill=p + (120,))
            d.point((round(x), round(y) - 1), fill=p + (120,))
    return im


def mix(a, b, k):
    return tuple(a[i] + (b[i] - a[i]) * k for i in range(3))


def smooth(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def filt(mode, c, y):
    """O mesmo de store_filter() em scripts/ui/post_fx.gd (cores de 0 a 1)."""
    l = 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
    if mode == 1:
        return mix(c, (l * 1.08 + 0.05, l * 0.9 + 0.025, l * 0.66), 0.85)
    if mode == 2:
        g = smooth(0.04, 0.92, l)
        red = min(max((c[0] - max(c[1], c[2]) * 2.2) * 4.0, 0.0), 1.0)
        return mix((g, g, g), c, red)
    if mode == 3:
        scan = 0.82 + 0.18 * (1.0 if y % 3 >= 1 else 0.0)
        v = l ** 0.9 * 1.15
        return (0.12 * v * scan, (v + 0.035) * scan, (0.38 * v + 0.012) * scan)
    if mode == 4:
        duo = mix((0.32, 0.18, 0.46), (0.78, 1.0, 0.96), l)
        return tuple(x * 0.92 + 0.06 for x in mix(c, duo, 0.55))
    if mode == 5:
        return mix(c, mix((0.14, 0.02, 0.05), (1.0, 0.78, 0.36), l), 0.7)
    if mode == 6:
        return mix(c, mix((0.03, 0.06, 0.15), (0.86, 0.95, 1.0), l), 0.65)
    return c


def screen_filter(mode):
    src = Image.open(SCENE).convert("RGB")
    out = Image.new("RGB", src.size)
    sp, op = src.load(), out.load()
    for y in range(src.height):
        for x in range(src.width):
            c = tuple(v / 255 for v in sp[x, y])
            r = filt(mode, c, y * 2)
            op[x, y] = tuple(max(0, min(255, round(v * 255))) for v in r)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    cos = cosmetics()
    n = 0
    for id_, fx in cos["BLADES"].items():
        blade(fx).resize((W * 2, H * 2), Image.NEAREST).save(os.path.join(OUT, id_ + ".png")); n += 1
    for id_, fx in cos["TRAILS"].items():
        trail(fx, fx["kind"]).resize((W * 2, H * 2), Image.NEAREST).save(os.path.join(OUT, id_ + ".png")); n += 1
    for id_, fx in cos["FILTERS"].items():
        screen_filter(int(fx["mode"])).save(os.path.join(OUT, id_ + ".png")); n += 1
    Image.open(SCENE).convert("RGB").save(os.path.join(OUT, "filtro_nenhum.png"))
    print("%d prévias em %s" % (n, OUT))


if __name__ == "__main__":
    main()
