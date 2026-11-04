"""Monta a folha do herói (assets/sprites/hero_g.png + .json) a partir do
herói gótico do Gothicvania (ansimuz, CC0), com os nomes de animação que o
jogo usa. Todos os quadros ficam numa grade igual, com os pés no mesmo ponto.

    python tools/importar_heroi.py      (depois de tools/baixar_arte.py)
"""
import json
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "arte_externa", "gothicvania-patreons-collection", " gothicvania patreon collection")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(ROOT, "tools", "previews")
CW, CH = 112, 88          # célula da grade
FOOT = CH - 2             # linha dos pés dentro da célula

STRIPS = {
    "idle": ("Gothic-hero-Files/PNG/gothic-hero-idle.png", 4),
    "run": ("Gothic-hero-Files/PNG/gothic-hero-run.png", 12),
    "attack": ("Gothic-hero-Files/PNG/gothic-hero-attack.png", 6),
    "jump": ("Gothic-hero-Files/PNG/gothic-hero-jump.png", 5),
    "crouch": ("Gothic-hero-p2-Files/PNG/spritesheets/gothic-hero-crouch.png", 3),
    "slash": ("Gothic-hero-p2-Files/PNG/spritesheets/gothic-hero-crouch-slash.png", 4),
    "hurt": ("Gothic-hero-p2-Files/PNG/spritesheets/gothic-hero-hurt.png", 3),
    "air": ("Gothic-hero-p2-Files/PNG/spritesheets/gothic-hero-jump-attack.png", 6),
    "climb": ("Gothic-hero-p2-Files/PNG/spritesheets/gothic-hero-jump-climb.png", 7),
}

# nome no jogo: [(tira, quadro)...], quadros por segundo
ANIMS = {
    "idle": ([("idle", i) for i in range(4)], 6),
    "idle_look": ([("idle", i) for i in (0, 1, 2, 3, 3, 2, 1, 0, 0, 1, 2, 3)], 6),
    "run": ([("run", i) for i in range(12)], 16),
    "jump": ([("jump", 0), ("jump", 1)], 10),
    "fall": ([("jump", 3), ("jump", 4)], 10),
    "roll": ([("crouch", 1), ("crouch", 2), ("crouch", 2), ("crouch", 2), ("crouch", 1), ("crouch", 0)], 20),
    "dash": ([("run", 5), ("run", 11)], 12),
    "flip": ([("air", 2), ("air", 3), ("jump", 2), ("air", 3), ("air", 2), ("jump", 3)], 20),
    "hurt": ([("hurt", 1), ("hurt", 2)], 12),
    "climb": ([("climb", 3), ("climb", 6)], 8),
    "dive": ([("air", 5), ("air", 5)], 12),
    "shoot": ([("attack", 0), ("attack", 1), ("attack", 3)], 1),
    "block": ([("crouch", 0)], 1),
    "heal": ([("idle", 0), ("idle", 1)], 6),
    "dead": ([("hurt", 2)], 1),
    "windup": ([("attack", 0)], 1),
    "strike": ([("attack", 2)], 1),
    "recover": ([("attack", 4)], 1),
}
# cada golpe do combo: preparo (0-1), impacto (2-3), volta (4-5)
for shape in ("down", "up", "thrust", "smash", "jab", "lash", "spin"):
    ANIMS["atk_" + shape] = ([("attack", i) for i in range(6)], 1)


def frames_of(strip):
    path, n = STRIPS[strip]
    im = Image.open(os.path.join(SRC, path)).convert("RGBA")
    w = im.width // n
    return [im.crop((i * w, 0, (i + 1) * w, im.height)) for i in range(n)]


def anchor(fr):
    """Onde ficam os pés: centro das colunas opacas nas últimas linhas do corpo."""
    box = fr.getbbox()
    if not box:
        return fr.width // 2, fr.height
    px = fr.load()
    bottom = box[3]
    xs = [x for y in range(max(box[1], bottom - 5), bottom) for x in range(fr.width) if px[x, y][3] > 0]
    cx = sum(xs) / len(xs) if xs else (box[0] + box[2]) / 2
    return round(cx), bottom


def main():
    cache = {k: frames_of(k) for k in STRIPS}
    # Âncora fixa por tira (a do primeiro quadro, e o pé mais baixo da tira):
    # o artista já alinhou os quadros dentro da tira. Ancorar quadro a quadro
    # pelo pé fazia o corpo pular até 25 px para os lados na corrida.
    first = {}
    for seq, _ in ANIMS.values():
        for strip, i in seq:
            first.setdefault(strip, i)
    ref_x = {}
    for k in cache:
        box = cache[k][first.get(k, 0)].getbbox()
        ref_x[k] = round((box[0] + box[2]) / 2)
    ref_y = {k: max(anchor(f)[1] for f in cache[k]) for k in cache}
    rows = list(ANIMS.items())
    cols = max(len(seq) for seq, _ in ANIMS.values())
    sheet = Image.new("RGBA", (cols * CW, len(rows) * CH), (0, 0, 0, 0))
    meta = {"w": CW, "h": CH, "size": CW, "color": True, "key_hue": 0.97, "anims": {}}
    for r, (name, (seq, fps)) in enumerate(rows):
        for i, (strip, k) in enumerate(seq):
            fr = cache[strip][k]
            ax, ay = ref_x[strip], ref_y[strip]
            ox = i * CW + CW // 2 - ax
            oy = r * CH + FOOT - ay
            sheet.alpha_composite(fr, (max(ox, i * CW), max(oy, r * CH)) if False else (ox, oy))
        meta["anims"][name] = {"row": r, "frames": len(seq), "fps": fps, "hands": [[[6, -18]]] * len(seq)}
    # recorta o que vazou para a célula vizinha (o rastro do golpe é largo)
    sheet.save(os.path.join(OUT, "hero_g.png"))
    json.dump(meta, open(os.path.join(OUT, "hero_g.json"), "w"), indent=1)
    prev = Image.new("RGBA", sheet.size, (52, 44, 60, 255))
    prev.alpha_composite(sheet)
    os.makedirs(PREV, exist_ok=True)
    prev.save(os.path.join(PREV, "hero_g.png"))
    print("hero_g", sheet.size, len(rows), "animações")


if __name__ == "__main__":
    main()
