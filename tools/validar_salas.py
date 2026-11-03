"""Confere se as salas são jogáveis com o alcance REAL do herói.

    python tools/validar_salas.py            (todas as salas de todos os biomas)

O teste antigo do gerador só via se as salas se ligam pelo ar. Aqui o herói
anda, cai, pula até 3 blocos (4 agarrando a beirada) e atravessa plataforma
por baixo. Para cada sala:
  - de cada porta dá para chegar em todas as outras portas;
  - porta no TETO: precisa de chão a até 1 bloco abaixo dela (senão não se
    sobe por ali, e quem caiu na sala de cima fica preso);
  - todo marcador importante (saída, item, baú, altar, Vigia...) é alcançável.
Marcadores alcançáveis só com pulo duplo (nichos de runa) entram como aviso.
"""
import os
import sys
from collections import deque

ROOT = os.path.join(os.path.dirname(__file__), "..")
SOLID = "#K"
PLATFORM = "="
IMPORTANT = "XicfUT$MVPLE"
JUMP_UP = 3
LEDGE_UP = 4


def load(path):
    rows = [l.rstrip("\n") for l in open(path, encoding="utf-8") if l.strip() and not l.startswith(";")]
    w = max(len(r) for r in rows)
    return [r.ljust(w, ".") for r in rows]


class Room:
    def __init__(self, rows):
        self.g = rows
        self.h, self.w = len(rows), len(rows[0])

    def c(self, x, y):
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return "#"
        ch = self.g[y][x]
        return "." if ch not in SOLID + PLATFORM + "D#" else ch

    def air(self, x, y):
        return self.c(x, y) in ".D" and not (self.c(x, y) == "D" and (y == self.h - 1))

    def free(self, x, y):
        return self.c(x, y) not in SOLID + "#"

    def stand(self, x, y):
        if not (0 <= x < self.w and 0 <= y < self.h):
            return False
        return self.free(x, y) and self.free(x, y - 1) and self.c(x, y + 1) in "#K="

    def fall(self, x, y):
        while y < self.h - 1:
            if self.stand(x, y):
                return (x, y)
            if not self.free(x, y + 1) and self.c(x, y + 1) != "=":
                return None
            y += 1
        return None

    def clear_column(self, x, y_from, y_to):
        for y in range(min(y_from, y_to), max(y_from, y_to) + 1):
            if not self.free(x, y) and self.c(x, y) != "=":
                return False
        return True

    def moves(self, x, y, up_limit=JUMP_UP):
        out = []
        for dx in (-1, 1):
            if self.stand(x + dx, y):
                out.append((x + dx, y))
            elif self.free(x + dx, y) and self.free(x + dx, y - 1):
                f = self.fall(x + dx, y)
                if f:
                    out.append(f)
        if self.c(x, y + 1) == "=":
            f = self.fall(x, y + 1)
            if f:
                out.append(f)
        for dy in range(-8, up_limit + 2):
            for dx in range(-5, 6):
                if dx == 0 and dy <= 0:
                    continue
                tx, ty = x + dx, y - dy
                if not self.stand(tx, ty):
                    continue
                reach = 5 if dy <= 0 else (4 if dy <= 2 else 3)
                if abs(dx) > reach:
                    continue
                if dy > up_limit:
                    # agarrar a beirada: só encostado e com parede embaixo do alvo
                    if dy > up_limit + 1 or abs(dx) > 1 or self.c(tx, ty + 1) not in SOLID:
                        continue
                top = min(y, ty) - 1
                if not self.clear_column(x, y, top) or not self.clear_column(tx, ty, top):
                    continue
                out.append((tx, ty))
        return out

    def reach(self, starts, up_limit=JUMP_UP):
        seen = set(starts)
        todo = deque(starts)
        while todo:
            p = todo.popleft()
            for q in self.moves(*p, up_limit=up_limit):
                if q not in seen:
                    seen.add(q)
                    todo.append(q)
        return seen


def doors(room):
    out = []
    g, w, h = room.g, room.w, room.h
    for side, cells in (("L", [(0, y) for y in range(h)]), ("R", [(w - 1, y) for y in range(h)]),
                        ("T", [(x, 0) for x in range(w)]), ("B", [(x, h - 1) for x in range(w)])):
        run = []
        for (x, y) in cells + [(-1, -1)]:
            if x >= 0 and g[y][x] == "D":
                run.append((x, y))
            elif run:
                out.append((side, run))
                run = []
    return out


def door_entry(room, side, run):
    """Onde o herói fica de pé ao entrar por essa porta."""
    if side in "LR":
        x = 1 if side == "L" else room.w - 2
        y = max(p[1] for p in run)
        f = room.fall(x, y)
        return [f] if f else []
    if side == "T":
        out = []
        for (x, _) in run:
            f = room.fall(x, 1)
            if f:
                out.append(f)
        return out
    xs = [p[0] for p in run]
    return [(x, room.h - 2) for x in range(min(xs) - 2, max(xs) + 3) if room.stand(x, room.h - 2)]


def door_exit_ok(room, side, run, reach):
    xs = [p[0] for p in run]
    if side in "LR":
        x = 1 if side == "L" else room.w - 2
        y = max(p[1] for p in run)
        f = room.fall(x, y)
        return f in reach
    if side == "T":
        # sobe pelo teto: de pé a até 1 bloco abaixo, perto da abertura
        return any(p[1] <= 2 and min(xs) - 2 <= p[0] <= max(xs) + 2 for p in reach)
    # desce pelo chão: chegar ao lado do buraco e cair
    return any(p[1] == room.h - 2 and min(xs) - 1 <= p[0] <= max(xs) + 1 for p in reach)


def check(path):
    return check_rows(load(path))


def check_rows(rows):
    room = Room(rows)
    problems, warnings = [], []
    ds = doors(room)
    entries = {i: door_entry(room, side, run) for i, (side, run) in enumerate(ds)}
    for i, (side, run) in enumerate(ds):
        if not entries[i] and side != "B":
            problems.append("porta %s em %s: sem chão para entrar" % (side, run[0]))
    starts = [(r.find("P"), y) for y, r in enumerate(rows) if "P" in r]
    # entradas do caminho principal: porta esquerda, porta do teto, ou o início
    primary = list(starts) + [e for i, (side, _) in enumerate(ds) if side in "LT" for e in entries[i]]
    if not primary:
        primary = [e for es in entries.values() for e in es]
    if not primary:
        return ["sala sem entrada"], []
    reach = room.reach(primary)
    for side, run in ds:
        if not door_exit_ok(room, side, run, reach):
            problems.append("a porta %s%s não se alcança" % (side, run[0]))
    # quem entra por qualquer porta precisa conseguir sair (nada de ficar preso)
    forward = [(side, run) for side, run in ds if side in "RB"]
    for i, (side, run) in enumerate(ds):
        if not entries[i]:
            continue
        r = room.reach(entries[i])
        outs = forward + ([(side, run)] if side in "TLRB" else [])
        if not any(door_exit_ok(room, s2, r2, r) for s2, r2 in outs) and not any(
                rows[y][x] == "X" for (x, y) in r):
            problems.append("quem entra por %s%s fica preso" % (side, run[0]))
    flying = room.reach(primary, up_limit=7)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in IMPORTANT and ch != "P":
                if (x, y) in reach:
                    continue
                if (x, y) in flying:
                    warnings.append("%s em (%d,%d) só com pulo duplo" % (ch, x, y))
                else:
                    problems.append("%s em (%d,%d) inalcançável" % (ch, x, y))
    return problems, warnings


def all_rooms():
    out = []
    base = os.path.join(ROOT, "content")
    for dirpath, _, files in os.walk(base):
        for f in sorted(files):
            if f.endswith(".txt"):
                out.append(os.path.join(dirpath, f))
    return out


if __name__ == "__main__":
    paths = sys.argv[1:] or all_rooms()
    bad = 0
    for p in paths:
        problems, warnings = check(p)
        name = os.path.relpath(p, os.path.join(ROOT, "content"))
        for w in warnings:
            print("  aviso  %s: %s" % (name, w))
        for pr in problems:
            print("  ERRO   %s: %s" % (name, pr))
        bad += 1 if problems else 0
    print("%d salas, %d com problema" % (len(paths), bad))
    sys.exit(1 if bad else 0)
