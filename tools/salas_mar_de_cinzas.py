"""Rascunho das salas do Mar de Cinzas.

As salas de verdade são os .txt em content/biomes/mar_de_cinzas/ — dá para
editar direto neles. Este script só existe para gerar a primeira versão com
retângulos (mais rápido do que desenhar caractere por caractere) e confere
que todo marcador está apoiado em chão.
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
BIOME = os.path.join(ROOT, "content", "biomes", "mar_de_cinzas")


class R:
    def __init__(s, name, kind, w, h, weight=10, head=""):
        s.name, s.kind, s.w, s.h, s.weight, s.head = name, kind, w, h, weight, head
        s.g = [["#" if x in (0, w - 1) or y in (0, h - 1) else "." for x in range(w)] for y in range(h)]

    def fill(s, x0, x1, y0, y1, ch="#"):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                s.g[y][x] = ch
        return s

    def door(s, side, start, size):
        for i in range(start, start + size):
            if side == "L": s.g[i][0] = "D"
            if side == "R": s.g[i][s.w - 1] = "D"
            if side == "T": s.g[0][i] = "D"
            if side == "B": s.g[s.h - 1][i] = "D"
        return s

    def put(s, x, y, ch):
        assert s.g[y][x] == ".", (s.name, x, y, s.g[y][x])
        assert s.g[y + 1][x] in "#=D", (s.name, "sem chão", x, y)
        s.g[y][x] = ch
        return s

    def save(s, folder):
        head = ["; " + s.head] if s.head else []
        lines = head + ["; tipo: " + s.kind, "; peso: %d" % s.weight] + ["".join(r) for r in s.g]
        with open(os.path.join(folder, s.name + ".txt"), "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines) + "\n")


def rooms():
    out = []
    r = R("inicio_portao", "inicio", 32, 14, head="O portão por onde os peregrinos entram no Mar de Cinzas")
    r.door("R", 9, 4).fill(13, 17, 9, 9, "=").fill(22, 24, 1, 3).put(3, 12, "P").put(9, 12, "L")
    out.append(r)

    r = R("combate_dunas", "combate", 40, 16, head="Duna com um bloco de arenito no meio (sobe agarrando a beirada)")
    r.door("L", 11, 4).door("R", 11, 4).fill(22, 27, 11, 14).fill(15, 19, 9, 9, "=")
    r.put(10, 14, "e").put(33, 14, "e").put(17, 8, "r")
    out.append(r)

    r = R("combate_escadaria", "combate", 44, 18, head="Escadaria até o terraço; poço no teto leva a um desvio")
    r.door("L", 13, 4).fill(26, 42, 11, 16).door("R", 7, 4).fill(18, 25, 14, 16)
    r.fill(36, 41, 8, 8, "=").fill(37, 41, 5, 5, "=").fill(37, 40, 2, 2, "=").door("T", 38, 3)
    r.fill(29, 34, 6, 6, "=").put(10, 16, "e").put(30, 10, "e").put(31, 5, "r")
    out.append(r)

    r = R("combate_poco", "combate", 36, 22, head="Borda alta e queda para o pátio de baixo")
    r.door("L", 6, 4).fill(1, 12, 10, 11).door("R", 17, 4).fill(14, 18, 15, 15, "=")
    r.put(6, 9, "r").put(20, 20, "e").put(30, 20, "e")
    out.append(r)

    r = R("combate_fortaleza", "combate", 48, 18, head="Muralha de uma Casa nobre: atiradores no adarve")
    r.door("L", 13, 4).door("R", 13, 4).fill(12, 35, 11, 11, "=").fill(11, 11, 11, 16).fill(36, 36, 11, 16)
    r.fill(20, 26, 8, 8, "=").fill(21, 25, 5, 5, "=").fill(22, 24, 2, 2, "=").door("T", 22, 3)
    r.put(16, 10, "r").put(31, 10, "r").put(24, 16, "e").put(42, 16, "e").put(5, 16, "e")
    out.append(r)

    r = R("combate_templo", "combate", 38, 16, head="Templo profético; o chão cede no meio (desvio para baixo)")
    r.door("L", 11, 4).door("R", 11, 4).door("B", 17, 3).fill(12, 13, 9, 14).fill(24, 25, 9, 14)
    r.fill(15, 22, 6, 6, "=").put(8, 14, "e").put(30, 14, "e").put(12, 8, "r")
    out.append(r)

    r = R("combate_vidro", "combate", 42, 14, weight=7, head="Campo de vidro: o chão estala antes de explodir")
    r.door("L", 9, 4).door("R", 9, 4).fill(14, 27, 8, 8, "=")
    r.put(12, 12, "w").put(20, 12, "w").put(28, 12, "w").put(34, 12, "e").put(20, 7, "r")
    out.append(r)

    r = R("corredor_colunas", "corredor", 28, 12, head="Colunata soterrada")
    r.door("L", 7, 4).door("R", 7, 4).fill(9, 10, 1, 5).fill(18, 19, 1, 4).put(14, 10, "L").put(22, 10, "e")
    out.append(r)

    r = R("corredor_desce", "corredor", 24, 20, head="Rampa que afunda na cinza")
    r.door("L", 3, 4).fill(1, 10, 7, 8).door("R", 15, 4).fill(14, 17, 13, 13, "=").put(18, 18, "e")
    out.append(r)

    r = R("elite_arena", "elite", 40, 16, head="Pátio de julgamento das Casas")
    r.door("L", 11, 4).door("R", 11, 4).fill(8, 12, 10, 10, "=").fill(27, 31, 10, 10, "=")
    r.put(20, 14, "E").put(3, 14, "L")
    out.append(r)

    r = R("tesouro_alto", "tesouro", 16, 12, head="Câmara acima do poço")
    r.door("B", 6, 3).put(11, 10, "i").put(3, 10, "i")
    out.append(r)

    r = R("tesouro_baixo", "tesouro", 18, 12, head="Cripta sob o templo")
    r.door("T", 7, 3).fill(3, 6, 8, 8, "=").fill(6, 10, 5, 5, "=").fill(6, 10, 2, 2, "=").put(14, 10, "i")
    out.append(r)

    r = R("tesouro_lado_esq", "tesouro", 18, 10)
    r.door("R", 5, 4).put(5, 8, "i")
    out.append(r)

    r = R("tesouro_lado_dir", "tesouro", 18, 10)
    r.door("L", 5, 4).put(12, 8, "i")
    out.append(r)

    r = R("fragmento_alto", "fragmento", 20, 12, head="Altar de um deus sem nome")
    r.door("B", 9, 3).put(15, 10, "f").put(4, 10, "L")
    out.append(r)

    r = R("fragmento_baixo", "fragmento", 20, 12)
    r.door("T", 8, 3).fill(3, 6, 8, 8, "=").fill(7, 11, 5, 5, "=").fill(7, 11, 2, 2, "=").put(15, 10, "f")
    out.append(r)

    r = R("fragmento_lado", "fragmento", 20, 12)
    r.door("L", 7, 4).put(14, 10, "f")
    out.append(r)

    r = R("saida_vigia", "saida", 34, 14, head="O posto da Vigia, à beira do Trono")
    r.door("L", 9, 4).fill(22, 30, 4, 4).put(8, 12, "L").put(15, 12, "V").put(27, 12, "X")
    out.append(r)
    return out


def throne():
    b = R("trono", "chefe", 44, 18, head="Sala do Trono do Imperador Cego")
    b.fill(6, 9, 12, 12, "=").fill(34, 37, 12, 12, "=").fill(19, 24, 1, 2)
    b.put(4, 16, "P").put(30, 16, "B").put(9, 16, "V").put(34, 16, "X").put(37, 16, "X").put(40, 16, "X")
    return b


if __name__ == "__main__":
    os.makedirs(os.path.join(BIOME, "rooms"), exist_ok=True)
    os.makedirs(os.path.join(BIOME, "chefe"), exist_ok=True)
    all_rooms = rooms()
    for r in all_rooms:
        r.save(os.path.join(BIOME, "rooms"))
    throne().save(os.path.join(BIOME, "chefe"))
    print(len(all_rooms), "salas + trono")
