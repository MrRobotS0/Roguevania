"""Salas desenhadas para os domínios da quarta leva: 5 por domínio, cada uma com
uma ideia que só faz sentido naquele lugar. Rode depois de salas_andares.py, que
limpa a pasta.

    python tools/salas_especiais.py

Medidas: o herói sobe 3 blocos com folga; de lado alcança 3 subindo 3, 4 subindo
1-2, e 5 no plano. Toda sala passa pelo verificador (validar_salas.py), inclusive
a regra de que de qualquer lugar se volta a todas as portas.
"""
import math
import os
import random

from salas_dominios import populate
from salas_mar_de_cinzas import R
from validar_salas import check_rows

ROOT = os.path.join(os.path.dirname(__file__), "..")
WEIGHT = 20


def sala(name, w, h, head, kind="combate", weight=WEIGHT):
    return R(name, kind, w, h, weight=weight, head=head)


def plat(r, x0, x1, y):
    for x in range(x0, x1 + 1):
        if r.g[y][x] == ".":
            r.g[y][x] = "="
    return r


def ground(r, row, x0=1, x1=None):
    """Chão: tudo de `row` para baixo é pedra."""
    r.fill(x0, (r.w - 2) if x1 is None else x1, row, r.h - 2)
    return r


def doors(r, left, right):
    """Portas de 4 blocos com o chão em `left` e `right` (linha da pedra)."""
    r.door("L", left - 4, 4).door("R", right - 4, 4)
    return r


def mark(r, x, y, ch):
    r.g[y][x] = ch
    return r


def ellipse(r, cx, cy, rx, ry):
    """Enche de pedra e abre uma caverna oval."""
    r.fill(1, r.w - 2, 1, r.h - 2)
    for y in range(1, r.h - 1):
        for x in range(1, r.w - 1):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                r.g[y][x] = "."
    return r


def tunnel(r, x0, x1, floor, height=4):
    r.fill(x0, x1, floor - height, floor - 1, ".")
    return r


def profile(r, heights):
    """Chão de altura variável: heights[x] é a linha da pedra na coluna x."""
    for x, top in enumerate(heights):
        if 1 <= x <= r.w - 2:
            r.fill(x, x, top, r.h - 2)
    return r


# --- Necrópole ----------------------------------------------------------------

def cemiterio():
    r = sala("esp_cemiterio", 58, 17, "Necrópole: o campo de covas, lápide atrás de lápide")
    ground(r, 14)
    doors(r, 14, 14)
    for x in range(7, 52, 7):
        r.fill(x, x + 1, 12, 13)
        r.fill(x + 3, x + 4, 13, 13)
    mark(r, 33, 13, "L")
    return r


def mausoleu():
    r = sala("esp_mausoleu", 54, 24, "Necrópole: o mausoléu; dentro, o que enterraram junto. Em cima, o que esqueceram")
    ground(r, 21)
    doors(r, 21, 21)
    r.fill(17, 36, 9, 20)
    r.fill(19, 34, 16, 20, ".")      # a câmara
    r.fill(17, 18, 18, 20, ".")      # entrada baixa, dos dois lados
    r.fill(35, 36, 18, 20, ".")
    mark(r, 27, 20, "c")
    for y, x in ((18, 12), (15, 12), (12, 12)):
        plat(r, x, x + 3, y)
    for y, x in ((18, 38), (15, 38), (12, 38)):
        plat(r, x, x + 3, y)
    mark(r, 27, 8, "i")
    return r


def ossuario():
    r = sala("esp_ossuario", 30, 33, "Necrópole: o ossuário, um poço de nichos empilhados")
    ground(r, 30)
    doors(r, 30, 8)
    r.fill(24, 28, 8, 8)
    plat(r, 10, 14, 27)
    y, left = 25, True
    while y > 9:
        if left:
            r.fill(1, 8, y, y)
        else:
            r.fill(15, 22, y, y)
        plat(r, 9, 14, y - 1) if y - 1 > 9 else None
        y -= 3
        left = not left
    return r


def cripta():
    r = sala("esp_cripta", 46, 12, "Necrópole: a cripta baixa; os arcos apertam a cabeça", kind="corredor")
    ground(r, 9, 1)
    doors(r, 9, 9)
    for x in range(7, 40, 8):
        r.fill(x, x + 2, 1, 4)
    r.fill(19, 24, 9, 9, ".")
    return r


def procissao():
    r = sala("esp_procissao", 60, 22, "Necrópole: a ponte da procissão; quem cai vai andar com os mortos lá embaixo")
    doors(r, 11, 11)
    ground(r, 11, 1, 9)
    ground(r, 11, 50, 58)
    ground(r, 20, 10, 49)
    # a ponte, e os degraus de volta nas duas pontas
    for x in range(13, 47, 7):
        r.fill(x, x + 3, 11, 11, "=")
    for x0 in (10, 46):
        for y in (17, 14):
            plat(r, x0, x0 + 3, y)
    r.fill(22, 23, 12, 17)
    r.fill(36, 37, 12, 17)
    return r


# --- Catedral Submersa --------------------------------------------------------

def nave():
    r = sala("esp_nave", 62, 24, "Catedral: a nave; colunas, arcos, e as varandas do coro")
    ground(r, 21)
    doors(r, 21, 21)
    for x in range(9, 56, 11):
        r.fill(x, x + 2, 1, 15)
        r.fill(x - 1, x + 3, 15, 15)
        if x + 11 < 56:
            plat(r, x + 4, x + 8, 18)
    return r


def altar():
    r = sala("esp_altar", 52, 19, "Catedral: o altar; quem reza aqui ainda está rezando", weight=12)
    ground(r, 16)
    doors(r, 16, 16)
    for k, (a, b) in enumerate(((16, 35), (19, 32), (22, 29))):
        r.fill(a, b, 14 - k * 2, 15 - k * 2)
    mark(r, 25, 9, "E")
    mark(r, 27, 9, "i")
    return r


def coro():
    r = sala("esp_coro", 56, 21, "Catedral: o coro; atiradores nas varandas dos dois lados")
    ground(r, 18)
    doors(r, 18, 18)
    r.fill(1, 14, 10, 11)
    r.fill(41, 54, 10, 11)
    for y in (15, 12):
        plat(r, 15, 18, y)
        plat(r, 37, 40, y)
    plat(r, 24, 31, 13)
    mark(r, 6, 9, "r")
    mark(r, 48, 9, "r")
    mark(r, 27, 12, "L")
    return r


def inundada():
    r = sala("esp_inundada", 56, 20, "Catedral: a parte que afundou; o piso desce e as tábuas ficaram")
    heights = [12] * 56
    for x in range(14, 42):
        d = min(x - 14, 41 - x) // 3
        heights[x] = 12 + min(d, 3) * 2
    profile(r, heights)
    doors(r, 12, 12)
    for x in range(16, 40, 6):
        plat(r, x, x + 2, 12)
    return r


def campanario():
    r = sala("esp_campanario", 26, 36, "Catedral: o campanário; o sino já tocou. Ninguém veio")
    ground(r, 33)
    doors(r, 33, 7)
    r.fill(20, 24, 7, 7)
    plat(r, 8, 15, 30)
    y, side = 28, 0
    while y > 8:
        if side % 2 == 0:
            r.fill(1, 7, y, y)
        else:
            r.fill(16, 22, y, y)
        plat(r, 8, 15, y - 1) if y - 1 > 8 else None
        y -= 3
        side += 1
    plat(r, 15, 18, 10)
    return r


# --- O Ventre -----------------------------------------------------------------

def garganta():
    r = sala("esp_garganta", 62, 20, "O Ventre: a garganta; as paredes se fecham e abrem como se respirassem")
    floor = [int(14 + 2.5 * math.sin(x / 6.0)) for x in range(62)]
    for x in range(0, 5):
        floor[x] = floor[5]
    for x in range(57, 62):
        floor[x] = floor[56]
    profile(r, floor)
    for x in range(1, 61):
        top = max(1, floor[x] - 7 - int(1.5 * math.sin(x / 4.0 + 1.0)))
        r.fill(x, x, 1, top - 1) if top > 1 else None
    doors(r, floor[1], floor[60])
    return r


def estomago():
    r = sala("esp_estomago", 48, 24, "O Ventre: o estômago; redondo, e o chão não é chão")
    ellipse(r, 24, 12, 22, 10)
    tunnel(r, 1, 8, 20)
    tunnel(r, 39, 46, 20)
    r.fill(1, 46, 20, 22)
    r.fill(9, 38, 20, 22, ".")
    r.fill(9, 38, 21, 22)
    doors(r, 20, 20)
    plat(r, 12, 17, 17)
    plat(r, 30, 35, 17)
    plat(r, 21, 26, 14)
    plat(r, 13, 17, 11)
    plat(r, 30, 34, 11)
    mark(r, 24, 13, "i")
    return r


def costelas():
    r = sala("esp_costelas", 60, 18, "O Ventre: as costelas descem do teto e sobem do chão")
    ground(r, 15)
    doors(r, 15, 15)
    for x in range(8, 54, 8):
        r.fill(x, x + 1, 1, 9)
        r.fill(x + 4, x + 5, 13, 14)
        plat(r, x + 2, x + 7, 11)
    return r


def intestino():
    r = sala("esp_intestino", 42, 27, "O Ventre: o intestino; o caminho dá voltas, e o que entra não volta inteiro")
    doors(r, 25, 7)
    r.fill(1, 34, 7, 8)
    r.fill(38, 40, 7, 8)
    r.fill(7, 40, 13, 14)
    r.fill(1, 34, 19, 20)
    # as subidas entre um andar e outro
    for y in (23, 20, 17):
        plat(r, 35, 37, y)
    for y in (16, 13, 10):
        plat(r, 3, 5, y)
    for y in (10, 7):
        plat(r, 35, 37, y)
    return r


def bexiga():
    r = sala("esp_bexiga", 58, 21, "O Ventre: o fosso de bile; as ilhas boiam, a borda é longe")
    ground(r, 12, 1, 11)
    ground(r, 12, 46, 56)
    ground(r, 19, 12, 45)
    doors(r, 12, 12)
    for x0 in (12, 42):
        for y in (16, 13):
            plat(r, x0, x0 + 3, y)
    r.fill(19, 23, 15, 16)
    r.fill(34, 38, 15, 16)
    r.fill(27, 30, 12, 13)
    mark(r, 28, 11, "c")
    return r


# --- Penhascos do Sonho -------------------------------------------------------

def cume():
    r = sala("esp_cume", 56, 30, "Penhascos: a subida; o sonho fica mais fino lá em cima")
    heights = [28] * 56
    level = 28
    for x in range(8, 49):
        if (x - 8) % 7 == 0:
            level -= 3
        heights[x] = level
    for x in range(49, 56):
        heights[x] = level
    profile(r, heights)
    doors(r, 28, level)
    return r


def nuvens():
    r = sala("esp_nuvens", 60, 20, "Penhascos: a ponte de nuvens; não olhe para baixo")
    ground(r, 11, 1, 8)
    ground(r, 11, 51, 58)
    ground(r, 18, 9, 50)
    doors(r, 11, 11)
    for x, y in ((12, 10), (19, 8), (26, 10), (33, 8), (40, 10), (46, 11)):
        plat(r, x, x + 3, y)
    for x0 in (9, 47):
        plat(r, x0, x0 + 3, 15)
        plat(r, x0, x0 + 3, 12)
    return r


def mirante():
    r = sala("esp_mirante", 50, 25, "Penhascos: o mirante; de lá se vê tudo o que o deus sonhou")
    ground(r, 22)
    doors(r, 22, 22)
    r.fill(21, 28, 8, 21)
    for y, x in ((19, 15), (16, 12), (13, 15), (10, 17)):
        plat(r, x, x + 4, y)
    for y, x in ((19, 30), (16, 33), (13, 30), (10, 29)):
        plat(r, x, x + 4, y)
    mark(r, 24, 7, "i")
    mark(r, 26, 7, "L")
    return r


def desfiladeiro():
    r = sala("esp_desfiladeiro", 54, 24, "Penhascos: o desfiladeiro; duas paredes e o vento no meio")
    ground(r, 22)
    doors(r, 8, 22)
    r.fill(1, 15, 8, 21)
    r.fill(38, 52, 8, 13)
    for y, x in ((19, 16), (16, 16), (13, 16), (10, 16)):
        plat(r, x, x + 3, y)
    for y in (19, 16):
        plat(r, 30, 34, y)
    plat(r, 35, 37, 17)
    plat(r, 34, 37, 14)
    return r


def queda():
    r = sala("esp_queda", 34, 32, "Penhascos: a queda; quem sonha caindo acorda antes do chão. Às vezes", kind="combate")
    ground(r, 30)
    doors(r, 7, 30)
    r.fill(1, 8, 7, 8)
    y, left = 27, True
    while y > 8:
        if left:
            plat(r, 9, 14, y)
        else:
            plat(r, 17, 22, y)
        y -= 3
        left = not left
    r.fill(26, 32, 17, 18)
    mark(r, 29, 16, "c")
    plat(r, 23, 25, 19)
    return r


# --- Cavernas Fundas ----------------------------------------------------------

def estalactites():
    rng = random.Random(71)
    r = sala("esp_estalactites", 58, 18, "Cavernas: dentes em cima, dentes embaixo")
    ground(r, 15)
    doors(r, 15, 15)
    x = 6
    while x < 52:
        r.fill(x, x + rng.randint(1, 2), 1, rng.randint(4, 8))
        x += rng.randint(4, 6)
    x = 8
    while x < 50:
        r.fill(x, x + rng.randint(0, 1), 15 - rng.randint(1, 2), 14)
        x += rng.randint(7, 10)
    return r


def galeria():
    r = sala("esp_galeria", 56, 23, "Cavernas: dois andares de galeria e dois buracos entre eles")
    ground(r, 21)
    doors(r, 21, 9)
    r.fill(1, 54, 9, 11)
    r.fill(14, 19, 9, 11, ".")
    r.fill(38, 43, 9, 11, ".")
    for y in (18, 15, 12, 9):
        plat(r, 15, 18, y)
    plat(r, 39, 42, 9)
    plat(r, 39, 42, 12)
    plat(r, 39, 42, 15)
    plat(r, 39, 42, 18)
    mark(r, 27, 8, "L")
    return r


def poco():
    r = sala("esp_poco", 28, 34, "Cavernas: o poço; dizem que no fundo tem um deus. Dizem")
    ground(r, 32)
    doors(r, 7, 32)
    r.fill(1, 7, 7, 8)
    y, left = 29, True
    while y > 8:
        if left:
            r.fill(8, 13, y, y)
        else:
            r.fill(15, 20, y, y)
        y -= 3
        left = not left
    plat(r, 9, 15, 8)
    r.fill(22, 26, 15, 16)
    mark(r, 24, 14, "c")
    plat(r, 21, 21, 17)
    return r


def gruta():
    r = sala("esp_gruta", 42, 10, "Cavernas: a gruta baixa; anda abaixado quem quer sair", kind="corredor")
    ground(r, 7)
    doors(r, 7, 7)
    for x in (9, 18, 27, 34):
        r.fill(x, x + 2, 1, 2)
    for x in (13, 23, 31):
        r.fill(x, x + 1, 6, 6)
    return r


def cristal():
    r = sala("esp_cristal", 50, 24, "Cavernas: o salão fundo; a pedra aqui não vê luz faz tanto tempo que brilha")
    ellipse(r, 25, 12, 24, 11)
    r.fill(1, 48, 20, 22)
    tunnel(r, 1, 7, 20)
    tunnel(r, 42, 48, 20)
    doors(r, 20, 20)
    r.fill(12, 16, 17, 17)
    r.fill(33, 37, 17, 17)
    r.fill(21, 28, 14, 15)
    plat(r, 17, 20, 15)
    plat(r, 29, 32, 15)
    mark(r, 25, 13, "i")
    return r


# --- Bosque Errante -----------------------------------------------------------

def troncos():
    r = sala("esp_troncos", 62, 25, "Bosque: as árvores são mais velhas que a estrada")
    ground(r, 22)
    doors(r, 22, 22)
    for x in range(10, 54, 13):
        r.fill(x, x + 3, 1, 16)
        plat(r, x - 4, x - 1, 19)
        plat(r, x + 4, x + 7, 19)
        plat(r, x - 4, x - 1, 16)
        plat(r, x + 4, x + 7, 16)
    return r


def clareira():
    r = sala("esp_clareira", 52, 19, "Bosque: a clareira; o deus parou aqui. Só aqui")
    heights = [16] * 52
    for x in range(52):
        d = abs(x - 26)
        heights[x] = 16 if d < 12 else (14 if d < 18 else 12)
    profile(r, heights)
    doors(r, 12, 12)
    mark(r, 26, 15, "L")
    plat(r, 20, 24, 12)
    plat(r, 28, 32, 12)
    return r


def raizes():
    r = sala("esp_raizes", 46, 12, "Bosque: por baixo das raízes", kind="corredor")
    ground(r, 9)
    doors(r, 9, 9)
    for x in (8, 15, 24, 33, 39):
        r.fill(x, x + 1, 1, 3 + (x % 2))
    for x in (12, 21, 29, 36):
        r.fill(x, x + 2, 8, 8)
    return r


def copa():
    r = sala("esp_copa", 58, 28, "Bosque: a copa; lá em cima ainda tem sol")
    ground(r, 25)
    doors(r, 25, 25)
    for i, y in enumerate((22, 19, 16, 13, 10, 7)):
        x = 8 + i * 7
        plat(r, x, x + 6, y)
        plat(r, 50 - i * 7 - 6, 50 - i * 7, y)
    plat(r, 22, 25, 8)
    plat(r, 26, 31, 7)
    mark(r, 28, 6, "i")
    return r


def trilha():
    r = sala("esp_trilha", 64, 16, "Bosque: a trilha; você já passou por essa pedra. Tem certeza?")
    heights = [int(11 + 2 * math.sin(x / 5.0) + math.sin(x / 2.3)) for x in range(64)]
    for x in range(0, 4):
        heights[x] = heights[4]
    for x in range(60, 64):
        heights[x] = heights[59]
    profile(r, heights)
    doors(r, heights[1], heights[62])
    for x in (20, 41):
        r.fill(x, x + 1, heights[x] - 3, heights[x] - 1)
    return r


ROOMS = {
    "necropole": [cemiterio, mausoleu, ossuario, cripta, procissao],
    "catedral": [nave, altar, coro, inundada, campanario],
    "ventre": [garganta, estomago, costelas, intestino, bexiga],
    "penhascos": [cume, nuvens, mirante, desfiladeiro, queda],
    "cavernas": [estalactites, galeria, poco, gruta, cristal],
    "bosque": [troncos, clareira, raizes, copa, trilha],
}


def build(biome):
    out, bad = [], 0
    rng = random.Random(sum(ord(c) * (i + 1) for i, c in enumerate(biome)))
    for make in ROOMS[biome]:
        r = make()
        populate(r, rng, hazard=r.kind != "corredor")
        rows = ["".join(row) for row in r.g]
        problems, warnings = check_rows(rows)
        if problems:
            bad += 1
            print("%s/%s:" % (biome, r.name))
            for p in problems[:4]:
                print("   ", p)
            print("\n".join("    " + row for row in rows))
        out.append(r)
    return out, bad


if __name__ == "__main__":
    total_bad = 0
    for biome in ROOMS:
        folder = os.path.join(ROOT, "content", "biomes", biome, "rooms")
        for f in os.listdir(folder):
            if f.startswith("esp_"):
                os.remove(os.path.join(folder, f))
        rooms, bad = build(biome)
        total_bad += bad
        for r in rooms:
            r.save(folder)
        print("%-10s %d salas, %d com problema" % (biome, len(rooms), bad))
    raise SystemExit(1 if total_bad else 0)
