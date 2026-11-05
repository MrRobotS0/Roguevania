"""Salas com a cara de cada domínio, geradas por plantas com parâmetros e
aprovadas pelo verificador (validar_salas.py). Planta que reprova é trocada.

    python tools/salas_dominios.py

Plantas:
  fossos     chão alto com 1-2 fossos e pranchas por cima
  pilares    pilares que descem do teto e varandas entre eles
  terracos   degraus de até 3 blocos subindo e descendo
  vertical   entra embaixo e sai em cima, plataformas em zigue-zague
  varandas   salão largo com varandas em dois andares
  ilhas      blocos flutuando sobre o chão
  ruela      corredor baixo e estreito com teto que pesa
"""
import os
import random

from salas_mar_de_cinzas import R
from salas_andares import top_ladders
from validar_salas import Room, check_rows

ROOT = os.path.join(os.path.dirname(__file__), "..")

DOMAINS = {
    "mar_de_cinzas": (["vertical", "fossos", "varandas", "vertical", "ilhas", "terracos", "vertical"], "Mar de Cinzas"),
    "saloes": (["pilares", "fossos", "varandas", "pilares", "ruela", "terracos", "varandas"], "Salões"),
    "forja_rubra": (["fossos", "terracos", "vertical", "fossos", "ruela", "fossos", "pilares"], "Forja"),
    "torre_babel": (["vertical", "vertical", "terracos", "varandas", "ruela", "vertical", "ilhas"], "Torre"),
    "jardim_primordial": (["terracos", "fossos", "varandas", "ilhas", "terracos", "ruela", "ilhas"], "Jardim"),
    "carcosa": (["ruela", "pilares", "terracos", "vertical", "ruela", "pilares", "fossos"], "Carcosa"),
    "observatorio": (["ilhas", "varandas", "vertical", "ilhas", "fossos", "ilhas", "ruela"], "Observatório"),
    "necropole": (["ruela", "fossos", "terracos", "pilares", "varandas", "fossos", "ruela"], "Necrópole"),
    "catedral": (["pilares", "varandas", "vertical", "pilares", "terracos", "varandas", "fossos"], "Catedral"),
    "ventre": (["fossos", "ilhas", "terracos", "fossos", "vertical", "ilhas", "fossos"], "Ventre"),
    "penhascos": (["ilhas", "vertical", "ilhas", "terracos", "ilhas", "varandas", "vertical"], "Penhascos"),
    "cavernas": (["pilares", "vertical", "fossos", "pilares", "ruela", "vertical", "terracos"], "Cavernas"),
    "bosque": (["ruela", "terracos", "fossos", "ruela", "varandas", "terracos", "ruela"], "Bosque"),
}

HEADS = {
    "fossos": "Fossos no chão, pranchas por cima",
    "pilares": "Pilares que descem do teto",
    "terracos": "Terraços que sobem e descem",
    "vertical": "Entra embaixo, sai lá em cima",
    "varandas": "Salão com varandas em dois andares",
    "ilhas": "Ilhas de pedra flutuando",
    "ruela": "Passagem baixa e apertada",
}


def floor_room(name, kind, w, h, door_rows=4):
    r = R(name, kind, w, h, weight=14)
    r.door("L", h - 1 - door_rows, door_rows).door("R", h - 1 - door_rows, door_rows)
    return r


def fossos(rng, name):
    w, h = rng.randint(40, 52), 16
    r = R(name, "combate", w, h, weight=14)
    ground = 12
    r.fill(1, w - 2, ground, h - 2)
    r.door("L", ground - 4, 4).door("R", ground - 4, 4)
    x = rng.randint(8, 12)
    for _ in range(rng.randint(1, 2)):
        width = rng.randint(8, 12)
        if x + width > w - 8:
            break
        r.fill(x, x + width, ground, h - 2, ".")
        r.fill(x, x + width, h - 1, h - 1, "#")
        for k in range(x + 2, x + width - 1, 4):
            r.fill(k, k + 1, ground, ground, "=")
        x += width + rng.randint(6, 10)
    if rng.random() < 0.6:
        r.door("T", w // 2 - 1, 3)
    return r


def pilares(rng, name):
    w, h = rng.randint(42, 54), 18
    r = floor_room(name, "combate", w, h)
    step = rng.randint(9, 12)
    for x in range(8, w - 6, step):
        r.fill(x, x + 1, 1, 9)
        if x + step < w - 6:
            r.fill(x + 3, x + step - 3, 14, 14, "=")
            r.fill(x + 4, x + step - 4, 11, 11, "=")
    return r


def terracos(rng, name):
    w, h = rng.randint(40, 50), 18
    r = floor_room(name, "combate", w, h)
    x = rng.randint(6, 9)
    level = 0
    while x < w - 10:
        wide = rng.randint(4, 7)
        level = max(0, min(3, level + rng.choice([-1, 1, 1])))
        # perto do fim o terraço desce: atrás de um degrau alto ninguém fica preso
        if x + wide >= w - 10 - level * 8:
            level = max(0, level - 1)
        if level > 0:
            r.fill(x, x + wide, h - 1 - level * 3, h - 2)
        x += wide + 1
    if rng.random() < 0.5:
        r.door("T", w // 2, 3)
    return r


def vertical(rng, name):
    w, h = rng.randint(28, 34), rng.randint(24, 30)
    r = R(name, "combate", w, h, weight=14)
    r.door("L", h - 5, 4)
    exit_row = rng.randint(3, 6)
    r.door("R", exit_row, 4)
    ledge = exit_row + 4
    r.fill(w - 8, w - 2, ledge, ledge)
    stand = h - 2
    left = True
    while stand - 3 > ledge - 1:
        stand -= 3
        x0 = rng.randint(3, 7) if left else rng.randint(w // 2 - 4, w // 2)
        r.fill(x0, x0 + 6, stand + 1, stand + 1, "=")
        left = not left
    # último degrau encostado na borda de saída
    r.fill(w - 15, w - 9, ledge + 2, ledge + 2, "=")
    if rng.random() < 0.5:
        r.door("B", w // 2, 3)
    return r


def varandas(rng, name):
    w, h = rng.randint(46, 56), 20
    r = floor_room(name, "combate", w, h)
    for y, count in ((h - 4, 3), (h - 7, 2), (h - 10, 2)):
        for i in range(count):
            x = rng.randint(4 + i * (w // count), (i + 1) * (w // count) - 10)
            r.fill(x, x + rng.randint(5, 8), y, y, "=")
    r.door("T", rng.randint(10, w - 12), 3)
    return r


def ilhas(rng, name):
    w, h = rng.randint(44, 54), 20
    r = floor_room(name, "combate", w, h)
    for i in range(rng.randint(3, 4)):
        x = 6 + i * (w - 12) // 4 + rng.randint(0, 4)
        y = rng.choice([h - 5, h - 8, h - 11])
        r.fill(x, x + rng.randint(4, 6), y, y + 1)
        r.fill(x - 3, x - 1, y + 3, y + 3, "=")
    r.door("T", w // 2, 3)
    return r


def ruela(rng, name):
    w, h = rng.randint(26, 34), 11
    r = floor_room(name, "corredor", w, h)
    x = rng.randint(6, 10)
    while x < w - 8:
        r.fill(x, x + rng.randint(3, 6), 1, rng.randint(3, 5))
        x += rng.randint(8, 12)
    return r


BUILDERS = {"fossos": fossos, "pilares": pilares, "terracos": terracos, "vertical": vertical,
            "varandas": varandas, "ilhas": ilhas, "ruela": ruela}


def populate(r, rng, hazard):
    """Inimigos no chão (e), atiradores no alto (r) e o perigo do domínio (w)."""
    room = Room(["".join(row) for row in r.g])
    stands = [(x, y) for y in range(1, r.h - 1) for x in range(2, r.w - 2)
              if room.stand(x, y) and r.g[y][x] == "." and r.g[y + 1][x] != "D"]
    if not stands:
        return
    low = max(y for _, y in stands)
    ground = [p for p in stands if p[1] >= low - 1 and 5 < p[0] < r.w - 5]
    high = [p for p in stands if p[1] < low - 2]
    rng.shuffle(ground)
    rng.shuffle(high)
    used = set()

    def put(p, ch):
        if any(abs(p[0] - u[0]) < 4 and abs(p[1] - u[1]) < 2 for u in used):
            return False
        r.g[p[1]][p[0]] = ch
        used.add(p)
        return True

    want_e = 2 if r.kind == "corredor" else 3
    for p in ground:
        if want_e and put(p, "e"):
            want_e -= 1
    for p in high[:2]:
        put(p, "r")
    if hazard:
        for p in ground:
            if put(p, "w"):
                break


def build_domain(bid, seed):
    layouts, label = DOMAINS[bid]
    rng = random.Random(seed)
    rooms = []
    for i, layout in enumerate(layouts):
        for attempt in range(80):
            name = "dom_%s_%d" % (layout, i)
            r = BUILDERS[layout](rng, name)
            r.head = "%s: %s" % (label, HEADS[layout].lower())
            populate(r, rng, hazard=layout != "ruela")
            top_ladders(r)
            problems, _ = check_rows(["".join(row) for row in r.g])
            if not problems:
                rooms.append(r)
                break
        else:
            print("  %s/%s: nenhuma versão passou" % (bid, layout))
    return rooms


if __name__ == "__main__":
    total = 0
    for k, bid in enumerate(DOMAINS):
        folder = os.path.join(ROOT, "content", "biomes", bid, "rooms")
        for f in os.listdir(folder):
            if f.startswith("dom_"):
                os.remove(os.path.join(folder, f))
        rooms = build_domain(bid, 1000 + k * 77)
        for r in rooms:
            r.save(folder)
        total += len(rooms)
        print("%-18s %d salas" % (bid, len(rooms)))
    print("total", total)
