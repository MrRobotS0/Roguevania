"""Prévia das molduras do HUD por domínio (tools/previews/hud_temas.png).
Imita o desenho de scripts/ui/hud_theme.gd para ver os 7 temas sem abrir o jogo."""
import math
import os
import re

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = open(os.path.join(ROOT, "scripts", "ui", "hud_theme.gd"), encoding="utf-8").read()
THEMES = {}
for m in re.finditer(r'"(\w*)": \{"frame": "(\w+)", "light": "(\w+)", "dark": "(\w+)", "bg": "(\w+)", "accent": "(\w+)", "style": "(\w+)"\}', SRC):
    k, *cols, style = m.groups()
    THEMES[k] = dict(zip(["frame", "light", "dark", "bg", "accent"], ["#" + c for c in cols]), style=style)

S = 4


def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def mix(a, b, k):
    return tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))


def rect(d, x, y, w, h, c):
    if w <= 0 or h <= 0:
        return
    d.rectangle([x * S, y * S, (x + w) * S - 1, (y + h) * S - 1], fill=c)


def panel(d, x, y, w, h, th, t, ornate=True):
    dark, frame, light, bg, a = (hexc(th[k]) for k in ("dark", "frame", "light", "bg", "accent"))
    rect(d, x - 2, y - 2, w + 4, h + 4, dark)
    rect(d, x - 1, y - 1, w + 2, h + 2, frame)
    rect(d, x, y, w, h, bg)
    rect(d, x - 1, y - 1, w + 2, 1, light)
    rect(d, x - 1, y + h, w + 2, 1, mix(frame, (0, 0, 0), 0.35))
    if not ornate:
        return
    x0, x1, y0, y1 = x - 2, x + w + 1, y - 2, y + h + 1
    st = th["style"]
    if st == "sun":
        for cx in (x0, x1):
            rect(d, cx - 1, y0 - 1, 3, 3, a)
            rect(d, cx, y0 - 3, 1, 2, mix(a, (0, 0, 0), 0.2))
            rect(d, cx - 3 if cx == x0 else cx + 2, y0, 2, 1, mix(a, (0, 0, 0), 0.2))
    elif st == "ice":
        i, xx = 0, x + 3
        while xx < x + w - 2:
            rect(d, xx, y1 + 1, 1, 1 + (i * 7) % 3, light if i % 2 == 0 else a)
            xx += 5 + i % 3
            i += 1
    elif st == "rivets":
        for cx, cy in ((x0 + 1, y0 + 1), (x1 - 1, y0 + 1), (x0 + 1, y1 - 1), (x1 - 1, y1 - 1)):
            rect(d, cx - 1, cy - 1, 2, 2, light)
        rect(d, x + 2, y1 + 1, w - 4, 1, mix(bg, a, 0.75))
    elif st == "glyphs":
        xx, i = x + 2, 0
        while xx < x + w - 2:
            hh = 1 + (i * 5) % 2
            rect(d, xx, y0 - hh, 1, hh, a if i % 3 else light)
            xx += 3
            i += 1
    elif st == "vines":
        xx, i = x, 0
        while xx < x + w:
            up = i % 2 == 0
            rect(d, xx, y1 + (1 if up else 2), 2, 1, mix(a, (0, 0, 0), 0.3))
            if i % 3 == 0:
                rect(d, xx + 1, y1 + (2 if up else 3), 2, 2, a)
            xx += 4
            i += 1
        rect(d, x0 - 1, y0 - 1, 3, 2, a)
    elif st == "drips":
        for i in range(4):
            xx = round(x + 4 + i * (w - 8) / 3.0)
            drop = round(1 + ((t * 0.6 + i * 0.37) % 1.0) * 4)
            c = mix(a, (0, 0, 0), 0.15 * (i % 2))
            rect(d, xx, y1 + 1, 1, drop, c)
    elif st == "circuit":
        for cx, cy in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
            rect(d, cx if cx == x0 else cx - 3, cy, 4, 1, a)
            rect(d, cx, cy if cy == y0 else cy - 3, 1, 4, a)
        rect(d, x + 30, y0, 2, 1, a)


def frame_for(name, th):
    W, H = 160, 64
    img = Image.new("RGB", (W * S, H * S), (30, 26, 34))
    d = ImageDraw.Draw(img)
    # um pedaço de mundo atrás
    for yy in range(H):
        rect(d, 0, yy, W, 1, mix((22, 20, 30), (48, 40, 52), yy / H))
    panel(d, 8, 8, 96, 7, th, 1.3)
    rect(d, 8, 8, 70, 7, (217, 67, 75))
    rect(d, 70, 8, 8, 7, (242, 193, 78))
    if th["style"] == "circuit":
        for xx in range(6, 96, 6):
            rect(d, 8 + xx, 8, 1, 7, hexc(th["bg"]))
    for i in range(3):
        rect(d, 10 + i * 9, 21, 5, 6, (180, 169, 204) if i < 2 else (74, 63, 96))
        rect(d, 11 + i * 9, 23, 3, 3, (217, 67, 75) if i < 2 else (27, 23, 38))
    for i in range(4):
        x = 8 + i * 22 + (6 if i >= 2 else 0)
        panel(d, x, 40, 18, 18, th, 0.0, False)
        rect(d, x + 4, 46, 10, 2, (217, 226, 236))
    panel(d, 112, 40, 40, 12, th, 0.7)
    d.text((112 * S, 2 * S), name or "padrão", fill=(240, 236, 255))
    return img


imgs = [frame_for(k, v) for k, v in THEMES.items()]
cols = 2
w, h = imgs[0].size
out = Image.new("RGB", (w * cols + 8, (h + 8) * ((len(imgs) + 1) // cols)), (10, 10, 14))
for i, im in enumerate(imgs):
    out.paste(im, ((i % cols) * (w + 8), (i // cols) * (h + 8)))
path = os.path.join(ROOT, "tools", "previews", "hud_temas.png")
out.save(path)
print(path, len(imgs))
