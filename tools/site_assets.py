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
    if meta.get("color"):
        # arte pronta em cor cheia: a própria folha do jogo, sem prévia pintada
        img = Image.open(os.path.join(SPR, sheet + ".png")).convert("RGBA")
        out = []
        for anim, idx in seq:
            a = meta["anims"].get(anim)
            if not a:
                continue
            for i in (range(a["frames"]) if idx is None else [idx]):
                fr = img.crop((i * w, a["row"] * h, (i + 1) * w, (a["row"] + 1) * h))
                out.append(fr.resize((w * KEEP, h * KEEP), Image.NEAREST))
        return out, w * KEEP, h * KEEP
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
    # tira justa: corta todos os quadros pela caixa que soma todos eles. O pé
    # fica na borda de baixo e o corpo não pula entre quadros (o site alinha
    # pelo pé e escala pelo tamanho real, sem margem transparente).
    boxes = [f.getbbox() for f in fr if f.getbbox()]
    if boxes:
        x0, y0 = min(b[0] for b in boxes), min(b[1] for b in boxes)
        x1, y1 = max(b[2] for b in boxes), max(b[3] for b in boxes)
        fr = [f.crop((x0, y0, x1, y1)) for f in fr]
        w, h = x1 - x0, y1 - y0
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
           "mason", "seed_pod", "dancer", "lens",
           # grande update: 6 domínios novos (comuns e elites)
           "mourner", "risen", "grave_cat", "drowned", "votive", "prayer", "maw_tentacle", "larva", "parasite",
           "nightmare", "incubus", "sleepwalker", "blind_lizard", "crevice_snake", "digger", "highwayman",
           "wanderer", "frogman", "elite_caller", "elite_priestess", "elite_glutton", "elite_reverie",
           "elite_hermit", "elite_bull", "elite_duelist", "elite_hunter", "elite_librarian", "elite_forgemaster",
           "elite_thornkeeper", "elite_brass"]

# chefes novos: a folha já se chama boss_<nome>
NEW_BOSSES = ["boss_forgotten", "boss_answer", "boss_insatiable", "boss_dragon", "boss_wyrm", "boss_fox"]
SIX = [("idle", None), ("walk", None), ("windup", 0), ("attack", 0), ("cast", None)]

MOVES = {
    "run": [("run", None)],
    "roll": [("roll", None)],
    "flip": [("jump", 0), ("flip", None), ("fall", 0)],
    "dash": [("dash", None), ("dash", None), ("dash", None)],
    "combo": [("atk_down", None), ("atk_up", None), ("atk_thrust", None)],
    "smash": [("atk_smash", None), ("atk_spin", None)],
    "idle": [("idle", None), ("idle_look", None)],
}

# domínio no site: prefixo dos fundos no jogo
DOMAINS = {"mar": "bd", "saloes": "bd_saloes", "forja": "bd_forja", "torre": "bd_torre",
           "jardim": "bd_jardim", "carcosa": "bd_carcosa", "observatorio": "bd_observatorio",
           "necropole": "bd_necropole", "catedral": "bd_catedral", "ventre": "bd_ventre",
           "penhascos": "bd_penhascos", "cavernas": "bd_cavernas", "bosque": "bd_bosque"}


def scenery():
    """Camadas do diorama 3D, a imagem de cada domínio e o herói (ícone e corrida)."""
    img = os.path.join(ROOT, "site", "img")
    os.makedirs(os.path.join(img, "layers"), exist_ok=True)
    for dom, prefix in DOMAINS.items():
        comp = None
        for layer in ("sky", "far", "mid", "near"):
            src = Image.open(os.path.join(SPR, "%s_cor_%s.png" % (prefix, layer))).convert("RGBA")
            src.save(os.path.join(img, "layers", "%s_%s.png" % (dom, layer)))
            if comp is None:
                comp = src.copy()
            else:
                comp.alpha_composite(src.crop((0, 0, comp.width, comp.height)))
        comp.resize((comp.width * 2, comp.height * 2), Image.NEAREST).save(os.path.join(img, dom + ".png"))
    meta = json.load(open(os.path.join(SPR, "hero_g.json")))
    sheet = Image.open(os.path.join(SPR, "hero_g.png")).convert("RGBA")
    w, h = meta["w"], meta["h"]

    def cell(anim, i, size):
        a = meta["anims"][anim]
        fr = sheet.crop((i * w, a["row"] * h, (i + 1) * w, (a["row"] + 1) * h))
        box = fr.getbbox()
        fr = fr.crop((box[0], 0, box[2], h))
        k = max(1, min(size // fr.width, size // h))
        fr = fr.resize((fr.width * k, h * k), Image.NEAREST)
        out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        out.alpha_composite(fr, ((size - fr.width) // 2, size - fr.height))
        return out

    # corrida: a caixa de todos os quadros juntos, ampliada inteira até caber em 128
    run = meta["anims"]["run"]
    row = run["row"]
    picks = [k * run["frames"] // 8 for k in range(8)]
    frs = [sheet.crop((i * w, row * h, (i + 1) * w, (row + 1) * h)) for i in picks]
    boxes = [f.getbbox() for f in frs]
    ux0, uy0 = min(b[0] for b in boxes), min(b[1] for b in boxes)
    ux1, uy1 = max(b[2] for b in boxes), max(b[3] for b in boxes)
    k = max(1, min(128 // (ux1 - ux0), 128 // (uy1 - uy0)))
    strip_ = Image.new("RGBA", (128 * 8, 128), (0, 0, 0, 0))
    for n, f in enumerate(frs):
        f = f.crop((ux0, uy0, ux1, uy1))
        f = f.resize((f.width * k, f.height * k), Image.NEAREST)
        strip_.alpha_composite(f, (n * 128 + (128 - f.width) // 2, 128 - f.height))
    strip_.save(os.path.join(img, "heroi_corrida.png"))
    cell("idle", 0, 256).save(os.path.join(img, "heroi.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    scenery()
    info = {}
    for b, seq in BOSSES.items():
        strip("boss_" + b, b, seq, info)
    for b in NEW_BOSSES:
        strip(b, b, SIX, info)
    # ícones do equipamento para a Wiki
    icons = os.path.join(ROOT, "site", "img", "icons")
    os.makedirs(icons, exist_ok=True)
    for f in os.listdir(os.path.join(ROOT, "assets", "icons")):
        if f.endswith(".png") and not f.endswith("_16.png"):
            Image.open(os.path.join(ROOT, "assets", "icons", f)).save(os.path.join(icons, f))
    for e in ENEMIES:
        if os.path.exists(os.path.join(SPR, e + ".json")):
            meta = json.load(open(os.path.join(SPR, e + ".json")))
            first = next(iter(meta["anims"]))
            seq = [(first, None)]
            for extra in ("walk", "run", "fly", "windup", "attack", "cast"):
                if extra in meta["anims"] and extra != first:
                    seq.append((extra, None))
            strip("enemy_" + e, e, seq, info)
    for m, seq in MOVES.items():
        strip("hero_" + m, "hero_g", seq, info)
    json.dump(info, open(os.path.join(OUT, "anim.json"), "w"), indent=1)
    print(len(info), "tiras")
