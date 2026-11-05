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
import unicodedata

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
    cap = lambda w: "-".join(p[:1].upper() + p[1:] for p in w.split("-"))
    return " ".join(w if (i and w in small) else cap(w) for i, w in enumerate(words))


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
_own_sheet, _parent, _class_file = {}, {}, {}
for f in glob.glob(os.path.join(ROOT, "scripts", "enemies", "*.gd")):
    s = open(f, encoding="utf-8").read()
    key = os.path.basename(f)[:-3]
    t = re.search(r'\btitle = "([^"]+)"', s)
    sh = re.search(r'\bsheet = "([^"]+)"', s)
    cn = re.search(r"^class_name (\w+)", s, re.M)
    ex = re.search(r"^extends (\w+)", s, re.M)
    _own_sheet[key] = sh.group(1) if sh else ""
    _parent[key] = ex.group(1) if ex else ""
    if cn:
        _class_file[cn.group(1)] = key
    if t:
        CREATURES[key] = t.group(1)
for key, title in list(CREATURES.items()):
    # quem não define folha herda a da classe mãe (a Sentinela de Gelo é um Arqueiro)
    k = key
    while k and not _own_sheet.get(k):
        k = _class_file.get(_parent.get(k, ""))
    CREATURES[key] = (title, _own_sheet.get(k, "") if k else "")

story = read("scripts", "combat", "story.gd")
BEST = dict(re.findall(r'^\t"([^"]+)": "((?:[^"\\]|\\.)*)",$', story, re.M))


def story_list(name):
    m = re.search(r"const %s := \[(.*?)\n\]" % name, story, re.S)
    return [json.loads('"%s"' % x) for x in re.findall(r'^\t"((?:[^"\\]|\\.)*)",$', m.group(1), re.M)]


INTRO, ENDING, TRUE_ENDING = story_list("INTRO"), story_list("ENDING"), story_list("TRUE_ENDING")
REVEAL, FINAL, PLUS_INTRO, PLUS_ENDING = story_list("REVEAL"), story_list("FINAL"), story_list("PLUS_INTRO"), story_list("PLUS_ENDING")


def story_dict(name):
    m = re.search(r"const %s := \{(.*?)\n\}" % name, story, re.S)
    return [(k, json.loads('"%s"' % v)) for k, v in re.findall(r'^\t"(\w+)": "((?:[^"\\]|\\.)*)",$', m.group(1), re.M)]


SEATS, AFTER = story_dict("SEATS"), story_dict("AFTER")

run = read("scripts", "autoload", "run.gd")
STAGES = {}
for k, v in re.findall(r'^\t"(\w+)": (\{.*\}),$', run, re.M):
    STAGES[k] = json.loads(v)

catalog = read("scripts", "combat", "catalog.gd")


def catalog_list(name):
    m = re.search(r"const %s := \[(.*?)\n\]" % name, catalog, re.S)
    return [dict_block(x) for x in re.findall(r"^\t(\{.*\}),$", m.group(1), re.M)]


MUTATIONS, BLESSINGS = catalog_list("MUTATIONS"), catalog_list("BLESSINGS")
ADVANTAGES, FEATS = catalog_list("ADVANTAGES"), catalog_list("FEATS")
FEAT_TITLE = {f["id"]: f["title"] for f in FEATS}
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


def sprite(name, box_w, box_h, most=1.5, label="", live=False):
    a = anim.get(name)
    if not a:
        return '<div class="spr empty" aria-hidden="true"></div>'
    k = min(most, box_w / a["w"], box_h / a["h"])
    w, h = round(a["w"] * k), round(a["h"] * k)
    return ('<div class="spr%s" role="img" aria-label="%s" style="width:%dpx;height:%dpx;--n:%d;--d:%.2fs">'
            '<div class="film" style="width:%dpx;height:%dpx;background-image:url(img/anim/%s.png);'
            'background-size:%dpx %dpx"></div></div>') % (" live" if live else "", esc(label), w, h, a["n"], a["n"] / 7.0,
                                                           w * a["n"], h, name, w * a["n"], h)


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
STAT = {"furia": ("Fúria", "Fury", "#ff7a66"), "astucia": ("Astúcia", "Cunning", "#7dbcf0"),
        "vigor": ("Vigor", "Vigor", "#7fd48a")}
CRIT = {"behind": ("Pelas costas", "From behind"), "burning": ("Alvo queimando", "Burning target"),
        "far": ("De longe", "From afar"), "stunned": ("Alvo atordoado", "Stunned target"),
        "airborne": ("No ar", "Airborne"), "tip": ("Com a ponta", "With the tip")}
KIND = {"bomb": ("Arremesso que explode e queima", "Thrown, explodes and burns"),
        "shield": ("Segure para defender; na hora certa, apara", "Hold to block; perfect timing parries"),
        "javelin": ("Projétil que atravessa inimigos", "Projectile that pierces enemies"),
        "trap": ("Lâminas no chão", "Blades on the ground"), "turret": ("Atira sozinha", "Shoots on its own"),
        "spirit": ("Um aliado que persegue", "An ally that hunts"), "hook": ("Puxa o inimigo e atordoa", "Pulls and stuns"),
        "bell": ("Atordoa tudo em volta", "Stuns everything around"), "roots": ("Corre pelo chão e prende", "Runs along the floor and roots"),
        "meteor": ("Cai no inimigo mais perto", "Falls on the nearest enemy")}


def norm(*parts):
    """Texto de busca: minúsculo e sem acento, nos dois idiomas."""
    t = " ".join(p for p in parts if p).lower()
    return esc("".join(ch for ch in unicodedata.normalize("NFD", t) if not unicodedata.combining(ch)))


def script_of(path):
    return path.rsplit("/", 1)[1][:-3]


def enemies_of(bid):
    out = []
    enemies = BIOMES[bid].get("enemies")
    for e in enemies if isinstance(enemies, list) else []:
        sc = script_of(e["script"])
        if sc not in out:
            out.append(sc)
    return out


def elite_of(bid):
    elites = BIOMES[bid].get("elites")
    return script_of(elites[0]) if isinstance(elites, list) and elites else ""


def dom_name(bid):
    return bi(BIOMES[bid]["title"], en(BIOMES[bid]["title"], "title"), "title")


def creature_text(script):
    title, sheet = CREATURES.get(script, (script, ""))
    return title, sheet, pt_title(title), en(title, "title"), BEST.get(title, "")


ROLE = {"enemy": ("Inimigo", "Enemy"), "elite": ("Elite", "Elite"), "boss": ("Guardião", "Guardian")}


def creature_row(script, role, where=None, searchable=True):
    title, sheet, name, name_en, desc = creature_text(script)
    place = ""
    extra = ""
    if where:
        place = '<span class="where">%s</span>' % " · ".join('<a href="#d-%s">%s</a>' % (d, dom_name(d)) for d in where)
        extra = " ".join(BIOMES[d]["title"] + " " + en(BIOMES[d]["title"], "title") for d in where)
    attrs = ' data-q="%s" data-tags="%s"' % (norm(name, name_en, desc, en(title) if desc else "", ROLE[role][0], ROLE[role][1], extra), role) if searchable else ""
    return ('<li class="creature"%s><div class="row"><div class="thumb">%s</div><div class="name">%s<span class="role">%s</span></div>'
            '%s%s</div></li>') % (
        attrs, sprite(strip_of(sheet, role == "boss"), 64, 56, 2.0, name), bi(name, name_en, "title"), bi(*ROLE[role]),
        '<p>%s</p>' % bi(desc) if desc else "", place)


def domain_section(i, bid):
    b = BIOMES[bid]
    acc = ACCENT.get(bid, "#e8a33d")
    god = b["subtitle"].replace("Domínio do deus que ", "")
    god_en = en(b["subtitle"]).replace("Domain of the god who ", "")
    site_id = SITE_ID.get(bid, bid)
    enemies = enemies_of(bid)
    elite = elite_of(bid)
    # o Mar de Cinzas não tem guardião: quem está no boss_script dele é o chefe do Trono, que usa o mesmo cenário
    boss = script_of(b["boss_script"]) if STAGES[bid].get("boss") else ""
    weather = WEATHER.get(b.get("weather", ""), ("", ""))
    hz = HAZARD.get(b.get("hazard_script", "").rsplit("/", 1)[-1][:-3], ("", ""))
    lore = "".join("<li>%s</li>" % bi(t) for t in b.get("lore", []))
    rows = creature_row(boss, "boss", searchable=False) if boss else ""
    rows += creature_row(elite, "elite", searchable=False) if elite else ""
    rows += "".join(creature_row(e, "enemy", searchable=False) for e in enemies)
    boss_pt, boss_en = creature_text(boss)[2:4] if boss else ("", "")
    keeper = (bi("Guardião:", "Guardian:") + " " + bi(boss_pt, boss_en, "title")) if boss else bi("Sem guardião: é o começo da partida", "No guardian: this is where runs begin")
    hint = HINTS.get(bid, "")
    q = norm(b["title"], en(b["title"], "title"), god, god_en, boss_pt, boss_en, weather[0], weather[1], hz[0], hz[1])
    return """
<li data-q="%s" style="--c:%s"><details class="dom" id="d-%s">
  <summary class="row"><img src="img/%s.png" alt="" loading="lazy" width="112" height="63">
    <span class="name"><small>%02d</small>%s</span>
    <span class="meta"><span>%s</span><span>%s</span></span></summary>
  <div class="dom-body">
    <dl class="facts">
      <div><dt>%s</dt><dd>%s</dd></div>
      <div><dt>%s</dt><dd>%s</dd></div>
      <div><dt>%s</dt><dd>%s</dd></div>
    </dl>
    <ul class="rows">%s</ul>
    <details class="lore-box"><summary>%s</summary><ol>%s</ol></details>
  </div>
</details></li>""" % (q, acc, bid, site_id, i + 1, bi(b["title"], en(b["title"], "title"), "title"),
                      bi("O deus que " + god, "The god who " + god_en),
                      keeper,
                      bi("Perigo", "Hazard"), bi(*hz), bi("Clima", "Weather"), bi(*weather),
                      bi("Como é", "What it's like"),
                      bi(hint.capitalize(), sentence(EN.get(hint, hint))),
                      rows, bi("Inscrições (%d)" % len(b.get("lore", [])), "Inscriptions (%d)" % len(b.get("lore", []))), lore)


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
            # o Trono não é domínio: o link leva a quem espera lá
            chips.append('<a class="chip" href="#%s" style="--c:%s">%s</a>' % (
                "d-" + s if s in BIOMES else "guardioes", ACCENT.get(s, "#f2c14e"), bi(name, en(name, "title"), "title")))
        out.append('<div class="step">%s</div>' % "".join(chips))
    return '<div class="route">%s</div>' % '<span class="arrow" aria-hidden="true">›</span>'.join(out)


def damage_range(g):
    vals = sorted({int(x) for x in re.findall(r"damage\W+(\d+)", str(g.get("moves", "")) + str(g.get("shot", "")) + str(g.get("damage", "")))})
    if not vals:
        return "–"
    return str(vals[0]) if len(vals) == 1 else "%d–%d" % (vals[0], vals[-1])


def lab(pt, en_text):
    return '<span class="lab">%s:</span> ' % bi(pt, en_text)


def stat_chips():
    out = ['<button type="button" data-v="" aria-pressed="true">%s</button>' % bi("Todos", "All")]
    out += ['<button type="button" data-v="%s" aria-pressed="false">%s</button>' % (k, bi(v[0], v[1])) for k, v in STAT.items()]
    return "".join(out)


def gear_rows(kind):
    folder = os.path.join(ROOT, "content", kind)
    order = re.findall(r'"res://content/%s/(\w+)\.tres"' % kind, catalog)
    out = []
    for gid in order:
        g = tres(os.path.join(folder, gid + ".tres"))
        st = STAT.get(g.get("stat", ""), ("–", "–", "#999"))
        stat_cell = '<span class="stat" style="--s:%s">%s</span>' % (st[2], bi(st[0], st[1]))
        if g.get("starter"):
            get_pt, get_en = "Inicial", "Starter"
        else:
            get_pt, get_en = "%d de essência" % g.get("unlock_cost", 0), "%d essence" % g.get("unlock_cost", 0)
        title_en = en(g["title"], "title")
        lore = g.get("lore", "")
        if kind == "weapons":
            what = ("Corpo a corpo", "Melee") if g.get("category") == "melee" else ("À distância", "Ranged")
            rule = CRIT.get(g.get("crit_rule", ""), ("Último golpe", "Last hit"))
            mult = g.get("crit_mult", 0)
            crit_pt = "%s ×%s" % (rule[0], str(mult).replace(".", ",")) if mult else rule[0]
            crit_en = "%s ×%s" % (rule[1], mult) if mult else rule[1]
            cells = ("<span>%s%s</span><span>%s%s</span><span>%s%s</span><span>%s%s</span><span>%s%s</span>" % (
                lab("Tipo", "Type"), bi(*what), lab("Atributo", "Stat"), stat_cell, lab("Dano", "Damage"), damage_range(g),
                lab("Crítico", "Crit"), bi(crit_pt, crit_en), lab("Como obter", "How to get"), bi(get_pt, get_en)))
            tags = "%s %s" % (g.get("stat", ""), "melee" if g.get("category") == "melee" else "ranged")
            q = norm(g["title"], title_en, what[0], what[1], st[0], st[1], rule[0], rule[1], lore)
        else:
            what = KIND.get(g.get("kind", ""), ("–", "–"))
            cd = g.get("cooldown", 0)
            cells = ("<span>%s</span><span>%s%s</span><span>%s%s</span><span>%s%s</span>" % (
                bi(*what), lab("Atributo", "Stat"), stat_cell, lab("Recarga", "Cooldown"), "%ds" % cd if cd else "–",
                lab("Como obter", "How to get"), bi(get_pt, get_en)))
            tags = g.get("stat", "")
            q = norm(g["title"], title_en, what[0], what[1], st[0], st[1], lore)
        out.append('<li data-q="%s" data-tags="%s"><details><summary class="row"><img src="img/icons/%s.png" width="48" height="48" alt="" loading="lazy">'
                   '<span class="name">%s</span><span class="meta">%s</span></summary><p class="more">%s</p></details></li>' % (
                       q, tags, gid, bi(g["title"], title_en, "title"), cells, bi(lore)))
    return "".join(out)


def skin_rows():
    order = re.findall(r'"res://content/skins/(\w+)\.tres"', catalog)
    out = []
    for sid in order:
        s = tres(os.path.join(ROOT, "content", "skins", sid + ".tres"))
        s["id"] = sid
        w, h = skin_figure(s)
        if s.get("unlock") == "starter":
            how = bi("Já vem liberada", "Unlocked from the start")
        elif s.get("unlock") == "essence":
            how = bi("%d de essência" % s.get("cost", 0), "%d essence" % s.get("cost", 0))
        else:
            how = bi(s.get("feat_text", "").capitalize(), sentence(EN.get(s.get("feat_text", ""), s.get("feat_text", ""))))
        chromas = len(re.findall(r'"id": ', open(os.path.join(ROOT, "content", "skins", sid + ".tres"), encoding="utf-8").read().split("chromas = ")[-1]))
        out.append('<li class="skin" data-q="%s"><div class="fig"><img src="img/skins/%s.png" width="%d" height="%d" alt="" loading="lazy"></div>'
                   '<div><b>%s</b><span>%s</span><em>%s</em></div></li>' % (
                       norm(s["title"], en(s["title"], "title"), s.get("lore", "")), sid, w, h,
                       bi(s["title"], en(s["title"], "title"), "title"), how,
                       bi("%d cromas" % chromas, "%d chromas" % chromas) if chromas else ""))
    return "".join(out)


def mutation_rows():
    return "".join('<li data-q="%s"><b>%s</b><span>%s</span></li>' % (
        norm(m["title"], en(m["title"], "title"), m["detail"], EN.get(m["detail"], "")),
        bi(m["title"], en(m["title"], "title"), "title"),
        bi(m["detail"].capitalize(), sentence(EN.get(m["detail"], m["detail"])))) for m in MUTATIONS)


def blessing_rows():
    return "".join('<li data-q="%s"><b>%s</b><span>%s</span><em>%s</em></li>' % (
        norm(m["title"], en(m["title"], "title"), m["detail"], EN.get(m["detail"], "")),
        bi(m["title"], en(m["title"], "title"), "title"), bi(m["detail"].capitalize(), sentence(EN.get(m["detail"], m["detail"]))),
        bi("%d de essência" % m["cost"], "%d essence" % m["cost"])) for m in BLESSINGS)


def advantage_rows():
    def how(a):
        if "needs" not in a:
            return bi("Desde o começo", "From the start")
        t = FEAT_TITLE[a["needs"]]
        return bi("Conquista: " + t, "Achievement: " + en(t, "title"))
    return "".join('<li data-q="%s"><b>%s</b><span>%s</span><em>%s</em></li>' % (
        norm(a["title"], en(a["title"], "title"), a["detail"], EN.get(a["detail"], "")),
        bi(a["title"], en(a["title"], "title"), "title"), bi(a["detail"].capitalize(), sentence(EN.get(a["detail"], a["detail"]))),
        how(a)) for a in ADVANTAGES)


# As secretas ficam só na contagem: são spoiler do final.
def feat_rows():
    return "".join('<li data-q="%s"><b>%s</b><span>%s</span></li>' % (
        norm(f["title"], en(f["title"], "title"), f["detail"], EN.get(f["detail"], "")),
        bi(f["title"], en(f["title"], "title"), "title"), bi(f["detail"].capitalize(), sentence(EN.get(f["detail"], f["detail"]))))
        for f in FEATS if not f.get("secret"))


def pages(lst):
    return "".join("<p>%s</p>" % bi(t) for t in lst)


def fate_rows(items, as_god):
    """O destino de cada deus (ou de cada domínio): nome à esquerda, frase ao lado."""
    out = []
    for bid, text in items:
        b = BIOMES[bid]
        if as_god:
            who = bi(b["subtitle"].replace("Domínio do deus", "O deus"), en(b["subtitle"]).replace("Domain of the god", "The god"))
        else:
            who = dom_name(bid)
        out.append('<li style="--c:%s"><b>%s</b><span>%s</span></li>' % (ACCENT.get(bid, "#e8a33d"), who, bi(text)))
    return "".join(out)


def boss_card(script, place_html, place_q, color):
    title, sheet, name, name_en, desc = creature_text(script)
    return ('<article class="boss" data-q="%s" style="--c:%s"><div class="stage">%s</div><h3>%s</h3>'
            '<div class="where">%s</div><p>%s</p></article>') % (
        norm(name, name_en, desc, en(title) if desc else "", place_q), color,
        sprite(strip_of(sheet, True), 220, 112, 1.0, name, live=True), bi(name, name_en, "title"), place_html, bi(desc) if desc else "")


def guardians():
    out = []
    for bid in ORDER:
        b = BIOMES[bid]
        if not STAGES[bid].get("boss"):
            continue
        out.append(boss_card(script_of(b["boss_script"]), '<a href="#d-%s">%s</a>' % (bid, dom_name(bid)),
                             b["title"] + " " + en(b["title"], "title"), ACCENT.get(bid, "#e8a33d")))
    out.append(boss_card("blind_emperor", bi("O Trono", "The Throne"), "O Trono The Throne", "#f2c14e"))
    return "".join(out)


def creature_list():
    """Bestiário: cada criatura uma vez, com os domínios onde aparece."""
    where, roles = {}, {}
    for bid in ORDER:
        for e in enemies_of(bid):
            where.setdefault(e, []).append(bid)
            roles[e] = "enemy"
        el = elite_of(bid)
        if el:
            where.setdefault(el, []).append(bid)
            roles.setdefault(el, "elite")
    names = sorted(where, key=lambda s: norm(creature_text(s)[2]))
    return "".join(creature_row(s, roles[s], where[s]) for s in names), len(names)


def counts():
    n_weap = len(re.findall(r'"res://content/weapons/', catalog))
    n_skill = len(re.findall(r'"res://content/skills/', catalog))
    n_skin = len(re.findall(r'"res://content/skins/', catalog))
    return dict(dom=len(ORDER), boss=sum(1 for b in ORDER if STAGES[b].get("boss")) + 1, weap=n_weap, skill=n_skill, skin=n_skin, mut=len(MUTATIONS), bless=len(BLESSINGS))


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
FAQ = [("O que perco quando morro?", "What do I lose when I die?",
        "Ouro e o que você carrega. Essência entregue à Vigia, plantas, bênçãos, aparências e runas ficam.",
        "Gold and what you carry. Essence spent at the Watcher, blueprints, blessings, skins and runes stay.", "progresso", "Progresso", "Progression"),
       ("Como funciona uma partida?", "How does a run work?",
        "Você renasce na Beira, escolhe o que levar e atravessa o arco. Daí são dez andares, e o relógio só corre depois do arco.",
        "You are reborn on the Shore, choose what to take and cross the arch. Then come ten floors, and the clock only runs past the arch.", "beira", "A Beira", "The Shore"),
       ("Onde troco de aparência e dificuldade?", "Where do I change skin and difficulty?",
        "Na Beira: os mantos trocam a aparência, o braseiro escolhe as brasas e os ciclos do Novo Jogo+.",
        "On the Shore: the cloaks change your skin, the brazier picks embers and New Game+ cycles.", "beira", "A Beira", "The Shore"),
       ("Como venço um guardião?", "How do I beat a guardian?",
        "Todo golpe é avisado. A cada três golpes ele para, exausto: é a sua janela. Com metade da vida, muda de fase.",
        "Every attack is telegraphed. Every third attack it stops, exhausted: that is your window. At half health, it changes phase.", "guardioes", "Guardiões", "Guardians"),
       ("Como ganho armas novas?", "How do I get new weapons?",
        "Entregue a planta à Vigia: a arma passa a aparecer nas partidas.",
        "Deliver the blueprint to the Watcher: the weapon starts showing up in runs.", "armas", "Armas", "Weapons"),
       ("Onde pego mutações?", "Where do I get mutations?",
        "No altar de cada passagem, até três por partida. O poço da Beira deixa começar com uma que você já bebeu.",
        "At the altar in each passage, up to three per run. The well on the Shore lets you start with one you already drank.", "mutacoes", "Mutações", "Mutations"),
       ("Como libero o final verdadeiro?", "How do I unlock the true ending?",
        "Vença o Imperador Cego com as 4 Brasas do Deus, a dificuldade máxima.",
        "Beat the Blind Emperor with all 4 God's Embers, the highest difficulty.", "progresso", "Brasas do Deus", "God's Embers"),
       ("O que vem depois do final verdadeiro?", "What comes after the true ending?",
        "O Novo Jogo+: ciclos mais difíceis, com o herói mais forte e os domínios mudados.",
        "New Game+: harder cycles, with a stronger hero and changed domains.", "progresso", "Novo Jogo+", "New Game+")]


def main():
    c = counts()
    creatures, n_creatures = creature_list()
    version = re.search(r'config/version="([^"]+)"', read("project.godot")).group(1)
    groups = [("", "", [("inicio", "Início", "Home", None)]),
              ("Mundo", "World", [("historia", "História", "Story", None), ("dominios", "Domínios", "Domains", c["dom"]),
                                  ("guardioes", "Guardiões", "Guardians", c["boss"]), ("criaturas", "Criaturas", "Creatures", n_creatures)]),
              ("Equipamento", "Gear", [("armas", "Armas", "Weapons", c["weap"]), ("habilidades", "Habilidades", "Skills", c["skill"]),
                                       ("mutacoes", "Mutações", "Mutations", c["mut"]), ("aparencias", "Aparências", "Skins", c["skin"])]),
              ("Consulta", "Reference", [("beira", "A Beira", "The Shore", None), ("progresso", "Progresso", "Progression", None), ("comandos", "Comandos", "Controls", None)])]
    nav = ""
    for gp, ge, items in groups:
        head = "<span>%s</span>" % bi(gp, ge) if gp else ""
        nav += '<div class="group">%s%s</div>' % (head, "".join(
            '<a href="#%s"><span>%s</span>%s</a>' % (a, bi(p, e), "<small>%d</small>" % n if n else "") for a, p, e, n in items))
    hubs = [("dominios", "Domínios", "Domains", c["dom"], "Onde cada caminho leva e o que espera lá", "Where each path leads and what waits there"),
            ("guardioes", "Guardiões", "Guardians", c["boss"], "Quem você enfrenta no fim de cada domínio", "Who you face at the end of each domain"),
            ("criaturas", "Criaturas", "Creatures", n_creatures, "O que cada uma faz e onde aparece", "What each one does and where it appears"),
            ("armas", "Armas", "Weapons", c["weap"], "Dano, crítico e como conseguir", "Damage, crits and how to get them"),
            ("habilidades", "Habilidades", "Skills", c["skill"], "O que fazem e quanto demoram a recarregar", "What they do and how long they recharge"),
            ("mutacoes", "Mutações", "Mutations", c["mut"], "Bônus do altar que valem até você morrer", "Altar bonuses that last until you die"),
            ("beira", "A Beira", "The Shore", None, "Onde você renasce e escolhe o que levar", "Where you are reborn and choose what to take"),
            ("progresso", "Progresso", "Progression", None, "O que fica para sempre e a dificuldade", "What you keep forever, and difficulty"),
            ("comandos", "Comandos", "Controls", None, "Teclado e controle", "Keyboard and gamepad")]
    hub = "".join('<a href="#%s"><b>%s%s</b><span>%s</span></a>' % (
        a, bi(p, e), "<i>%d</i>" % n if n else "", bi(dp, de)) for a, p, e, n, dp, de in hubs)
    faq = "".join('<div><dt>%s</dt><dd>%s <a href="#%s">%s</a></dd></div>' % (bi(qp, qe), bi(ap, ae), link, bi(lp, le))
                  for qp, qe, ap, ae, link, lp, le in FAQ)
    domains = "".join(domain_section(i, b) for i, b in enumerate(ORDER))
    heat = "".join("<tr><td>%s</td><td>%s</td></tr>" % (bi(a, b), bi(x, y)) for a, b, x, y in HEAT)
    ctrl = "".join("<tr><td>%s</td><td><kbd>%s</kbd></td><td><kbd>%s</kbd></td></tr>" % (bi(a, b), esc(k), esc(p))
                   for a, b, k, p, _ in CONTROLS)
    page = TEMPLATE
    for k, v in dict(NAV=nav, HUB=hub, FAQ=faq, ROUTE=route_section(), DOMAINS=domains, GUARDIANS=guardians(), CREATURES=creatures,
                     WEAPONS=gear_rows("weapons"), SKILLS=gear_rows("skills"), SKINS=skin_rows(), STAT_CHIPS=stat_chips(),
                     MUTATIONS=mutation_rows(), BLESSINGS=blessing_rows(), HEAT=heat, CONTROLS=ctrl,
                     ADVANTAGES=advantage_rows(), FEATS=feat_rows(), FEAT_COUNT=str(len(FEATS)), FEAT_SECRET=str(sum(1 for f in FEATS if f.get("secret"))),
                     INTRO=pages(INTRO), ENDING=pages(ENDING), TRUE_ENDING=pages(TRUE_ENDING),
                     FINAL=pages(REVEAL + FINAL), GODS_END=fate_rows(SEATS, True), AFTER=fate_rows(AFTER, False),
                     PLUS_STORY=pages(PLUS_INTRO + PLUS_ENDING),
                     VERSION=version).items():
        page = page.replace("{{%s}}" % k, v)
    open(os.path.join(SITE, "wiki.html"), "w", encoding="utf-8", newline="\n").write(page)
    print("wiki.html", len(page) // 1024, "KB ·", c, "criaturas", n_creatures)


TEMPLATE = open(os.path.join(os.path.dirname(__file__), "wiki_modelo.html"), encoding="utf-8").read()

if __name__ == "__main__":
    main()
