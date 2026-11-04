"""Gera a Wiki do MOKSHA (site/wiki.html) direto dos dados do jogo.

    python tools/gerar_wiki.py      (depois de tools/site_assets.py)

Tudo vem do que o jogo usa de verdade: domínios e inscrições (content/biomes),
bestiário e história (scripts/combat/story.gd), rota (scripts/autoload/run.gd),
armas, habilidades e aparências (content/), mutações e bênçãos
(scripts/combat/catalog.gd). O inglês vem de content/lang/en.txt. Assim a
Wiki nunca fica para trás: rodou o gerador, está igual ao jogo.
"""
import colorsys
import glob
import html
import json
import os
import re

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SITE = os.path.join(ROOT, "site")
IMG = os.path.join(SITE, "img")


def read(*p):
    return open(os.path.join(ROOT, *p), encoding="utf-8").read()


# ---------------------------------------------------------------- inglês
EN = {}
for line in read("content", "lang", "en.txt").splitlines():
    if line.startswith(";") or " = " not in line:
        continue
    k, v = line.split(" = ", 1)
    EN[k.strip()] = v.strip()


def sentence(t):
    """O inglês do jogo é todo em maiúsculas: aqui vira frase normal."""
    t = t.lower()
    out, cap = [], True
    for ch in t:
        out.append(ch.upper() if cap and ch.isalpha() else ch)
        if ch.isalpha():
            cap = False
        if ch in ".!?:\"":
            cap = True
    s = "".join(out)
    return re.sub(r"\bi\b", "I", s)


def titlecase(t):
    small = {"of", "the", "and", "in", "a", "to"}
    words = t.lower().split()
    return " ".join(w if (i and w in small) else w[:1].upper() + w[1:] for i, w in enumerate(words))


def en(pt, kind="sentence"):
    t = EN.get(pt.upper().strip())
    if not t:
        return pt
    return titlecase(t) if kind == "title" else sentence(t)


def esc(t):
    return html.escape(t, quote=True)


def bi(pt, en_text=None, kind="sentence", tag="span"):
    """Texto nos dois idiomas; o CSS mostra um conforme html[data-lang]."""
    if en_text is None:
        en_text = en(pt, kind)
    if kind == "title":
        pt = pt[:1].upper() + pt[1:]
    return '<%s lang="pt">%s</%s><%s lang="en">%s</%s>' % (tag, esc(pt), tag, tag, esc(en_text), tag)


def pt_title(t):
    """Títulos do jogo vêm em maiúsculas (O REI SEM ROSTO): vira O Rei sem Rosto."""
    small = {"de", "da", "do", "das", "dos", "e", "sem", "que", "a", "o", "em"}
    words = t.lower().split()
    return " ".join(w if (i and w in small) else w[:1].upper() + w[1:] for i, w in enumerate(words))


# ---------------------------------------------------------------- dados do jogo
def tres(path):
    out = {}
    for line in open(path, encoding="utf-8"):
        m = re.match(r"^(\w+) = (.*)$", line.rstrip("\n"))
        if not m:
            continue
        k, v = m.groups()
        if v.startswith('"'):
            out[k] = json.loads(v)
        elif v.startswith("["):
            try:
                out[k] = json.loads(v)
            except ValueError:
                out[k] = v
        elif re.fullmatch(r"-?\d+(\.\d+)?", v):
            out[k] = float(v) if "." in v else int(v)
        elif v in ("true", "false"):
            out[k] = v == "true"
        elif v.startswith("Color("):
            r, g, b = [float(x) for x in v[6:-1].split(",")[:3]]
            out[k] = "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))
        else:
            out[k] = v
    return out


def dict_block(text):
    """Os dicionários do GDScript que importam aqui são JSON válido linha a linha."""
    text = re.sub(r"Color\(([^)]*)\)", lambda m: '"Color(%s)"' % m.group(1), text)
    return json.loads(text)


# criaturas: script -> (título, folha)
CREATURES = {}
for f in glob.glob(os.path.join(ROOT, "scripts", "enemies", "*.gd")):
    s = open(f, encoding="utf-8").read()
    t = re.search(r'\btitle = "([^"]+)"', s)
    sh = re.search(r'\bsheet = "([^"]+)"', s)
    if t:
        CREATURES[os.path.basename(f)[:-3]] = (t.group(1), sh.group(1) if sh else "")

story = read("scripts", "combat", "story.gd")
BEST = dict(re.findall(r'^\t"([^"]+)": "((?:[^"\\]|\\.)*)",$', story, re.M))


def story_list(name):
    m = re.search(r"const %s := \[(.*?)\n\]" % name, story, re.S)
    return [json.loads('"%s"' % x) for x in re.findall(r'^\t"((?:[^"\\]|\\.)*)",$', m.group(1), re.M)]


INTRO, ENDING, TRUE_ENDING = story_list("INTRO"), story_list("ENDING"), story_list("TRUE_ENDING")

run = read("scripts", "autoload", "run.gd")
STAGES = {}
for k, v in re.findall(r'^\t"(\w+)": (\{.*\}),$', run, re.M):
    STAGES[k] = json.loads(v)

catalog = read("scripts", "combat", "catalog.gd")


def catalog_list(name):
    m = re.search(r"const %s := \[(.*?)\n\]" % name, catalog, re.S)
    return [dict_block(x) for x in re.findall(r"^\t(\{.*\}),$", m.group(1), re.M)]


MUTATIONS, BLESSINGS = catalog_list("MUTATIONS"), catalog_list("BLESSINGS")
STAGE_NAMES = dict(re.findall(r'^\t"(\w+)": "([^"]+)",$', catalog.split("const STAGE_NAMES")[1].split("}")[0], re.M))
HINTS = {"mar_de_cinzas": "O COMEÇO DE TODA PARTIDA · CINZA E VIDRO"}
HINTS.update(dict(re.findall(r'^\t"(\w+)": "([^"]+)",$', catalog.split("const STAGE_HINTS")[1].split("}")[0], re.M)))

hud = read("scripts", "ui", "hud_theme.gd")
ACCENT = {k: "#" + v for k, v in re.findall(r'^\t"(\w+)": \{.*?"accent": "(\w+)"', hud, re.M)}

ORDER = ["mar_de_cinzas", "saloes", "forja_rubra", "necropole", "torre_babel", "jardim_primordial", "catedral",
         "carcosa", "observatorio", "ventre", "penhascos", "cavernas", "bosque"]
SITE_ID = {"mar_de_cinzas": "mar", "forja_rubra": "forja", "torre_babel": "torre", "jardim_primordial": "jardim"}
BIOMES = {b: tres(os.path.join(ROOT, "content", "biomes", b, "biome.tres")) for b in ORDER}

WEATHER = {"ashstorm": ("Tempestade de cinzas", "Ash storm"), "snow": ("Neve e aurora", "Snow and aurora"),
           "embers": ("Brasas no ar", "Rising embers"), "dust": ("Poeira dourada", "Golden dust"),
           "spores": ("Esporos no ar", "Drifting spores"), "shadow": ("Flocos de sombra", "Shadow flakes"),
           "stars": ("Estrelas piscando", "Twinkling stars")}
HAZARD = {"fulgurant": ("Espinho de vidro sobe da cinza", "Glass spikes rise from the ash"),
          "icicle": ("Estalactites caem do teto", "Icicles fall from the ceiling"),
          "fire_vent": ("Jatos de fogo no chão", "Fire jets from the floor"),
          "falling_stone": ("Pedras caem do teto", "Stones fall from the ceiling"),
          "spore_pod": ("Casulos de esporos", "Spore pods"),
          "tendril_root": ("Tentáculos sobem do chão", "Tendrils rise from the floor"),
          "meteor_mark": ("Meteoros caem onde você está", "Meteors fall where you stand"),
          "grave_hand": ("Mãos de osso saem da cova", "Bone hands rise from the graves"),
          "geyser": ("Jorros d'água do piso alagado", "Water jets from the flooded floor"),
          "bile_vent": ("Poros da carne cospem bile", "Flesh pores spit bile"),
          "dream_flash": ("Lampejos do sonho caem do céu", "Dream flashes fall from the sky"),
          "cave_drip": ("Pontas de rocha caem do teto", "Rock spikes drop from the ceiling"),
          "bramble": ("Espinheiros brotam onde você pisa", "Brambles sprout where you step")}

anim = json.load(open(os.path.join(IMG, "anim", "anim.json")))


def strip_of(sheet, boss=False):
    if boss:
        return sheet if sheet.startswith("boss_") else "boss_" + sheet
    return "enemy_" + sheet


def sprite(name, box_w, box_h, most=1.5, label=""):
    a = anim.get(name)
    if not a:
        return '<div class="spr empty" aria-hidden="true"></div>'
    k = max(.5, int(min(most, box_w / a["w"], box_h / a["h"]) * 2) / 2)
    w, h = round(a["w"] * k), round(a["h"] * k)
    return ('<div class="spr" role="img" aria-label="%s" style="width:%dpx;height:%dpx;--n:%d;--d:%.2fs">'
            '<div class="film" style="width:%dpx;height:%dpx;background-image:url(img/anim/%s.png);'
            'background-size:%dpx %dpx"></div></div>') % (esc(label), w, h, a["n"], a["n"] / 7.0, w * a["n"], h,
                                                           name, w * a["n"], h)


# ---------------------------------------------------------------- aparências: o herói recolorido
def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def skin_figure(skin):
    meta = json.load(open(os.path.join(ROOT, "assets", "sprites", "hero_g.json")))
    sheet = Image.open(os.path.join(ROOT, "assets", "sprites", "hero_g.png")).convert("RGBA")
    w, h = meta["w"], meta["h"]
    row = meta["anims"]["idle"]["row"]
    fr = sheet.crop((0, row * h, w, (row + 1) * h))
    fr = fr.crop(fr.getbbox())
    key = meta.get("key_hue", 0.97)
    th, ts, tv = colorsys.rgb_to_hsv(*hex_rgb(skin["cloak"]))
    px = fr.load()
    for y in range(fr.height):
        for x in range(fr.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            ch, cs, cv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            d = abs((ch - key + 0.5) % 1.0 - 0.5) * 6.2832
            if cs > 0.25 and d < 0.35:
                nr, ng, nb = colorsys.hsv_to_rgb(th, min(1, ts * cs / 0.75), min(1, cv * (0.45 + tv)))
                px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    fr = fr.resize((fr.width * 2, fr.height * 2), Image.NEAREST)
    os.makedirs(os.path.join(IMG, "skins"), exist_ok=True)
    fr.save(os.path.join(IMG, "skins", skin["id"] + ".png"))
    return fr.size


# ---------------------------------------------------------------- seções
STAT = {"furia": ("Fúria", "Fury", "#e0503f"), "astucia": ("Astúcia", "Cunning", "#5fa8e8"),
        "vigor": ("Vigor", "Vigor", "#6fc27a")}
CRIT = {"behind": ("Crítico pelas costas", "Crit from behind"), "burning": ("Crítico em alvo queimando", "Crit on burning targets"),
        "far": ("Crítico de longe", "Crit from afar"), "stunned": ("Crítico em alvo atordoado", "Crit on stunned targets"),
        "airborne": ("Crítico no ar", "Crit while airborne"), "tip": ("Crítico com a ponta", "Crit with the tip")}
KIND = {"bomb": ("Arremesso que explode e queima", "Thrown, explodes and burns"),
        "shield": ("Segure para defender; na hora certa, apara", "Hold to block; perfect timing parries"),
        "javelin": ("Projétil que atravessa inimigos", "Projectile that pierces enemies"),
        "trap": ("Lâminas no chão", "Blades on the ground"), "turret": ("Atira sozinha", "Shoots on its own"),
        "spirit": ("Um aliado que persegue", "An ally that hunts"), "hook": ("Puxa o inimigo e atordoa", "Pulls and stuns"),
        "bell": ("Atordoa tudo em volta", "Stuns everything around"), "roots": ("Corre pelo chão e prende", "Runs along the floor and roots"),
        "meteor": ("Cai no inimigo mais perto", "Falls on the nearest enemy")}


def creature_card(script, role_pt, role_en, boss=False, size=(290, 150)):
    title, sheet = CREATURES.get(script, (script, ""))
    name = pt_title(title)
    desc = BEST.get(title, "")
    return ('<article class="card creature" data-q="%s"><div class="stage">%s</div>'
            '<div><p class="role">%s</p><h4>%s</h4><p>%s</p></div></article>') % (
        esc((name + " " + en(title, "title") + " " + desc).lower()),
        sprite(strip_of(sheet, boss), size[0], size[1], 2.0 if not boss else 1.0, name),
        bi(role_pt, role_en), bi(name, en(title, "title"), "title"), bi(desc) if desc else "")


def domain_section(i, bid):
    b = BIOMES[bid]
    acc = ACCENT.get(bid, "#e8a33d")
    god = b["subtitle"].replace("Domínio do deus que ", "")
    god_en = en(b["subtitle"]).replace("Domain of the god who ", "")
    site_id = SITE_ID.get(bid, bid)
    enemies = []
    for e in b.get("enemies", []) if isinstance(b.get("enemies"), list) else []:
        sc = e["script"].rsplit("/", 1)[1][:-3]
        if sc not in enemies:
            enemies.append(sc)
    elite = b["elites"][0].rsplit("/", 1)[1][:-3] if isinstance(b.get("elites"), list) and b["elites"] else ""
    boss = b["boss_script"].rsplit("/", 1)[1][:-3]
    weather = WEATHER.get(b.get("weather", ""), ("", ""))
    hz = HAZARD.get(b.get("hazard_script", "").rsplit("/", 1)[-1][:-3], ("", ""))
    lore = "".join("<li>%s</li>" % bi(t) for t in b.get("lore", []))
    cards = "".join(creature_card(s, "Inimigo", "Enemy") for s in enemies)
    cards += creature_card(elite, "Elite", "Elite") if elite else ""
    cards += creature_card(boss, "Guardião", "Guardian", boss=True, size=(290, 150))
    tier = b.get("tier", 0)
    return '''
<section class="domain" id="d-%s" style="--c:%s">
  <div class="banner" style="background-image:url(img/%s.png)"><div class="shade"></div>
    <div class="ban-text"><p class="num">%02d · %s</p><h3>%s</h3><p class="god">%s</p></div></div>
  <div class="facts">
    <div><span class="k">%s</span>%s</div>
    <div><span class="k">%s</span>%s</div>
    <div><span class="k">%s</span>%s</div>
  </div>
  <ol class="lore">%s</ol>
  <div class="grid cards3">%s</div>
</section>''' % (bid, acc, site_id, i + 1, bi("Profundidade %d" % tier, "Depth %d" % tier),
                 bi(b["title"], en(b["title"], "title"), "title"),
                 bi("O deus que " + god, "The god who " + god_en),
                 bi("Clima", "Weather"), bi(*weather), bi("Perigo", "Hazard"), bi(*hz),
                 bi("Como é", "What it's like"), bi(HINTS.get(bid, "").capitalize(), sentence(EN.get(HINTS.get(bid, ""), HINTS.get(bid, "")))),
                 lore, cards)


def route_section():
    cols, seen = [["mar_de_cinzas"]], {"mar_de_cinzas"}
    frontier = ["mar_de_cinzas"]
    while True:
        nxt = []
        for s in frontier:
            ids = STAGES[s].get("next", [])
            if STAGES[s].get("boss"):
                ids = STAGES[STAGES[s]["boss"]].get("next", [])
            for n in ids:
                if n not in nxt:
                    nxt.append(n)
        nxt = [n for n in nxt if n not in seen]
        if not nxt:
            break
        cols.append(nxt)
        seen.update(nxt)
        frontier = nxt
    out = []
    for c in cols:
        chips = []
        for s in c:
            name = STAGE_NAMES.get(s, s)
            chips.append('<a class="chip" href="#d-%s" style="--c:%s">%s</a>' % (
                s if s in BIOMES else "trono", ACCENT.get(s, "#f2c14e"), bi(name, en(name, "title"), "title")))
        out.append('<div class="step">%s</div>' % "".join(chips))
    return '<div class="route">%s</div>' % '<span class="arrow" aria-hidden="true">›</span>'.join(out)


def gear_cards(kind):
    folder = os.path.join(ROOT, "content", kind)
    order = re.findall(r'"res://content/%s/(\w+)\.tres"' % kind, catalog)
    out = []
    for gid in order:
        g = tres(os.path.join(folder, gid + ".tres"))
        st = STAT.get(g.get("stat", ""), ("", "", "#999"))
        if kind == "weapons":
            what = ("Corpo a corpo", "Melee") if g.get("category") == "melee" else ("À distância", "Ranged")
            rule = CRIT.get(g.get("crit_rule", ""), ("", ""))
            extra = bi(*rule) if rule[0] else ""
        else:
            what = KIND.get(g.get("kind", ""), ("", ""))
            cd = g.get("cooldown", 0)
            extra = bi("Recarga %ds" % cd, "Cooldown %ds" % cd) if cd else ""
        unlock = bi("Inicial", "Starter") if g.get("starter") else bi("%d de essência na Vigia" % g.get("unlock_cost", 0),
                                                                        "%d essence at the Watcher" % g.get("unlock_cost", 0))
        out.append('''<article class="card gear" data-q="%s"><img src="img/icons/%s.png" width="64" height="64" alt="" loading="lazy">
  <div><h4>%s</h4><p class="tags"><span class="stat" style="--s:%s">%s</span><span>%s</span>%s</p>
  <p>%s</p><p class="unlock">%s</p></div></article>''' % (
            esc((g["title"] + " " + en(g["title"], "title") + " " + g.get("lore", "")).lower()), gid,
            bi(g["title"], en(g["title"], "title"), "title"), st[2], bi(st[0], st[1]), bi(*what),
            ('<span>%s</span>' % extra) if extra else "", bi(g.get("lore", "")), unlock))
    return "".join(out)


def skin_cards():
    order = re.findall(r'"res://content/skins/(\w+)\.tres"', catalog)
    out = []
    for sid in order:
        s = tres(os.path.join(ROOT, "content", "skins", sid + ".tres"))
        s["id"] = sid
        w, h = skin_figure(s)
        if s.get("unlock") == "starter":
            how = bi("Já vem liberada", "Unlocked from the start")
        elif s.get("unlock") == "essence":
            how = bi("%d de essência na Vigia" % s.get("cost", 0), "%d essence at the Watcher" % s.get("cost", 0))
        else:
            how = bi(s.get("feat_text", ""))
        chromas = len(re.findall(r'"id": ', open(os.path.join(ROOT, "content", "skins", sid + ".tres"), encoding="utf-8").read().split("chromas = ")[-1]))
        out.append('''<article class="card skin" data-q="%s"><div class="fig"><img src="img/skins/%s.png" width="%d" height="%d" alt="" loading="lazy"></div>
  <div><h4>%s</h4><p>%s</p><p class="unlock">%s%s</p></div></article>''' % (
            esc((s["title"] + " " + en(s["title"], "title")).lower()), sid, w, h,
            bi(s["title"], en(s["title"], "title"), "title"), bi(s.get("lore", "")), how,
            (" · " + bi("%d cromas" % chromas, "%d chromas" % chromas)) if chromas else ""))
    return "".join(out)


def mutation_rows():
    return "".join('<li><b>%s</b><span>%s</span></li>' % (bi(m["title"], en(m["title"], "title"), "title"),
                                                            bi(m["detail"].capitalize(), sentence(EN.get(m["detail"], m["detail"]))))
                   for m in MUTATIONS)


def blessing_rows():
    return "".join('<li><b>%s</b><span>%s</span><em>%s</em></li>' % (
        bi(m["title"], en(m["title"], "title"), "title"), bi(m["detail"].capitalize(), sentence(EN.get(m["detail"], m["detail"]))),
        bi("%d de essência" % m["cost"], "%d essence" % m["cost"])) for m in BLESSINGS)


def pages(lst):
    return "".join("<p>%s</p>" % bi(t) for t in lst)


def guardians():
    out = []
    for bid in ORDER:
        b = BIOMES[bid]
        boss = b["boss_script"].rsplit("/", 1)[1][:-3]
        out.append(creature_card(boss, b["title"], en(b["title"], "title"), boss=True, size=(290, 150)))
    out.append(creature_card("blind_emperor", "O Trono", "The Throne", boss=True, size=(290, 150)))
    return "".join(out)


def counts():
    n_weap = len(re.findall(r'"res://content/weapons/', catalog))
    n_skill = len(re.findall(r'"res://content/skills/', catalog))
    n_skin = len(re.findall(r'"res://content/skins/', catalog))
    commons = set()
    for b in BIOMES.values():
        for e in b.get("enemies", []):
            commons.add(e["script"])
    return dict(dom=len(ORDER), boss=len(ORDER) + 1, enemies=len(commons), elites=len(ORDER),
                weap=n_weap, skill=n_skill, skin=n_skin, mut=len(MUTATIONS))


CONTROLS = [("Andar", "Move", "A / D · ←/→", "Analógico", "Stick"),
            ("Pular (segure = mais alto, 2× = pulo duplo)", "Jump (hold = higher, 2× = double jump)", "Espaço", "A", "A"),
            ("Arma 1 / Arma 2", "Weapon 1 / Weapon 2", "J / K · mouse", "X / Y", "X / Y"),
            ("Habilidade 1 / 2", "Skill 1 / 2", "U / I", "LB / RB", "LB / RB"),
            ("Rolar (invencível) e esquiva no ar", "Roll (invincible) and air dash", "Shift", "B / RT", "B / RT"),
            ("Beber o frasco", "Drink the flask", "Q", "LT", "LT"),
            ("Usar / pegar", "Use / pick up", "E", "↑", "↑"),
            ("Mergulho (no ar)", "Dive (in the air)", "S + J", "↓ + X", "↓ + X"),
            ("Mapa (segure)", "Map (hold)", "M / Tab", "Select", "Select"),
            ("Pausa", "Pause", "Esc", "Start", "Start")]
HEAT = [("Nenhuma", "None", "Como da primeira vez", "Like the first time"),
        ("1", "1", "Inimigos +40% de vida, +25% de dano", "Enemies +40% health, +25% damage"),
        ("2", "2", "+80% de vida, +50% de dano, um frasco a menos", "+80% health, +50% damage, one flask fewer"),
        ("3", "3", "+120% de vida, +75% de dano, um frasco a menos", "+120% health, +75% damage, one flask fewer"),
        ("4", "4", "+160% de vida, +100% de dano, um frasco a menos · libera o final verdadeiro",
         "+160% health, +100% damage, one flask fewer · unlocks the true ending")]


def main():
    c = counts()
    version = re.search(r'config/version="([^"]+)"', read("project.godot")).group(1)
    toc = [("historia", "História", "Story"), ("deuses", "Os 13 deuses", "The 13 gods"), ("rota", "A rota", "The route"),
           ("dominios", "Domínios", "Domains"), ("guardioes", "Guardiões", "Guardians"), ("armas", "Armas", "Weapons"),
           ("habilidades", "Habilidades", "Skills"), ("aparencias", "Aparências", "Skins"), ("mutacoes", "Mutações", "Mutations"),
           ("progresso", "Progresso", "Progression"), ("comandos", "Comandos", "Controls")]
    nav = "".join('<a href="#%s">%s</a>' % (a, bi(p, e)) for a, p, e in toc)
    gods = "".join('<li style="--c:%s"><a href="#d-%s"><b>%s</b><span>%s</span></a></li>' % (
        ACCENT.get(b, "#e8a33d"), b, bi(BIOMES[b]["subtitle"].replace("Domínio do deus que ", "O deus que "),
                                         en(BIOMES[b]["subtitle"]).replace("Domain of the god who ", "The god who ")),
        bi(BIOMES[b]["title"], en(BIOMES[b]["title"], "title"), "title")) for b in ORDER)
    domains = "".join(domain_section(i, b) for i, b in enumerate(ORDER))
    heat = "".join("<tr><td>%s</td><td>%s</td></tr>" % (bi(a, b), bi(x, y)) for a, b, x, y in HEAT)
    ctrl = "".join("<tr><td>%s</td><td><kbd>%s</kbd></td><td><kbd>%s</kbd></td></tr>" % (bi(a, b), esc(k), esc(p))
                   for a, b, k, p, _ in CONTROLS)
    stats = [(c["dom"], "domínios", "domains"), (c["boss"], "guardiões", "guardians"),
             (c["enemies"] + c["elites"], "criaturas", "creatures"), (c["weap"], "armas", "weapons"),
             (c["skill"], "habilidades", "skills"), (c["skin"], "aparências", "skins"), (c["mut"], "mutações", "mutations")]
    statbar = "".join('<div><b>%d</b>%s</div>' % (n, bi(p, e)) for n, p, e in stats)
    page = TEMPLATE
    for k, v in dict(NAV=nav, GODS=gods, ROUTE=route_section(), DOMAINS=domains, GUARDIANS=guardians(),
                     WEAPONS=gear_cards("weapons"), SKILLS=gear_cards("skills"), SKINS=skin_cards(),
                     MUTATIONS=mutation_rows(), BLESSINGS=blessing_rows(), HEAT=heat, CONTROLS=ctrl,
                     INTRO=pages(INTRO), ENDING=pages(ENDING), TRUE_ENDING=pages(TRUE_ENDING), STATS=statbar,
                     VERSION=version).items():
        page = page.replace("{{%s}}" % k, v)
    open(os.path.join(SITE, "wiki.html"), "w", encoding="utf-8", newline="\n").write(page)
    print("wiki.html", len(page) // 1024, "KB ·", c)


TEMPLATE = open(os.path.join(os.path.dirname(__file__), "wiki_modelo.html"), encoding="utf-8").read()

if __name__ == "__main__":
    main()
