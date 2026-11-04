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
          "carcosa": "elite_duelist", "observatorio": "elite_brass",
          "necropole": "elite_caller", "catedral": "elite_priestess", "ventre": "elite_glutton",
          "penhascos": "elite_reverie", "cavernas": "elite_hermit", "bosque": "elite_bull"}

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

    # ===================== grande update: os 6 deuses que faltavam =====================
    biome("necropole", "A Necrópole", "Domínio do deus que lembrava os mortos",
          dict(stone="4a5068", deep="1a1c28", top="8a92aa", light="d8dce8", shadow="0a0c12", moss="a8b4c8",
               wood="3a3030", wood_top="6a5a50", wood_dark="1e1818", vein="a8c0e8", cloth="3a2a4a"),
          dict(sky0="0a0a18", sky1="1e1a34", sky2="2a2444", glow="c84a8a", sun="f0c8e0", accent="a8c0e8", ambient="8088a8"),
          "bd_necropole", "shadow",
          [("risen", "e", 10), ("mourner", "e", 9), ("grave_cat", "e", 9), ("grunt", "e", 3)],
          "boss_forgotten", "grave_hand", 2,
          ["Aqui o deus guardava o nome de cada morto. Enquanto alguém lembra, ninguém some de vez.",
           "Ele sumiu na mesma noite que os outros. Desde então os mortos não sabem mais quem foram.",
           "As carpideiras choram por todos. Não lembram por quem.",
           "Na lápide maior não há nome. Só a coroa, gasta de tanto ser tocada.",
           "Escrito por dentro de uma cova aberta: SE VOCÊ LEMBRAR DE MIM, EU VOLTO."],
          "06060c", combat=7)

    biome("catedral", "A Catedral Submersa", "Domínio do deus que ouvia as preces",
          dict(stone="3a5068", deep="121c28", top="6a8aa8", light="b8d8f0", shadow="060a10", moss="5a9ab0",
               wood="2a2a3a", wood_top="4a5a6a", wood_dark="141820", vein="8ad0f0", cloth="5a1a2a"),
          dict(sky0="040c16", sky1="0e2236", sky2="16304a", glow="3a8ab0", sun="d8f4ff", accent="8ad0f0", ambient="6a90a8"),
          "bd_catedral", "spores",
          [("drowned", "e", 10), ("votive", "e", 9), ("prayer", "r", 9), ("archer", "r", 3)],
          "boss_answer", "geyser", 3,
          ["Todas as preces do mundo desciam até aqui. O deus ouvia uma por uma.",
           "Quando ele sumiu, as preces continuaram caindo. Encheram a nave até o teto.",
           "Os afogados não se afogaram. Desceram rezando e não quiseram subir.",
           "Alguma coisa no fundo começou a responder. Ninguém pediu isso a ela.",
           "No banco da frente, gravado com a unha: EU PEDI QUE ELE VOLTASSE. VEIO OUTRO."],
          "02060c", combat=7)

    biome("ventre", "O Ventre", "Domínio do deus que devorava",
          dict(stone="5a1a20", deep="1e0608", top="a83a3a", light="f0a090", shadow="0c0204", moss="c8d040",
               wood="4a2018", wood_top="7a3a28", wood_dark="200a08", vein="c8d040", cloth="2a0a10"),
          dict(sky0="100204", sky1="2a080c", sky2="3a0e12", glow="c83a3a", sun="ffd0a0", accent="c8d040", ambient="9a6a6a"),
          "bd_ventre", "embers",
          [("larva", "e", 10), ("parasite", "e", 9), ("maw_tentacle", "r", 9), ("slag", "e", 3)],
          "boss_insatiable", "bile_vent", 4,
          ["O deus que devorava comia o que sobrava do mundo, para o mundo caber nele mesmo.",
           "Quando os outros sumiram, ele ficou com fome deles. Comeu o próprio domínio por dentro.",
           "Você está andando por dentro dele. As paredes respiram.",
           "Os parasitas eram as últimas coisas que ele engoliu. Ainda não foram digeridos.",
           "Raspado no osso de uma costela: A FOME FICOU. O DEUS FOI EMBORA."],
          "0a0204", combat=7)

    biome("penhascos", "Os Penhascos do Sonho", "Domínio do deus que sonhava",
          dict(stone="5a5a7a", deep="20203a", top="8ac88a", light="e0f0d0", shadow="0c0c18", moss="b8e08a",
               wood="4a3a5a", wood_top="7a6a9a", wood_dark="241a30", vein="c8a8ff", cloth="5a3a8a"),
          dict(sky0="2a2050", sky1="7a68c0", sky2="b8a8e8", glow="f0d0ff", sun="fff8ff", accent="c8a8ff", ambient="b0a8d8"),
          "bd_penhascos", "stars",
          [("sleepwalker", "r", 10), ("nightmare", "e", 9), ("incubus", "e", 9), ("gargoyle", "e", 3)],
          "boss_dragon", "dream_flash", 5,
          ["Isto não existe. É o sonho de um deus que dormiu e não acordou mais.",
           "O mar lá embaixo é o sono dele. Quem cai, sonha junto e esquece de voltar.",
           "Os pesadelos correm por cima de quem dorme. Aqui, todos dormem.",
           "Ele sonhou um guarda para não ser acordado. O guarda tem asas.",
           "Escrito numa nuvem que não se mexe: NÃO ME ACORDE. NO SONHO ELES AINDA ESTÃO AQUI."],
          "0c0a1a", combat=7)

    biome("cavernas", "As Cavernas Fundas", "Domínio do deus que se escondia",
          dict(stone="3a3a48", deep="121218", top="6a6a80", light="a8b8c8", shadow="040406", moss="5a8a9a",
               wood="2a2420", wood_top="5a4a3a", wood_dark="120e0a", vein="8ac8e8", cloth="2a3a4a"),
          dict(sky0="040406", sky1="0e0e16", sky2="181822", glow="3a6a8a", sun="b8e8ff", accent="8ac8e8", ambient="5a6070"),
          "bd_cavernas", "dust",
          [("blind_lizard", "e", 10), ("crevice_snake", "e", 9), ("digger", "e", 9), ("mason", "e", 3)],
          "boss_wyrm", "cave_drip", 5,
          ["O deus que se escondia viu o que ia acontecer. Desceu antes de todo mundo.",
           "Cavou até não ouvir mais nada lá de cima. Os lagartos daqui nunca viram a luz.",
           "Os escavadores vieram atrás dele. Cavam há tanto tempo que esqueceram por quê.",
           "Na porta do fundo dorme a serpe. Ele deixou ela ali para ninguém descer mais.",
           "Riscado na rocha, bem fundo: ELE SABIA. E NÃO CONTOU A NINGUÉM."],
          "020204", combat=7)

    biome("bosque", "O Bosque Errante", "Domínio do deus que caminhava",
          dict(stone="4a4a3a", deep="1a1a12", top="7a8a4a", light="d8d0a0", shadow="0a0a06", moss="a8c870",
               wood="5a3a20", wood_top="8a6a3a", wood_dark="2a1a0e", vein="e8d070", cloth="6a2a1a"),
          dict(sky0="2a1a0a", sky1="7a4a1a", sky2="c88a3a", glow="ffd890", sun="fff4c8", accent="e8d070", ambient="b09a70"),
          "bd_bosque", "spores",
          [("highwayman", "e", 10), ("wanderer", "e", 9), ("frogman", "e", 9), ("wolf", "e", 3)],
          "boss_fox", "bramble", 5,
          ["O deus que caminhava nunca parou num lugar. O bosque andava com ele.",
           "Quando ele sumiu, o bosque continuou andando, sem saber para onde.",
           "Os andarilhos seguiam o deus. Agora seguem a estrada, que anda em círculo.",
           "A raposa ia sempre na frente, mostrando o caminho. Ainda vai.",
           "Numa placa de estrada, apontando para todos os lados: ELE FOI POR AQUI."],
          "0a0804", recolor={"wolf": "moss_beast"}, combat=7)
    print("ok")
