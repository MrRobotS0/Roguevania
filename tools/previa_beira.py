"""Prévia da Beira sem abrir o jogo: a sala com os desenhos no lugar.

    python tools/previa_beira.py saida.png
"""
import json
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
SPR = os.path.join(ROOT, "assets", "sprites")
T = 16
ANIM = {"1": "mantos", "2": "poco", "3": "carroca", "4": "marcas", "6": "limiar", "7": "poste", "8": "estatua", "9": "cinzas"}


def main(out):
    rows = [l.rstrip("\n") for l in open(os.path.join(ROOT, "content", "beira.txt"), encoding="utf-8") if not l.startswith(";")]
    meta = json.load(open(os.path.join(SPR, "beira.json")))
    sheet = Image.open(os.path.join(SPR, "beira.png")).convert("RGBA")
    props = Image.open(os.path.join(SPR, "bd_cor_sky.png")).convert("RGBA")
    img = Image.new("RGBA", (len(rows[0]) * T, len(rows) * T), (58, 50, 66, 255))
    for x in range(0, img.width, props.width):
        img.alpha_composite(props, (x, 0))
    d = ImageDraw.Draw(img)
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if c == "#":
                d.rectangle((x * T, y * T, x * T + T - 1, y * T + T - 1), fill=(38, 32, 42, 255), outline=(60, 52, 66, 255))
            elif c == "=":
                d.rectangle((x * T, y * T, x * T + T - 1, y * T + 3), fill=(92, 72, 58, 255))
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            cx, feet = int((x + 0.5) * T), (y + 1) * T
            if c in ANIM:
                r = meta["anims"][ANIM[c]]["row"]
                frame = sheet.crop((0, r * meta["h"], meta["w"], (r + 1) * meta["h"]))
                img.alpha_composite(frame, (cx - meta["w"] // 2, feet - meta["h"] + 2))
            elif c in "PV5":
                d.rectangle((cx - 6, feet - 26, cx + 6, feet - 1), outline=(255, 216, 102, 255))
                d.text((cx - 3, feet - 40), c, fill="white")
    img.save(out)
    print(img.size)


if __name__ == "__main__":
    main(sys.argv[1])
