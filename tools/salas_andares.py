"""Salas dos andares novos e das peças que todo andar tem.

    python tools/salas_andares.py

Gera:
  content/passagem.txt                      Vigia, altar de mutação, duas saídas
  content/biomes/<bioma>/rooms/*.txt         Forja Rubra e Salões (o conjunto todo)
  + em todos os biomas: saída com Porta do Relógio, loja, cofre (entra por
    parede rachada) e, onde houver runa, a sala da runa

Regras de quem desenha salas aqui:
  - pulo alcança ~3 blocos; agarrar a beirada sobe parede de 4;
  - porta lateral (L/R) tem 4 de altura e fica no chão;
  - desvio (tesouro, loja, cofre...) sai em 4 versões, uma para cada lado
    de porta, para o gerador sempre achar onde prender;
  - nicho só alcançável com pulo duplo: 6 blocos acima do chão mais próximo.
"""
import os

from salas_mar_de_cinzas import R

ROOT = os.path.join(os.path.dirname(__file__), "..")
CONTENT = os.path.join(ROOT, "content")


def branch_variants(name, kind, w, h, inside, head="", weight=10):
    """Um desvio em 4 versões: porta embaixo, em cima, à esquerda, à direita."""
    out = []
    for side in ("B", "T", "L", "R"):
        r = R("%s_%s" % (name, side.lower()), kind, w, h, weight=weight, head=head)
        if side == "B":
            r.door("B", w // 2 - 1, 3)
        elif side == "T":
            r.door("T", w // 2 - 1, 3)
            r.fill(w // 2 - 3, w // 2 + 3, 4, 4, "=")
        elif side == "L":
            r.door("L", h - 5, 4)
        else:
            r.door("R", h - 5, 4)
        inside(r)
        out.append(r)
    return out


def common(biome, rune):
    """Peças que todo andar tem (inclusive o Mar de Cinzas)."""
    out = []
    r = R("saida_relogio", "saida", 42, 14, head="A saída; atrás da Porta do Relógio, o que fica para quem tem pressa")
    r.door("L", 9, 4).fill(34, 34, 1, 9)
    r.put(10, 12, "L").put(26, 12, "X").put(34, 12, "T").put(37, 12, "c").put(39, 12, "i")
    r.fill(14, 18, 9, 9, "=")
    out.append(r)

    out += branch_variants("loja", "loja", 22, 11,
                           lambda r: r.put(9, 9, "$").put(5, 9, "L") if r.g[9][5] == "." else r.put(9, 9, "$"),
                           head="Um mercador que ninguém viu chegar")
    out += branch_variants("cofre", "cofre", 16, 10,
                           lambda r: r.put(5, 8, "c").put(10, 8, "i"),
                           head="Cofre emparedado: parede rachada na entrada")
    if rune:
        out += branch_variants("runa", "runa", 22, 12,
                               lambda r: r.put(11, 10, "U").put(16, 10, "E") if r.g[10][16] == "." else r.put(11, 10, "U"),
                               head="Onde a runa espera, há sempre alguém de guarda")
    return out


def floor_rooms(biome, hazard_rooms):
    """O conjunto de salas de um andar novo (mesma planta, biomas diferentes)."""
    out = []
    r = R("inicio", "inicio", 30, 14, head="Entrada do andar")
    r.door("R", 9, 4).fill(12, 16, 9, 9, "=").put(3, 12, "P").put(8, 12, "L").door("T", 13, 3)
    out.append(r)

    r = R("combate_ponte", "combate", 44, 16, head="Fosso no meio, pranchas por cima")
    r.fill(1, 15, 12, 14).fill(28, 42, 12, 14).door("L", 8, 4).door("R", 8, 4)
    r.fill(18, 20, 12, 12, "=").fill(24, 26, 12, 12, "=").fill(20, 23, 8, 8, "=").door("T", 20, 3)
    r.put(8, 11, "e").put(34, 11, "e").put(21, 7, "r")
    if hazard_rooms:
        r.put(22, 14, "w")
    out.append(r)

    r = R("combate_degraus", "combate", 40, 18, head="Degraus até o alto e descida do outro lado")
    r.door("L", 13, 4).door("R", 13, 4)
    for i, x in enumerate(range(10, 30, 4)):
        top = 16 - min(i, 4 - i) * 3 if i <= 4 else 16
        r.fill(x, x + 3, max(top, 7), 16)
    r.put(5, 16, "e").put(19, 9, "r").put(34, 16, "e").door("B", 36, 2).fill(36, 37, 16, 16, ".")
    out.append(r)

    r = R("combate_galeria", "combate", 50, 16, head="Galeria comprida; um nicho alto que só alcança quem voa")
    r.door("L", 11, 4).door("R", 11, 4)
    for x in (10, 42):
        r.fill(x, x + 1, 12, 14)
    r.fill(24, 29, 8, 8)                      # nicho: 7 acima do chão, longe dos pilares (pulo duplo)
    r.put(26, 7, "c")
    r.put(6, 14, "e").put(19, 14, "e").put(38, 14, "e").door("T", 45, 3)
    if hazard_rooms:
        r.put(30, 14, "w")
    out.append(r)

    r = R("combate_torre", "combate", 30, 26, head="Torre: entra embaixo, sai lá em cima")
    r.door("L", 20, 4).door("R", 3, 4).fill(22, 28, 7, 7).door("B", 10, 3).door("T", 3, 3)
    for i, (x0, y) in enumerate(((6, 21), (14, 18), (6, 15), (14, 12), (21, 9))):
        r.fill(x0, x0 + 5, y, y, "=")
    r.put(4, 24, "e").put(24, 24, "e").put(17, 17, "r").put(25, 6, "e")
    out.append(r)

    r = R("combate_fosso", "combate", 40, 20, head="Entra pelo alto e cai no fosso")
    r.door("L", 5, 4).door("R", 14, 4).fill(1, 12, 9, 18).fill(30, 38, 9, 13).door("T", 20, 3)
    r.fill(16, 20, 13, 13, "=").fill(24, 28, 10, 10, "=")
    r.put(6, 8, "e").put(18, 18, "e").put(26, 18, "e").put(34, 8, "r")
    if hazard_rooms:
        r.put(22, 18, "w")
    out.append(r)

    r = R("combate_cripta", "combate", 36, 14, weight=8, head="Cripta baixa com teto que pesa")
    r.door("L", 9, 4).door("R", 9, 4).fill(10, 25, 1, 4).fill(15, 20, 5, 6).door("B", 17, 2)
    r.fill(17, 18, 12, 12, ".")
    r.put(7, 12, "e").put(28, 12, "e").put(14, 12, "e")
    out.append(r)

    r = R("corredor_baixo", "corredor", 24, 10)
    r.door("L", 5, 4).door("R", 5, 4).fill(10, 13, 7, 8).put(5, 8, "L").door("T", 17, 3)
    out.append(r)

    r = R("corredor_rampa", "corredor", 26, 16, head="Rampa que desce")
    r.door("L", 3, 4).door("R", 11, 4).door("T", 18, 3)
    for i, x in enumerate(range(1, 21, 4)):
        r.fill(x, x + 3, 7 + i * 2, 14)
    out.append(r)

    r = R("elite_salao", "elite", 40, 16, head="Salão do guardião do andar")
    r.door("L", 11, 4).door("R", 11, 4).fill(8, 12, 10, 10, "=").fill(27, 31, 10, 10, "=")
    r.fill(17, 22, 7, 7, "=").put(20, 14, "E").put(19, 6, "i").door("T", 30, 3)
    out.append(r)

    out += branch_variants("tesouro", "tesouro", 18, 11, lambda r: r.put(6, 9, "i").put(11, 9, "c"))
    out += branch_variants("fragmento", "fragmento", 18, 11, lambda r: r.put(9, 9, "f"))
    return out


def passage():
    r = R("passagem", "passagem", 46, 14, head="A passagem entre dois domínios")
    r.fill(14, 18, 9, 9, "=").fill(27, 31, 9, 9, "=")
    r.put(3, 12, "P").put(10, 12, "V").put(22, 12, "M").put(36, 12, "X").put(42, 12, "X")
    return r


def save(rooms, folder, clear_prefixes=()):
    os.makedirs(folder, exist_ok=True)
    for f in os.listdir(folder):
        if f.endswith(".txt") and f.startswith(clear_prefixes):
            os.remove(os.path.join(folder, f))
    for r in rooms:
        r.save(folder)


if __name__ == "__main__":
    p = passage()
    p.save(CONTENT)
    os.replace(os.path.join(CONTENT, "passagem.txt"), os.path.join(CONTENT, "passagem.txt"))

    mar = os.path.join(CONTENT, "biomes", "mar_de_cinzas", "rooms")
    save(common("mar_de_cinzas", False), mar, ("saida_", "loja_", "cofre_", "runa_"))

    arena = R("arena", "chefe", 46, 18, head="Arena do guardião do andar")
    arena.fill(6, 11, 12, 12, "=").fill(34, 39, 12, 12, "=").fill(19, 26, 8, 8, "=")
    arena.put(4, 16, "P").put(30, 16, "B").put(40, 16, "X")
    arena.save(CONTENT)

    for biome, rune, hazard in (("forja_rubra", "punho", True), ("saloes", "asa", True),
                                ("torre_babel", "", True), ("jardim_primordial", "", True),
                                ("carcosa", "", True), ("observatorio", "", True)):
        folder = os.path.join(CONTENT, "biomes", biome, "rooms")
        save(floor_rooms(biome, hazard) + common(biome, rune), folder, ("",))
    print("ok")
