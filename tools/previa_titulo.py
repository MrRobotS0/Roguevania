"""Prévia da tela de título sem abrir o jogo (tools/previews/titulo.png).

    python tools/previa_titulo.py

Lê a fonte de scripts/ui/pixel_font.gd e imita scripts/ui/screen.gd
(_draw_title, _logo, _sigil, _title_menu) sobre o fundo do Mar de Cinzas.
Não inclui a ambiência nem o brilho (bloom) do jogo.
"""
import os
import re

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
SP = os.path.join(ROOT, "assets", "sprites")
FONT = open(os.path.join(ROOT, "scripts", "ui", "pixel_font.gd"), encoding="utf-8").read()
W, H = 480, 270


def table(name):
    block = FONT[FONT.index("const %s := {" % name):]
    return block[:block.index("\n}")]


BODY = {k: rows for k, rows in ((m.group(1), re.findall(r'"([.#]{5})"', m.group(2)))
                                for m in re.finditer(r'"(.)": \[([^\]]*)\]', table("BODY")))}
SMALL = {m.group(1): m.group(2) for m in re.finditer(r'"(.)": "([01]{15})"', table("GLYPHS"))}
ACC = {m.group(1): (m.group(2), m.group(3)) for m in re.finditer(r'"(.)": \["(.)", "(\w+)"\]', table("ACCENTS"))}


def marks(name):
    out = {}
    for m in re.finditer(r'"(\w+)": \[([^\]]*)\]', table(name)):
        out[m.group(1)] = [(int(a), int(b)) for a, b in re.findall(r"Vector2i\((-?\d+), (-?\d+)\)", m.group(2))]
    return out


MB, MS = marks("MARKS_BODY"), marks("MARKS_SMALL")


def hexc(h, a=255):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


GOLD, DIM, SHADOW, ESSENCE = hexc("f2c14e"), hexc("b4a9cc"), hexc("07060b"), hexc("9fe8ff")
INK, BRONZE, DEEP, FACE = hexc("1a0b04"), hexc("6b3410"), hexc("d27c22"), hexc("ffd866")


def body(d, text, x, y, color, sc=1, shadow=SHADOW):
    if shadow:
        body(d, text, x + sc, y + sc, shadow, sc, None)
    for ch in text.upper():
        base, mark = ACC.get(ch, (ch, ""))
        rows = BODY.get(base, BODY.get("?"))
        for r, row in enumerate(rows):
            for c, px in enumerate(row):
                if px == "#":
                    d.rectangle([x + c * sc, y + r * sc, x + (c + 1) * sc - 1, y + (r + 1) * sc - 1], fill=color)
        for mx, my in MB.get(mark, []):
            d.rectangle([x + mx * sc, y + my * sc, x + (mx + 1) * sc - 1, y + (my + 1) * sc - 1], fill=color)
        x += 6 * sc


def small(d, text, x, y, color, shadow=SHADOW):
    if shadow:
        small(d, text, x + 1, y + 1, shadow, None)
    for ch in text.upper():
        base, mark = ACC.get(ch, (ch, ""))
        bits = SMALL.get(base, SMALL.get("?", "0" * 15))
        for i, b in enumerate(bits):
            if b == "1":
                d.point((x + i % 3, y + i // 3), fill=color)
        for mx, my in MS.get(mark, []):
            d.point((x + mx, y + my), fill=color)
        x += 4


def backdrop():
    img = Image.new("RGBA", (W, H), (10, 10, 14, 255))
    for layer in ("sky", "far", "mid", "near"):
        p = os.path.join(SP, "bd_cor_%s.png" % layer)
        if os.path.exists(p):
            im = Image.open(p).convert("RGBA")
            img.alpha_composite(im.crop((0, 0, min(W, im.width), im.height)), (0, H - im.height))
    # o fundo no jogo fica um pouco apagado (backdrop.modulate)
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 70))
    img.alpha_composite(shade)
    return img


def title(options, selected, saved=""):
    img = backdrop()
    veil = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vp = veil.load()
    for x in range(250):
        a = 0.82 if x < 150 else 0.82 * (1 - (x - 150) / 100)
        for y in range(H):
            vp[x, y] = (7, 6, 11, int(a * 255))
    img.alpha_composite(veil)
    d = ImageDraw.Draw(img)
    mx = 34
    at = (mx - 4, 26)
    def bold(x, y, col):
        body(d, "MOKSHA", x, y, col, 4, None)
        body(d, "MOKSHA", x + 2, y, col, 4, None)
    for dy, col in ((10, INK), (8, BRONZE), (6, BRONZE)):
        bold(at[0], at[1] + dy, col)
    for dx, dy in ((-2, 0), (2, 0), (0, -2), (-2, -2), (2, -2), (-2, 4), (2, 4)):
        bold(at[0] + dx, at[1] + dy, INK)
    bold(at[0], at[1] + 2, DEEP)
    bold(at[0], at[1], FACE)
    w = 6 * 6 * 4 - 4 + 2
    sx, sy = mx - 2, 72
    c = sx + w // 2
    line = GOLD[:3] + (178,)
    d.rectangle([sx, sy, sx + w // 2 - 13, sy], fill=line)
    d.rectangle([c + 12, sy, sx + w - 1, sy], fill=line)
    for r in ([c - 9, sy - 2, c + 8, sy - 2], [c - 9, sy + 2, c + 8, sy + 2], [c - 11, sy - 1, c - 10, sy + 1],
              [c + 9, sy - 1, c + 10, sy + 1], [c - 2, sy - 1, c + 1, sy + 1]):
        d.rectangle(r, fill=GOLD)
    d.rectangle([c - 1, sy, c, sy], fill=INK)
    top = 98
    for i, label in enumerate(options):
        y = top + i * 15
        sel = i == selected
        x = mx
        if sel:
            m = mx - 13
            d.point((m + 2, y - 3), fill=GOLD)
            d.rectangle([m + 1, y - 2, m + 3, y - 2], fill=GOLD)
            d.rectangle([m, y - 1, m + 4, y - 1], fill=GOLD)
            d.rectangle([m + 1, y, m + 3, y], fill=GOLD)
            d.point((m + 2, y + 1), fill=GOLD)
            x += 3
        body(d, label, x, y - 4, GOLD if sel else DIM)
    foot = H - 14
    small(d, "J/K ESCOLHER   ESPAÇO CONFIRMAR", mx, foot, DIM)
    if saved:
        small(d, saved, mx, foot - 11, GOLD)
    small(d, "V0.3.0", W - 8 - 6 * 4 + 1, foot, DIM)
    return img


def main():
    a = title(["CONTINUAR", "COMEÇAR", "DESAFIO DO DIA", "APARÊNCIA", "OPÇÕES", "EXTRAS", "SAIR"], 0,
              "PARTIDA SALVA: SALÕES   ·   12:40")
    b = title(["COMEÇAR", "DESAFIO DO DIA", "APARÊNCIA", "OPÇÕES", "EXTRAS", "SAIR"], 2)
    sheet = Image.new("RGBA", (W * 2 + 6, H), (255, 0, 255, 255))
    sheet.paste(a, (0, 0))
    sheet.paste(b, (W + 6, 0))
    out = os.path.join(ROOT, "tools", "previews", "titulo.png")
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(out)
    print(out)


if __name__ == "__main__":
    main()
