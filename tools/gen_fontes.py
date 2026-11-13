"""Converte fontes pixel (OFL, em tools/fontes) para a grade 5x7 do PixelFont.

    python tools/gen_fontes.py [previa.png]

Cada letra vira 7 linhas de 5 colunas ("#" e "."), no mesmo formato da tabela
BODY de scripts/ui/pixel_font.gd. A base da letra fica na última linha. Letra
mais larga que 5 perde colunas repetidas; se ainda não couber, fica de fora e o
jogo usa a da fonte clássica. Os acentos continuam os do jogo (desenhados por
cima da letra-base), então todas as fontes escrevem português.

Gera scripts/ui/font_tables.gd. Com um caminho, salva também uma prévia.
"""
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DIR = os.path.join(ROOT, "tools", "fontes")
W, H = 5, 7

# id: (arquivo, tamanho em px, nome na tela)
FONTS = {
    "silkscreen": ("Silkscreen-Regular.ttf", 8, "SILKSCREEN"),
    "pixelify": ("PixelifySans[wght].ttf", 10, "PIXELIFY"),
    "tiny5": ("Tiny5.ttf", 8, "TINY5"),
}


def chars():
    src = open(os.path.join(ROOT, "scripts", "ui", "pixel_font.gd"), encoding="utf-8").read()
    start = src.index("const BODY :=")
    block = src[start:src.index("\n}", start)]
    return [c.encode().decode("unicode_escape") if c.startswith("\\") else c
            for c in re.findall(r'^\t"(.+?)": \[', block, re.M)]


def squeeze(cols, limit):
    """Tira colunas (ou linhas) iguais à vizinha até caber."""
    cols = list(cols)
    while len(cols) > limit:
        for i in range(1, len(cols)):
            if cols[i] == cols[i - 1]:
                del cols[i]
                break
        else:
            return None
    return cols


def raster(font, ch):
    im = Image.new("1", (64, 64), 0)
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    base = 40
    d.text((10, base), ch, font=font, fill=1, anchor="ls")
    box = im.getbbox()
    if box is None:
        return ["." * W] * H
    x0, y0, x1, y1 = box
    rows = [[im.getpixel((x, y)) for x in range(x0, x1)] for y in range(y0, y1)]
    # vírgula, Q e afins descem da linha de base: sobem até caber
    bottom = y1 - base               # pixels abaixo da base
    top_row = H - (base - y0)        # linha da grade onde a letra começa (pode ser < 0)
    if bottom > 0:
        top_row -= bottom
    if top_row < 0:
        rows = squeeze(rows, H)
        if rows is None:
            return None
        top_row = max(H - len(rows), 0)
    cols = squeeze(list(zip(*rows)), W)
    if cols is None:
        return None
    rows = [list(r) for r in zip(*cols)]
    w = len(cols)
    left = (W - w) // 2
    grid = [["."] * W for _ in range(H)]
    for r, line in enumerate(rows):
        for c, on in enumerate(line):
            if on and 0 <= top_row + r < H:
                grid[top_row + r][left + c] = "#"
    return ["".join(r) for r in grid]


def main():
    keys = [c for c in chars() if c not in "↑←→↓·"]
    tables = {}
    for fid, (file, size, _) in FONTS.items():
        font = ImageFont.truetype(os.path.join(DIR, file), size)
        table = {}
        for ch in keys:
            if ch == " ":
                continue
            g = raster(font, ch)
            if g is not None:
                table[ch] = g
        tables[fid] = table
        print(fid, len(table), "letras de", len(keys) - 1)

    out = ["# Gerado por tools/gen_fontes.py a partir das fontes em tools/fontes (SIL OFL 1.1).",
           "# Não editar à mão.", "class_name FontTables", "", "const NAMES := {"]
    for fid, (_, _, name) in FONTS.items():
        out.append('\t"%s": "%s",' % (fid, name))
    out += ["}", "", "const TABLES := {"]
    for fid, table in tables.items():
        out.append('\t"%s": {' % fid)
        for ch, rows in table.items():
            key = ch.replace("\\", "\\\\").replace('"', '\\"')
            out.append('\t\t"%s": [%s],' % (key, ", ".join('"%s"' % r for r in rows)))
        out.append("\t},")
    out.append("}")
    path = os.path.join(ROOT, "scripts", "ui", "font_tables.gd")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print("gravado", path)

    if len(sys.argv) > 1:
        sample = "AÇÃO! FÚRIA, VIDA 120. MOKSHA ?:;-+=/()"
        scale = 4
        img = Image.new("RGB", ((len(sample) * 6 + 4) * scale, (len(tables) * 12 + 4) * scale), (14, 11, 20))
        d = ImageDraw.Draw(img)
        for row, (fid, table) in enumerate(tables.items()):
            for i, ch in enumerate(sample):
                base = {"Ç": "C", "Ã": "A", "Ú": "U"}.get(ch, ch)
                g = table.get(base)
                color = (242, 236, 255) if g else (255, 90, 90)
                for r, line in enumerate(g or ["#####"] * 7):
                    for c, px in enumerate(line):
                        if px == "#":
                            x = (2 + i * 6 + c) * scale
                            y = (2 + row * 12 + r) * scale
                            d.rectangle([x, y, x + scale - 1, y + scale - 1], fill=color)
        img.save(sys.argv[1])


if __name__ == "__main__":
    main()
