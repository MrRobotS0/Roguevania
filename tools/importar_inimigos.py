"""Inimigos e chefes com arte pronta (Gothicvania, bestiário do OpenGameArt etc.).

    python tools/importar_inimigos.py     (depois de tools/baixar_arte.py)

Cada folha do jogo (assets/sprites/<nome>.png + .json) é refeita em cor cheia
("color": true) com os MESMOS nomes de animação que o script do inimigo pede
(sprite_anim). Idle/andar/voar ganham vários quadros; preparo e golpe ficam
com o quadro-chave, porque os scripts mostram o quadro 0 nesses estados.

Fontes:
  ("strip", caminho, n)          tira com n quadros iguais
  ("grid", caminho, fw, fh)      grade; o quadro é (coluna, linha)
  ("files", padrão)              um arquivo por quadro (ordem numérica)
Opções da folha: scale (inteiro), hue (graus), sat, bright, flip (a arte olha
para a esquerda; o jogo espera direita), key (cor de fundo a apagar).

Os pés ficam no fundo da célula, no centro: o alinhamento que o artista deu
dentro de cada tira é mantido (a âncora é o centro da célula de origem e o pé
mais baixo da tira).
"""
import colorsys
import glob
import json
import os
import re

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "arte_externa")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(ROOT, "tools", "previews")
GPC = "gothicvania-patreons-collection/ gothicvania patreon collection/"
BEST = "dark-fantasy-platformer-bestiary/"
CEM = "gothicvania-cemetery-pack/gothicvania-cemetery-files/PNG/Sprites/"
CHURCH = "gothicvania-church-pack/gothicvania church files/SPRITES/"
SWAMP = "gotthicvania-swamp/Gothicvania Swamp files/Sprites/"
GROTTO = "sideview-fantasy-patreon-collection/Sideview Fantasy Patreon Collection/Sprites/"

SOURCES = {
    "emperor": ("grid", "dark-emperor/darkemperor.png", 96, 48),
    "skel": ("files", CEM + "skeleton/skeleton-[0-9]*.png"),
    "skel_c": ("files", CEM + "skeleton-clothed/skeleton-clothed-[0-9]*.png"),
    "rise": ("files", CEM + "skeleton-rise/skeleton-rise-[0-9]*.png"),
    "rise_c": ("files", CEM + "skeleton-rise-clothed/skeleton-rise-clothed-[0-9]*.png"),
    "gato": ("files", CEM + "hell-gato/hell-gato-[0-9]*.png"),
    "ghost_h": ("files", CEM + "ghost-halo/ghost-halo-[0-9]*.png"),
    "angel": ("files", CHURCH + "angel/sprites/idle/angel[0-9]*.png"),
    "angel_atk": ("files", CHURCH + "angel/sprites/angel-attack/angel-attack-[0-9]*.png"),
    "wizard": ("strip", CHURCH + "wizard/spritesheet/wizard.png", 15),
    "ghoul": ("strip", CHURCH + "burning-ghoul/spritesheet/v1/burning-ghoul.png", 8),
    "hound_idle": ("strip", "hell-hound-character/Hell-Hound-Files/PNG/hell-hound-idle.png", 6),
    "hound_walk": ("strip", "hell-hound-character/Hell-Hound-Files/PNG/hell-hound-walk.png", 12),
    "hound_run": ("strip", "hell-hound-character/Hell-Hound-Files/PNG/hell-hound-run.png", 5),
    "hound_jump": ("strip", "hell-hound-character/Hell-Hound-Files/PNG/hell-hound-jump.png", 6),
    "wolf": ("strip", GPC + "wolf-runing-cycle/Sprites/wolf-runing-cycle.png", 4),
    "fskull": ("strip", GPC + "Fire-Skull-Files/PNG/fire-skull.png", 8),
    "ghost_idle": ("strip", GPC + "Ghost-Files/PNG/ghost-idle.png", 7),
    "ghost_shriek": ("strip", GPC + "Ghost-Files/PNG/ghost-shriek.png", 4),
    "ghost_appear": ("strip", GPC + "Ghost-Files/PNG/ghost-appears.png", 6),
    "beast_idle": ("strip", GPC + "Hell-Beast-Files/PNG/with-stroke/hell-beast-idle.png", 6),
    "beast_breath": ("strip", GPC + "Hell-Beast-Files/PNG/with-stroke/hell-beast-breath.png", 4),
    "beast_burn": ("strip", GPC + "Hell-Beast-Files/PNG/with-stroke/hell-beast-burn.png", 6),
    "mare_idle": ("strip", GPC + "Nightmare-Files/PNG/nightmare-idle.png", 4),
    "mare_run": ("strip", GPC + "Nightmare-Files/PNG/nightmare-galloping.png", 4),
    "demon_idle": ("strip", GPC + "demon-Files/PNG/demon-idle.png", 6),
    "demon_atk": ("strip", GPC + "demon-Files/PNG/demon-attack-no-breath.png", 8),
    "dragon_idle": ("strip", GROTTO + "Grotto-escape-2-boss-dragon/PNG/spritesheets/idle.png", 6),
    "dragon_breath": ("strip", GROTTO + "Grotto-escape-2-boss-dragon/PNG/spritesheets/breath.png", 7),
    "dragon_tail": ("strip", GROTTO + "Grotto-escape-2-boss-dragon/PNG/spritesheets/tail.png", 8),
    "lizard_walk": ("strip", GROTTO + "Grotto-escape-2-lizzard/PNG/spritesheets/walk.png", 6),
    "lizard_idle": ("strip", GROTTO + "Grotto-escape-2-lizzard/PNG/spritesheets/idle.png", 4),
    "lizard_tongue": ("strip", GROTTO + "Grotto-escape-2-lizzard/PNG/spritesheets/tongue.png", 5),
    "lizard_jump": ("strip", GROTTO + "Grotto-escape-2-lizzard/PNG/spritesheets/jump.png", 3),
    "spider": ("files", SWAMP + "Spider/walk/spider[0-9]*.png"),
    "thing": ("files", SWAMP + "Thing/walk thing/thing[0-9]*.png"),
    "golem": ("grid", BEST + "redshrike-thompson-golem-pal2-alpha.png", 64, 72),
    "wartaur": ("grid", BEST + "redshrike-wartaur-alpha.png", 80, 80),
    "frog": ("grid", BEST + "redshrike-evert-pufalotti-frogman-pal2-alpha.png", 80, 40),
    "eyewasp": ("grid", BEST + "redshrike-emceeflesher-eyewasp-alpha.png", 36, 36),
    "snail": ("grid", BEST + "surt-emceeflesher-spitsnail-alpha_0.png", 32, 32),
    "bat": ("grid", BEST + "redshrike-blatty-alpha.png", 64, 64),
    "worm": ("grid", BEST + "calciumtrice-emceeflesher-worm-alpha.png", 32, 32),
    "shambler": ("strip", BEST + "ansimuz-shambler-pal2-alpha_0.png", 4),
    "andro": ("grid", BEST + "balmer-andromalius-57x88-alpha.png", 57, 88),
    "minion": ("grid", BEST + "balmer-minion-45x66-alpha.png", 45, 66),
    # garimpo de 04/11 (escolhidos pelo que o desenho mostra x a história do personagem)
    "pwolf_sit": ("strip", "pixel-wolf/wolf_sit.png", 4),
    "pwolf_run": ("strip", "pixel-wolf/wolf_run.png", 5),
    "pwolf_jump": ("strip", "pixel-wolf/wolf_jump.png", 4),
    "pwolf_tail": ("strip", "pixel-wolf/wolf_tail.png", 2),
    "plant_idle": ("grid", "pixel-predator-plant-mob-character/Idle/Plant3_Idle_full.png", 64, 64),
    "plant_atk": ("grid", "pixel-predator-plant-mob-character/Attack/Plant3_Attack_full.png", 64, 64),
    "statue": ("grid", "animated-statue/statue spritesheet no green.png", 64, 64),
}


def seq(src, idx):
    return [(src, i) for i in idx]


def grid_row(src, row, cols):
    return [(src, (c, row)) for c in cols]


# Os "humanoides" de 6 animações (idle, walk, windup, attack, cast, rest).
def six(idle, walk, windup, attack, cast, rest):
    return {"idle": idle, "walk": walk, "windup": windup, "attack": attack, "cast": cast, "rest": rest}


SHEETS = {
    # ---- Mar de Cinzas
    "penitent": ({"idle": seq("skel_c", [0, 1]), "walk": seq("skel_c", range(8)), "windup": seq("skel_c", [3]),
                  "attack": seq("skel_c", [6]), "stun": seq("rise_c", [2])}, {"flip": True}),
    "assassin": ({"idle": seq("skel", [0, 1]), "walk": seq("skel", range(8)), "crouch": seq("rise", [1]),
                  "windup": seq("skel", [3]), "slash": seq("skel", [6])}, {"flip": True}),
    "archer": ({"idle": seq("wizard", range(5)), "walk": seq("wizard", range(5)), "aim": seq("wizard", [8]),
                "aim_lock": seq("wizard", [11])}, {}),
    "pilgrim": ({"walk": seq("ghoul", range(8)), "ignite": seq("ghoul", [3, 6])}, {"flip": True}),
    # Lobo Pálido: "guarda a porta de um dono que não volta" — lobo cinza-claro (alizard, CC0)
    "wolf": ({"idle": seq("pwolf_tail", [0, 1]), "run": seq("pwolf_run", range(5)), "crouch": seq("pwolf_sit", [0]),
              "lunge": seq("pwolf_jump", [1]), "stun": seq("pwolf_jump", [3])}, {"key": (12, 98, 98), "flip": True}),
    "gargoyle": ({"fly": grid_row("bat", 1, range(4)), "windup": grid_row("bat", 0, [0]), "dive": grid_row("bat", 1, [2])}, {}),
    "star": ({"idle": seq("fskull", range(8)), "windup": seq("fskull", [2, 5])}, {}),
    "emperor": ({"idle": grid_row("emperor", 0, range(4)), "walk": grid_row("emperor", 4, range(6)), "windup": grid_row("emperor", 1, [1]),
                 "sweep": grid_row("emperor", 1, [3]), "cast": grid_row("emperor", 2, [0, 1]), "kneel": grid_row("emperor", 6, [2]),
                 "summon": grid_row("emperor", 3, [0])}, {"scale": 2, "key": (0, 255, 255)}),
    # ---- Salões
    "guard": ({"idle": grid_row("wartaur", 0, range(4)), "walk": grid_row("wartaur", 0, range(4)), "windup": grid_row("wartaur", 1, [0]),
               "attack": grid_row("wartaur", 1, [2]), "recover": grid_row("wartaur", 1, [3]), "stun": grid_row("wartaur", 2, [1])},
              {"flip": True, "hue": 175, "sat": 0.45}),
    "inquisitor": ({"idle": seq("gato", [0, 1]), "walk": seq("gato", range(4)), "windup": seq("gato", [0]), "slash": seq("gato", [2]),
                    "crouch": seq("gato", [3]), "leap": seq("gato", [2])}, {"flip": True, "hue": 200, "sat": 0.6}),
    "herald": (six(seq("angel", range(8)), seq("angel", range(8)), seq("angel_atk", [0]), seq("angel_atk", [2]),
                   seq("angel_atk", [0, 1]), seq("angel", [0])), {}),
    "wolf_king": (six(seq("hound_idle", range(6)), seq("hound_walk", range(12)), seq("hound_jump", [0]), seq("hound_jump", [2]),
                      seq("hound_idle", [0, 3]), seq("hound_jump", [5])), {"flip": True, "scale": 2, "hue": 195, "sat": 0.55, "bright": 1.15}),
    # ---- Forja
    "automaton": (six(grid_row("golem", 0, [0, 2]), grid_row("golem", 1, range(6)), grid_row("golem", 2, [1]),
                      grid_row("golem", 2, [3]), grid_row("golem", 2, [1, 2]), grid_row("golem", 2, [5])), {"hue": 20, "sat": 0.6}),
    "smith": ({"idle": grid_row("andro", 0, range(8)), "walk": grid_row("andro", 1, range(8)), "windup": grid_row("andro", 2, [1]),
               "slam": grid_row("andro", 2, [4]), "stun": grid_row("andro", 2, [7])}, {"flip": True}),
    "slag": ({"idle": grid_row("worm", 1, [0, 1, 2]), "hop": grid_row("worm", 2, [3]), "land": grid_row("worm", 1, [4])}, {"hue": -40, "sat": 1.3}),
    "mason": (six(grid_row("minion", 0, [0, 1]), grid_row("minion", 0, range(4)), grid_row("minion", 0, [1]),
                  grid_row("minion", 1, [0]), grid_row("minion", 0, [2, 3]), grid_row("minion", 0, [0])), {"flip": True}),
    # Colosso da Bigorna: "o ferreiro que o deus esqueceu ligado" — estátua com martelo (Calciumtrice, CC-BY),
    # em 2x e puxada para bronze; o golpe bate o martelo e solta a onda no chão
    "colossus": (six(grid_row("statue", 0, range(4)), grid_row("statue", 1, range(8)), grid_row("statue", 2, [1]),
                     grid_row("statue", 2, [3]), grid_row("statue", 2, [0, 1]), grid_row("statue", 3, [2])),
                 {"scale": 2, "sat": 2.2, "bright": 0.8}),
    # ---- Jardim
    "moss_beast": ({"idle": grid_row("frog", 0, range(6)), "walk": grid_row("frog", 0, range(6)), "windup": grid_row("frog", 1, [0]),
                    "charge": grid_row("frog", 1, [1]), "rest": grid_row("frog", 2, [0])}, {"flip": True}),
    "seed_pod": ({"idle": grid_row("snail", 0, range(4)), "walk": grid_row("snail", 1, range(10)), "windup": grid_row("snail", 1, [4, 5]),
                  "attack": grid_row("snail", 1, [7])}, {"flip": True}),
    # Espinheiro: "abre a flor antes de atirar" — flor carnívora (CraftPix, OGA-BY), linha de perfil
    "thorn": ({"idle": grid_row("plant_idle", 3, range(4)), "windup": grid_row("plant_atk", 3, [2]),
               "attack": grid_row("plant_atk", 3, [5])}, {}),
    "mother_root": (six(seq("dragon_idle", range(6)), seq("dragon_idle", range(6)), seq("dragon_breath", [1]), seq("dragon_breath", [4]),
                        seq("dragon_tail", range(8)), seq("dragon_idle", [0])), {"flip": True, "scale": 2}),
    # ---- Torre de Babel
    "scribe": (six(seq("wizard", range(5)), seq("wizard", range(5)), seq("wizard", [8]), seq("wizard", [11]),
                   seq("wizard", [9, 10]), seq("wizard", [0])), {"hue": 230, "sat": 0.8}),
    "architect": (six(seq("demon_idle", range(6)), seq("demon_idle", range(6)), seq("demon_atk", [2]), seq("demon_atk", [5]),
                      seq("demon_atk", [0, 1]), seq("demon_idle", [0])), {"hue": 25, "sat": 0.7}),
    # ---- Carcosa
    "dancer": (six(seq("ghost_h", range(4)), seq("ghost_h", range(4)), seq("ghost_h", [1]), seq("ghost_h", [3]),
                   seq("ghost_h", [0, 2]), seq("ghost_h", [0])), {"hue": 40}),
    "masked": (six(seq("shambler", [0, 1]), seq("shambler", range(4)), seq("shambler", [1]), seq("shambler", [3]),
                   seq("shambler", [0, 2]), seq("shambler", [0])), {"hue": 30}),
    "faceless_king": (six(seq("mare_idle", range(4)), seq("mare_run", range(4)), seq("mare_idle", [1]), seq("mare_run", [2]),
                          seq("mare_idle", [2, 3]), seq("mare_idle", [0])), {"flip": True, "hue": 45, "sat": 0.9}),
    # ---- Observatório
    "lens": ({"idle": grid_row("eyewasp", 0, range(4)), "windup": grid_row("eyewasp", 1, [0, 2]), "attack": grid_row("eyewasp", 0, [1])},
             {"flip": True, "hue": 160}),
    "astronomer": (six(seq("ghost_idle", range(7)), seq("ghost_idle", range(7)), seq("ghost_shriek", [1]), seq("ghost_shriek", [3]),
                       seq("ghost_appear", range(6)), seq("ghost_idle", [0])), {"scale": 2, "hue": 200, "sat": 1.2}),
    # ---- elites (variações recoloridas)
    "elite_brass": (six(grid_row("golem", 0, [0, 2]), grid_row("golem", 1, range(6)), grid_row("golem", 2, [1]),
                        grid_row("golem", 2, [3]), grid_row("golem", 2, [1, 2]), grid_row("golem", 2, [5])), {"hue": 60, "sat": 1.4, "bright": 1.1}),
    "elite_duelist": (six(grid_row("wartaur", 0, range(4)), grid_row("wartaur", 0, range(4)), grid_row("wartaur", 1, [0]),
                          grid_row("wartaur", 1, [2]), grid_row("wartaur", 1, [1, 3]), grid_row("wartaur", 2, [1])), {"flip": True, "hue": -30}),
    "elite_forgemaster": (six(grid_row("andro", 0, range(8)), grid_row("andro", 1, range(8)), grid_row("andro", 2, [1]),
                              grid_row("andro", 2, [4]), grid_row("andro", 2, [2, 3]), grid_row("andro", 2, [7])), {"flip": True, "hue": -25, "sat": 1.3}),
    "elite_hunter": (six(seq("lizard_idle", range(4)), seq("lizard_walk", range(6)), seq("lizard_jump", [0]), seq("lizard_tongue", [3]),
                         seq("lizard_tongue", [1, 2]), seq("lizard_idle", [0])), {"scale": 2}),
    "elite_librarian": (six(seq("wizard", range(5)), seq("wizard", range(5)), seq("wizard", [8]), seq("wizard", [11]),
                            seq("wizard", [9, 10]), seq("wizard", [0])), {"hue": 120}),
    "elite_thornkeeper": (six(seq("spider", range(4)), seq("spider", range(4)), seq("spider", [1]), seq("spider", [3]),
                              seq("spider", [0, 2]), seq("spider", [0])), {"hue": 90, "scale": 2}),
}

FPS = {"idle": 6, "walk": 10, "run": 12, "fly": 10, "cast": 6}


# ------------------------------------------------------------------ leitura

def find(pattern):
    hits = [f for f in glob.glob(os.path.join(ART, pattern), recursive=True) if "__MACOSX" not in f and not os.path.basename(f).startswith("._")]
    if not hits:
        raise SystemExit("não achei: " + pattern)
    return hits


def num(path):
    m = re.findall(r"(\d+)", os.path.basename(path))
    return int(m[-1]) if m else 0


_cache = {}


def frames(name):
    """{índice: (Image do quadro, âncora x, âncora y)} de uma fonte."""
    if name in _cache:
        return _cache[name]
    spec = SOURCES[name]
    out = {}
    if spec[0] == "strip":
        im = Image.open(find(spec[1])[0]).convert("RGBA")
        n = spec[2]
        fw = im.width // n
        cells = {i: im.crop((i * fw, 0, (i + 1) * fw, im.height)) for i in range(n)}
    elif spec[0] == "grid":
        im = Image.open(find(spec[1])[0]).convert("RGBA")
        fw, fh = spec[2], spec[3]
        cells = {(c, r): im.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh))
                 for r in range(im.height // fh) for c in range(im.width // fw)}
    else:
        files = sorted(set(find(spec[1])), key=num)
        imgs = [Image.open(f).convert("RGBA") for f in files]
        w = max(i.width for i in imgs)
        h = max(i.height for i in imgs)
        cells = {}
        for k, i in enumerate(imgs):
            c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            c.paste(i, ((w - i.width) // 2, h - i.height))
            cells[k] = c
    for k, c in cells.items():
        out[k] = c
    _cache[name] = out
    return out


def clean(im, key):
    if key is None:
        return im
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and abs(r - key[0]) < 40 and abs(g - key[1]) < 40 and abs(b - key[2]) < 40:
                px[x, y] = (0, 0, 0, 0)
    return im


def recolor(im, hue, sat, bright):
    if hue == 0 and sat == 1.0 and bright == 1.0:
        return im
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h = (h + hue / 360.0) % 1.0
            r2, g2, b2 = colorsys.hsv_to_rgb(h, min(1.0, s * sat), min(1.0, v * bright))
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return im


def build(name, anims, opt):
    scale = opt.get("scale", 1)
    key = opt.get("key")
    # pé de cada fonte: o mais baixo entre os quadros usados dela
    used = {}
    for seq_ in anims.values():
        for src, i in seq_:
            used.setdefault(src, set()).add(i)
    foot = {}
    for src, idx in used.items():
        fr = frames(src)
        foot[src] = max((clean(fr[i], key).getbbox() or (0, 0, 0, fr[i].height))[3] for i in idx)
    # caixa total em volta da âncora (centro da célula, pé)
    left = right = up = 0
    for src, idx in used.items():
        for i in idx:
            im = clean(frames(src)[i], key)
            box = im.getbbox()
            if not box:
                continue
            ax = im.width / 2
            left = max(left, ax - box[0])
            right = max(right, box[2] - ax)
            up = max(up, foot[src] - box[1])
    half = int(max(left, right) + 1)
    cw, ch = (half * 2) * scale, (int(up) + 2) * scale
    cols = max(len(s) for s in anims.values())
    sheet = Image.new("RGBA", (cols * cw, len(anims) * ch), (0, 0, 0, 0))
    meta = {"w": cw, "h": ch, "size": max(cw, ch), "color": True, "anims": {}}
    for r, (anim, seq_) in enumerate(anims.items()):
        for c, (src, i) in enumerate(seq_):
            im = clean(frames(src)[i], key)
            if opt.get("flip"):
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
            im = recolor(im, opt.get("hue", 0), opt.get("sat", 1.0), opt.get("bright", 1.0))
            ox = half - im.width / 2
            oy = int(up) - foot[src]
            cell = Image.new("RGBA", (half * 2, int(up) + 2), (0, 0, 0, 0))
            cell.alpha_composite(im, (int(round(ox)), oy))
            if scale != 1:
                cell = cell.resize((cell.width * scale, cell.height * scale), Image.NEAREST)
            sheet.alpha_composite(cell, (c * cw, r * ch))
        meta["anims"][anim] = {"row": r, "frames": len(seq_), "fps": FPS.get(anim, 8)}
    sheet.save(os.path.join(OUT, name + ".png"))
    with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    return sheet, meta


def main():
    os.makedirs(PREV, exist_ok=True)
    only = os.environ.get("SO")
    shots = []
    for name, (anims, opt) in SHEETS.items():
        if only and name not in only.split(","):
            continue
        sheet, meta = build(name, anims, opt)
        # prévia: a primeira linha (idle/andar) de cada folha
        first = sheet.crop((0, 0, sheet.width, meta["h"]))
        shots.append((name, first))
        print("ok %-18s %dx%d  %s" % (name, meta["w"], meta["h"], " ".join("%s:%d" % (k, v["frames"]) for k, v in meta["anims"].items())))
    W = 1800
    x = y = rowh = 0
    pos = []
    for name, im in shots:
        if x + im.width > W:
            x, y, rowh = 0, y + rowh + 14, 0
        pos.append((x, y))
        x += im.width + 8
        rowh = max(rowh, im.height)
    prev = Image.new("RGBA", (W, y + rowh + 14), (44, 40, 54, 255))
    from PIL import ImageDraw
    d = ImageDraw.Draw(prev)
    for (name, im), (px, py) in zip(shots, pos):
        prev.alpha_composite(im, (px, py))
        d.text((px, py + im.height), name, fill=(255, 230, 140, 255))
        d.line([(px, py + im.height - 2), (px + im.width, py + im.height - 2)], fill=(90, 200, 90, 255))
    prev.save(os.path.join(PREV, "inimigos.png"))


if __name__ == "__main__":
    main()
