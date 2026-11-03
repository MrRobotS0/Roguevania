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
                move(0.10, 0.10, 0.26, 17, 180, (50, 12), 140, 0.07, 3.0, "thrust")],
         shot={},
         lore="Os peregrinos caminham até o centro do deserto apoiados nela. Poucos voltam. As lanças sempre voltam."),
    dict(id="machado_carrasco", title="Machado do Carrasco", category="melee", stat="vigor",
         crit_rule="stunned", crit_mult=2.0, starter=False, unlock_cost=40, color="#b8a6c9",
         moves=[move(0.20, 0.10, 0.28, 26, 220, (34, 26), 40, 0.09, 4.5, "smash"),
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
         moves=[move(0.24, 0.12, 0.34, 28, 240, (34, 24), 40, 0.1, 5.0, "smash", status={"burn": 2.0}),
                move(0.28, 0.14, 0.42, 36, 320, (40, 28), 70, 0.13, 7.0, "smash", status={"burn": 3.0})],
         shot={},
         lore="Os ferreiros cativos não largam os seus. Este foi tirado de uma mão que ainda estava quente."),
    dict(id="arco_inverno", title="Arco do Último Inverno", category="bow", stat="astucia",
         crit_rule="stunned", crit_mult=2.0, starter=False, unlock_cost=50, color="#9fe8ff",
         moves=[], shot=dict(draw=0.3, recover=0.22, speed=360.0, damage=11.0, pierce=0, status={"stun": 0.5}),
         lore="A corda é um fio de gelo que nunca derrete. A flecha chega antes do frio."),
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
]

SKINS = [
    dict(id="andarilho", title="O Andarilho", unlock="starter",
         cloak="#2e5d8a", cloak_dark="#1f3f60", hood="#1a2a45", eye="#8ff7e8", scarf="#e8a33d",
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

for w in WEAPONS:
    write("weapons", "res://scripts/combat/weapon_data.gd", "WeaponData", w)
for s in SKILLS:
    write("skills", "res://scripts/combat/skill_data.gd", "SkillData", s)
for k in SKINS:
    write("skins", "res://scripts/actors/skin_data.gd", "SkinData", k)
print(len(WEAPONS), "armas,", len(SKILLS), "habilidades,", len(SKINS), "aparências")
