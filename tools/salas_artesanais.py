"""Salas feitas à mão para os quatro domínios novos (Torre, Jardim, Carcosa e
Observatório): 6 por domínio, só de combate e corredor.

    python tools/salas_artesanais.py            grava as salas
    python tools/salas_artesanais.py --previa   grava e desenha tools/previews/*.png

Cada sala passa pelo verificador (validar_salas.py) e por uma conferência a
mais: de todo lugar onde o herói consegue pisar tem que dar para chegar a
alguma porta. O verificador só olha as portas; um fosso sem volta passaria.

Lembretes de medida (os mesmos do salas_andares.py):
  - pulo sobe 3 blocos (até 3 de lado); 1-2 blocos, até 4 de lado; agarrando
    a beirada de pedra, 4 blocos colado na parede;
  - no plano ou descendo, alcança 5 de lado (vão de até 4 vazios);
  - '=' se atravessa por baixo, então dá para empilhar sem bater a cabeça.
"""
import os
import sys
import zlib
from collections import deque

from salas_andares import top_ladders
from salas_mar_de_cinzas import R
from validar_salas import Room, check_rows, doors, door_entry, door_exit_ok

ROOT = os.path.join(os.path.dirname(__file__), "..")


def sala(name, w, h, head, kind="combate", weight=12):
    return R(name, kind, w, h, weight=weight, head=head)


def degraus(r, x, y, n, larg=3, lado=1, ch="#"):
    """Escada de lajes: cada degrau sobe 1 bloco e anda `larg` para o lado.
    (x, y) é a ponta do primeiro degrau, o mais baixo."""
    for i in range(n):
        x0 = x + i * larg if lado > 0 else x - i * larg - (larg - 1)
        r.fill(x0, x0 + larg - 1, y - i, y - i, ch)
    return r


def solo(r, x, y, ch):
    """Marcador no primeiro chão abaixo de (x, y)."""
    while r.g[y][x] != "." or r.g[y + 1][x] not in "#=":
        y += 1
    r.put(x, y, ch)
    return r


# ---------------------------------------------------------------- Torre de Babel

def torre():
    out = []

    r = sala("combate_escadaria_babel", 34, 26, "Torre: escadaria em lances, e a varanda quebrada lá no alto")
    r.door("L", 21, 4).door("R", 3, 4).door("B", 28, 3)
    degraus(r, 8, 22, 5)
    r.fill(26, 32, 18, 18)
    degraus(r, 26, 15, 6, lado=-1)
    r.fill(1, 8, 10, 10)
    r.fill(10, 14, 7, 7).fill(18, 21, 7, 7, "=").fill(25, 32, 7, 7)
    solo(r, 14, 20, "e")
    solo(r, 6, 20, "e")
    solo(r, 30, 10, "e")
    solo(r, 3, 1, "r")
    solo(r, 19, 1, "r")
    solo(r, 18, 21, "w")
    out.append(r)

    r = sala("combate_poco_babel", 22, 28, "Torre: o poço, com sacadas trocando de parede")
    r.door("L", 23, 4).door("R", 2, 4).door("T", 9, 3).door("B", 15, 3)
    for k, y in enumerate((24, 21, 18, 15, 12, 9, 6, 3)):
        if k % 2 == 0:
            r.fill(12, 20, y, y)
        else:
            r.fill(1, 9, y, y)
    solo(r, 5, 22, "w")
    solo(r, 18, 20, "e")
    solo(r, 4, 13, "e")
    solo(r, 16, 10, "r")
    solo(r, 5, 7, "r")
    solo(r, 4, 1, "L")
    out.append(r)

    r = sala("combate_andaimes_babel", 46, 18, "Torre: andaimes sobre o vão; pedras soltas na viga")
    r.door("L", 10, 4).door("R", 10, 4).door("T", 21, 3)
    r.fill(1, 13, 14, 16).fill(32, 44, 14, 16)
    r.fill(15, 19, 12, 12, "=").fill(21, 25, 10, 10, "=").fill(27, 30, 12, 12, "=")
    r.fill(14, 31, 3, 3)
    r.fill(35, 38, 11, 11, "=").fill(33, 36, 8, 8, "=").fill(32, 34, 5, 5, "=")
    r.fill(8, 9, 1, 6)
    solo(r, 5, 9, "e")
    solo(r, 20, 13, "e")
    solo(r, 40, 9, "e")
    solo(r, 18, 1, "r")
    solo(r, 23, 4, "w")
    out.append(r)

    r = sala("combate_descida_babel", 36, 24, "Torre: entra pelo alto e desce pelos andaimes")
    r.door("L", 3, 4).door("R", 19, 4).door("T", 26, 3)
    r.fill(1, 8, 7, 7)
    r.fill(16, 19, 8, 22)
    r.fill(11, 13, 8, 8, "=")
    for y, x0 in ((20, 3), (17, 9), (14, 3), (11, 9)):
        r.fill(x0, x0 + 3, y, y, "=")
    for y, x0 in ((20, 21), (17, 25), (14, 21), (11, 21)):
        r.fill(x0, x0 + 3, y, y, "=")
    r.fill(21, 24, 5, 5, "=").fill(25, 28, 3, 3, "=")
    solo(r, 4, 1, "L")
    solo(r, 8, 15, "e")
    solo(r, 28, 18, "e")
    solo(r, 17, 1, "r")
    solo(r, 31, 18, "w")
    out.append(r)

    r = sala("combate_biblioteca_babel", 40, 16, "Torre: a sala dos escribas, estantes e mezanino")
    r.door("L", 11, 4).door("R", 11, 4).door("B", 34, 3).door("T", 14, 3)
    r.fill(8, 10, 12, 14).fill(18, 20, 11, 14).fill(29, 31, 12, 14)
    r.fill(12, 17, 8, 8, "=").fill(22, 27, 8, 8, "=")
    r.fill(18, 21, 5, 5, "=").fill(14, 17, 3, 3, "=")
    solo(r, 3, 10, "L")
    solo(r, 23, 10, "e")
    solo(r, 33, 10, "e")
    solo(r, 13, 1, "r")
    solo(r, 26, 1, "r")
    solo(r, 14, 10, "w")
    out.append(r)

    r = sala("corredor_escada_babel", 30, 14, "Torre: escada apertada entre duas paredes", kind="corredor")
    r.door("L", 9, 4).door("R", 2, 4)
    for i in range(6):
        x0, y = 6 + i * 3, 12 - i
        r.fill(x0, x0 + 2, y, 12)
        if y - 5 >= 1:
            r.fill(x0, x0 + 2, 1, y - 5)
    r.fill(24, 28, 6, 12)
    solo(r, 13, 1, "e")
    solo(r, 22, 1, "e")
    solo(r, 19, 1, "w")
    out.append(r)
    return out


# ---------------------------------------------------------------- Jardim Primordial

def jardim():
    out = []

    r = sala("combate_raizes_jardim", 48, 18, "Jardim: chão torto, raízes por cima dos buracos")
    r.door("L", 10, 4).door("R", 10, 4).door("T", 25, 3)
    for x0, x1, top in ((1, 6, 14), (7, 10, 13), (11, 12, 14), (21, 26, 13), (27, 29, 12),
                        (30, 31, 13), (37, 41, 14), (42, 46, 14)):
        r.fill(x0, x1, top, 16)
    r.fill(13, 15, 13, 13, "=").fill(16, 17, 14, 14, "=").fill(18, 20, 13, 13, "=")
    r.fill(33, 35, 10, 10)
    r.fill(23, 26, 8, 8)
    r.fill(19, 22, 5, 5, "=").fill(24, 27, 3, 3, "=")
    solo(r, 9, 5, "w")
    solo(r, 40, 5, "w")
    solo(r, 4, 5, "e")
    solo(r, 24, 9, "e")
    solo(r, 44, 5, "e")
    solo(r, 25, 4, "r")
    out.append(r)

    r = sala("combate_cova_jardim", 40, 22, "Jardim: a cova coberta de musgo, com um torrão suspenso")
    r.door("L", 5, 4).door("R", 9, 4).door("B", 20, 3)
    r.fill(1, 8, 9, 20).fill(9, 12, 12, 20).fill(13, 15, 15, 20)
    r.fill(28, 31, 16, 20).fill(32, 38, 13, 20)
    r.fill(16, 18, 18, 18, "=").fill(25, 27, 18, 18, "=")
    r.fill(17, 19, 12, 12, "=")
    r.fill(18, 22, 9, 9)
    solo(r, 20, 1, "i")
    solo(r, 10, 1, "e")
    solo(r, 17, 19, "e")
    solo(r, 35, 1, "e")
    solo(r, 29, 1, "r")
    solo(r, 24, 19, "w")
    out.append(r)

    r = sala("combate_pontes_jardim", 50, 20, "Jardim: pontes de raiz entre montes de terra")
    r.door("L", 6, 4).door("R", 6, 4).door("B", 24, 3)
    r.fill(1, 7, 10, 18).fill(16, 20, 11, 18).fill(30, 33, 9, 18).fill(42, 48, 10, 18)
    r.fill(8, 9, 11, 11, "=").fill(10, 13, 12, 12, "=").fill(14, 15, 11, 11, "=")
    r.fill(21, 22, 12, 12, "=").fill(23, 27, 13, 13, "=").fill(28, 29, 12, 12, "=")
    r.fill(34, 35, 10, 10, "=").fill(36, 39, 11, 11, "=").fill(40, 41, 10, 10, "=")
    r.fill(8, 10, 16, 16, "=").fill(11, 13, 14, 14)
    r.fill(26, 28, 16, 16, "=").fill(21, 23, 15, 15, "=")
    r.fill(38, 40, 16, 16, "=").fill(40, 41, 13, 13)
    solo(r, 4, 1, "e")
    solo(r, 18, 1, "e")
    solo(r, 31, 1, "r")
    solo(r, 45, 1, "e")
    solo(r, 22, 17, "w")
    solo(r, 36, 17, "w")
    out.append(r)

    r = sala("combate_torroes_jardim", 44, 20, "Jardim: torrões pendurados por cipós")
    r.door("L", 15, 4).door("R", 13, 4).door("T", 30, 3)
    for x0, x1, top in ((6, 9, 18), (14, 17, 17), (18, 22, 18), (27, 30, 18), (34, 42, 17)):
        r.fill(x0, x1, top, 18)
    r.fill(26, 28, 11, 11, "=")
    r.fill(10, 14, 14, 14).fill(20, 24, 11, 11).fill(30, 34, 14, 14)
    r.fill(26, 28, 8, 8, "=").fill(29, 32, 5, 5, "=").fill(27, 30, 3, 3, "=")
    solo(r, 12, 1, "r")
    solo(r, 22, 1, "i")
    solo(r, 4, 1, "e")
    solo(r, 25, 1, "e")
    solo(r, 38, 1, "e")
    solo(r, 16, 1, "w")
    out.append(r)

    r = sala("combate_tronco_jardim", 46, 16, "Jardim: o tronco caído e oco; dá para ir por dentro ou por cima")
    r.door("L", 11, 4).door("R", 11, 4)
    r.fill(10, 36, 6, 7).fill(10, 36, 12, 12)
    r.fill(22, 24, 6, 7, ".")
    r.fill(22, 24, 9, 9, "=")
    r.fill(5, 7, 12, 12, "=").fill(7, 9, 9, 9, "=")
    r.fill(38, 40, 12, 12, "=").fill(37, 39, 9, 9, "=")
    solo(r, 4, 1, "e")
    solo(r, 16, 8, "e")
    solo(r, 30, 8, "w")
    solo(r, 41, 13, "e")
    solo(r, 14, 1, "r")
    solo(r, 33, 1, "L")
    out.append(r)

    r = sala("corredor_charco_jardim", 32, 12, "Jardim: trilha encharcada, um buraco com raiz por cima", kind="corredor")
    r.door("L", 6, 4).door("R", 5, 4)
    for x0, x1, top in ((1, 7, 10), (8, 11, 9), (17, 22, 10), (23, 26, 9), (27, 30, 9)):
        r.fill(x0, x1, top, 10)
    r.fill(12, 16, 9, 9, "=")
    r.fill(9, 12, 1, 3).fill(20, 22, 1, 4)
    solo(r, 5, 1, "e")
    solo(r, 24, 1, "e")
    solo(r, 14, 10, "w")
    out.append(r)
    return out


# ---------------------------------------------------------------- Carcosa

def carcosa():
    out = []

    r = sala("combate_telhados_carcosa", 48, 20, "Carcosa: sobe da rua pelos toldos e corre pelos telhados")
    r.door("L", 15, 4).door("R", 5, 4).door("T", 42, 3)
    r.fill(8, 14, 13, 18).fill(17, 23, 10, 18).fill(28, 33, 12, 18).fill(37, 46, 9, 18)
    r.fill(4, 7, 16, 16, "=")
    r.fill(15, 16, 16, 16, "=").fill(15, 16, 13, 13, "=")
    r.fill(24, 26, 16, 16, "=").fill(25, 27, 13, 13, "=")
    r.fill(34, 36, 16, 16, "=").fill(35, 36, 13, 13, "=").fill(34, 35, 11, 11, "=")
    r.fill(37, 39, 6, 6, "=").fill(41, 44, 3, 3, "=")
    solo(r, 6, 17, "e")
    solo(r, 20, 1, "e")
    solo(r, 31, 1, "e")
    solo(r, 11, 1, "r")
    solo(r, 43, 4, "r")
    solo(r, 26, 17, "w")
    solo(r, 39, 7, "L")
    out.append(r)

    r = sala("combate_beco_carcosa", 36, 18, "Carcosa: beco que dobra a esquina duas vezes")
    r.door("L", 13, 4).door("R", 3, 4).door("B", 18, 3)
    r.fill(1, 28, 12, 12)
    r.fill(7, 34, 7, 7)
    r.fill(31, 34, 14, 14, "=").fill(2, 4, 9, 9, "=")
    solo(r, 26, 13, "e")
    solo(r, 9, 8, "e")
    solo(r, 24, 8, "e")
    solo(r, 20, 1, "r")
    solo(r, 15, 13, "w")
    out.append(r)

    r = sala("combate_arcos_carcosa", 46, 16, "Carcosa: rua sob os arcos, passadiço por cima")
    r.door("L", 11, 4).door("R", 11, 4).door("B", 30, 3)
    r.fill(6, 18, 8, 8).fill(24, 40, 8, 8)
    for x in (6, 12, 24, 30, 36):
        r.fill(x, x + 1, 9, 10)
    r.fill(17, 18, 9, 10)
    r.fill(19, 23, 13, 14)
    r.fill(20, 22, 10, 10, "=")
    r.fill(10, 15, 4, 7)
    solo(r, 8, 11, "e")
    solo(r, 36, 11, "e")
    solo(r, 33, 1, "e")
    solo(r, 12, 1, "r")
    solo(r, 26, 11, "w")
    out.append(r)

    r = sala("combate_praca_carcosa", 42, 24, "Carcosa: a praça do sino, onde o Arauto anuncia o rei")
    r.door("L", 10, 4).door("R", 8, 4).door("T", 21, 3)
    r.fill(1, 8, 14, 22).fill(34, 40, 12, 22)
    r.fill(19, 22, 9, 22)
    for y in (20, 17):
        r.fill(15, 18, y, y, "=").fill(23, 26, y, y, "=")
    r.fill(10, 18, 14, 14, "=").fill(23, 26, 14, 14, "=")
    r.fill(15, 18, 11, 11, "=").fill(23, 33, 11, 11, "=")
    r.fill(16, 18, 6, 6, "=").fill(20, 23, 3, 3, "=")
    solo(r, 12, 15, "e")
    solo(r, 29, 15, "e")
    solo(r, 20, 4, "e")
    solo(r, 11, 12, "r")
    solo(r, 37, 1, "r")
    solo(r, 14, 15, "L")
    solo(r, 26, 15, "w")
    out.append(r)

    r = sala("combate_muralha_carcosa", 44, 18, "Carcosa: o portão da muralha; arqueiros no alto")
    r.door("L", 13, 4).door("R", 13, 4).door("T", 20, 3)
    r.fill(18, 25, 3, 11)
    r.fill(13, 16, 14, 14, "=").fill(9, 12, 11, 11, "=").fill(13, 16, 8, 8, "=").fill(15, 17, 5, 5, "=")
    r.fill(32, 36, 13, 13, "=")
    solo(r, 8, 13, "e")
    solo(r, 30, 13, "e")
    solo(r, 38, 13, "e")
    solo(r, 19, 1, "r")
    solo(r, 24, 1, "r")
    solo(r, 34, 1, "r")
    solo(r, 22, 13, "w")
    out.append(r)

    r = sala("corredor_viela_carcosa", 34, 12, "Carcosa: viela de arcos baixos; sempre tem alguém do outro lado", kind="corredor")
    r.door("L", 6, 4).door("R", 6, 4)
    r.fill(8, 10, 1, 5).fill(18, 20, 1, 4).fill(26, 28, 1, 5)
    r.fill(13, 15, 9, 10)
    solo(r, 12, 1, "e")
    solo(r, 30, 1, "e")
    solo(r, 22, 1, "w")
    out.append(r)
    return out


# ---------------------------------------------------------------- Observatório

def observatorio():
    out = []

    r = sala("combate_cupula_observatorio", 56, 24, "Observatório: a cúpula grande, a luneta no meio")
    r.door("L", 18, 4).door("R", 18, 4).door("T", 27, 3)
    for y, larg in enumerate((18, 14, 11, 8, 6, 4, 3, 2, 1), start=1):
        r.fill(1, larg, y, y).fill(54 - larg + 1, 54, y, y)
    r.fill(25, 30, 17, 22)
    r.fill(10, 14, 20, 20, "=").fill(16, 20, 17, 17, "=")
    r.fill(41, 45, 20, 20, "=").fill(35, 39, 17, 17, "=")
    r.fill(21, 24, 14, 14, "=").fill(31, 34, 14, 14, "=")
    r.fill(15, 19, 11, 11, "=").fill(36, 40, 11, 11, "=")
    r.fill(21, 25, 8, 8, "=").fill(30, 34, 8, 8, "=")
    r.fill(26, 29, 5, 5, "=").fill(23, 26, 3, 3, "=")
    solo(r, 27, 10, "L")
    solo(r, 20, 21, "e")
    solo(r, 38, 21, "e")
    solo(r, 49, 21, "e")
    solo(r, 17, 9, "r")
    solo(r, 38, 9, "r")
    solo(r, 33, 21, "w")
    solo(r, 24, 1, "i")
    out.append(r)

    r = sala("combate_ilhas_observatorio", 52, 20, "Observatório: ilhas de pedra soltas no vazio")
    r.door("L", 6, 4).door("R", 6, 4).door("B", 24, 3)
    r.fill(1, 7, 10, 18).fill(43, 50, 10, 18)
    r.fill(11, 15, 11, 12).fill(19, 23, 9, 10).fill(27, 31, 12, 13).fill(35, 39, 10, 11)
    r.fill(16, 18, 16, 16, "=").fill(16, 18, 13, 13, "=")
    r.fill(32, 34, 16, 16, "=").fill(33, 34, 13, 13, "=")
    solo(r, 21, 1, "r")
    solo(r, 29, 1, "e")
    solo(r, 37, 1, "w")
    solo(r, 10, 15, "e")
    solo(r, 40, 15, "e")
    out.append(r)

    r = sala("combate_luneta_observatorio", 34, 26, "Observatório: subindo pelo cano da luneta")
    r.door("L", 20, 4).door("R", 7, 4).door("B", 24, 3)
    for i in range(14):
        if i == 7:
            continue
        x0, y = 4 + 2 * i, 24 - i
        r.fill(x0, x0 + 1, y, min(y + 1, 24))
    r.fill(30, 32, 11, 12)
    r.fill(17, 20, 21, 21, "=")
    solo(r, 12, 1, "e")
    solo(r, 24, 1, "e")
    solo(r, 28, 1, "r")
    solo(r, 14, 22, "e")
    solo(r, 27, 22, "w")
    out.append(r)

    r = sala("combate_orbita_observatorio", 50, 20, "Observatório: astros de pedra girando parados no ar")
    r.door("L", 14, 4).door("R", 14, 4).door("T", 23, 3)
    for x0, y0 in ((9, 14), (18, 11), (28, 13), (38, 10)):
        r.fill(x0 + 1, x0 + 3, y0, y0).fill(x0, x0 + 4, y0 + 1, y0 + 1).fill(x0 + 1, x0 + 3, y0 + 2, y0 + 2)
    r.fill(4, 7, 16, 16, "=").fill(14, 17, 13, 13, "=").fill(23, 27, 13, 13, "=")
    r.fill(33, 36, 12, 12, "=").fill(43, 46, 15, 15, "=")
    r.fill(20, 23, 8, 8, "=").fill(23, 26, 5, 5, "=").fill(19, 22, 3, 3, "=")
    solo(r, 11, 1, "r")
    solo(r, 40, 1, "r")
    solo(r, 6, 17, "e")
    solo(r, 25, 17, "e")
    solo(r, 44, 17, "e")
    solo(r, 30, 1, "w")
    out.append(r)

    r = sala("combate_ponte_observatorio", 54, 14, "Observatório: a ponte dos astrônomos, com vãos")
    r.door("L", 5, 4).door("R", 5, 4).door("B", 33, 3)
    r.fill(1, 52, 9, 9)
    for x0 in (11, 20, 30, 41):
        r.fill(x0, x0 + 2, 9, 9, ".")
    r.fill(24, 28, 5, 5, "=")
    solo(r, 7, 1, "e")
    solo(r, 26, 1, "r")
    solo(r, 37, 1, "e")
    solo(r, 17, 1, "w")
    solo(r, 22, 11, "e")
    solo(r, 47, 1, "L")
    out.append(r)

    r = sala("corredor_galeria_observatorio", 36, 12, "Observatório: galeria baixa com uma fresta no chão", kind="corredor")
    r.door("L", 5, 4).door("R", 5, 4)
    r.fill(1, 34, 9, 10)
    r.fill(14, 20, 9, 10, ".")
    r.fill(16, 18, 7, 7, "=")
    r.fill(6, 9, 1, 2).fill(26, 29, 1, 2)
    solo(r, 8, 1, "e")
    solo(r, 27, 1, "e")
    solo(r, 17, 9, "w")
    out.append(r)
    return out


DOMAINS = {"torre_babel": torre, "jardim_primordial": jardim,
           "carcosa": carcosa, "observatorio": observatorio}


def presos(rows):
    """Lugares onde o herói pisa e de onde nenhuma porta se alcança."""
    room = Room(rows)
    ds = doors(room)
    starts = [p for side, run in ds for p in door_entry(room, side, run)]
    seen = set(starts)
    todo = deque(starts)
    edges = {}
    while todo:
        p = todo.popleft()
        edges[p] = room.moves(*p)
        for q in edges[p]:
            if q not in seen:
                seen.add(q)
                todo.append(q)
    back = {}
    for p, qs in edges.items():
        for q in qs:
            back.setdefault(q, []).append(p)
    ok = {p for p in seen if any(door_exit_ok(room, side, run, {p}) for side, run in ds)}
    todo = deque(ok)
    while todo:
        q = todo.popleft()
        for p in back.get(q, []):
            if p not in ok:
                ok.add(p)
                todo.append(p)
    return sorted(seen - ok)


def _ok(rows):
    problems, warnings = check_rows(rows)
    return not problems and not warnings and not presos(rows)


def _perto_de_porta(rows, x, y, folga=2):
    for yy in range(max(y - folga, 0), min(y + folga + 1, len(rows))):
        for xx in range(max(x - folga, 0), min(x + folga + 1, len(rows[0]))):
            if rows[yy][xx] == "D":
                return True
    return False


def organico(rows, seed):
    """Jardim: o chão ganha calombos e o teto solta raízes. Cada mudança só
    fica se a sala continuar jogável."""
    import random
    rnd = random.Random(seed)
    g = [list(r) for r in rows]
    h, w = len(g), len(g[0])
    cand = []
    for x in range(2, w - 2):
        for y in range(2, h - 1):
            # chão: ar em cima (3 livres) e pedra embaixo
            if g[y][x] == "." and g[y + 1][x] == "#" and all(g[y - k][x] == "." for k in (1, 2, 3)):
                cand.append(("calombo", x, y))
            # teto: pedra em cima, 4 livres embaixo
            if g[y][x] == "." and g[y - 1][x] == "#" and y + 4 < h and all(g[y + k][x] == "." for k in (1, 2, 3, 4)):
                cand.append(("raiz", x, y))
    rnd.shuffle(cand)
    feitos = 0
    for kind, x, y in cand:
        if feitos >= max(6, w // 4):
            break
        if _perto_de_porta(g, x, y, 3):
            continue
        cells = [(x, y)] if kind == "calombo" else [(x, y + k) for k in range(rnd.choice((1, 1, 2)))]
        if any(g[cy][cx] != "." for cx, cy in cells):
            continue
        for cx, cy in cells:
            g[cy][cx] = "#"
        if _ok(["".join(r) for r in g]):
            feitos += 1
        else:
            for cx, cy in cells:
                g[cy][cx] = "."
    return ["".join(r) for r in g]


def nicho_secreto(rows, premio="i"):
    """Um nicho cavado na rocha ao lado do chão, atrás de uma parede falsa
    (F): quem bate na parede certa acha o prêmio."""
    g = [list(r) for r in rows]
    h, w = len(g), len(g[0])
    for y in range(h - 3, 2, -1):
        for x in range(2, w - 6):
            for lado in (1, -1):
                f, a, fundo = x + lado, x + 2 * lado, x + 3 * lado
                if not (1 <= f < w - 1 and 1 <= a < w - 1 and 0 <= fundo < w):
                    continue
                if g[y][x] != "." or g[y - 1][x] != "." or g[y + 1][x] not in "#=":
                    continue
                if not all(g[yy][c] == "#" for c in (f, a) for yy in (y - 2, y - 1, y, y + 1)):
                    continue
                if g[y][fundo] != "#" or g[y - 1][fundo] != "#":
                    continue
                if _perto_de_porta(g, x, y, 3):
                    continue
                for yy in (y - 1, y):
                    g[yy][f] = "F"
                    g[yy][a] = "."
                g[y][a] = premio
                novo = ["".join(r) for r in g]
                if _ok(novo):
                    return novo
                g = [list(r) for r in rows]
    # sem rocha dos lados: um poço escondido no chão, coberto pela parede falsa
    for y in range(2, h - 5):
        for x in range(3, w - 3):
            if g[y][x] != "." or g[y - 1][x] != "." or g[y + 1][x] != "#":
                continue
            if not all(g[yy][xx] == "#" for xx in (x - 1, x, x + 1) for yy in (y + 1, y + 2, y + 3, y + 4)):
                continue
            if _perto_de_porta(g, x, y, 3) or any(g[y][xx] not in ".#" for xx in (x - 1, x + 1)):
                continue
            g[y + 1][x] = "F"
            g[y + 2][x] = "."
            g[y + 3][x] = premio
            novo = ["".join(r) for r in g]
            if _ok(novo):
                return novo
            g = [list(r) for r in rows]
    return rows


SEGREDOS_POR_DOMINIO = 2
PREMIOS = ["i", "L"]


def previa(rows, path):
    import numpy as np
    from PIL import Image

    cores = {"F": (120, 90, 140), "#": (70, 64, 60), "=": (170, 140, 90), "D": (90, 200, 120), "e": (220, 60, 60),
             "r": (240, 150, 40), "w": (180, 80, 220), "L": (80, 160, 240), "i": (250, 230, 80)}
    img = np.zeros((len(rows), len(rows[0]), 3), dtype=np.uint8)
    img[:] = (22, 22, 30)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in cores:
                img[y, x] = cores[ch]
    Image.fromarray(img).resize((img.shape[1] * 12, img.shape[0] * 12), Image.NEAREST).save(path)


if __name__ == "__main__":
    desenhar = "--previa" in sys.argv
    pasta_previa = os.path.join(ROOT, "tools", "previews")
    if desenhar:
        os.makedirs(pasta_previa, exist_ok=True)
    ruins = 0
    for bid, plantas in DOMAINS.items():
        folder = os.path.join(ROOT, "content", "biomes", bid, "rooms")
        segredos = 0
        for r in plantas():
            rows = ["".join(row) for row in r.g]
            if any(p for p in check_rows(rows)[0] if "porta T" in p):
                top_ladders(r)
                rows = ["".join(row) for row in r.g]
            if bid == "jardim_primordial":
                rows = organico(rows, zlib.crc32(r.name.encode()))
            if segredos < SEGREDOS_POR_DOMINIO and r.kind == "combate":
                antes = rows
                rows = nicho_secreto(rows, PREMIOS[segredos])
                if rows != antes:
                    segredos += 1
                    print("  %s/%s: nicho secreto (%s)" % (bid, r.name, PREMIOS[segredos - 1]))
            r.g = [list(row) for row in rows]
            problems, warnings = check_rows(rows)
            problems += warnings
            soltos = presos(rows)
            if soltos:
                problems.append("sem volta a nenhuma porta: %s" % soltos[:6])
            for p in problems:
                print("  %s/%s: %s" % (bid, r.name, p))
            ruins += 1 if problems else 0
            r.save(folder)
            if desenhar:
                previa(rows, os.path.join(pasta_previa, "%s_%s.png" % (bid, r.name)))
    print("%d salas com problema" % ruins)
