"""Tiras de animação para o site (site/img/anim/), tiradas das prévias pintadas.

    python tools/site_assets.py

Cada tira é uma linha de quadros com fundo transparente, no tamanho do jogo
x2 (o CSS amplia sem borrar). Grava também site/img/anim/anim.json com a
largura, altura e número de quadros de cada uma.
"""
import json
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
PREV = os.path.join(ROOT, "tools", "previews")
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = os.path.join(ROOT, "site", "img", "anim")
SCALE = 4      # escala das prévias
KEEP = 2       # escala gravada


def frames(sheet, seq):
    meta = json.load(open(os.path.join(SPR, sheet + ".json")))
    w, h = meta.get("w", meta.get("size", 32)), meta.get("h", meta.get("size", 32))
    img = Image.open(os.path.join(PREV, sheet + ".png")).convert("RGBA")
    bg = img.getpixel((0, 0))
    out = []
    for anim, idx in seq:
        a = meta["anims"].get(anim)
        if not a:
            continue
        for i in (range(a["frames"]) if idx is None else [idx]):
            box = (i * w * SCALE, a["row"] * h * SCALE, (i + 1) * w * SCALE, (a["row"] + 1) * h * SCALE)
            fr = img.crop(box)
            px = fr.load()
            for y in range(fr.height):
                for x in range(fr.width):
                    if px[x, y][:3] == bg[:3]:
                        px[x, y] = (0, 0, 0, 0)
            out.append(fr.resize((w * KEEP, h * KEEP), Image.NEAREST))
    return out, w * KEEP, h * KEEP


def strip(name, sheet, seq, info):
    fr, w, h = frames(sheet, seq)
    s = Image.new("RGBA", (w * len(fr), h), (0, 0, 0, 0))
    for i, f in enumerate(fr):
        s.alpha_composite(f, (i * w, 0))
    s.save(os.path.join(OUT, name + ".png"))
    info[name] = {"w": w, "h": h, "n": len(fr)}


BOSSES = {
    "emperor": [("walk", None), ("windup", 0), ("sweep", 0), ("sweep", 0), ("cast", None), ("kneel", 0)],
    "wolf_king": [("walk", None), ("windup", 0), ("attack", 0), ("attack", 0), ("cast", None)],
    "colossus": [("walk", None), ("windup", 0), ("windup", 0), ("attack", 0), ("attack", 0), ("cast", None)],
    "architect": [("idle", None), ("cast", None), ("cast", None), ("windup", 0), ("attack", 0)],
    "mother_root": [("idle", None), ("walk", None), ("windup", 0), ("attack", 0), ("cast", None)],
    "faceless_king": [("walk", None), ("windup", 0), ("attack", 0), ("cast", None), ("rest", 0)],
    "astronomer": [("idle", None), ("cast", None), ("cast", None), ("windup", 0), ("attack", 0)],
}

ENEMIES = ["penitent", "guard", "pilgrim", "archer", "assassin", "inquisitor", "smith", "slag", "wolf",
           "scribe", "gargoyle", "thorn", "moss_beast", "masked", "herald", "automaton", "star",
           "mason", "seed_pod", "dancer", "lens"]

MOVES = {
    "run": [("run", None)],
    "roll": [("roll", None)],
    "flip": [("jump", 0), ("flip", None), ("fall", 0)],
    "dash": [("dash", None), ("dash", None), ("dash", None)],
    "combo": [("atk_down", None), ("atk_up", None), ("atk_thrust", None)],
    "smash": [("atk_smash", None), ("atk_spin", None)],
    "idle": [("idle", None), ("idle_look", None)],
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    info = {}
    for b, seq in BOSSES.items():
        strip("boss_" + b, b, seq, info)
    for e in ENEMIES:
        if os.path.exists(os.path.join(PREV, e + ".png")):
            meta = json.load(open(os.path.join(SPR, e + ".json")))
            first = next(iter(meta["anims"]))
            seq = [(first, None)]
            for extra in ("walk", "run", "fly", "windup", "attack", "cast"):
                if extra in meta["anims"] and extra != first:
                    seq.append((extra, None))
            strip("enemy_" + e, e, seq, info)
    for m, seq in MOVES.items():
        strip("hero_" + m, "hero", seq, info)
    json.dump(info, open(os.path.join(OUT, "anim.json"), "w"), indent=1)
    print(len(info), "tiras")
