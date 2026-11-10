# Relatório do robô

8 partidas · brasas 0 · reflexo 0.75 · semente inicial 1000 · 461 s de relógio

O robô joga com o jogo de verdade, sem tela. Ele não joga como gente: anda pelo caminho mais curto, reage a 75% dos avisos e não aprende. Os números servem para **comparar** andares, chefes e inimigos entre si, não para dizer se o jogo está fácil para uma pessoa.

**Vitórias:** 0 de 8

## Por andar

| Andar | Vezes | Morreu aqui | Tempo médio | Vida perdida (média) | Frascos (média) | Abates (média) | Preso | Quem mais machucou |
|---|---|---|---|---|---|---|---|---|
| mar_de_cinzas | 8 | 2 (25%) | 3:18 | 135 | 0.8 | 6.3 | 16 | ATIRADOR DE VIDRO 333, GUARDA DA CASA 320, ESPINHO DE VIDRO 177 |
| mar_de_cinzas (passagem) | 5 | 0 (0%) | 0:07 | 0 | 0.0 | 18.2 | 0 |  |
| forja_rubra | 5 | 4 (80%) | 2:19 | 139 | 0.8 | 8.2 | 21 | ATIRADOR DE VIDRO 479, QUEIMADURA 80, ESCÓRIA VIVA 36 |
| colosso | 1 | 1 (100%) | 0:10 | 60 | 0.0 | 0.0 | 0 | O COLOSSO DA BIGORNA 36, QUEIMADURA 24 |

## Quem mais matou

- ATIRADOR DE VIDRO: 3
- ESPINHO DE VIDRO: 2
- GUARDA DA CASA: 1
- O COLOSSO DA BIGORNA: 1

## Quem mais tirou vida (todas as partidas)

- ATIRADOR DE VIDRO: 812
- GUARDA DA CASA: 349
- ESPINHO DE VIDRO: 177
- QUEIMADURA: 148
- INQUISIDOR PROFETA: 106
- PEREGRINO CINZENTO: 66
- ASSASSINO DA DUNA: 36
- ESCÓRIA VIVA: 36
- O COLOSSO DA BIGORNA: 36
- FERREIRO CATIVO: 31
- PENITENTE: 18
- ?: 14
- ESCÓRIA DERRETIDA: 10

## Partidas

| # | Semente | Resultado | Onde | Tempo | Morto por | Caminho |
|---|---|---|---|---|---|---|
| 1 | 1000 | morte | forja_rubra | 3:18 | GUARDA DA CASA | mar_de_cinzas > forja_rubra |
| 2 | 1001 | morte | forja_rubra | 5:02 | ATIRADOR DE VIDRO | mar_de_cinzas > forja_rubra |
| 3 | 1002 | morte | colosso | 5:51 | O COLOSSO DA BIGORNA | mar_de_cinzas > forja_rubra > colosso |
| 4 | 1003 | morte | mar_de_cinzas | 3:36 | ESPINHO DE VIDRO | mar_de_cinzas |
| 5 | 1004 | morte | mar_de_cinzas | 1:17 | ESPINHO DE VIDRO | mar_de_cinzas |
| 6 | 1005 | tempo esgotado | mar_de_cinzas | 7:00 |  | mar_de_cinzas |
| 7 | 1006 | morte | forja_rubra | 5:52 | ATIRADOR DE VIDRO | mar_de_cinzas > forja_rubra |
| 8 | 1007 | morte | forja_rubra | 6:54 | ATIRADOR DE VIDRO | mar_de_cinzas > forja_rubra |

## Onde o robô ficou preso

Cada linha é um ponto em que ele não conseguiu seguir o caminho por 11 s e foi empurrado para a frente. Muitos no mesmo andar podem ser sala ruim ou só o robô.

- semente 1000, mar_de_cinzas: (36, 32) combate_dunas, (68, 32) combate_dunas, (149, 17) combate_templo
- semente 1001, mar_de_cinzas: (46, 65) combate_dunas
- semente 1001, forja_rubra: (26, 94) inicio, (19, 94) inicio, (40, 94) combate_ponte, (43, 94) combate_ponte, (39, 88) combate_ponte
- semente 1002, mar_de_cinzas: (83, 48) dom_varandas_2
- semente 1002, forja_rubra: (66, 52) combate_torre, (168, 71) dom_pilares_6, (176, 71) dom_pilares_6
- semente 1003, mar_de_cinzas: (49, 49) combate_poco
- semente 1004, mar_de_cinzas: (50, 64) dom_fossos_1
- semente 1005, mar_de_cinzas: (36, 43) dom_vertical_6, (72, 27) combate_dunas
- semente 1006, mar_de_cinzas: (51, 28) dom_vertical_3, (92, 31) dom_vertical_3, (92, 31) dom_vertical_3, (87, 28) dom_vertical_3, (101, 21) dom_vertical_3, (132, 19) dom_terracos_5
- semente 1006, forja_rubra: (53, 49) combate_fosso, (119, 36) combate_galeria
- semente 1007, mar_de_cinzas: (68, 22) dom_vertical_3
- semente 1007, forja_rubra: (72, 32) inicio, (82, 32) combate_degraus, (82, 32) combate_degraus, (78, 32) combate_degraus, (83, 32) combate_degraus, (78, 32) combate_degraus, (78, 32) combate_degraus, (82, 32) combate_degraus, (111, 35) combate_galeria, (116, 42) combate_torre, (187, 65) tesouro_t

### Salas onde ele prende (em quantas partidas)

- combate_dunas: 3
- inicio: 2
- combate_torre: 2
- dom_vertical_3: 2
- combate_galeria: 2
- combate_templo: 1
- combate_ponte: 1
- dom_varandas_2: 1
- dom_pilares_6: 1
- combate_poco: 1
- dom_fossos_1: 1
- dom_vertical_6: 1
- dom_terracos_5: 1
- combate_fosso: 1
- combate_degraus: 1
- tesouro_t: 1
