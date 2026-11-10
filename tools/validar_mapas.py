"""Procura lugares de onde não se sai, nos mapas montados pelo gerador.

    python tools/validar_mapas.py [sementes por domínio]

validar_salas.py olha cada sala sozinha e conta com todas as portas dela; na
fase montada as portas sem ligação viram parede. Aqui o herói anda pelo mapa
inteiro a partir do início: todo lugar onde ele pode parar tem que ter caminho
até a saída, com o pulo simples.
"""
import collections
import os
import subprocess
import sys
import tempfile

from validar_salas import ROOT, Room, deque

GODOT_EXE = "Godot_v4.7.2-stable_win64_console.exe"
# MOKSHA_GODOT aponta para o executável; sem ela, procura na Área de Trabalho e em ~/Godot
GODOT = os.environ.get("MOKSHA_GODOT") or next(
    (p for p in (os.path.join(os.path.expanduser("~"), d, GODOT_EXE) for d in ("Desktop", os.path.join("OneDrive", "Desktop"), "Godot"))
     if os.path.exists(p)), os.path.join(os.path.expanduser("~"), "Desktop", GODOT_EXE))


def dump(seeds):
    path = os.path.join(tempfile.gettempdir(), "moksha_mapas.txt")
    subprocess.run([GODOT, "--headless", "--path", ROOT, "res://tests/dump_mapas.tscn", "--",
                    "--out=" + path, "--seeds=%d" % seeds], check=True, capture_output=True, timeout=300)
    maps = []
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("@"):
            maps.append((line[1:], [], []))
        elif line.startswith("!"):
            n, *nums = line[1:].split(" ")
            maps[-1][2].append((n, *map(int, nums)))
        else:
            maps[-1][1].append(line)
    return maps


def traps(rows, up=3):
    """Lugares alcançáveis a partir do P de onde não se chega ao X."""
    room = Room(rows)
    start = [(r.find("P"), y) for y, r in enumerate(rows) if "P" in r]
    start = [room.fall(*p) or p for p in start]
    seen, todo, back = set(start), deque(start), collections.defaultdict(list)
    while todo:
        p = todo.popleft()
        for q in room.moves(*p, up_limit=up):
            back[q].append(p)
            if q not in seen:
                seen.add(q)
                todo.append(q)
    goals = [p for p in seen if rows[p[1]][p[0]] == "X"]
    ok, todo = set(goals), deque(goals)
    while todo:
        for q in back[todo.popleft()]:
            if q not in ok:
                ok.add(q)
                todo.append(q)
    return sorted(seen - ok), bool(goals), len(seen)


if __name__ == "__main__":
    maps = dump(int(sys.argv[1]) if len(sys.argv) > 1 else 6)
    bad = 0
    culprits = collections.Counter()
    for name, rows, parts in maps:
        t, has_exit, n = traps(rows)
        if t or not has_exit:
            bad += 1
            where = {r[0] for p in t for r in parts if r[1] <= p[0] < r[1] + r[3] and r[2] <= p[1] < r[2] + r[4]}
            for w in where:
                culprits[w] += 1
            print("%s: %d de %d lugares sem saída%s: %s" % (
                name, len(t), n, "" if has_exit else " SEM CAMINHO ATÉ O X", ", ".join(sorted(where))))
    for k, v in culprits.most_common(30):
        print("  %3d  %s" % (v, k))
    print("%d mapas, %d com lugar sem saída" % (len(maps), bad))
    sys.exit(1 if bad else 0)
