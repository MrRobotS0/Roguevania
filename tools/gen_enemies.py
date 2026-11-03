"""Folhas de sprite dos inimigos do Mar de Cinzas (e do Imperador Cego).

    python tools/gen_enemies.py

Mesmo sistema do herói (pixelrig): pose -> formas -> luz -> contorno, e a
imagem guarda índices de paleta. A arma vem desenhada na pose. Cada inimigo
tem a paleta em ENEMY_PALETTES (o jogo usa a mesma tabela, em
scripts/enemies/enemy_looks.gd).

Índices:  1 contorno | 2-4 roupa (claro, base, escuro) | 5-7 segunda peça
          8 olho | 9-11 detalhe (bronze, ouro, faixa) | 12 rosto
          13-14 madeira (escura, base) | 15 metal
"""
import json
import math
import os

from pixelrig import Canvas, OUTLINE, sheet, preview, hexc, shade

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "previews")

MAIN_HI, MAIN, MAIN_DK = 2, 3, 4
SEC_HI, SEC, SEC_DK = 5, 6, 7
EYE = 8
ACC_HI, ACC, ACC_DK = 9, 10, 11
FACE = 12
WOOD_DK, WOOD = 13, 14
METAL = 15


def v(a, length):
    return (math.sin(a) * length, math.cos(a) * length)


def add(p, q):
    return (p[0] + q[0], p[1] + q[1])


class Fig:
    """Um corpo genérico. Medidas em pixels, pés em (cx, fy)."""

    def __init__(self, w, h, **k):
        self.c = Canvas(w, h)
        self.cx = w / 2
        self.fy = h - 2
        self.k = k
        c = self.c
        self.p_main = c.new_part(MAIN, MAIN_HI, MAIN_DK)
        self.p_main_back = c.new_part(MAIN_DK, MAIN, OUTLINE)
        self.p_sec = c.new_part(SEC, SEC_HI, SEC_DK)
        self.p_sec_back = c.new_part(SEC_DK, SEC, OUTLINE)
        self.p_acc = c.new_part(ACC, ACC_HI, ACC_DK)
        self.p_face = c.new_part(FACE, FACE, FACE)
        self.p_wood = c.new_part(WOOD, WOOD, WOOD_DK)
        self.p_metal = c.new_part(METAL, METAL, ACC_DK)

    def limb2(self, start, a, bend, l1, l2, w1, w2, part):
        mid = add(start, v(a, l1))
        end = add(mid, v(a + bend, l2))
        self.c.limb(start, mid, w1, part)
        self.c.limb(mid, end, w2, part)
        return end

    def weapon(self, hand, kind, ang, part_shaft=None):
        c = self.c
        d = v(ang, 1.0)
        if kind == "club":
            tip = add(hand, (d[0] * 11, d[1] * 11))
            c.limb(add(hand, (-d[0] * 2, -d[1] * 2)), tip, 2.2, self.p_wood)
            c.ellipse(tip, 2.8, 2.8, self.p_wood)
            c.mark(tip[0] - 1, tip[1] - 1, METAL)
            c.mark(tip[0] + 1, tip[1] + 1, METAL)
        elif kind == "hammer":
            tip = add(hand, (d[0] * 10, d[1] * 10))
            c.limb(add(hand, (-d[0] * 2, -d[1] * 2)), tip, 2.0, self.p_wood)
            side = (-d[1], d[0])
            a0 = add(tip, (side[0] * 5, side[1] * 5))
            a1 = add(tip, (-side[0] * 5, -side[1] * 5))
            fw = (d[0] * 4, d[1] * 4)
            c.poly([a0, a1, add(a1, fw), add(a0, fw)], self.p_metal)
        elif kind == "spear":
            back = add(hand, (-d[0] * 10, -d[1] * 10))
            tip = add(hand, (d[0] * 16, d[1] * 16))
            c.limb(back, tip, 1.4, self.p_wood)
            point = add(tip, (d[0] * 4, d[1] * 4))
            side = (-d[1] * 1.8, d[0] * 1.8)
            c.poly([add(tip, side), point, add(tip, (-side[0], -side[1]))], self.p_metal)
        elif kind == "staff":
            c.limb(add(hand, (0, -8)), add(hand, (0, 9)), 1.4, self.p_wood)
            c.ellipse(add(hand, (0, -9)), 1.5, 1.5, self.p_acc)
        elif kind == "dagger":
            tip = add(hand, (d[0] * 8, d[1] * 8))
            c.limb(hand, tip, 1.2, self.p_metal)
            c.rect(hand[0] - 1, hand[1] - 1, 2, 2, self.p_acc)
        elif kind == "censer":
            ball = add(hand, (d[0] * 9, d[1] * 9))
            n = 6
            for i in range(1, n):
                p = add(hand, (d[0] * 9 * i / n, d[1] * 9 * i / n))
                c.mark(p[0], p[1], ACC_DK)
            c.ellipse(ball, 2.6, 2.6, self.p_acc)
            c.mark(ball[0], ball[1] + 1, EYE)
        elif kind == "bow":
            # arco vertical na frente da mão; corda puxada conforme ang (0..1)
            pull = ang
            top, bot = add(hand, (1, -8)), add(hand, (1, 8))
            for i in range(17):
                t = i / 16
                bulge = math.sin(t * math.pi) * 3
                c.mark(hand[0] + 1 + bulge, hand[1] - 8 + t * 16, WOOD)
            c.mark(top[0], top[1], WOOD_DK)
            c.mark(bot[0], bot[1], WOOD_DK)
            for i in range(17):
                t = i / 16
                sx = hand[0] + 1 - pull * 4 * math.sin(t * math.pi)
                c.mark(sx, hand[1] - 8 + t * 16, SEC_HI)
        elif kind == "scepter":
            tip = add(hand, (d[0] * 22, d[1] * 22))
            c.limb(add(hand, (-d[0] * 6, -d[1] * 6)), tip, 2.0, self.p_acc)
            c.ellipse(add(tip, (d[0] * 2, d[1] * 2)), 3.2, 3.2, self.p_metal)
            c.mark(tip[0] + d[0] * 2, tip[1] + d[1] * 2, EYE)

    def done(self):
        self.c.finish()
        return self.c


# --- Penitente: corcunda pesado, capuz de saco, clava -------------------------

def penitent(walk=0.0, lean=0.0, club=("idle", 0.0), bob=0):
    f = Fig(40, 36)
    c, cx, fy = f.c, f.cx, f.fy
    hip = (cx + lean * 0.3, fy - 8 + bob)
    sh = (cx + 1.5 + lean, fy - 17 + bob)
    s = math.sin(walk)
    for a, part in ((-0.3 - 0.5 * s, f.p_sec_back), (0.3 + 0.5 * s, f.p_sec)):
        end = f.limb2(hip, a, -0.35, 4.5, 4.0, 4.0, 3.6, part)
        c.rect(end[0] - 2, end[1] - 1, 4, 2, f.p_sec_back)
    arm_back = f.limb2((sh[0] - 3, sh[1] + 2), -0.2 + 0.4 * s, 0.4, 4, 4, 3.2, 3, f.p_main_back)
    # corpo largo, corcunda
    c.poly([(sh[0] - 6, sh[1] - 1), (sh[0] + 3, sh[1] - 2), (hip[0] + 6, hip[1] + 1),
            (hip[0] - 6, hip[1] + 2), (sh[0] - 8, sh[1] + 5)], f.p_main)
    c.rect(hip[0] - 6, hip[1] - 2, 12, 2, f.p_acc)
    # capuz de saco com costura e um olho
    head = (sh[0] + 3, sh[1] - 3)
    c.ellipse(head, 4.2, 4.0, f.p_sec)
    c.mark(head[0] - 2, head[1] - 2, SEC_DK)
    c.mark(head[0] - 1, head[1] - 3, SEC_DK)
    c.mark(head[0] + 2, head[1] - 0.5, EYE)
    kind, t = club
    if kind == "windup":
        hand = f.limb2((sh[0] + 1, sh[1] + 1), -2.6, 0.2, 4, 4, 3.4, 3, f.p_main)
        f.weapon(hand, "club", -2.9)
    elif kind == "attack":
        hand = f.limb2((sh[0] + 1, sh[1] + 1), 1.4, 0.1, 4.5, 4.5, 3.4, 3, f.p_main)
        f.weapon(hand, "club", 1.55)
    else:
        hand = f.limb2((sh[0] + 1, sh[1] + 1), 0.4 - 0.3 * s, -0.2, 4, 4, 3.4, 3, f.p_main)
        f.weapon(hand, "club", 0.35)
    return f.done()


def penitent_anims():
    A = {"idle": (3, [penitent(bob=b) for b in (0, 1)])}
    A["walk"] = (8, [penitent(walk=i / 4 * math.tau, bob=-(i % 2)) for i in range(4)])
    A["windup"] = (1, [penitent(lean=-2, club=("windup", 0))])
    A["attack"] = (1, [penitent(lean=2, club=("attack", 0))])
    A["stun"] = (1, [penitent(lean=-2.5, bob=1)])
    return A


# --- Guarda da Casa: armadura, elmo de bronze, escudo de torre, lança ------------

def guard(walk=0.0, spear=0.0, shield=True, lean=0.0, bob=0):
    f = Fig(48, 36)
    c, cx, fy = f.c, f.cx, f.fy
    hip = (cx + lean * 0.3, fy - 9 + bob)
    sh = (cx + lean, fy - 18 + bob)
    s = math.sin(walk)
    for a, part in ((-0.25 - 0.45 * s, f.p_main_back), (0.25 + 0.45 * s, f.p_main)):
        end = f.limb2(hip, a, -0.3, 4.6, 4.6, 3.6, 3.2, part)
        c.rect(end[0] - 1.5, end[1] - 1, 4, 2, f.p_sec_back)
    c.poly([(sh[0] - 5, sh[1] - 1), (sh[0] + 5, sh[1] - 1), (hip[0] + 5, hip[1] + 1),
            (hip[0] - 5, hip[1] + 1)], f.p_main)
    c.rect(hip[0] - 5, hip[1] - 3, 10, 2, f.p_acc)
    c.ellipse((sh[0] - 4, sh[1] + 1), 2.5, 2.2, f.p_acc)
    head = (sh[0] + 1, sh[1] - 4)
    c.ellipse(head, 3.8, 4.2, f.p_acc)
    c.rect(head[0] - 1, head[1] - 7, 2, 3, f.p_main)      # crista
    c.rect(head[0] + 0.5, head[1] - 0.5, 4, 1, f.p_face)  # fenda do elmo
    hand = f.limb2((sh[0] + 1, sh[1] + 2), 1.35, 0.2, 4, 3.5, 3, 2.6, f.p_main)
    f.weapon(add(hand, (spear, 0)), "spear", 1.57)
    if shield:
        c.rect(sh[0] + 6, sh[1] - 3, 5, 18, f.p_acc)
        c.rect(sh[0] + 7, sh[1] + 2, 3, 1, f.p_main)
        c.mark(sh[0] + 8, sh[1] + 5, ACC_DK)
    else:
        c.rect(sh[0] - 9, sh[1] - 2, 4, 16, f.p_acc)
    return f.done()


def guard_anims():
    A = {"idle": (3, [guard(bob=b) for b in (0, 1)])}
    A["walk"] = (8, [guard(walk=i / 4 * math.tau, bob=-(i % 2)) for i in range(4)])
    A["windup"] = (1, [guard(spear=-6, lean=-1.5)])
    A["attack"] = (1, [guard(spear=8, lean=2, shield=False)])
    A["recover"] = (1, [guard(spear=3, lean=0.5, shield=False)])
    A["stun"] = (1, [guard(spear=-2, lean=-2, bob=1)])
    return A


# --- Peregrino Cinzento: manto comprido, cajado; no aviso abre os braços em brasa --

def pilgrim(sway=0.0, ignite=0.0, bob=0):
    f = Fig(32, 32)
    c, cx, fy = f.c, f.cx, f.fy
    hip = (cx + sway, fy - 7 + bob)
    sh = (cx + sway * 0.5, fy - 15 + bob)
    c.poly([(sh[0] - 3.5, sh[1] - 1), (sh[0] + 3, sh[1] - 1), (hip[0] + 5, fy),
            (hip[0] - 5, fy), (hip[0] - 4, hip[1] - 2)], f.p_main)
    c.rect(hip[0] - 5, fy - 3, 10, 2, f.p_main_back)
    head = (sh[0] + 1, sh[1] - 3.5)
    c.poly([(head[0] - 2, head[1] - 4), (head[0] + 4, head[1] - 1), (head[0] + 3, head[1] + 3),
            (head[0] - 4, head[1] + 3)], f.p_sec)
    c.rect(head[0] + 0.5, head[1] - 0.5, 3, 2, f.p_face)
    c.mark(head[0] + 2, head[1], EYE)
    if ignite > 0:
        f.limb2((sh[0] - 2, sh[1] + 1), -2.2, -0.3, 3.5, 3, 2.4, 2, f.p_main)
        f.limb2((sh[0] + 2, sh[1] + 1), 2.3, 0.3, 3.5, 3, 2.4, 2, f.p_main)
        core = (sh[0], sh[1] + 4)
        c.ellipse(core, 1.5 + ignite * 2.5, 1.5 + ignite * 2.5, f.p_acc)
        c.mark(core[0], core[1], EYE)
    else:
        hand = f.limb2((sh[0] + 1.5, sh[1] + 1), 0.6, 0.6, 3.5, 3, 2.4, 2, f.p_main)
        f.weapon(hand, "staff", 0)
    return f.done()


def pilgrim_anims():
    A = {"walk": (5, [pilgrim(sway=s, bob=b) for s, b in ((0, 0), (0.6, -1), (0, 0), (-0.6, -1))])}
    A["ignite"] = (10, [pilgrim(ignite=0.4), pilgrim(ignite=1.0)])
    return A


# --- Atirador de Vidro: capuz, arco, aljava ------------------------------------------

def archer(pull=0.0, walk=0.0, bob=0, aim=False):
    f = Fig(32, 32)
    c, cx, fy = f.c, f.cx, f.fy
    hip = (cx, fy - 8 + bob)
    sh = (cx, fy - 16 + bob)
    s = math.sin(walk)
    for a, part in ((-0.2 - 0.4 * s, f.p_sec_back), (0.2 + 0.4 * s, f.p_sec)):
        end = f.limb2(hip, a, -0.3, 4, 4, 3, 2.6, part)
        c.rect(end[0] - 1, end[1] - 1, 3, 2, f.p_sec_back)
    c.rect(sh[0] - 6, sh[1] - 1, 3, 9, f.p_acc)            # aljava
    c.mark(sh[0] - 5, sh[1] - 2, METAL)
    c.mark(sh[0] - 4, sh[1] - 3, METAL)
    c.poly([(sh[0] - 3.5, sh[1] - 1), (sh[0] + 3, sh[1] - 1), (hip[0] + 4, hip[1] + 2),
            (hip[0] - 4, hip[1] + 2)], f.p_main)
    c.rect(hip[0] - 3.5, hip[1] - 2, 7, 1, f.p_acc)
    head = (sh[0] + 0.8, sh[1] - 4)
    c.poly([(head[0] - 1.5, head[1] - 4), (head[0] - 5, head[1] + 1), (head[0] - 1.5, head[1] + 3)], f.p_main)
    c.ellipse(head, 3.5, 3.8, f.p_main)
    c.rect(head[0] + 0.5, head[1] - 1, 3, 3, f.p_face)
    c.mark(head[0] + 2, head[1], EYE)
    if aim:
        f.limb2((sh[0] - 1, sh[1] + 1), 1.2 - pull * 0.5, 0.9 * pull, 3.5, 3, 2.2, 2, f.p_main_back)
        hand = f.limb2((sh[0] + 1, sh[1] + 1.5), 1.55, 0, 4, 3.5, 2.2, 2, f.p_main)
        f.weapon(hand, "bow", pull)
        if pull > 0.3:
            c.limb(add(hand, (1 - pull * 4, 0)), add(hand, (6, 0)), 1, f.p_metal)
    else:
        hand = f.limb2((sh[0] + 1, sh[1] + 1.5), 0.3, 0.2, 4, 3.5, 2.2, 2, f.p_main)
        f.weapon(hand, "bow", 0)
    return f.done()


def archer_anims():
    A = {"idle": (2, [archer(bob=b) for b in (0, 1)])}
    A["walk"] = (8, [archer(walk=i / 4 * math.tau, bob=-(i % 2)) for i in range(4)])
    A["aim"] = (1, [archer(aim=True, pull=0.4)])
    A["aim_lock"] = (1, [archer(aim=True, pull=1.0)])
    return A


# --- Assassino da Duna: corpo enfaixado, lenço no rosto, adagas -----------------------

def assassin(walk=0.0, pose="idle", bob=0):
    f = Fig(40, 32)
    c, cx, fy = f.c, f.cx, f.fy
    crouch = 3 if pose in ("crouch", "windup") else 0
    hip = (cx, fy - 8 + crouch + bob)
    sh = (cx + (2 if pose == "slash" else 0), fy - 16 + crouch * 1.3 + bob)
    s = math.sin(walk)
    legs = ((-0.3 - 0.5 * s, 0.4), (0.4 + 0.5 * s, 0.4)) if pose != "slash" else ((-0.9, 0.3), (0.9, 0.5))
    if crouch:
        legs = ((-0.8, 1.6), (0.9, 1.7))
    for (a, bend), part in zip(legs, (f.p_main_back, f.p_main)):
        end = f.limb2(hip, a, -bend, 4.2, 4.2, 3, 2.6, part)
        c.rect(end[0] - 1, end[1] - 1, 3, 2, f.p_sec_back)
    c.poly([(sh[0] - 3, sh[1] - 1), (sh[0] + 3, sh[1] - 1), (hip[0] + 3.5, hip[1] + 1),
            (hip[0] - 3.5, hip[1] + 1)], f.p_main)
    for i in range(3):
        c.rect(sh[0] - 3, sh[1] + 1 + i * 2.5, 6.5, 1, f.p_sec)      # faixas
    head = (sh[0] + 0.8, sh[1] - 4)
    c.ellipse(head, 3.4, 3.6, f.p_main)
    c.rect(head[0] - 3, head[1] + 0.5, 7, 3, f.p_sec)                # lenço
    c.rect(head[0] - 7, head[1] + 1, 4, 1.5, f.p_sec)                 # ponta do lenço
    c.mark(head[0] + 2, head[1] - 1, EYE)
    if pose == "windup":
        hand = f.limb2((sh[0] + 1, sh[1] + 1), -2.2, 0.5, 3.5, 3.5, 2.2, 2, f.p_main)
        f.weapon(hand, "dagger", -2.6)
    elif pose == "slash":
        hand = f.limb2((sh[0] + 1, sh[1] + 1), 1.6, -0.1, 4, 4, 2.2, 2, f.p_main)
        f.weapon(hand, "dagger", 1.9)
    else:
        hand = f.limb2((sh[0] + 1, sh[1] + 1), 0.5 - 0.4 * s, 0.6, 3.5, 3.5, 2.2, 2, f.p_main)
        f.weapon(hand, "dagger", 1.0)
    f.limb2((sh[0] - 1, sh[1] + 1), -0.4 + 0.4 * s, 0.5, 3.5, 3.5, 2.2, 2, f.p_main)
    return f.done()


def assassin_anims():
    A = {"idle": (3, [assassin(bob=b) for b in (0, 1)])}
    A["walk"] = (10, [assassin(walk=i / 4 * math.tau, bob=-(i % 2)) for i in range(4)])
    A["crouch"] = (1, [assassin(pose="crouch")])
    A["windup"] = (1, [assassin(pose="windup")])
    A["slash"] = (1, [assassin(pose="slash")])
    return A


# --- Inquisidor Profeta: túnica longa, mitra dourada, incensário ----------------------

def inquisitor(sway=0.0, swing=0.4, crouch=0, bob=0, air=False):
    f = Fig(48, 40)
    c, cx, fy = f.c, f.cx, f.fy
    hip = (cx, fy - 9 + crouch + bob)
    sh = (cx + sway * 0.4, fy - 21 + crouch * 1.4 + bob)
    hem = fy - (4 if air else 0)
    c.poly([(sh[0] - 4.5, sh[1] - 1), (sh[0] + 4, sh[1] - 1), (hip[0] + 7 + sway, hem),
            (hip[0] - 7 + sway, hem)], f.p_main)
    c.rect(sh[0] - 1.5, sh[1] + 1, 3, hem - sh[1] - 2, f.p_acc)       # faixa dourada
    c.rect(hip[0] - 7 + sway, hem - 2, 14, 2, f.p_main_back)
    c.poly([(sh[0] - 5, sh[1] - 1), (sh[0] + 5, sh[1] - 1), (sh[0] + 4, sh[1] + 4), (sh[0] - 5, sh[1] + 4)], f.p_sec)
    head = (sh[0] + 1, sh[1] - 4)
    c.ellipse(head, 3.6, 3.8, f.p_sec)
    c.rect(head[0] + 0.5, head[1] - 0.5, 3, 2, f.p_face)
    c.mark(head[0] + 2, head[1], EYE)
    c.poly([(head[0] - 3, head[1] - 3), (head[0] + 3, head[1] - 3), (head[0] + 1, head[1] - 10),
            (head[0] - 1, head[1] - 10)], f.p_acc)                       # mitra
    hand = f.limb2((sh[0] + 2, sh[1] + 2), swing, 0.3, 4.5, 4, 3, 2.6, f.p_main)
    f.weapon(hand, "censer", swing + 0.3)
    f.limb2((sh[0] - 2, sh[1] + 2), -0.3, 0.4, 4.5, 4, 3, 2.6, f.p_main)
    return f.done()


def inquisitor_anims():
    A = {"idle": (3, [inquisitor(bob=b) for b in (0, 1)])}
    A["walk"] = (6, [inquisitor(sway=s, bob=b) for s, b in ((0, 0), (1, -1), (0, 0), (-1, -1))])
    A["windup"] = (1, [inquisitor(swing=-2.4)])
    A["slash"] = (1, [inquisitor(swing=1.7, sway=1.5)])
    A["crouch"] = (1, [inquisitor(crouch=4, swing=-0.6)])
    A["leap"] = (1, [inquisitor(swing=-1.5, air=True)])
    return A


# --- O Imperador Cego: manto imperial, venda, coroa de três pontas, cetro -----------

def emperor(pose="idle", bob=0, sway=0.0):
    f = Fig(72, 64)
    c, cx, fy = f.c, f.cx, f.fy
    kneel = 10 if pose == "kneel" else 0
    hip = (cx, fy - 14 + kneel + bob)
    sh = (cx + sway, fy - 32 + kneel + bob)
    c.poly([(sh[0] - 8, sh[1] - 1), (sh[0] + 7, sh[1] - 1), (hip[0] + 12 + sway, fy),
            (hip[0] - 12 + sway, fy), (hip[0] - 11, hip[1])], f.p_main)
    c.poly([(sh[0] - 9, sh[1] - 2), (sh[0] + 8, sh[1] - 2), (sh[0] + 9, sh[1] + 6), (sh[0] - 10, sh[1] + 7)], f.p_sec)
    c.rect(sh[0] - 2, sh[1] + 4, 4, fy - sh[1] - 6, f.p_acc)
    c.rect(hip[0] - 12 + sway, fy - 3, 24, 3, f.p_main_back)
    for i in range(4):
        c.mark(sh[0] - 1 + (i % 2) * 2, sh[1] + 8 + i * 5, ACC_HI)
    head = (sh[0] + 1, sh[1] - 6)
    c.ellipse(head, 5.5, 6.0, f.p_face)
    c.rect(head[0] - 5, head[1] - 1.5, 11, 3, f.p_sec)                  # venda
    c.rect(head[0] - 7, head[1] - 0.5, 3, 6, f.p_sec)                   # ponta da venda
    c.rect(head[0] - 5, head[1] - 7, 11, 2, f.p_acc)                    # coroa
    for dx, tall in ((-5, 3), (-0.5, 5), (4, 3)):
        c.rect(head[0] + dx, head[1] - 7 - tall, 2, tall, f.p_acc)
    eye_on = pose in ("cast", "cast2", "summon")
    c.mark(head[0], head[1] - 4, EYE if eye_on else ACC_DK)
    c.mark(head[0] + 1, head[1] - 4, EYE if eye_on else ACC_DK)
    if pose in ("cast", "cast2"):
        lift = -2.6 if pose == "cast" else -2.9
        f.limb2((sh[0] - 6, sh[1] + 2), lift, -0.3, 7, 6, 4, 3.6, f.p_main)
        hand = f.limb2((sh[0] + 6, sh[1] + 2), -lift, 0.3, 7, 6, 4, 3.6, f.p_main)
        f.weapon(hand, "scepter", math.pi)
    elif pose == "windup":
        hand = f.limb2((sh[0] + 5, sh[1] + 2), -2.5, -0.2, 7, 6, 4, 3.6, f.p_main)
        f.weapon(hand, "scepter", -2.9)
    elif pose == "sweep":
        hand = f.limb2((sh[0] + 5, sh[1] + 2), 1.5, 0.1, 8, 7, 4, 3.6, f.p_main)
        f.weapon(hand, "scepter", 1.6)
    elif pose == "summon":
        f.limb2((sh[0] - 6, sh[1] + 2), -1.6, 0.2, 7, 6, 4, 3.6, f.p_main)
        hand = f.limb2((sh[0] + 6, sh[1] + 2), 1.6, -0.2, 7, 6, 4, 3.6, f.p_main)
        f.weapon(hand, "scepter", 2.6)
    else:
        hand = f.limb2((sh[0] + 6, sh[1] + 2), 0.35, 0.3, 7, 6, 4, 3.6, f.p_main)
        f.weapon(add(hand, (0, 0)), "scepter", math.pi)
    return f.done()


def emperor_anims():
    A = {"idle": (2, [emperor(bob=b) for b in (0, 1)])}
    A["walk"] = (5, [emperor(sway=s, bob=b) for s, b in ((0, 0), (1, -1), (0, 0), (-1, -1))])
    A["windup"] = (1, [emperor(pose="windup")])
    A["sweep"] = (1, [emperor(pose="sweep", sway=2)])
    A["cast"] = (6, [emperor(pose="cast"), emperor(pose="cast2")])
    A["kneel"] = (1, [emperor(pose="kneel")])
    A["summon"] = (1, [emperor(pose="summon")])
    return A


# --- Ferreiro Cativo: corpulento, avental de couro, martelo enorme -------------------

def smith(walk=0.0, hammer="idle", bob=0, lean=0.0):
    f = Fig(56, 52)
    c, cx, fy = f.c, f.cx, f.fy
    hip = (cx + lean * 0.3, fy - 9 + bob)
    sh = (cx + lean, fy - 21 + bob)
    s = math.sin(walk)
    for a, part in ((-0.25 - 0.4 * s, f.p_sec_back), (0.25 + 0.4 * s, f.p_sec)):
        end = f.limb2(hip, a, -0.3, 4.8, 4.6, 4.4, 4.0, part)
        c.rect(end[0] - 2, end[1] - 1, 5, 2, f.p_main_back)
    f.limb2((sh[0] - 5, sh[1] + 2), -0.3 + 0.3 * s, 0.4, 5, 4.5, 4, 3.6, f.p_main_back)
    c.ellipse((sh[0], sh[1] + 5), 8, 8, f.p_main)                    # tronco largo
    c.poly([(sh[0] - 5, sh[1] + 3), (sh[0] + 6, sh[1] + 3), (hip[0] + 6, hip[1] + 3), (hip[0] - 5, hip[1] + 3)], f.p_sec)
    c.rect(sh[0] - 6, hip[1] - 2, 13, 2, f.p_acc)
    head = (sh[0] + 3, sh[1] - 4)
    c.ellipse(head, 3.6, 3.8, f.p_face)
    c.rect(head[0] - 3, head[1] - 1, 7, 2, f.p_acc)                  # tira de ferro nos olhos
    c.mark(head[0] + 2, head[1], EYE)
    if hammer == "windup":
        hand = f.limb2((sh[0] + 4, sh[1] + 2), -2.8, 0.1, 5, 5, 4, 3.6, f.p_main)
        f.weapon(hand, "hammer", -3.0)
    elif hammer == "slam":
        hand = f.limb2((sh[0] + 4, sh[1] + 2), 1.2, 0.3, 5.5, 5.5, 4, 3.6, f.p_main)
        f.weapon(hand, "hammer", 1.8)
    else:
        hand = f.limb2((sh[0] + 4, sh[1] + 2), 0.5 - 0.2 * s, -1.6, 5, 4, 4, 3.6, f.p_main)
        f.weapon(hand, "hammer", -2.3)
    return f.done()


def smith_anims():
    A = {"idle": (2, [smith(bob=b) for b in (0, 1)])}
    A["walk"] = (6, [smith(walk=i / 4 * math.tau, bob=-(i % 2)) for i in range(4)])
    A["windup"] = (1, [smith(hammer="windup", lean=-2)])
    A["slam"] = (1, [smith(hammer="slam", lean=3, bob=1)])
    A["stun"] = (1, [smith(lean=-2.5, bob=1)])
    return A


# --- Escória Viva: bolha de metal derretido com crosta -------------------------------

def slag(sx=1.0, sy=1.0, lift=0):
    f = Fig(32, 24)
    c, cx, fy = f.c, f.cx, f.fy
    rx, ry = 7 * sx, 6 * sy
    center = (cx, fy - ry - lift)
    c.ellipse(center, rx, ry, f.p_main)
    for dx, dy, r in ((-3, -2, 2.2), (2, -3, 1.8), (3, 1, 1.6), (-2, 2, 1.4)):
        c.ellipse((center[0] + dx * sx, center[1] + dy * sy), r, r, f.p_acc)
    c.mark(center[0] + 2, center[1] - 1, EYE)
    c.mark(center[0] + 4, center[1] - 1, EYE)
    if lift == 0:
        c.rect(center[0] - rx, fy - 1, rx * 2, 1, f.p_acc)            # poça embaixo
    return f.done()


def slag_anims():
    A = {"idle": (4, [slag(1.0, 1.0), slag(1.08, 0.92)])}
    A["hop"] = (1, [slag(0.82, 1.2, lift=3)])
    A["land"] = (1, [slag(1.3, 0.7)])
    return A


# --- Lobo Pálido: quadrúpede magro, investe mordendo ----------------------------------

def wolf(run=0.0, pose="idle", bob=0):
    f = Fig(48, 32)
    c, cx, fy = f.c, f.cx, f.fy
    crouch = 3 if pose == "crouch" else 0
    stretch = 4 if pose == "lunge" else 0
    hip = (cx - 7 - stretch * 0.5, fy - 10 + crouch + bob)
    sh = (cx + 6 + stretch * 0.5, fy - 11 + crouch + bob)
    s = math.sin(run)
    legs_back = ((-0.5 * s, 0.6), (0.5 * s, 0.6)) if pose != "lunge" else ((-1.2, 0.2), (-0.9, 0.3))
    legs_front = ((0.5 * s, -0.5), (-0.5 * s, -0.5)) if pose != "lunge" else ((1.3, -0.1), (1.0, -0.2))
    for (a, bend), part in zip(legs_back, (f.p_main_back, f.p_main)):
        f.limb2(hip, a, -bend, 4.5, 4.5, 3.2, 2.2, part)
    for (a, bend), part in zip(legs_front, (f.p_main_back, f.p_main)):
        f.limb2(sh, a, -bend, 4.5, 4.5, 3.0, 2.2, part)
    c.limb(hip, sh, 7.5, f.p_main)                                    # corpo
    c.limb((hip[0] - 3, hip[1] - 1), (hip[0] - 11, hip[1] - 4 - (2 if pose == "idle" else 0)), 2.6, f.p_sec)
    head = (sh[0] + 5, sh[1] - 4 + (2 if pose == "crouch" else 0))
    c.ellipse(head, 4, 3.4, f.p_main)
    c.poly([(head[0] + 2, head[1] - 1), (head[0] + 8, head[1] + 0.5), (head[0] + 2, head[1] + 2.5)], f.p_main)
    if pose == "lunge":
        c.poly([(head[0] + 3, head[1] + 2), (head[0] + 8, head[1] + 4), (head[0] + 3, head[1] + 4)], f.p_main)
        c.mark(head[0] + 5, head[1] + 2, METAL)
    c.poly([(head[0] - 2, head[1] - 3), (head[0] - 1, head[1] - 7), (head[0] + 1, head[1] - 3)], f.p_main)
    c.mark(head[0] + 1, head[1] - 1, EYE)
    c.rect(sh[0] - 3, sh[1] - 4, 6, 3, f.p_sec)                       # juba de geada
    return f.done()


def wolf_anims():
    A = {"idle": (2, [wolf(bob=b) for b in (0, 1)])}
    A["run"] = (12, [wolf(run=i / 4 * math.tau, pose="run", bob=-(i % 2)) for i in range(4)])
    A["crouch"] = (1, [wolf(pose="crouch")])
    A["lunge"] = (1, [wolf(pose="lunge")])
    A["stun"] = (1, [wolf(pose="crouch", bob=1)])
    return A


# paletas: roupa, segunda peça, olho, detalhe, rosto, madeira, metal
ENEMY_PALETTES = {
    "penitent": ("#6b5a3a", "#8a7752", "#ff5a4a", "#7a3b2b", "#1a1210", "#5b3f2c", "#c9c2b0"),
    "guard": ("#8a2e2e", "#4a2a24", "#ff5a4a", "#c8964a", "#120c0c", "#6b4a32", "#d9e2ec"),
    "pilgrim": ("#8b8577", "#6e6a60", "#ff9a3c", "#ff9a3c", "#16120f", "#5b3f2c", "#c9c2b0"),
    "archer": ("#5e4a72", "#3d3049", "#ff5a4a", "#7a5a3a", "#120e16", "#8a6242", "#bfe6ea"),
    "assassin": ("#3a3046", "#c9b38a", "#ff5a4a", "#8a6242", "#0e0b12", "#5b3f2c", "#d9e2ec"),
    "inquisitor": ("#e2d6b8", "#9d3b3b", "#8ff7e8", "#d9a93f", "#1a1410", "#5b3f2c", "#e8e2d0"),
    "emperor": ("#3b2550", "#efe6d2", "#8ff7e8", "#e0b04a", "#2a2028", "#5b3f2c", "#8ff7e8"),
    "smith": ("#8a5a48", "#4a3428", "#ff8a3a", "#5a5a62", "#1a1210", "#3a2a22", "#c9c2b0"),
    "slag": ("#3a2a2a", "#2a1e1e", "#ffe08a", "#ff8a3a", "#120c0c", "#3a2a22", "#ffd84a"),
    "wolf": ("#c8d4e0", "#e8f2fa", "#9fe8ff", "#8aa0b8", "#1a2230", "#5b3f2c", "#ffffff"),
    "archer_ice": ("#5a7aa0", "#2a3a5a", "#9fe8ff", "#8aa0b8", "#0c1220", "#6a7a8a", "#dff6ff"),
    "penitent_ice": ("#6a7a8a", "#9aa8b8", "#9fe8ff", "#3a4a6a", "#10161e", "#4a3a30", "#dff6ff"),
    "guard_forge": ("#3a3a42", "#2a2a30", "#ff8a3a", "#b86a3a", "#0c0c10", "#4a2a1e", "#e8c09a"),
}


def enemy_palette(main, sec, eye, acc, face, wood, metal):
    m, s, e, a, f, w, mt = (hexc(x) for x in (main, sec, eye, acc, face, wood, metal))
    pal = [(0, 0, 0)] * 16
    pal[1] = hexc("#0b0910")
    pal[MAIN_HI], pal[MAIN], pal[MAIN_DK] = shade(m, 0.22), m, shade(m, -0.38)
    pal[SEC_HI], pal[SEC], pal[SEC_DK] = shade(s, 0.22), s, shade(s, -0.38)
    pal[EYE] = e
    pal[ACC_HI], pal[ACC], pal[ACC_DK] = shade(a, 0.3), a, shade(a, -0.35)
    pal[FACE] = f
    pal[WOOD_DK], pal[WOOD] = shade(w, -0.35), w
    pal[METAL] = mt
    return pal


def build(name, anims, w, h, pal):
    rows, meta = [], {}
    for r, (anim, (fps, frames)) in enumerate(anims.items()):
        rows.append(frames)
        meta[anim] = {"row": r, "frames": len(frames), "fps": fps, "hands": [[[0, -12]]] * len(frames)}
    cols = max(len(r) for r in rows)
    from PIL import Image
    img = Image.new("RGBA", (cols * w, len(rows) * h), (0, 0, 0, 0))
    px = img.load()
    for r, row in enumerate(rows):
        for ci, cv in enumerate(row):
            for y in range(h):
                for x in range(w):
                    i = cv.idx[y][x]
                    if i:
                        px[ci * w + x, r * h + y] = (i * 16 + 8, 0, 0, 255)
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    img.save(os.path.join(OUT, name + ".png"))
    with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"size": w, "w": w, "h": h, "anims": meta}, f, indent=1)
    preview(img, [pal], scale=4).save(os.path.join(PREV, name + ".png"))


SHEETS = {
    "penitent": (penitent_anims, 40, 36),
    "guard": (guard_anims, 48, 36),
    "pilgrim": (pilgrim_anims, 32, 32),
    "archer": (archer_anims, 32, 32),
    "assassin": (assassin_anims, 40, 32),
    "inquisitor": (inquisitor_anims, 48, 40),
    "emperor": (emperor_anims, 72, 64),
    "smith": (smith_anims, 56, 52),
    "slag": (slag_anims, 32, 24),
    "wolf": (wolf_anims, 48, 32),
}

if __name__ == "__main__":
    for name, (fn, w, h) in SHEETS.items():
        build(name, fn(), w, h, enemy_palette(*ENEMY_PALETTES[name]))
    print("ok", len(SHEETS))
