"""Gera os .tres de armas e habilidades a partir das tabelas abaixo.
Editar aqui e rodar `python tools/gen_content.py` (ou editar o .tres no Godot)."""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")

def v(x):
    if isinstance(x, bool): return "true" if x else "false"
    if isinstance(x, (int, float)): return repr(float(x)) if isinstance(x, float) else str(x)
    if isinstance(x, str): return '"%s"' % x.replace('"', '\\"').replace("\n", "\n")
    if isinstance(x, tuple): return "Vector2(%s, %s)" % x
    if isinstance(x, dict): return "{" + ", ".join("%s: %s" % (v(k), v(val)) for k, val in x.items()) + "}"
    if isinstance(x, list): return "[" + ", ".join(v(i) for i in x) + "]"
    raise TypeError(x)

def color(hexs):
    h = hexs.lstrip("#")
    r, g, b = (int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
    return "Color(%.3f, %.3f, %.3f, 1)" % (r, g, b)

def write(kind, script, cls, item):
    path = os.path.join(ROOT, "content", kind, item["id"] + ".tres")
    lines = ['[gd_resource type="Resource" script_class="%s" load_steps=2 format=3]' % cls, "",
             '[ext_resource type="Script" path="%s" id="1"]' % script, "", "[resource]", 'script = ExtResource("1")']
    for k, val in item.items():
        is_color = isinstance(val, str) and len(val) == 7 and val.startswith("#")
        lines.append("%s = %s" % (k, color(val[1:]) if is_color else v(val)))
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")

def move(startup, active, recover, damage, knock, reach, lunge, stop, shake, shape, **extra):
    m = dict(startup=startup, active=active, recover=recover, damage=damage, knock=knock,
             reach=reach, lunge=lunge, stop=stop, shake=shake, shape=shape)
    m.update(extra)
    return m

WEAPONS = [
    dict(id="espada_cerimonial", title="Espada Cerimonial", category="melee", stat="furia",
         crit_rule="", crit_mult=1.75, starter=True, unlock_cost=0, color="#d9e2ec",
         moves=[move(0.06, 0.08, 0.16, 10, 90, (28, 18), 70, 0.045, 1.5, "down"),
                move(0.06, 0.08, 0.18, 12, 110, (28, 20), 80, 0.05, 2.0, "up"),
                move(0.12, 0.10, 0.30, 15, 240, (34, 22), 150, 0.09, 4.0, "thrust", crit=True)],
         shot={},
         lore="Forjada para os desfiles das Casas do Mar de Cinzas. Nunca devia ter visto sangue. Viu."),
    dict(id="lanca_peregrino", title="Lança do Peregrino", category="melee", stat="astucia",
         crit_rule="behind", crit_mult=1.9, starter=False, unlock_cost=30, color="#c9b38a",
         moves=[move(0.08, 0.09, 0.18, 13, 120, (46, 10), 90, 0.05, 2.0, "thrust"),
                move(0.09, 0.10, 0.20, 11, 100, (40, 22), 60, 0.05, 2.0, "up"),
                move(0.10, 0.10, 0.26, 17, 180, (50, 12), 140, 0.07, 3.0, "thrust")],
         shot={},
         lore="Os peregrinos caminham até o centro do deserto apoiados nela. Poucos voltam. As lanças sempre voltam."),
    dict(id="machado_carrasco", title="Machado do Carrasco", category="melee", stat="vigor",
         crit_rule="stunned", crit_mult=2.0, starter=False, unlock_cost=40, color="#b8a6c9",
         moves=[move(0.20, 0.10, 0.28, 26, 220, (34, 26), 40, 0.09, 4.5, "smash"),
                move(0.16, 0.10, 0.26, 20, 160, (34, 28), 50, 0.08, 4.0, "up"),
                move(0.24, 0.12, 0.40, 34, 300, (38, 28), 60, 0.12, 6.0, "smash", status={"stun": 0.6})],
         shot={},
         lore="Na Casa Vesper, a sentença era lida pelo cego e executada pelo surdo. Assim ninguém ouvia o perdão."),
    dict(id="arco_dunas", title="Arco das Dunas", category="bow", stat="astucia",
         crit_rule="far", crit_mult=1.8, starter=True, unlock_cost=0, color="#c9b38a",
         moves=[], shot=dict(draw=0.22, recover=0.18, speed=380.0, damage=12.0, pierce=0),
         lore="Corda de tendão de besta-de-areia. Acerta melhor quem tem paciência para esperar a distância certa."),
    dict(id="arco_brasa", title="Arco de Brasa", category="bow", stat="astucia",
         crit_rule="burning", crit_mult=1.8, starter=False, unlock_cost=35, color="#ff9a3c",
         moves=[], shot=dict(draw=0.26, recover=0.2, speed=340.0, damage=9.0, pierce=1, status={"burn": 2.5}),
         lore="As pontas são mergulhadas em Cinza Sagrada. O que ela toca lembra que um deus ardeu aqui."),
    dict(id="adagas_gemeas", title="Adagas Gêmeas", category="melee", stat="astucia",
         crit_rule="behind", crit_mult=2.1, starter=False, unlock_cost=45, color="#d9e2ec",
         moves=[move(0.03, 0.06, 0.08, 6, 50, (22, 14), 60, 0.03, 1.0, "down"),
                move(0.03, 0.06, 0.08, 6, 50, (22, 14), 60, 0.03, 1.0, "up"),
                move(0.03, 0.06, 0.10, 7, 60, (22, 14), 70, 0.03, 1.0, "down"),
                move(0.05, 0.08, 0.16, 10, 120, (26, 16), 110, 0.05, 2.0, "thrust")],
         shot={},
         lore="Um par de assassinos da duna usava uma cada. Quando um morreu, o outro passou a usar as duas."),
    dict(id="martelo_forja", title="Martelo da Forja", category="melee", stat="vigor",
         crit_rule="burning", crit_mult=1.9, starter=False, unlock_cost=55, color="#ff8a3a",
         moves=[move(0.18, 0.14, 0.30, 20, 200, (30, 24), 30, 0.09, 4.0, "spin", status={"burn": 1.5}),
                move(0.24, 0.12, 0.34, 28, 240, (34, 24), 40, 0.1, 5.0, "smash", status={"burn": 2.0}),
                move(0.28, 0.14, 0.42, 36, 320, (40, 28), 70, 0.13, 7.0, "smash", status={"burn": 3.0})],
         shot={},
         lore="Os ferreiros cativos não largam os seus. Este foi tirado de uma mão que ainda estava quente."),
    dict(id="arco_inverno", title="Arco do Último Inverno", category="bow", stat="astucia",
         crit_rule="stunned", crit_mult=2.0, starter=False, unlock_cost=50, color="#9fe8ff",
         moves=[], shot=dict(draw=0.3, recover=0.22, speed=360.0, damage=11.0, pierce=0, status={"stun": 0.5}),
         lore="A corda é um fio de gelo que nunca derrete. A flecha chega antes do frio."),
    dict(id="chicote_espinhos", title="Chicote de Espinhos", category="melee", stat="astucia",
         crit_rule="tip", crit_mult=1.9, starter=False, unlock_cost=45, color="#9cc65a",
         moves=[move(0.10, 0.08, 0.20, 11, 80, (62, 10), 30, 0.05, 1.5, "lash"),
                move(0.10, 0.08, 0.22, 12, 100, (62, 14), 30, 0.05, 1.5, "up"),
                move(0.12, 0.09, 0.26, 14, 140, (66, 12), 40, 0.06, 2.0, "lash", status={"stun": 0.3}),
                move(0.14, 0.14, 0.32, 16, 180, (34, 22), 20, 0.07, 3.0, "spin")],
         shot={},
         lore="Trançado com um galho que ainda cresce. Cada vez que estala, fica um pouco mais comprido."),
    dict(id="foice_inverno", title="Foice do Inverno", category="melee", stat="vigor",
         crit_rule="stunned", crit_mult=1.9, starter=False, unlock_cost=50, color="#bfe6ff",
         moves=[move(0.10, 0.10, 0.22, 13, 120, (34, 22), 50, 0.06, 2.5, "down"),
                move(0.14, 0.12, 0.26, 15, 150, (30, 24), 30, 0.07, 3.0, "spin"),
                move(0.18, 0.14, 0.36, 21, 220, (34, 26), 50, 0.09, 4.0, "spin", status={"stun": 0.5})],
         shot={},
         lore="O ceifeiro dos Salões colhia o trigo que nunca nasceu. Gira para os dois lados, como quem não sabe de onde vem o frio."),
    dict(id="punhos_bronze", title="Punhos de Bronze", category="melee", stat="furia",
         crit_rule="airborne", crit_mult=1.8, starter=False, unlock_cost=40, color="#e0a85a",
         moves=[move(0.02, 0.05, 0.06, 5, 40, (18, 14), 50, 0.025, 0.8, "jab"),
                move(0.02, 0.05, 0.06, 5, 40, (18, 14), 50, 0.025, 0.8, "jab"),
                move(0.03, 0.06, 0.08, 7, 60, (18, 20), 40, 0.03, 1.5, "up"),
                move(0.03, 0.05, 0.07, 6, 50, (18, 14), 60, 0.03, 1.0, "jab"),
                move(0.06, 0.08, 0.18, 12, 200, (22, 18), 120, 0.06, 3.0, "thrust", crit=True)],
         shot={},
         lore="Mãos de um autômato do Observatório, desparafusadas com paciência. Ainda contam os golpes em voz baixa."),
    dict(id="besta_carcosa", title="Besta de Carcosa", category="bow", stat="astucia",
         crit_rule="behind", crit_mult=2.0, starter=False, unlock_cost=45, color="#e8d25a",
         moves=[], shot=dict(draw=0.34, recover=0.28, speed=420.0, damage=7.0, pierce=0, count=3, spread=0.12, look="crossbow"),
         lore="Três virotes amarelos de uma vez. Em Carcosa ninguém mira: atira-se em tudo que tem rosto."),
    dict(id="cetro_astronomo", title="Cetro do Astrônomo", category="bow", stat="furia",
         crit_rule="stunned", crit_mult=1.9, starter=False, unlock_cost=55, color="#b9a8ff",
         moves=[], shot=dict(draw=0.26, recover=0.24, speed=220.0, damage=10.0, pierce=0, style="star", homing=4.0, look="staff"),
         lore="Aponta para onde o deus estava. O que sai dele procura alguém para acertar, como o astrônomo procurava."),
]

SKILLS = [
    dict(id="granada_cinzas", title="Granada de Cinzas", kind="bomb", stat="astucia", cooldown=6.0,
         damage=22.0, params=dict(radius=34.0, burn=3.0), color="#ff9a3c", starter=True, unlock_cost=0,
         lore="Um punhado de Cinza Sagrada num jarro de barro. Os sacerdotes chamam de heresia. Os soldados, de munição."),
    dict(id="egide_bronze", title="Égide de Bronze", kind="shield", stat="vigor", cooldown=0.0,
         damage=0.0, params={}, color="#f2c14e", starter=False, unlock_cost=35,
         lore="Escudo da guarda pessoal do Imperador. O polimento é um espelho: quem ataca vê a si mesmo antes do golpe."),
    dict(id="lanca_vidro", title="Lança de Vidro", kind="javelin", stat="furia", cooldown=5.0,
         damage=24.0, params=dict(pierce=4), color="#bfe6ea", starter=False, unlock_cost=35,
         lore="Arrancada do corpo de um fulgurante. Ainda vibra quando passa perto da areia."),
    dict(id="armadilha_laminas", title="Armadilha de Lâminas", kind="trap", stat="astucia", cooldown=9.0,
         damage=7.0, params=dict(life=8.0, tick=0.35, width=30.0), color="#d9e2ec", starter=False, unlock_cost=40,
         lore="Os caçadores da duna enterram isto na cinza e esperam. A cinza é paciente; eles também."),
    dict(id="torreta_vidro", title="Torreta de Vidro", kind="turret", stat="astucia", cooldown=14.0,
         damage=7.0, params=dict(life=12.0, rate=0.7, range=170.0), color="#bfe6ea", starter=False, unlock_cost=50,
         lore="Um olho de fulgurante preso num tripé. Atira em tudo que se mexe, menos em quem o montou."),
    dict(id="espirito_cinza", title="Espírito de Cinza", kind="spirit", stat="furia", cooldown=16.0,
         damage=10.0, params=dict(life=10.0, speed=150.0), color="#ffb36b", starter=False, unlock_cost=55,
         lore="O que sobra de um peregrino que ardeu acreditando. Ainda quer lutar."),
    dict(id="corrente_ferreiro", title="Corrente do Ferreiro", kind="hook", stat="vigor", cooldown=6.0,
         damage=12.0, params=dict(range=150.0), color="#8a8a96", starter=False, unlock_cost=45,
         lore="Prendia os cativos à bigorna. Agora puxa quem estiver longe demais."),
    dict(id="sino_carcosa", title="Sino de Carcosa", kind="bell", stat="vigor", cooldown=11.0,
         damage=9.0, params=dict(radius=72.0, stun=1.4), color="#e8d25a", starter=False, unlock_cost=50,
         lore="O sino do Arauto, que anuncia o rei que nunca chega. Quem ouve para no lugar, esperando."),
    dict(id="raiz_viva", title="Raiz Viva", kind="roots", stat="astucia", cooldown=8.0,
         damage=14.0, params=dict(speed=230.0, stun=0.7), color="#7fbf4a", starter=False, unlock_cost=45,
         lore="Uma muda da Mãe-Raiz. Plantada no chão, corre na direção que você apontar e não perdoa nada no caminho."),
    dict(id="estrela_cadente", title="Estrela Cadente", kind="meteor", stat="furia", cooldown=12.0,
         damage=30.0, params=dict(radius=36.0, range=220.0, burn=2.0), color="#ffd27a", starter=False, unlock_cost=60,
         lore="Cada estrela caída é um nome que o deus esqueceu. Esta lembra o seu."),
]

SKINS = [
    dict(id="andarilho", title="O Andarilho", unlock="starter",
         cloak="#c41e3a", cloak_dark="#7a1424", hood="#1a1420", eye="#8ff7e8", scarf="#e8a33d",
         lore="Você acordou com ele. Ninguém lembra de costurar."),
    dict(id="manto_cinza", title="Manto de Cinza", unlock="essence", cost=60,
         cloak="#8a8580", cloak_dark="#5e5a57", hood="#3b3836", eye="#ffb36b", scarf="#c8452f",
         lore="Tecido com a cinza do deus que ardeu. Ainda morno."),
    dict(id="herdeiro_vesper", title="Herdeiro Vesper", unlock="essence", cost=90,
         cloak="#7a1f2b", cloak_dark="#4f1219", hood="#1d1418", eye="#f2c14e", scarf="#d9b45a",
         lore="As cores da Casa Vesper. A Casa caiu; o orgulho não."),
    dict(id="casca_vidro", title="Casca de Vidro", unlock="essence", cost=140,
         cloak="#6fb3b8", cloak_dark="#3f7f86", hood="#24474f", eye="#ffffff", scarf="#bfe6ea",
         lore="Um fulgurante tentou te engolir. Ficou com a forma."),
    dict(id="olhos_fechados", title="Olhos Fechados", unlock="feat", feat="boss",
         feat_text="Derrote o Imperador Cego",
         cloak="#3d2a5c", cloak_dark="#281b3e", hood="#15101f", eye="#6b5b88", scarf="#f2c14e", closed_eyes=True,
         lore="O futuro se vê de olhos fechados. Ele tinha razão."),
    dict(id="saco_penitente", title="Saco de Penitente", unlock="feat", feat="deaths10",
         feat_text="Morra 10 vezes",
         cloak="#7a6a4f", cloak_dark="#54482f", hood="#3a3122", eye="#ff5a4a", scarf="#9a8a6a",
         lore="Dez vezes na cinza. Agora você começa a ouvir."),
]

# Cromas: a mesma aparência pintada com as cores de um domínio.
# (manto, capuz, olho, cachecol); o tom escuro do manto sai do manto.
CHROMA_THEMES = {
    "geada": ("Geada", "#9fc4dc", "#2a3a5a", "#dff6ff", "#e8f2fa"),
    "brasa": ("Brasa", "#8a2a1a", "#2a1210", "#ffb050", "#ff8a3a"),
    "musgo": ("Musgo", "#4a6a2a", "#1e2a14", "#d8f07a", "#c84a6a"),
    "carcosa": ("Carcosa", "#c8a830", "#2a2010", "#ffffff", "#5a1a2a"),
    "astral": ("Astral", "#2a3a7a", "#0e1430", "#b48cff", "#9fe8ff"),
    "babel": ("Ouro de Babel", "#d8c890", "#3a3a6a", "#ffd84a", "#e0b04a"),
    "cinza": ("Cinza", "#6a6662", "#24201e", "#ff6a4a", "#9a948c"),
    "abismo": ("Abismo", "#141018", "#07060b", "#ff3a4a", "#3a2a4a"),
}
CHROMAS_OF = {
    "andarilho": ["geada", "brasa", "musgo", "abismo"],
    "manto_cinza": ["geada", "astral", "carcosa", "abismo"],
    "herdeiro_vesper": ["babel", "geada", "musgo", "abismo"],
    "casca_vidro": ["brasa", "astral", "carcosa", "cinza"],
    "olhos_fechados": ["babel", "brasa", "geada", "cinza"],
    "saco_penitente": ["musgo", "carcosa", "astral", "abismo"],
}



# ---------------------------------------------------------------------------
# Grande update: equipamento dos 6 domínios novos (um pouco de cada deus).
WEAPONS += [
    dict(id="lamina_luto", title="Lâmina do Luto", category="melee", stat="astucia",
         crit_rule="behind", crit_mult=2.0, starter=False, unlock_cost=45, color="#a8c0e8",
         moves=[move(0.05, 0.08, 0.14, 9, 80, (28, 16), 80, 0.04, 1.5, "down"),
                move(0.05, 0.08, 0.14, 9, 80, (28, 16), 80, 0.04, 1.5, "up"),
                move(0.08, 0.10, 0.22, 14, 160, (32, 18), 130, 0.06, 2.5, "thrust")],
         shot={},
         lore="As carpideiras cortam uma mecha de quem choram com ela. A lâmina não lembra de quem; você vai lembrar."),
    dict(id="cetro_nomes", title="Cetro dos Nomes", category="bow", stat="furia",
         crit_rule="stunned", crit_mult=1.9, starter=False, unlock_cost=55, color="#c86ae8",
         moves=[], shot=dict(draw=0.3, recover=0.26, speed=200.0, damage=11.0, pierce=1, style="glyph", homing=3.0, look="staff"),
         lore="O Chamador lia os nomes dos mortos com ele. Cada glifo que sai é um nome procurando o dono."),
    dict(id="espada_rei", title="Espada do Rei Esquecido", category="melee", stat="vigor",
         crit_rule="stunned", crit_mult=2.0, starter=False, unlock_cost=70, color="#d8dce8",
         moves=[move(0.16, 0.12, 0.28, 22, 200, (38, 26), 60, 0.09, 4.0, "down"),
                move(0.18, 0.12, 0.30, 24, 220, (38, 28), 60, 0.09, 4.0, "spin"),
                move(0.24, 0.14, 0.40, 34, 320, (44, 30), 90, 0.13, 6.5, "smash", status={"stun": 0.7})],
         shot={},
         lore="Grande demais para qualquer mão viva. O rei a carregava sem saber por quê. Agora você também."),
    dict(id="arco_ossos", title="Arco de Osso", category="bow", stat="astucia",
         crit_rule="far", crit_mult=1.9, starter=False, unlock_cost=40, color="#e8e0c8",
         moves=[], shot=dict(draw=0.24, recover=0.2, speed=420.0, damage=11.0, pierce=2),
         lore="Costela e tendão de alguém que pediu para ser útil depois de morto."),
    dict(id="tridente_afogado", title="Tridente Afogado", category="melee", stat="astucia",
         crit_rule="tip", crit_mult=2.0, starter=False, unlock_cost=50, color="#6ab8e8",
         moves=[move(0.08, 0.10, 0.20, 12, 120, (52, 10), 80, 0.05, 2.0, "thrust"),
                move(0.10, 0.10, 0.22, 13, 120, (52, 12), 80, 0.05, 2.0, "thrust"),
                move(0.14, 0.12, 0.30, 19, 220, (58, 14), 150, 0.08, 3.5, "thrust", status={"stun": 0.4})],
         shot={},
         lore="O cavaleiro votivo desceu com ele para guardar a nave. A ferrugem é a única coisa que não se afogou."),
    dict(id="clava_votiva", title="Clava Votiva", category="melee", stat="vigor",
         crit_rule="stunned", crit_mult=2.1, starter=False, unlock_cost=50, color="#f2c14e",
         moves=[move(0.18, 0.12, 0.28, 22, 220, (32, 26), 40, 0.09, 4.5, "smash", status={"stun": 0.4}),
                move(0.22, 0.14, 0.38, 30, 300, (36, 28), 50, 0.12, 6.0, "smash", status={"stun": 0.8})],
         shot={},
         lore="Feita com os votos de ouro que ninguém veio buscar. Cada pancada é uma promessa cumprida."),
    dict(id="arco_prece", title="Arco da Prece", category="bow", stat="furia",
         crit_rule="burning", crit_mult=1.8, starter=False, unlock_cost=45, color="#8ad0f0",
         moves=[], shot=dict(draw=0.2, recover=0.16, speed=340.0, damage=8.0, pierce=0, count=2, spread=0.08),
         lore="Atira duas flechas: uma para pedir, outra para agradecer. As duas acertam."),
    dict(id="cutelo_glutao", title="Cutelo do Glutão", category="melee", stat="vigor",
         crit_rule="burning", crit_mult=1.9, starter=False, unlock_cost=55, color="#e86a6a",
         moves=[move(0.14, 0.10, 0.24, 18, 180, (34, 24), 50, 0.08, 3.5, "down", status={"burn": 2.0}),
                move(0.14, 0.10, 0.24, 18, 180, (34, 24), 50, 0.08, 3.5, "up", status={"burn": 2.0}),
                move(0.20, 0.14, 0.34, 28, 280, (38, 28), 70, 0.12, 5.5, "smash", status={"burn": 3.0})],
         shot={},
         lore="O primeiro que o deus engoliu cortava a própria comida com isto. Por dentro do deus, nunca faltou."),
    dict(id="garras_parasita", title="Garras do Parasita", category="melee", stat="astucia",
         crit_rule="airborne", crit_mult=1.9, starter=False, unlock_cost=45, color="#ff7a5a",
         moves=[move(0.02, 0.05, 0.05, 5, 40, (20, 14), 60, 0.02, 0.8, "jab"),
                move(0.02, 0.05, 0.05, 5, 40, (20, 14), 60, 0.02, 0.8, "jab"),
                move(0.02, 0.05, 0.05, 5, 40, (20, 14), 60, 0.02, 0.8, "jab"),
                move(0.04, 0.08, 0.16, 11, 160, (24, 18), 120, 0.05, 2.5, "up", crit=True)],
         shot={},
         lore="Arrancadas de algo que vivia dentro de algo que vivia dentro do deus."),
    dict(id="dentes_ventre", title="Dentes do Ventre", category="bow", stat="astucia",
         crit_rule="behind", crit_mult=2.0, starter=False, unlock_cost=50, color="#f0e0c8",
         moves=[], shot=dict(draw=0.3, recover=0.24, speed=360.0, damage=6.0, pierce=0, count=4, spread=0.18, style="thorn"),
         lore="Um punhado de dentes que caíram da Goela. Jogados, voltam a morder."),
    dict(id="lamina_devaneio", title="Lâmina do Devaneio", category="melee", stat="furia",
         crit_rule="airborne", crit_mult=2.0, starter=False, unlock_cost=60, color="#c8a8ff",
         moves=[move(0.08, 0.10, 0.18, 12, 120, (32, 22), 60, 0.05, 2.0, "spin"),
                move(0.08, 0.10, 0.18, 12, 120, (32, 22), 60, 0.05, 2.0, "spin"),
                move(0.12, 0.12, 0.26, 18, 200, (36, 24), 100, 0.08, 3.5, "thrust", crit=True)],
         shot={},
         lore="Ela sonhava que lutava. Quando acordou, a lâmina ficou na sua mão, ainda sonhando."),
    dict(id="arco_sonho", title="Arco do Sonho", category="bow", stat="furia",
         crit_rule="far", crit_mult=1.9, starter=False, unlock_cost=55, color="#e0d0ff",
         moves=[], shot=dict(draw=0.28, recover=0.22, speed=240.0, damage=10.0, pierce=0, style="star", homing=3.5),
         lore="A Sonâmbula atirava dormindo e nunca errava. A flecha sabe onde você queria acertar."),
    dict(id="lanca_pesadelo", title="Lança do Pesadelo", category="melee", stat="furia",
         crit_rule="airborne", crit_mult=2.1, starter=False, unlock_cost=55, color="#6ae8ff",
         moves=[move(0.08, 0.10, 0.20, 14, 140, (48, 12), 110, 0.05, 2.5, "thrust"),
                move(0.10, 0.10, 0.22, 14, 140, (40, 24), 70, 0.05, 2.5, "up"),
                move(0.14, 0.12, 0.30, 22, 260, (54, 14), 180, 0.09, 4.0, "thrust")],
         shot={},
         lore="Feita da crina de fogo azul de um pesadelo. Quem leva o golpe acorda assustado, se acordar."),
    dict(id="picareta_escavador", title="Picareta do Escavador", category="melee", stat="vigor",
         crit_rule="stunned", crit_mult=2.0, starter=False, unlock_cost=45, color="#a8b8c8",
         moves=[move(0.18, 0.12, 0.26, 21, 200, (30, 28), 30, 0.09, 4.5, "smash"),
                move(0.20, 0.12, 0.30, 24, 240, (30, 30), 30, 0.1, 5.0, "smash", status={"stun": 0.5})],
         shot={},
         lore="Cavou mil anos atrás de um deus que não queria ser achado. Ainda tem a forma da mão do dono."),
    dict(id="sacola_bombas", title="Sacola de Bombas", category="bow", stat="vigor",
         crit_rule="burning", crit_mult=1.8, starter=False, unlock_cost=50, color="#ff9a3c",
         moves=[], shot=dict(draw=0.34, recover=0.3, speed=220.0, damage=16.0, pierce=0, style="bomb", status={"burn": 2.0}),
         lore="Os escavadores abriam caminho com isto. O caminho, às vezes, era alguém."),
    dict(id="punhal_cego", title="Punhal Cego", category="melee", stat="astucia",
         crit_rule="stunned", crit_mult=2.4, starter=False, unlock_cost=50, color="#8ac8e8",
         moves=[move(0.03, 0.06, 0.08, 7, 50, (22, 14), 70, 0.03, 1.0, "down"),
                move(0.03, 0.06, 0.08, 7, 50, (22, 14), 70, 0.03, 1.0, "thrust"),
                move(0.05, 0.08, 0.14, 11, 120, (26, 14), 110, 0.05, 2.0, "thrust")],
         shot={},
         lore="O Eremita lutava no escuro e não precisava ver. Acerta onde dói, não onde brilha."),
    dict(id="espada_estrada", title="Espada da Estrada", category="melee", stat="furia",
         crit_rule="", crit_mult=1.75, starter=False, unlock_cost=35, color="#d8d0a0",
         moves=[move(0.06, 0.08, 0.16, 11, 100, (30, 18), 80, 0.045, 1.8, "down"),
                move(0.06, 0.08, 0.16, 12, 110, (30, 20), 80, 0.05, 2.0, "up"),
                move(0.06, 0.08, 0.18, 12, 110, (30, 18), 90, 0.05, 2.0, "down"),
                move(0.10, 0.10, 0.28, 17, 240, (36, 22), 160, 0.09, 4.0, "thrust", crit=True)],
         shot={},
         lore="O salteador cobrava pedágio com ela. Não tinha onde gastar: a estrada não chega a lugar nenhum."),
    dict(id="machado_touro", title="Machado do Touro", category="melee", stat="vigor",
         crit_rule="behind", crit_mult=2.0, starter=False, unlock_cost=55, color="#c8a060",
         moves=[move(0.16, 0.12, 0.28, 20, 200, (34, 26), 60, 0.09, 4.0, "spin"),
                move(0.22, 0.14, 0.36, 30, 300, (38, 28), 140, 0.12, 6.0, "smash")],
         shot={},
         lore="Pedágio pago em ferro. O touro aceitava, mas cortava junto."),
    dict(id="arco_raposa", title="Arco da Raposa", category="bow", stat="astucia",
         crit_rule="far", crit_mult=1.9, starter=False, unlock_cost=60, color="#9fd8ff",
         moves=[], shot=dict(draw=0.24, recover=0.2, speed=260.0, damage=7.0, pierce=0, count=2, spread=0.25, style="orb", homing=2.5),
         lore="Duas chamas-fátuas por disparo. Como a raposa, vão na frente e não param de procurar."),
    dict(id="bordao_andarilho", title="Bordão do Andarilho", category="melee", stat="astucia",
         crit_rule="tip", crit_mult=1.9, starter=False, unlock_cost=40, color="#b89a5a",
         moves=[move(0.08, 0.10, 0.18, 10, 140, (46, 12), 60, 0.05, 2.0, "thrust"),
                move(0.10, 0.12, 0.22, 12, 160, (40, 22), 40, 0.05, 2.0, "spin"),
                move(0.12, 0.12, 0.28, 16, 240, (48, 14), 100, 0.07, 3.0, "thrust", status={"stun": 0.5})],
         shot={},
         lore="Gasto na ponta de tanto apontar caminhos. Todos errados, mas com convicção."),
]

SKILLS += [
    dict(id="grito_carpideira", title="Grito da Carpideira", kind="bell", stat="vigor", cooldown=10.0,
         damage=8.0, params=dict(radius=84.0, stun=1.1), color="#a8c0e8", starter=False, unlock_cost=45,
         lore="Um choro tão alto que os vivos esquecem de se mexer."),
    dict(id="mao_cova", title="Mão da Cova", kind="roots", stat="astucia", cooldown=8.0,
         damage=15.0, params=dict(speed=200.0, stun=0.9), color="#e8e0c8", starter=False, unlock_cost=45,
         lore="Corre por baixo da terra e agarra o primeiro pé que encontra."),
    dict(id="prece_lancada", title="Prece Lançada", kind="javelin", stat="furia", cooldown=6.0,
         damage=20.0, params=dict(pierce=7), color="#8ad0f0", starter=False, unlock_cost=45,
         lore="Uma prece afiada. Atravessa tudo até chegar a quem tem que ouvir."),
    dict(id="onda_catedral", title="Onda da Nave", kind="roots", stat="vigor", cooldown=9.0,
         damage=12.0, params=dict(speed=300.0, stun=0.5), color="#6ab8e8", starter=False, unlock_cost=50,
         lore="A água que encheu a Catedral ainda corre pelo chão quando você chama."),
    dict(id="bile_acida", title="Bile Ácida", kind="bomb", stat="astucia", cooldown=7.0,
         damage=18.0, params=dict(radius=40.0, burn=4.0), color="#c8d040", starter=False, unlock_cost=45,
         lore="Um jarro do que o Ventre usava para digerir deuses. Queima por mais tempo."),
    dict(id="dentes_chao", title="Arcada", kind="trap", stat="astucia", cooldown=10.0,
         damage=9.0, params=dict(life=7.0, tick=0.3, width=36.0), color="#f0e0c8", starter=False, unlock_cost=50,
         lore="Uma fileira de dentes plantada no chão. Mordem quem pisa."),
    dict(id="pesadelo_vivo", title="Pesadelo Domado", kind="spirit", stat="furia", cooldown=15.0,
         damage=13.0, params=dict(life=9.0, speed=200.0), color="#6ae8ff", starter=False, unlock_cost=60,
         lore="Um pesadelo pequeno, que aprendeu a correr por cima dos outros."),
    dict(id="olho_sonho", title="Olho que Sonha", kind="turret", stat="furia", cooldown=13.0,
         damage=8.0, params=dict(life=10.0, rate=0.55, range=190.0), color="#c8a8ff", starter=False, unlock_cost=55,
         lore="Fica parado, de olho fechado, atirando no que vê no sonho. Vê tudo."),
    dict(id="lanterna_caida", title="Lanterna Caída", kind="meteor", stat="vigor", cooldown=11.0,
         damage=26.0, params=dict(radius=42.0, range=220.0, burn=1.0), color="#8ac8e8", starter=False, unlock_cost=55,
         lore="A última luz que alguém levou para as Cavernas. Caiu. Ainda cai, sempre que você pede."),
    dict(id="escudo_eremita", title="Escudo do Eremita", kind="shield", stat="vigor", cooldown=0.0,
         damage=0.0, params={}, color="#a8b8c8", starter=False, unlock_cost=45,
         lore="Uma tampa de pedra do fundo da caverna. Não brilha. Não precisa."),
    dict(id="laco_salteador", title="Laço do Salteador", kind="hook", stat="astucia", cooldown=5.0,
         damage=10.0, params=dict(range=180.0), color="#d8c890", starter=False, unlock_cost=40,
         lore="Puxa a vítima para perto. Na estrada, a conversa é sempre de perto."),
    dict(id="fogo_raposa", title="Fogo-Fátuo da Raposa", kind="spirit", stat="astucia", cooldown=14.0,
         damage=9.0, params=dict(life=12.0, speed=170.0), color="#9fd8ff", starter=False, unlock_cost=60,
         lore="Uma das nove chamas da raposa. Vai na frente, como ela ia."),
]

SKINS += [
    dict(id="mortalha", title="Mortalha", unlock="essence", cost=110,
         cloak="#c8ccd8", cloak_dark="#8a8e9e", hood="#2a2e3e", eye="#a8c0e8", scarf="#5a4a7a",
         lore="Costurada pelas carpideiras para quem ninguém mais lembra."),
    dict(id="vestes_afogadas", title="Vestes Afogadas", unlock="essence", cost=120,
         cloak="#2a5a7a", cloak_dark="#1a3a52", hood="#0e1e2c", eye="#8ad0f0", scarf="#c8a830",
         lore="Ainda pingam. Cheiram a incenso e a fundo de rio."),
    dict(id="pele_ventre", title="Pele do Ventre", unlock="essence", cost=130,
         cloak="#8a2a30", cloak_dark="#5a1a20", hood="#2a0a10", eye="#c8d040", scarf="#e8b098",
         lore="Não pergunte do que é feito. Ainda está quente."),
    dict(id="manto_sonho", title="Manto do Sonho", unlock="essence", cost=140,
         cloak="#9a8ad8", cloak_dark="#6a5aa8", hood="#2a2050", eye="#ffffff", scarf="#f0d0ff",
         lore="Leve como quem dorme. Quem olha muito tempo boceja."),
    dict(id="couro_fenda", title="Couro da Fenda", unlock="essence", cost=120,
         cloak="#3a4048", cloak_dark="#262c34", hood="#0a0c10", eye="#8ac8e8", scarf="#6a5a3a",
         lore="Curtido no escuro. Não reflete luz nenhuma."),
    dict(id="capa_estrada", title="Capa da Estrada", unlock="essence", cost=100,
         cloak="#7a5a2a", cloak_dark="#54401c", hood="#2a1e10", eye="#e8d070", scarf="#a8c870",
         lore="Poeira de todos os caminhos do Bosque, que são um só."),
    dict(id="rei_esquecido", title="Coroa sem Nome", unlock="feat", feat="boss",
         feat_text="Derrote o Imperador Cego",
         cloak="#e8e0c8", cloak_dark="#a8a088", hood="#3a3a4a", eye="#ffd84a", scarf="#ffd84a",
         lore="Uma coroa gasta de tanto ser tocada. O nome, você inventa."),
    dict(id="nove_caudas", title="Nove Caudas", unlock="essence", cost=180,
         cloak="#e8eef8", cloak_dark="#a8b8d8", hood="#5a6a8a", eye="#9fd8ff", scarf="#ff8a6a",
         lore="Pelo branco de raposa, com a ponta acesa."),
    dict(id="escama_serpe", title="Escama da Serpe", unlock="essence", cost=170,
         cloak="#a83a2a", cloak_dark="#6a2018", hood="#2a0e0a", eye="#ffb050", scarf="#ff8a3a",
         lore="Uma escama só já pesa como armadura. Esta é a mais leve."),
    dict(id="asa_dragao", title="Asa do Dragão Sonhado", unlock="essence", cost=190,
         cloak="#7a4ab8", cloak_dark="#4e2a80", hood="#1e1030", eye="#ff8af0", scarf="#ffd84a",
         lore="Existe só enquanto alguém sonha. Por via das dúvidas, não durma."),
    dict(id="tentaculo", title="O Que Responde", unlock="essence", cost=200,
         cloak="#2a5a3a", cloak_dark="#1a3a24", hood="#0a1a10", eye="#6ae88a", scarf="#1a6a4a",
         lore="Alguém rezou para ficar com isto. Foi atendido."),
    dict(id="cinza_pura", title="Cinza Pura", unlock="feat", feat="deaths10",
         feat_text="Morra 10 vezes",
         cloak="#2a2826", cloak_dark="#1a1816", hood="#0c0a0a", eye="#ff6a3a", scarf="#ff6a3a",
         lore="O que sobra de quem voltou da cinza vezes demais."),
]

CHROMA_THEMES.update({
    "luto": ("Luto", "#c8ccd8", "#2a2e3e", "#a8c0e8", "#5a4a7a"),
    "afogado": ("Afogado", "#2a5a7a", "#0e1e2c", "#8ad0f0", "#c8a830"),
    "carne": ("Carne", "#8a2a30", "#2a0a10", "#c8d040", "#e8b098"),
    "sonho": ("Sonho", "#9a8ad8", "#2a2050", "#ffffff", "#f0d0ff"),
    "fenda": ("Fenda", "#3a4048", "#0a0c10", "#8ac8e8", "#6a5a3a"),
    "estrada": ("Estrada", "#7a5a2a", "#2a1e10", "#e8d070", "#a8c870"),
})
CHROMAS_OF.update({
    "mortalha": ["afogado", "sonho", "abismo"], "vestes_afogadas": ["luto", "fenda", "abismo"],
    "pele_ventre": ["brasa", "estrada", "abismo"], "manto_sonho": ["luto", "astral", "carne"],
    "couro_fenda": ["afogado", "estrada", "brasa"], "capa_estrada": ["musgo", "fenda", "carcosa"],
    "nove_caudas": ["sonho", "brasa", "luto"], "escama_serpe": ["fenda", "carne", "babel"],
    "asa_dragao": ["sonho", "astral", "abismo"], "tentaculo": ["afogado", "musgo", "abismo"],
    "rei_esquecido": ["luto", "babel", "abismo"], "cinza_pura": ["brasa", "luto", "carne"],
})

# Ícones (pixel art 32x32, "496 pixel art icons for medieval/fantasy RPG",
# Henrique Lazarini / 7Soul1, CC0): escolhidos pelo desenho de cada item.
ICONS = {
    "espada_cerimonial": "W_Sword001", "arco_dunas": "W_Bow01", "lanca_peregrino": "W_Spear001",
    "machado_carrasco": "W_Axe007", "arco_brasa": "W_Bow08", "adagas_gemeas": "W_Dagger005",
    "martelo_forja": "W_Mace003", "arco_inverno": "W_Bow10", "chicote_espinhos": "W_Mace006",
    "foice_inverno": "W_Spear013", "punhos_bronze": "W_Fist004", "besta_carcosa": "W_Bow16",
    "cetro_astronomo": "W_Staff05",
    "lamina_luto": "W_Sword019", "cetro_nomes": "W_Staff07", "espada_rei": "W_Gold_Sword", "arco_ossos": "W_Bow06",
    "tridente_afogado": "W_Spear009", "clava_votiva": "W_Mace011", "arco_prece": "W_Bow13",
    "cutelo_glutao": "W_Axe011", "garras_parasita": "W_Fist003", "dentes_ventre": "W_Throw004",
    "lamina_devaneio": "W_Sword016", "arco_sonho": "W_Bow14", "lanca_pesadelo": "W_Spear014",
    "picareta_escavador": "W_Axe014", "sacola_bombas": "W_Mace005", "punhal_cego": "W_Dagger019",
    "espada_estrada": "W_Sword012", "machado_touro": "W_Axe012", "arco_raposa": "W_Bow15",
    "bordao_andarilho": "W_Staff01",
    "granada_cinzas": "I_IronBall", "egide_bronze": "E_Gold01", "lanca_vidro": "S_Ice04",
    "armadilha_laminas": "S_Earth04", "torreta_vidro": "I_Cannon03", "espirito_cinza": "S_Fire01",
    "corrente_ferreiro": "W_Mace004", "sino_carcosa": "S_Thunder03", "raiz_viva": "S_Poison08",
    "estrela_cadente": "S_Fire05",
    "grito_carpideira": "S_Shadow14", "mao_cova": "S_Shadow16", "prece_lancada": "S_Water04",
    "onda_catedral": "S_Water03", "bile_acida": "S_Poison05", "dentes_chao": "S_Dagger04",
    "pesadelo_vivo": "S_Shadow09", "olho_sonho": "S_Magic03", "lanterna_caida": "S_Light02",
    "escudo_eremita": "E_Metal06", "laco_salteador": "S_Wind06", "fogo_raposa": "S_Fire03",
}
ICON_SRC = os.path.join(ROOT, "arte_externa", "496-pixel-art-icons-for-medievalfantasy-rpg")
ICON_OUT = os.path.join(ROOT, "assets", "icons")
os.makedirs(ICON_OUT, exist_ok=True)
import shutil
for item in WEAPONS + SKILLS:
    name = ICONS.get(item["id"])
    if name:
        src = os.path.join(ICON_SRC, name + ".png")
        if os.path.exists(src):
            shutil.copyfile(src, os.path.join(ICON_OUT, item["id"] + ".png"))
            # versão 16 px para o HUD e o pedestal (o jogo roda em 480x270): média de
            # cada bloco 2x2 com o alfa cortado, para o contorno continuar nítido
            from PIL import Image
            im = Image.open(src).convert("RGBA").resize((16, 16), Image.BOX)
            px = im.load()
            for y in range(16):
                for x in range(16):
                    r, g, b_, a = px[x, y]
                    px[x, y] = (r, g, b_, 255 if a >= 96 else 0)
            im.save(os.path.join(ICON_OUT, item["id"] + "_16.png"))
        item["icon"] = "res://assets/icons/%s.png" % item["id"]


def dark(hexs, k=0.32):
    h = hexs.lstrip("#")
    return "#" + "".join("%02x" % int(int(h[i:i + 2], 16) * (1 - k)) for i in (0, 2, 4))


def blend(a, b, t=0.5):
    a, b = a.lstrip("#"), b.lstrip("#")
    return "#" + "".join("%02x" % round(int(a[i:i + 2], 16) * (1 - t) + int(b[i:i + 2], 16) * t) for i in (0, 2, 4))


# o croma troca manto e cachecol; o capuz fica no meio do caminho entre o da
# aparência e o do tema, e o olho segue o da aparência: ela continua sendo ela
for k in SKINS:
    k["chromas"] = [dict(id=c, title=CHROMA_THEMES[c][0], cloak=CHROMA_THEMES[c][1], cloak_dark=dark(CHROMA_THEMES[c][1]),
                         hood=blend(k["hood"], CHROMA_THEMES[c][2]), eye=k["eye"], scarf=CHROMA_THEMES[c][4], cost=25)
                    for c in CHROMAS_OF.get(k["id"], [])]

for w in WEAPONS:
    write("weapons", "res://scripts/combat/weapon_data.gd", "WeaponData", w)
for s in SKILLS:
    write("skills", "res://scripts/combat/skill_data.gd", "SkillData", s)
for k in SKINS:
    write("skins", "res://scripts/actors/skin_data.gd", "SkinData", k)
print(len(WEAPONS), "armas,", len(SKILLS), "habilidades,", len(SKINS), "aparências")
