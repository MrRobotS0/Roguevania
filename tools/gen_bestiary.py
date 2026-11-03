"""Inimigos e chefes dos domínios novos (e os chefes dos Salões e da Forja).

    python tools/gen_bestiary.py

Usa o mesmo corpo (Fig) e as mesmas regras de gen_enemies.py, com um
humanoide de escala ajustável (k) para os chefes sairem grandes sem perder a
densidade de pixel. As paletas ficam em gen_enemies.ENEMY_PALETTES (e no jogo,
em scripts/enemies/enemy_looks.gd).
"""
import math

import gen_enemies as en
from gen_enemies import Fig, add, v, EYE, METAL, ACC_DK, SEC_HI


def humanoid(w, h, k=1.0, pose="idle", t=0.0, bob=0, robe=True, head="hood", weapon=None,
             cape=False, book=False, orrery=False, float_=False):
    """pose: idle | walk | windup | attack | cast | rest"""
    f = Fig(w, h)
    c, cx, fy = f.c, f.cx, f.fy
    lift = 6 * k if float_ else 0
    crouch = 4 * k if pose == "rest" else 0
    hip = (cx, fy - 9 * k - lift + crouch + bob)
    sh = (cx + (1.5 * k if pose == "attack" else -1 * k if pose == "windup" else 0), fy - 21 * k - lift + crouch * 1.3 + bob)
    s = math.sin(t)
    if cape:
        c.poly([(sh[0] - 4 * k, sh[1]), (sh[0] + 1 * k, sh[1]), (hip[0] - 2 * k, fy - lift),
                (hip[0] - 9 * k - 2 * abs(s) * k, fy - lift - 2 * k)], f.p_sec_back)
    if robe:
        c.poly([(sh[0] - 4.5 * k, sh[1] - k), (sh[0] + 4 * k, sh[1] - k), (hip[0] + 7 * k, fy - lift),
                (hip[0] - 7 * k, fy - lift)], f.p_main)
        c.rect(hip[0] - 7 * k, fy - lift - 2 * k, 14 * k, 2 * k, f.p_main_back)
        if float_:
            for i in range(4):
                c.mark(hip[0] - 5 * k + i * 3 * k, fy - lift + 2 + (i % 2), SEC_HI)
    else:
        for a, part in ((-0.3 - 0.5 * s, f.p_main_back), (0.3 + 0.5 * s, f.p_main)):
            end = f.limb2(hip, a, -0.35, 4.6 * k, 4.6 * k, 3.2 * k, 2.8 * k, part)
            c.rect(end[0] - 1.5 * k, end[1] - k, 3.5 * k, 2 * k, f.p_sec_back)
        c.poly([(sh[0] - 4 * k, sh[1] - k), (sh[0] + 4 * k, sh[1] - k), (hip[0] + 4.5 * k, hip[1] + 2 * k),
                (hip[0] - 4.5 * k, hip[1] + 2 * k)], f.p_main)
    c.rect(sh[0] - 1.2 * k, sh[1] + k, 2.4 * k, (hip[1] - sh[1]), f.p_acc)
    head_c = (sh[0] + 1 * k, sh[1] - 4.2 * k)
    if head == "hood":
        c.poly([(head_c[0] - 1.5 * k, head_c[1] - 3.4 * k), (head_c[0] - 6 * k, head_c[1] + k),
                (head_c[0] - 2 * k, head_c[1] + 3 * k)], f.p_sec)
        c.ellipse(head_c, 3.8 * k, 4 * k, f.p_sec)
        c.rect(head_c[0] + 0.5 * k, head_c[1] - k, 3 * k, 3 * k, f.p_face)
        c.mark(head_c[0] + 2 * k, head_c[1], EYE)
    elif head == "mask":
        c.ellipse(head_c, 3.6 * k, 4 * k, f.p_sec_back)
        c.ellipse((head_c[0] + 1 * k, head_c[1]), 3 * k, 3.6 * k, f.p_acc)
        c.rect(head_c[0] + 0.5 * k, head_c[1] - 1 * k, 2.5 * k, 1, f.p_face)
        c.rect(head_c[0] - 0.5 * k, head_c[1] + 1.5 * k, 3 * k, 1, f.p_face)
    elif head == "crown":
        c.ellipse(head_c, 3.8 * k, 4 * k, f.p_face)
        c.rect(head_c[0] - 4 * k, head_c[1] - 5 * k, 8 * k, 1.5 * k, f.p_acc)
        for dx in (-3.5, -0.5, 2.5):
            c.rect(head_c[0] + dx * k, head_c[1] - 7.5 * k, 1.2 * k, 2.5 * k, f.p_acc)
        c.mark(head_c[0] + 2 * k, head_c[1], EYE)
    elif head == "helm":
        c.rect(head_c[0] - 3.5 * k, head_c[1] - 4 * k, 7.5 * k, 7.5 * k, f.p_acc)
        c.rect(head_c[0] + 0.5 * k, head_c[1] - 0.5 * k, 3.5 * k, 1.2 * k, f.p_face)
        c.mark(head_c[0] + 2 * k, head_c[1], EYE)
    elif head == "lens":
        c.rect(head_c[0] - 3 * k, head_c[1] - 3.5 * k, 6.5 * k, 6.5 * k, f.p_acc)
        c.ellipse((head_c[0] + 1.5 * k, head_c[1]), 2 * k, 2 * k, f.p_face)
        c.mark(head_c[0] + 1.5 * k, head_c[1], EYE)
    # braços e o que vai na mão
    poses = {"idle": (0.3, 0.4), "walk": (0.3 - 0.3 * s, 0.4), "windup": (-2.4, 0.2), "attack": (1.5, 0.05),
             "cast": (-2.7, -0.3), "rest": (0.2, 0.6)}
    a, bend = poses.get(pose, poses["idle"])
    f.limb2((sh[0] - 2 * k, sh[1] + 2 * k), -0.3 if pose != "cast" else 2.6, 0.4, 4.5 * k, 4 * k, 2.8 * k, 2.4 * k, f.p_main_back)
    hand = f.limb2((sh[0] + 2 * k, sh[1] + 2 * k), a, bend, 4.5 * k, 4 * k, 2.8 * k, 2.4 * k, f.p_main)
    if weapon == "sword":
        ang = {"windup": -2.8, "attack": 1.6, "cast": -3.0}.get(pose, 0.5)
        tip = add(hand, (math.sin(ang) * 13 * k, math.cos(ang) * 13 * k))
        c.limb(hand, tip, 1.3 * k, f.p_metal)
        c.rect(hand[0] - 1.5 * k, hand[1] - 0.6 * k, 3 * k, 1.2 * k, f.p_acc)
    elif weapon == "staff":
        c.limb(add(hand, (0, -9 * k)), add(hand, (0, 9 * k)), 1.4 * k, f.p_wood)
        c.ellipse(add(hand, (0, -10 * k)), 2 * k, 2 * k, f.p_metal)
        c.mark(hand[0], hand[1] - 10 * k, EYE)
    elif weapon == "bell":
        c.limb(hand, add(hand, (0, 4 * k)), 1.0, f.p_wood)
        c.poly([add(hand, (-3 * k, 9 * k)), add(hand, (-1.5 * k, 4 * k)), add(hand, (1.5 * k, 4 * k)), add(hand, (3 * k, 9 * k))], f.p_acc)
    elif weapon == "hammer":
        ang = {"windup": -3.0, "attack": 1.8}.get(pose, -2.3)
        d = (math.sin(ang), math.cos(ang))
        tip = add(hand, (d[0] * 10 * k, d[1] * 10 * k))
        c.limb(add(hand, (-d[0] * 2 * k, -d[1] * 2 * k)), tip, 2.0 * k, f.p_wood)
        side = (-d[1] * 5 * k, d[0] * 5 * k)
        fw = (d[0] * 4.5 * k, d[1] * 4.5 * k)
        a0, a1 = add(tip, side), add(tip, (-side[0], -side[1]))
        c.poly([a0, a1, add(a1, fw), add(a0, fw)], f.p_metal)
    if book:
        c.rect(hand[0] - 2 * k, hand[1] - 3 * k, 5 * k, 4 * k, f.p_acc)
        c.rect(hand[0] - 1.5 * k, hand[1] - 2.5 * k, 4 * k, 3 * k, f.p_sec)
        c.mark(hand[0], hand[1] - 1.5 * k, EYE)
    if orrery:
        center = (sh[0] + 9 * k, sh[1] - 8 * k)
        for i in range(3):
            a2 = t * 1.5 + i * math.tau / 3
            c.ellipse((center[0] + math.cos(a2) * 6 * k, center[1] + math.sin(a2) * 3 * k), 1.6 * k, 1.6 * k, f.p_metal)
        c.ellipse(center, 2.2 * k, 2.2 * k, f.p_acc)
        c.mark(center[0], center[1], EYE)
    return f.done()


def human_anims(w, h, k=1.0, frames_walk=4, **opts):
    A = {"idle": (2, [humanoid(w, h, k, "idle", bob=b, **opts) for b in (0, 1)])}
    A["walk"] = (8, [humanoid(w, h, k, "walk", t=i / frames_walk * math.tau, bob=-(i % 2), **opts) for i in range(frames_walk)])
    A["windup"] = (1, [humanoid(w, h, k, "windup", **opts)])
    A["attack"] = (1, [humanoid(w, h, k, "attack", **opts)])
    A["cast"] = (6, [humanoid(w, h, k, "cast", t=i * 2.0, **opts) for i in range(2)])
    A["rest"] = (1, [humanoid(w, h, k, "rest", **opts)])
    return A


# --- criaturas que não são gente ------------------------------------------------------

def gargoyle(flap=0.0, pose="idle"):
    f = Fig(40, 32)
    c, cx, fy = f.c, f.cx, f.fy - 8
    body = (cx, fy - 6)
    wing = math.sin(flap) * 5
    for side in (-1, 1):
        c.poly([(body[0] + side * 3, body[1] - 2), (body[0] + side * 15, body[1] - 6 - wing),
                (body[0] + side * 12, body[1] + 3 - wing * 0.4), (body[0] + side * 4, body[1] + 3)], f.p_sec)
    c.ellipse(body, 5, 6, f.p_main)
    c.ellipse((body[0] + 3, body[1] - 6), 3.5, 3.2, f.p_main)
    c.poly([(body[0] + 1, body[1] - 9), (body[0] + 2, body[1] - 13), (body[0] + 3, body[1] - 9)], f.p_main)
    c.mark(body[0] + 5, body[1] - 6, EYE)
    if pose == "dive":
        c.limb((body[0], body[1] + 5), (body[0] + 6, body[1] + 11), 2, f.p_main)
    else:
        c.limb((body[0] - 1, body[1] + 5), (body[0] - 1, body[1] + 9), 2, f.p_main)
    return f.done()


def gargoyle_anims():
    A = {"fly": (10, [gargoyle(i / 4 * math.tau) for i in range(4)])}
    A["windup"] = (1, [gargoyle(1.5, "idle")])
    A["dive"] = (1, [gargoyle(-1.0, "dive")])
    return A


def thorn_plant(open_=0.0):
    f = Fig(32, 32)
    c, cx, fy = f.c, f.cx, f.fy
    c.poly([(cx - 6, fy), (cx - 3, fy - 8), (cx + 3, fy - 8), (cx + 6, fy)], f.p_sec)
    for side in (-1, 1):
        c.poly([(cx, fy - 6), (cx + side * 9, fy - 10), (cx + side * 4, fy - 3)], f.p_sec)
    bud = (cx, fy - 13 - open_ * 2)
    c.ellipse(bud, 5 + open_, 5, f.p_main)
    if open_ > 0.3:
        c.ellipse(bud, 2.5, 2.5, f.p_face)
        c.mark(bud[0], bud[1], EYE)
    for i in range(6):
        a = i * math.tau / 6
        c.mark(bud[0] + math.cos(a) * (6 + open_), bud[1] + math.sin(a) * 6, METAL)
    return f.done()


def thorn_anims():
    return {"idle": (2, [thorn_plant(0), thorn_plant(0.2)]), "windup": (1, [thorn_plant(1.0)]),
            "attack": (1, [thorn_plant(1.4)])}


def moss_beast(run=0.0, pose="idle", k=1.0, w=48, h=36):
    f = Fig(w, h)
    c, cx, fy = f.c, f.cx, f.fy
    s = math.sin(run)
    crouch = 3 * k if pose == "windup" else 0
    hip = (cx - 7 * k, fy - 10 * k + crouch)
    sh = (cx + 6 * k, fy - 11 * k + crouch)
    for base, sign in ((hip, 1), (sh, -1)):
        for ph, part in ((s, f.p_main_back), (-s, f.p_main)):
            a = 0.5 * ph * sign if pose != "charge" else (-1.0 if base == hip else 1.1)
            f.limb2(base, a, 0.3, 4.5 * k, 4.5 * k, 3.6 * k, 3.0 * k, part)
    c.limb(hip, sh, 10 * k, f.p_main)
    for i in range(5):
        c.ellipse((hip[0] + i * 3.2 * k, hip[1] - 4 * k), 2.6 * k, 2.2 * k, f.p_sec)
    head = (sh[0] + 6 * k, sh[1] - 1 * k + (2 * k if pose == "windup" else 0))
    c.ellipse(head, 5 * k, 4 * k, f.p_main)
    c.poly([(head[0] + 2 * k, head[1] + 2 * k), (head[0] + 6 * k, head[1] + 5 * k), (head[0] + 1 * k, head[1] + 4 * k)], f.p_metal)
    c.mark(head[0] + 2 * k, head[1] - 1 * k, EYE)
    return f.done()


def moss_anims():
    A = {"idle": (2, [moss_beast(0, "idle"), moss_beast(0.4, "idle")])}
    A["walk"] = (8, [moss_beast(i / 4 * math.tau, "walk") for i in range(4)])
    A["windup"] = (1, [moss_beast(0, "windup")])
    A["charge"] = (1, [moss_beast(0, "charge")])
    A["rest"] = (1, [moss_beast(0, "windup")])
    return A


def star(pulse=0.0, w=32, h=32, k=1.0):
    f = Fig(w, h)
    c, cx, fy = f.c, f.cx, f.fy - 8 * k
    r = (4 + pulse) * k
    for i in range(4):
        a = i * math.tau / 4 + pulse * 0.3
        tip = (cx + math.cos(a) * (r + 5 * k), fy + math.sin(a) * (r + 5 * k))
        c.poly([(cx + math.cos(a + 0.5) * r, fy + math.sin(a + 0.5) * r), tip,
                (cx + math.cos(a - 0.5) * r, fy + math.sin(a - 0.5) * r)], f.p_acc)
    c.ellipse((cx, fy), r, r, f.p_main)
    c.mark(cx, fy, EYE)
    return f.done()


def star_anims():
    return {"idle": (6, [star(0.0), star(0.6), star(1.0), star(0.6)]), "windup": (12, [star(1.4), star(0.4)])}


def mother_root(pose="idle", t=0.0):
    """A Mãe-Raiz: bulbo enorme preso ao chão, com um olho e raízes."""
    f = Fig(96, 80)
    c, cx, fy = f.c, f.cx, f.fy
    for i in range(7):
        a = -0.9 + i * 0.3
        c.limb((cx, fy - 10), (cx + math.sin(a) * 40, fy), 4, f.p_sec_back)
    c.ellipse((cx, fy - 28), 26, 26, f.p_main)
    for i in range(10):
        a = i * math.tau / 10 + t * 0.2
        c.ellipse((cx + math.cos(a) * 22, fy - 28 + math.sin(a) * 22), 5, 5, f.p_sec)
    eye_open = {"idle": 4.0, "cast": 7.0, "windup": 6.0, "attack": 7.5, "rest": 1.0}.get(pose, 4.0)
    c.ellipse((cx, fy - 30), 9, eye_open, f.p_face)
    if eye_open > 2:
        c.ellipse((cx, fy - 30), 3, min(3, eye_open), f.p_acc)
        c.mark(cx, fy - 30, EYE)
    for side in (-1, 1):
        lift = {"cast": 18, "windup": 12, "attack": -4}.get(pose, 4) + math.sin(t + side) * 2
        c.limb((cx + side * 20, fy - 40), (cx + side * 38, fy - 50 - lift), 4, f.p_sec)
        c.ellipse((cx + side * 38, fy - 50 - lift), 4, 4, f.p_acc)
    return f.done()


def mother_anims():
    return {"idle": (2, [mother_root("idle", t) for t in (0, 1)]), "walk": (2, [mother_root("idle", t) for t in (0, 1)]),
            "windup": (1, [mother_root("windup")]), "attack": (1, [mother_root("attack")]),
            "cast": (6, [mother_root("cast", t) for t in (0, 2)]), "rest": (1, [mother_root("rest")])}


def wolf_king_anims():
    A = {"idle": (2, [wolf_k(0, "idle", b) for b in (0, 1)])}
    A["walk"] = (10, [wolf_k(i / 4 * math.tau, "run", -(i % 2)) for i in range(4)])
    A["windup"] = (1, [wolf_k(0, "crouch")])
    A["attack"] = (1, [wolf_k(0, "lunge")])
    A["cast"] = (6, [wolf_k(0, "howl"), wolf_k(0.5, "howl")])
    A["rest"] = (1, [wolf_k(0, "crouch", 2)])
    return A


def wolf_k(run, pose, bob=0, k=2.0):
    f = Fig(96, 64)
    c, cx, fy = f.c, f.cx, f.fy
    crouch = 3 * k if pose == "crouch" else 0
    stretch = 4 * k if pose == "lunge" else 0
    hip = (cx - 7 * k - stretch * 0.5, fy - 10 * k + crouch + bob)
    sh = (cx + 6 * k + stretch * 0.5, fy - 11 * k + crouch + bob)
    s = math.sin(run)
    for base, sgn in ((hip, 1), (sh, -1)):
        for ph, part in ((s, f.p_main_back), (-s, f.p_main)):
            a = 0.5 * ph * sgn if pose != "lunge" else (-1.2 if base == hip else 1.2)
            f.limb2(base, a, -0.5 * sgn, 4.5 * k, 4.5 * k, 3.2 * k, 2.2 * k, part)
    c.limb(hip, sh, 7.5 * k, f.p_main)
    c.limb((hip[0] - 3 * k, hip[1] - k), (hip[0] - 11 * k, hip[1] - 5 * k), 2.6 * k, f.p_sec)
    head_lift = -5 * k if pose == "howl" else 0
    head = (sh[0] + 5 * k, sh[1] - 4 * k + head_lift + (2 * k if pose == "crouch" else 0))
    c.ellipse(head, 4 * k, 3.4 * k, f.p_main)
    c.poly([(head[0] + 2 * k, head[1] - k), (head[0] + 8 * k, head[1] + 0.5 * k + head_lift * 0.3), (head[0] + 2 * k, head[1] + 2.5 * k)], f.p_main)
    if pose in ("lunge", "howl"):
        c.poly([(head[0] + 3 * k, head[1] + 2 * k), (head[0] + 8 * k, head[1] + 4 * k), (head[0] + 3 * k, head[1] + 4 * k)], f.p_main)
    c.poly([(head[0] - 2 * k, head[1] - 3 * k), (head[0] - 1 * k, head[1] - 7 * k), (head[0] + 1 * k, head[1] - 3 * k)], f.p_main)
    c.ellipse((head[0] + 1 * k, head[1] - 1 * k), 1.2 * k, 1.0 * k, f.p_acc)
    c.mark(head[0] + 1 * k, head[1] - 1 * k, EYE)
    c.rect(sh[0] - 4 * k, sh[1] - 5 * k, 8 * k, 4 * k, f.p_sec)
    for i in range(4):
        c.poly([(sh[0] - 3 * k + i * 2 * k, sh[1] - 5 * k), (sh[0] - 2 * k + i * 2 * k, sh[1] - 9 * k), (sh[0] - 1 * k + i * 2 * k, sh[1] - 5 * k)], f.p_metal)
    return f.done()


SHEETS = {
    # inimigos
    "scribe": (lambda: human_anims(40, 40, 1.0, head="hood", book=True), 40, 40),
    "gargoyle": (gargoyle_anims, 40, 32),
    "thorn": (thorn_anims, 32, 32),
    "moss_beast": (moss_anims, 48, 36),
    "masked": (lambda: human_anims(40, 40, 1.0, robe=False, head="mask", weapon="sword", cape=True), 40, 40),
    "herald": (lambda: human_anims(40, 40, 1.0, head="hood", weapon="bell"), 40, 40),
    "automaton": (lambda: human_anims(40, 40, 1.05, robe=False, head="lens"), 40, 40),
    "star": (star_anims, 32, 32),
    # chefes
    "wolf_king": (wolf_king_anims, 96, 64),
    "colossus": (lambda: human_anims(96, 80, 2.2, robe=False, head="helm", weapon="hammer"), 96, 80),
    "architect": (lambda: human_anims(88, 88, 2.0, head="crown", book=True, float_=True), 88, 88),
    "mother_root": (mother_anims, 96, 80),
    "faceless_king": (lambda: human_anims(72, 72, 1.6, robe=False, head="mask", weapon="sword", cape=True), 72, 72),
    "astronomer": (lambda: human_anims(80, 80, 1.8, head="hood", weapon="staff", orrery=True), 80, 80),
}

PALETTES = {
    "scribe": ("#c8b48a", "#3a3a6a", "#ffd84a", "#d9a93f", "#14101a", "#5b3f2c", "#e8e2d0"),
    "gargoyle": ("#7a7468", "#5a544a", "#ff5a4a", "#9a9488", "#1a1612", "#4a3a30", "#c9c2b0"),
    "thorn": ("#7a3a5a", "#3a6a3a", "#ffd84a", "#c8e07a", "#140c10", "#4a3a20", "#e8f0c0"),
    "moss_beast": ("#4a5a3a", "#6a8a4a", "#ffd84a", "#8aa05a", "#141810", "#4a3a20", "#d9e2c0"),
    "masked": ("#2a2232", "#14101a", "#ffd84a", "#e8d070", "#100c14", "#4a3a30", "#d9e2ec"),
    "herald": ("#d8d0a0", "#4a3a5a", "#ffd84a", "#c8a040", "#14101a", "#4a3a30", "#e8e2d0"),
    "automaton": ("#8a6a3a", "#4a3a2a", "#9fe8ff", "#c8a050", "#0c1018", "#3a2a1a", "#dff6ff"),
    "star": ("#e8f0ff", "#9ab0d8", "#ffffff", "#ffd84a", "#1a2030", "#3a2a1a", "#ffffff"),
    "wolf_king": ("#dfe8f0", "#f4fbff", "#9fe8ff", "#6a8ab0", "#1a2230", "#5b3f2c", "#bfe6ea"),
    "colossus": ("#7a4a38", "#4a2a20", "#ff8a3a", "#4a4a52", "#140c0c", "#3a2a22", "#ffb050"),
    "architect": ("#d8c890", "#3a3a7a", "#ffd84a", "#e0b04a", "#1a1420", "#5b3f2c", "#e8e2d0"),
    "mother_root": ("#5a3a4a", "#4a7a3a", "#ffd84a", "#c84a6a", "#140810", "#3a2a18", "#e8f0c0"),
    "faceless_king": ("#3a2a1a", "#d8c050", "#ffd84a", "#f0e8c0", "#0c0a08", "#4a3a20", "#e8e2d0"),
    "astronomer": ("#2a3a6a", "#14203a", "#9fe8ff", "#d8b060", "#0a0e18", "#5b3f2c", "#ffffff"),
}

if __name__ == "__main__":
    import sys
    only = sys.argv[1:]
    for name, (fn, w, h) in SHEETS.items():
        if only and name not in only:
            continue
        en.build(name, fn(), w, h, en.enemy_palette(*PALETTES[name]))
    print("ok", len(SHEETS))
