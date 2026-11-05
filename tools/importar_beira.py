"""Arte da Beira (a área onde o herói renasce) e a sala dela.

    python tools/importar_beira.py

Tudo CC0, do ansimuz (Gothicvania): poço, carroça, estandarte, lápides, poste,
estátua e o arco de pedra. Monta uma folha colorida de quadros 112x112, com a
base do desenho na linha 110 (é onde `region_sprite` põe o chão).
"""
import json
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "arte_externa")
OUT = os.path.join(ROOT, "assets", "sprites")
CEM = os.path.join(ART, "gothicvania-cemetery-pack", "gothicvania-cemetery-files", "PNG", "Environment", "sliced-objects")
TOWN = os.path.join(ART, "gothicvania-town", "GothicVania-town-files", "PNG", "environment", "props-sliced")
FORT = os.path.join(ART, "fort-of-illusion", "Fort of Illusion Files", "Layers", "Props")
CELL = 112
FLOOR = 110


def art(folder, name):
    return Image.open(os.path.join(folder, name + ".png")).convert("RGBA")


def cell():
    return Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))


def centered(img):
    c = cell()
    c.alpha_composite(img, ((CELL - img.width) // 2, FLOOR - img.height))
    return c


# Os mantos: o estandarte pendurado numa trave entre dois postes.
def mantos():
    c = cell()
    d = ImageDraw.Draw(c)
    banner = art(FORT, "banner")
    top = FLOOR - banner.height - 16
    left, right = (CELL - banner.width) // 2 - 4, (CELL + banner.width) // 2 + 3
    for x in (left, right):
        d.rectangle((x, top, x + 2, FLOOR - 1), fill=(38, 26, 24, 255))
        d.rectangle((x + 1, top, x + 1, FLOOR - 1), fill=(74, 50, 38, 255))
    d.rectangle((left - 2, top, right + 4, top + 2), fill=(38, 26, 24, 255))
    d.rectangle((left - 2, top, right + 4, top), fill=(74, 50, 38, 255))
    c.alpha_composite(banner, ((CELL - banner.width) // 2, top + 2))
    return c


# As marcas: quatro lápides lado a lado.
def marcas():
    c = cell()
    x = 5
    for name in ("stone-4", "stone-1", "stone-3", "stone-2"):
        s = art(CEM, name)
        c.alpha_composite(s, (x, FLOOR - s.height))
        x += s.width + 1
    return c


# O monte de cinza onde o herói renasce.
def cinzas():
    c = cell()
    rng = random.Random(13)
    tones = [(52, 48, 56, 255), (74, 70, 78, 255), (104, 98, 106, 255), (138, 130, 144, 255)]
    for x in range(CELL // 2 - 24, CELL // 2 + 25):
        k = 1.0 - ((x - CELL // 2) / 24.0) ** 2
        tall = max(1, round(k * 9 + rng.uniform(-1, 1)))
        for i in range(tall):
            tone = tones[min(3, (i * 4) // max(tall, 1))]
            c.putpixel((x, FLOOR - 1 - i), tone if rng.random() > 0.08 else tones[0])
    return c


SHEET = [
    ("mantos", mantos()),
    ("poco", centered(art(TOWN, "well"))),
    ("carroca", centered(art(TOWN, "wagon"))),
    ("marcas", marcas()),
    ("limiar", centered(art(FORT, "door"))),
    ("poste", centered(art(TOWN, "street-lamp"))),
    ("estatua", centered(art(CEM, "statue"))),
    ("cinzas", cinzas()),
]

# Plano: anda-se direto, sem pulo obrigatório (é o caminho de toda partida).
# 1 mantos  2 poço  3 carroça  4 marcas  5 braseiro  6 limiar
# 7 poste   8 estátua  9 cinzas
W = 72
SPOTS = ((3, "P"), (5, "9"), (10, "V"), (17, "1"), (22, "7"), (27, "2"), (38, "3"), (44, "7"), (49, "4"), (57, "5"), (61, "8"), (67, "6"))
DOOR_TOP = 9    # o arco tem 5 blocos de altura: a parede desce até ele
FLOOR_ROW = 13
PLATFORMS = {7: ((35, 39), (46, 51)), 10: ((30, 34), (52, 55))}


def row_at(y):
    row = ["."] * W
    row[0] = "#"
    row[W - 1] = "#"
    # a parede do fundo: acima do arco e depois dele
    for x in range(63 if y < DOOR_TOP else 70, W):
        row[x] = "#"
    for a, b in PLATFORMS.get(y, ()):
        for x in range(a, b):
            row[x] = "="
    if y == FLOOR_ROW:
        for x, ch in SPOTS:
            row[x] = ch
    return "".join(row)


def room():
    lines = ["; A Beira: onde o herói renasce e onde toda partida começa", "; tipo: beira", "#" * W]
    lines += [row_at(y) for y in range(1, FLOOR_ROW + 1)]
    lines += ["#" * W] * 4
    return "\n".join(lines) + "\n"


def main():
    sheet = Image.new("RGBA", (CELL, CELL * len(SHEET)), (0, 0, 0, 0))
    anims = {}
    for row, (name, img) in enumerate(SHEET):
        sheet.alpha_composite(img, (0, row * CELL))
        anims[name] = {"row": row, "frames": 1, "fps": 1, "hands": [[[0, 0]]]}
    sheet.save(os.path.join(OUT, "beira.png"))
    with open(os.path.join(OUT, "beira.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"size": CELL, "w": CELL, "h": CELL, "color": True, "anims": anims}, f)
    with open(os.path.join(ROOT, "content", "beira.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write(room())
    print("beira.png", sheet.size, "· sala", W, "de largura")


if __name__ == "__main__":
    main()
