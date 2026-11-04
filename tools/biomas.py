"""Gera os biome.tres dos domínios (Salões e Forja ganham chefe aqui também).

    python tools/biomas.py
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")


def col(h):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return "Color(%.3f, %.3f, %.3f, 1)" % (r, g, b)


def s(x):
    return '"%s"' % x.replace('"', '\\"')


def dct(d):
    return "{\n" + ",\n".join('"%s": %s' % (k, v) for k, v in d.items()) + "\n}"


def arr(xs):
    return "[" + ", ".join(xs) + "]"


def enemies(lst):
    return arr(['{"script": "res://scripts/enemies/%s.gd", "slot": "%s", "weight": %d}' % e for e in lst])


def write(biome_id, f):
    lines = ['[gd_resource type="Resource" script_class="BiomeData" load_steps=2 format=3]', '',
             '[ext_resource type="Script" path="res://scripts/biomes/biome_data.gd" id="1"]', '',
             '[resource]', 'script = ExtResource("1")']
    for k, v in f.items():
        lines.append("%s = %s" % (k, v))
    path = os.path.join(ROOT, "content", "biomes", biome_id, "biome.tres")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")


def biome(bid, title, subtitle, colors, sky, layers, weather, enemy_list, boss, hazard, tier, lore,
          ink, recolor=None, rune="", combat=6):
    write(bid, dict(
        id=s(bid), title=s(title), subtitle=s(subtitle),
        colors=dct({k: col(v) for k, v in colors.items()}),
        sky=dct({k: col(v) for k, v in sky.items()}),
        backdrop=s("painted"), layers=s(layers), weather=s(weather),
        rooms_dir=s("res://content/biomes/%s/rooms" % bid), boss_room=s("res://content/arena.txt"),
        combat_rooms=str(combat), enemies=enemies(enemy_list),
        elites=arr([s("res://scripts/enemies/%s.gd" % ELITES[bid])]),
        boss_script=s("res://scripts/enemies/%s.gd" % boss),
        exits=arr(['{"title": "Seguir em frente", "to": "passagem"}']),
        lore=arr([s(x) for x in lore]), tier=str(tier),
        hazard_script=s("res://scripts/enemies/%s.gd" % hazard), rune=s(rune), ink=col(ink),
        recolor=dct({k: s(v) for k, v in (recolor or {}).items()}) if recolor else "{}",
    ))


ELITES = {"torre_babel": "elite_librarian", "jardim_primordial": "elite_thornkeeper",
          "carcosa": "elite_duelist", "observatorio": "elite_brass"}

SALOES_FORJA_BOSS = {"saloes": "boss_wolf_king", "forja_rubra": "boss_colossus"}

if __name__ == "__main__":
    for bid, boss in SALOES_FORJA_BOSS.items():
        p = os.path.join(ROOT, "content", "biomes", bid, "biome.tres")
        t = open(p, encoding="utf-8").read()
        t = t.replace('boss_script = ""', 'boss_script = "res://scripts/enemies/%s.gd"' % boss)
        t = t.replace('boss_room = "res://content/biomes/mar_de_cinzas/chefe/trono.txt"', 'boss_room = "res://content/arena.txt"')
        open(p, "w", encoding="utf-8", newline="\n").write(t)

    biome("torre_babel", "A Torre de Babel", "Domínio do deus que falava todas as línguas",
          dict(stone="7a6a50", deep="2e2620", top="b09a70", light="e0caa0", shadow="1a1410", moss="d8c8a0",
               wood="4a3a28", wood_top="7a6040", wood_dark="2a2014", vein="e8d070", cloth="3a3a6a"),
          dict(sky0="1a1630", sky1="3a2e4a", sky2="4a3a54", glow="c09a5a", sun="f2dca0", accent="e8d070", ambient="8c8aa0"),
          "bd_torre", "dust",
          [("gargoyle", "e", 10), ("scribe", "r", 10), ("mason", "e", 9), ("shield_guard", "e", 3)],
          "boss_architect", "falling_stone", 3,
          ["A Torre foi feita para chegar ao deus. Chegou. Ele já tinha ido embora.",
           "Cada andar fala uma língua. Quem sobe esquece a de baixo.",
           "Os escribas copiam o mesmo livro há mil anos. Ninguém sabe ler o original.",
           "As gárgulas eram guardas. Ficaram de pedra esperando a ordem de parar.",
           "No topo há uma porta. Do lado de dentro, só céu."],
          "0c0a14", combat=7)

    biome("jardim_primordial", "O Jardim Primordial", "Domínio do deus que plantou o mundo",
          dict(stone="3a4a30", deep="16201a", top="6a8a4a", light="b8d07a", shadow="0c120c", moss="8ab05a",
               wood="4a3a20", wood_top="7a6030", wood_dark="2a2010", vein="e8f070", cloth="6a2a4a"),
          dict(sky0="0e1a18", sky1="1e3a2e", sky2="24443a", glow="6aa06a", sun="e8f0b0", accent="b8d05a", ambient="7a9a80"),
          "bd_jardim", "spores",
          [("moss_beast", "e", 10), ("thorn_plant", "r", 10), ("seed_pod", "e", 9), ("wolf", "e", 3)],
          "boss_mother_root", "spore_pod", 3,
          ["Aqui tudo nasceu primeiro. Por isso tudo aqui é mais velho que a morte.",
           "As feras-musgo não comem. Só crescem por cima do que encontram.",
           "O deus do Jardim não sumiu. Virou raiz. Ainda sente cada passo.",
           "Os espinheiros apontam sempre para quem respira.",
           "Uma placa coberta de musgo: NÃO ARRANQUE NADA. ELA LEMBRA."],
          "060c08", recolor={"wolf": "moss_beast"}, combat=7)

    biome("carcosa", "Carcosa", "Domínio do deus que usava máscara",
          dict(stone="4a3a2a", deep="1a140e", top="7a6a3a", light="d8c050", shadow="0e0a06", moss="b8a040",
               wood="3a2a1a", wood_top="6a5030", wood_dark="1a1208", vein="e8d070", cloth="4a2a5a"),
          dict(sky0="120c10", sky1="2a1a20", sky2="3a2428", glow="b8a040", sun="f0e070", accent="e8d070", ambient="8a7a70"),
          "bd_carcosa", "shadow",
          [("masked", "e", 10), ("herald", "r", 8), ("dancer", "e", 9), ("assassin", "e", 3)],
          "boss_faceless_king", "tendril_root", 4,
          ["Em Carcosa os sóis são negros e ninguém estranha.",
           "Todo morador usa máscara. Por baixo, a mesma máscara.",
           "O Arauto anuncia um rei que nunca chega. Os sinos tocam assim mesmo.",
           "Quem tira a máscara aqui some. Ninguém tira.",
           "Escrito na parede, em amarelo: VOCÊ JÁ ESTEVE AQUI."],
          "0a0606", combat=7)

    biome("observatorio", "O Observatório Celeste", "Domínio do deus que contava as estrelas",
          dict(stone="3a4060", deep="141828", top="6a7090", light="c8d0f0", shadow="080a14", moss="9aa8d8",
               wood="4a3a2a", wood_top="8a6a40", wood_dark="2a2014", vein="9fe8ff", cloth="2a3a6a"),
          dict(sky0="060814", sky1="101a36", sky2="18244a", glow="3a4a8a", sun="e8f0ff", accent="9fe8ff", ambient="7a80a8"),
          "bd_observatorio", "stars",
          [("automaton", "e", 10), ("fallen_star", "e", 8), ("lens", "r", 9), ("ice_sentinel", "r", 3)],
          "boss_astronomer", "meteor_mark", 4,
          ["O último astrônomo contou as estrelas até elas acabarem. Depois contou de novo.",
           "Os autômatos medem o céu. Não sabem mais para quem.",
           "Cada estrela caída é um nome que o deus esqueceu.",
           "A luneta aponta para um ponto vazio. Lá estava o deus.",
           "No caderno de bordo, a última linha: ELE OLHOU DE VOLTA."],
          "04060c", combat=7)
    print("ok")
