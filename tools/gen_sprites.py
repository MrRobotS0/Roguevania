"""Gera as folhas de sprite do jogo em assets/sprites/ (índices de paleta)
e prévias coloridas em tools/previews/ para conferir sem abrir o jogo.

    python tools/gen_sprites.py

Quadros de 32x32, pés em (16, 30), virado para a direita. Junto de cada
folha sai um .json com as animações e onde fica a mão em cada quadro
(o jogo desenha a arma ali).
"""
import json
import math
import os

from pixelrig import Canvas, OUTLINE, sheet, preview, hexc, shade

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "previews")
SIZE = 32

# índices da paleta do herói (o jogo monta a paleta a partir da aparência)
CLOAK_HI, CLOAK, CLOAK_DK = 2, 3, 4
HOOD_HI, HOOD, HOOD_DK = 5, 6, 7
EYE = 8
SCARF_HI, SCARF, SCARF_DK = 9, 10, 11
FACE = 12
LEG_DK, LEG = 13, 14
TRIM = 15


def v(a, length):
    return (math.sin(a) * length, math.cos(a) * length)


def add(p, q):
    return (p[0] + q[0], p[1] + q[1])


def hero_frame(bob=0.0, lean=0.0, crouch=0.0, legs=((-0.1, 0.05), (0.1, 0.05)),
               arms=((-0.2, 0.3), (0.15, 0.3)), flare=0.0, look=0.0, hood_back=0.0):
    c = Canvas(SIZE, SIZE)
    cape = c.new_part(CLOAK_DK, CLOAK, OUTLINE)
    leg_back = c.new_part(LEG_DK, LEG_DK, OUTLINE)
    leg_front = c.new_part(LEG, LEG, LEG_DK)
    boot = c.new_part(HOOD_DK, HOOD, OUTLINE)
    sleeve_back = c.new_part(HOOD_DK, HOOD_DK, OUTLINE)
    tunic = c.new_part(LEG, LEG, LEG_DK)
    mantle = c.new_part(CLOAK, CLOAK_HI, CLOAK_DK)
    sleeve = c.new_part(HOOD, HOOD_HI, HOOD_DK)
    hood = c.new_part(HOOD, HOOD_HI, HOOD_DK)
    scarf = c.new_part(SCARF, SCARF_HI, SCARF_DK)
    face = c.new_part(FACE, FACE, FACE)
    glove = c.new_part(LEG_DK, LEG, OUTLINE)

    hip = (16.0 + lean * 0.4, 21.0 + bob + crouch)
    sh = (16.0 + lean, 13.0 + bob + crouch)
    hands = []

    def leg(spec, part):
        a, bend = spec
        knee = add(hip, v(a, 4.6))
        foot = add(knee, v(a - bend, 4.6))
        c.limb(hip, knee, 3.0, part)
        c.limb(knee, foot, 2.6, part)
        c.rect(foot[0] - 1, foot[1] - 1, 3, 2, boot)

    def arm(spec, part, shoulder):
        a, bend = spec
        elbow = add(shoulder, v(a, 3.6))
        hand = add(elbow, v(a + bend, 3.6))
        c.limb(shoulder, elbow, 2.4, part)
        c.limb(elbow, hand, 2.2, part)
        c.rect(hand[0] - 0.5, hand[1] - 0.5, 2, 2, glove)
        hands.append(hand)

    # capa: presa nos ombros, cai atrás do corpo até o joelho e voa com o movimento
    c.poly([(sh[0] - 3.0, sh[1] - 1.0), (sh[0] + 0.5, sh[1] - 1.0),
            (hip[0] - 0.5, hip[1] + 3.5), (hip[0] - 3.0 - flare * 1.3, hip[1] + 4.0 - flare * 0.9),
            (hip[0] - 5.0 - flare * 1.1, hip[1] + 1.0 - flare * 0.9),
            (sh[0] - 5.0 - flare * 0.6, sh[1] + 3.0)], cape)
    arm(arms[0], sleeve_back, (sh[0] - 1.0, sh[1] + 1.5))
    leg(legs[0], leg_back)
    leg(legs[1], leg_front)
    # túnica escura por baixo, cinto com fivela
    c.poly([(sh[0] - 2.5, sh[1]), (sh[0] + 2.8, sh[1]),
            (hip[0] + 3.4, hip[1] + 1.5), (hip[0] - 2.8, hip[1] + 1.5)], tunic)
    c.rect(hip[0] - 3, hip[1] - 2, 7, 1, glove)
    c.mark(hip[0] + 1, hip[1] - 2, TRIM)
    # gola do manto sobre os ombros (é ela que carrega a cor da aparência)
    c.poly([(sh[0] - 4.0, sh[1] - 0.5), (sh[0] + 3.5, sh[1] - 0.5),
            (sh[0] + 4.3, sh[1] + 4.5), (sh[0] + 0.5, sh[1] + 5.5), (sh[0] - 4.8, sh[1] + 4.5)], mantle)
    # capuz: cabeça redonda com a ponta caída para trás
    head = (sh[0] + 0.6 + look, sh[1] - 4.4)
    c.poly([(head[0] - 1.5, head[1] - 3.4), (head[0] - 6.0 - hood_back, head[1] + 0.8 + hood_back * 0.4),
            (head[0] - 2.0, head[1] + 3.2)], hood)
    c.ellipse(head, 4.1, 4.2, hood)
    c.rect(head[0] + 0.6, head[1] - 1.0, 3, 3, face)
    c.mark(head[0] + 2.0, head[1], EYE)
    c.mark(head[0] + 3.0, head[1], EYE)
    # cachecol enrolado no pescoço
    c.rect(sh[0] - 3, sh[1] - 1.5, 6.5, 2, scarf)
    c.rect(sh[0] - 4.5, sh[1] - 0.5, 2, 2.5, scarf)
    arm(arms[1], sleeve, (sh[0] + 1.0, sh[1] + 1.5))
    c.finish()
    return c, [(round(h[0] - 16), round(h[1] - 30)) for h in hands]


def roll_frame(i, n):
    c = Canvas(SIZE, SIZE)
    cloak = c.new_part(CLOAK, CLOAK_HI, CLOAK_DK)
    hood = c.new_part(HOOD, HOOD_HI, HOOD_DK)
    scarf = c.new_part(SCARF, SCARF_HI, SCARF_DK)
    legs = c.new_part(LEG, LEG, LEG_DK)
    center = (16.0, 23.5)
    a = -i / n * math.tau
    c.ellipse(center, 6.2, 6.0, cloak)
    knee = add(center, (math.cos(a + 2.3) * 4.5, math.sin(a + 2.3) * 4.5))
    c.ellipse(knee, 2.0, 2.0, legs)
    hd = add(center, (math.cos(a) * 3.5, math.sin(a) * 3.5))
    c.ellipse(hd, 2.8, 2.8, hood)
    tail = add(center, (math.cos(a - 1.4) * 5.5, math.sin(a - 1.4) * 5.5))
    c.rect(tail[0] - 1, tail[1] - 1, 3, 2, scarf)
    c.finish()
    return c, [(0, -7)]


def dead_frame():
    c = Canvas(SIZE, SIZE)
    cloak = c.new_part(CLOAK, CLOAK_HI, CLOAK_DK)
    hood = c.new_part(HOOD, HOOD_HI, HOOD_DK)
    scarf = c.new_part(SCARF, SCARF_HI, SCARF_DK)
    legs = c.new_part(LEG, LEG, LEG_DK)
    c.limb((6, 28.5), (11, 28.5), 2.6, legs)
    c.poly([(9, 25.5), (21, 25), (23, 30), (8, 30)], cloak)
    c.ellipse((24.5, 27), 3.4, 3.0, hood)
    c.rect(18, 25, 4, 2, scarf)
    c.rect(14, 26, 5, 1, scarf)
    c.finish()
    return c, [(4, -2)]


# --- golpes: poses-chave por formato de golpe, interpoladas -------------------------

NEUTRAL = dict(lean=0.5, crouch=0.0, legs=((-0.35, 0.25), (0.35, 0.3)), arms=((-0.3, 0.3), (0.3, 0.3)),
               flare=1.0, hood_back=0.0, look=0.0, bob=0.0)


def pose(**k):
    p = dict(NEUTRAL)
    p.update(k)
    return p


def mix(a, b, t):
    if isinstance(a, tuple):
        return tuple(mix(x, y, t) for x, y in zip(a, b))
    return a + (b - a) * t


def tween(a, b, t):
    return {k: mix(a[k], b[k], t) for k in a}


# preparo, impacto, fim do movimento
SWINGS = {
    "down": (pose(lean=-1.0, legs=((-0.35, 0.4), (0.35, 0.2)), arms=((-0.6, 0.2), (-2.6, 0.3))),
             pose(lean=2.0, crouch=1, legs=((-0.7, 0.3), (0.75, 0.6)), arms=((-0.8, 0.2), (1.55, 0.05)), flare=3.0, hood_back=1.5),
             pose(lean=1.5, crouch=1.5, legs=((-0.7, 0.4), (0.7, 0.7)), arms=((-0.6, 0.2), (0.6, 0.1)), flare=2.0, hood_back=1.0)),
    "up": (pose(lean=-0.5, crouch=1.5, legs=((-0.5, 0.5), (0.5, 0.6)), arms=((-0.5, 0.2), (0.25, 0.1))),
           pose(lean=1.5, crouch=-1, legs=((-0.6, 0.2), (0.6, 0.3)), arms=((-1.2, 0.2), (2.5, -0.1)), flare=2.5, hood_back=1.0),
           pose(lean=0.8, crouch=-0.5, legs=((-0.5, 0.3), (0.5, 0.3)), arms=((-0.8, 0.2), (2.9, -0.1)), flare=1.5)),
    "thrust": (pose(lean=-1.2, legs=((-0.6, 0.3), (0.3, 0.5)), arms=((-0.4, 0.2), (-1.0, 1.6))),
               pose(lean=2.6, crouch=1, legs=((-0.9, 0.2), (0.8, 0.8)), arms=((-1.0, 0.2), (1.57, 0.0)), flare=3.5, hood_back=2.0),
               pose(lean=1.8, crouch=1, legs=((-0.8, 0.3), (0.7, 0.7)), arms=((-0.8, 0.2), (1.45, 0.1)), flare=2.5, hood_back=1.0)),
    "smash": (pose(lean=-1.5, crouch=-1, legs=((-0.4, 0.3), (0.3, 0.3)), arms=((-2.8, 0.1), (-2.9, 0.2)), flare=0.5),
              pose(lean=2.2, crouch=2.5, legs=((-0.8, 0.6), (0.8, 0.9)), arms=((0.9, 0.1), (1.0, 0.0)), flare=3.0, hood_back=1.5),
              pose(lean=2.0, crouch=3, legs=((-0.8, 0.7), (0.8, 1.0)), arms=((0.5, 0.1), (0.6, 0.0)), flare=1.5)),
    "jab": (pose(lean=0.5, legs=((-0.5, 0.3), (0.5, 0.4)), arms=((1.0, 0.8), (0.9, 1.4))),
            pose(lean=2.0, legs=((-0.7, 0.3), (0.6, 0.5)), arms=((0.9, 1.2), (1.57, 0.0)), flare=2.0),
            pose(lean=1.5, legs=((-0.6, 0.3), (0.6, 0.5)), arms=((1.57, 0.0), (1.0, 1.0)), flare=1.5)),
    "lash": (pose(lean=-1.0, legs=((-0.4, 0.3), (0.4, 0.3)), arms=((-0.5, 0.2), (-2.2, 0.6))),
             pose(lean=1.8, legs=((-0.7, 0.3), (0.7, 0.5)), arms=((-0.9, 0.2), (1.75, -0.2)), flare=2.5, hood_back=1.0),
             pose(lean=1.0, legs=((-0.6, 0.3), (0.6, 0.4)), arms=((-0.6, 0.2), (1.3, 0.2)), flare=1.5)),
    "spin": (pose(lean=-0.5, crouch=1, legs=((-0.6, 0.4), (0.6, 0.4)), arms=((1.4, 0.2), (-1.4, 0.2)), flare=2.0),
             pose(lean=0.0, crouch=1.5, legs=((-0.7, 0.4), (0.7, 0.4)), arms=((-1.57, 0.0), (1.57, 0.0)), flare=4.0, hood_back=2.0),
             pose(lean=0.5, crouch=1, legs=((-0.6, 0.4), (0.6, 0.4)), arms=((-1.0, 0.2), (1.2, 0.2)), flare=2.5)),
}


def swing_frames(shape):
    w, s, f = SWINGS[shape]
    keys = [tween(NEUTRAL, w, 0.55), w, tween(w, s, 0.6), s, f, tween(f, NEUTRAL, 0.5)]
    return [hero_frame(**k) for k in keys]


def hero_anims():
    A = {}
    # parado: respira (sobe e desce 1 px) e o capuz balança de leve
    A["idle"] = (5, [hero_frame(bob=b, flare=f, arms=((-0.25, 0.35), (0.2, 0.3)))
                     for b, f in ((0, 0), (0, 0.5), (1, 1), (1, 0.5))])
    # corrida: 8 quadros, inclinado para a frente, braços contrários às pernas
    run = []
    for i in range(8):
        p = i / 8 * math.tau
        s = math.sin(p)
        front = (0.85 * s, 0.25 + 0.95 * max(0.0, -math.cos(p)))
        back = (-0.85 * s, 0.25 + 0.95 * max(0.0, math.cos(p)))
        bob = -1.0 if abs(s) < 0.5 else 0.0
        run.append(hero_frame(bob=bob, lean=1.5, legs=(back, front), flare=2.5 + abs(s),
                              arms=((0.9 * s, -0.6), (-0.9 * s, -0.7)), hood_back=1.5))
    A["run"] = (14, run)
    A["jump"] = (10, [hero_frame(crouch=-1, legs=((-0.3, 0.9), (0.7, 1.4)), arms=((-1.9, -0.4), (-1.2, -0.6)),
                                 flare=1.5, hood_back=1.0),
                      hero_frame(crouch=-1, legs=((-0.2, 0.7), (0.6, 1.2)), arms=((-2.1, -0.3), (-1.5, -0.5)),
                                 flare=2.0, hood_back=1.5)])
    A["fall"] = (10, [hero_frame(legs=((-0.35, 0.3), (0.35, 0.5)), arms=((-2.4, 0.3), (2.2, -0.3)),
                                 flare=3.5, hood_back=2.5),
                      hero_frame(legs=((-0.4, 0.35), (0.3, 0.45)), arms=((-2.5, 0.4), (2.3, -0.4)),
                                 flare=4.0, hood_back=3.0)])
    A["roll"] = (20, [roll_frame(i, 6) for i in range(6)])
    # golpe: puxa a arma para trás e por cima, avança o corpo e estica o braço
    A["windup"] = (1, [hero_frame(lean=-1.0, legs=((-0.35, 0.4), (0.35, 0.2)), arms=((-0.6, 0.2), (-2.5, 0.3)),
                                  flare=1.0)])
    A["strike"] = (1, [hero_frame(lean=2.0, crouch=1, legs=((-0.7, 0.3), (0.75, 0.6)),
                                  arms=((-0.8, 0.2), (1.55, 0.05)), flare=3.0, hood_back=1.5)])
    A["recover"] = (1, [hero_frame(lean=1.0, legs=((-0.5, 0.3), (0.5, 0.4)), arms=((-0.5, 0.2), (0.9, 0.2)),
                                   flare=1.5)])
    A["shoot"] = (1, [hero_frame(lean=-0.5, legs=((-0.45, 0.2), (0.4, 0.2)), arms=((1.45, 0.0), (1.6, -0.3)),
                                 flare=0.5)])
    A["block"] = (1, [hero_frame(lean=-0.5, crouch=1, legs=((-0.5, 0.4), (0.4, 0.5)),
                                 arms=((0.6, 0.3), (1.3, 0.4)))])
    A["heal"] = (6, [hero_frame(bob=b, arms=((-0.2, 0.3), (2.0, 1.0)), look=-0.3) for b in (0, 1)])
    A["hurt"] = (1, [hero_frame(lean=-2.0, legs=((-0.4, 0.4), (0.2, 0.6)), arms=((-2.0, 0.4), (2.3, 0.5)),
                                flare=2.0, look=-0.5)])
    A["climb"] = (8, [hero_frame(crouch=1, legs=((0.3, 1.4), (0.6, 1.6)), arms=((2.9, 0.1), (3.0, 0.0))),
                      hero_frame(crouch=-1, legs=((0.2, 1.0), (0.5, 1.2)), arms=((2.7, 0.3), (2.8, 0.2)))])
    A["dive"] = (1, [hero_frame(crouch=-1, legs=((-0.2, 1.6), (0.3, 1.8)), arms=((-0.4, 0.0), (0.1, 0.0)),
                                flare=-1.0, hood_back=-1.0)])
    A["dead"] = (1, [dead_frame()])
    for shape in SWINGS:
        A["atk_" + shape] = (1, swing_frames(shape))
    draw = pose(lean=-0.5, legs=((-0.45, 0.2), (0.4, 0.2)), arms=((1.45, 0.0), (1.6, -0.3)), flare=0.5)
    A["shoot"] = (1, [hero_frame(**tween(NEUTRAL, draw, 0.6)), hero_frame(**draw),
                      hero_frame(**pose(lean=-1.2, legs=((-0.5, 0.2), (0.4, 0.2)), arms=((1.45, 0.0), (1.2, 0.6)), flare=1.0))])
    A["dash"] = (12, [hero_frame(lean=3.0, crouch=1, legs=((-1.4, 0.3), (-1.0, 0.6)), arms=((-1.6, 0.0), (1.2, 0.3)),
                                 flare=5.0, hood_back=3.0),
                      hero_frame(lean=3.0, crouch=1, legs=((-1.5, 0.3), (-1.1, 0.5)), arms=((-1.7, 0.0), (1.3, 0.3)),
                                 flare=5.5, hood_back=3.5)])
    A["flip"] = (20, [roll_frame(i, 6) for i in range(6)])
    A["hurt"] = (12, [hero_frame(lean=-2.0, legs=((-0.4, 0.4), (0.2, 0.6)), arms=((-2.0, 0.4), (2.3, 0.5)),
                                 flare=2.0, look=-0.5),
                      hero_frame(lean=-1.0, legs=((-0.4, 0.4), (0.3, 0.5)), arms=((-1.2, 0.4), (1.5, 0.5)),
                                 flare=1.5, look=-0.3)])
    A["dive"] = (12, [hero_frame(crouch=-1, legs=((-0.2, 1.6), (0.3, 1.8)), arms=((-0.4, 0.0), (0.1, 0.0)),
                                 flare=-1.0, hood_back=-1.0),
                      hero_frame(crouch=-1, legs=((-0.1, 1.7), (0.2, 1.9)), arms=((-0.3, 0.0), (0.0, 0.0)),
                                 flare=-1.5, hood_back=-1.5)])
    return A


SKIN_PREVIEWS = {
    "andarilho": ("#2e5d8a", "#1f3f60", "#1a2a45", "#8ff7e8", "#e8a33d"),
    "herdeiro_vesper": ("#7a1f2b", "#4f1219", "#1d1418", "#f2c14e", "#d9b45a"),
    "casca_vidro": ("#6fb3b8", "#3f7f86", "#24474f", "#ffffff", "#bfe6ea"),
}


def hero_palette(cloak, cloak_dk, hood, eye, scarf):
    cl, cd, hd, ey, sc = (hexc(x) for x in (cloak, cloak_dk, hood, eye, scarf))
    pal = [(0, 0, 0)] * 16
    pal[1] = hexc("#0b0910")
    pal[CLOAK_HI], pal[CLOAK], pal[CLOAK_DK] = shade(cl, 0.22), cl, cd
    pal[HOOD_HI], pal[HOOD], pal[HOOD_DK] = shade(hd, 0.3), hd, shade(hd, -0.4)
    pal[EYE] = ey
    pal[SCARF_HI], pal[SCARF], pal[SCARF_DK] = shade(sc, 0.25), sc, shade(sc, -0.3)
    pal[FACE] = hexc("#0e0b12")
    pal[LEG_DK], pal[LEG] = hexc("#2a2230"), hexc("#3d3346")
    pal[TRIM] = hexc("#c9a24a")
    return pal


def build(name, anims, palettes):
    rows, meta = [], {}
    for r, (anim, (fps, frames)) in enumerate(anims.items()):
        rows.append([f[0] for f in frames])
        meta[anim] = {"row": r, "frames": len(frames), "fps": fps, "hands": [f[1] for f in frames]}
    img = sheet(rows, SIZE)
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    img.save(os.path.join(OUT, name + ".png"))
    with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"size": SIZE, "anims": meta}, f, indent=1)
    preview(img, palettes, scale=4).save(os.path.join(PREV, name + ".png"))
    return img


if __name__ == "__main__":
    build("hero", hero_anims(), [hero_palette(*p) for p in SKIN_PREVIEWS.values()])
    print("ok")
