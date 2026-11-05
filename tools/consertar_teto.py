"""Porta no teto precisa de degrau bem embaixo do vão, a 3 blocos da sala de
cima: de lado, o herói bate a cabeça antes de entrar. Refaz as escadas de todas
as salas (pode rodar quantas vezes quiser).

    python tools/consertar_teto.py
"""
from validar_salas import all_rooms

RUNG_ROW = 2      # plataforma na linha 2: de pé nela faltam 3 blocos até o chão de cima
STEP = 3


def header_and_rows(path):
    head, rows = [], []
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith(";") or not line.strip():
            if not rows:
                head.append(line)
        else:
            rows.append(line)
    w = max(len(r) for r in rows)
    return head, [list(r.ljust(w, ".")) for r in rows]


def rungs(g, door):
    """Pilha de plataformas bem embaixo do vão, de 3 em 3 blocos, até o chão."""
    h, w = len(g), len(g[0])
    x0, x1 = min(door), max(door)
    before = "".join("".join(r) for r in g)
    # degraus antigos colados no teto e ao lado do vão não deixam passar a cabeça
    # (o que tem item ou inimigo em cima fica: é parte da sala)
    for y in range(1, 5):
        x = max(1, x0 - 7)
        while x < min(w - 1, x1 + 8):
            if g[y][x] != "=":
                x += 1
                continue
            end = x
            while end + 1 < w and g[y][end + 1] == "=":
                end += 1
            if all(g[y - 1][k] in ".#D" for k in range(x, end + 1)):
                for k in range(x, end + 1):
                    g[y][k] = "."
            x = end + 1
    y = RUNG_ROW
    while y < h - 1:
        for x in range(x0, x1 + 1):
            if g[y][x] == ".":
                g[y][x] = "="
        # chão ou pedra a até 3 blocos: daqui já se alcança
        if any(g[k][x] in "#K" for k in range(y + 1, min(h, y + STEP + 1)) for x in range(x0, x1 + 1)):
            break
        y += STEP
    return before != "".join("".join(r) for r in g)


def fix(path):
    head, g = header_and_rows(path)
    door = [x for x in range(len(g[0])) if g[0][x] == "D"]
    if not door:
        return False
    runs, cur = [], []
    for x in door:
        if cur and x != cur[-1] + 1:
            runs.append(cur)
            cur = []
        cur.append(x)
    runs.append(cur)
    changed = False
    for run in runs:
        changed = rungs(g, run) or changed
    if changed:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(head + ["".join(r) for r in g]) + "\n")
    return changed


if __name__ == "__main__":
    n = sum(1 for p in all_rooms() if "rooms" in p and fix(p))
    print("%d salas com escada refeita" % n)
