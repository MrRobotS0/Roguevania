# Relatório do robô

8 partidas · brasas 0 · reflexo 0.75 · semente inicial 1000 · 555 s de relógio

O robô joga com o jogo de verdade, sem tela. Ele não joga como gente: anda pelo caminho mais curto, reage a 75% dos avisos e não aprende. Os números servem para **comparar** andares, chefes e inimigos entre si, não para dizer se o jogo está fácil para uma pessoa.

**Vitórias:** 0 de 8

## Por andar

| Andar | Vezes | Morreu aqui | Tempo médio | Vida perdida (média) | Frascos (média) | Abates (média) | Preso | Quem mais machucou |
|---|---|---|---|---|---|---|---|---|
| mar_de_cinzas | 8 | 1 (13%) | 4:59 | 137 | 0.9 | 9.0 | 29 | ATIRADOR DE VIDRO 432, GUARDA DA CASA 160, ESPINHO DE VIDRO 159 |
| mar_de_cinzas (passagem) | 4 | 0 (0%) | 0:07 | 0 | 0.0 | 20.3 | 0 |  |
| saloes | 2 | 1 (50%) | 3:59 | 116 | 0.5 | 8.0 | 18 | SENTINELA DE GELO 88, GUARDA DA CASA 50, ? 40 |
| forja_rubra | 2 | 2 (100%) | 1:03 | 75 | 0.0 | 6.0 | 3 | ATIRADOR DE VIDRO 48, FERREIRO CATIVO 35, GUARDA DA CASA 32 |

## Quem mais matou

- GUARDA DA CASA: 2
- FERREIRO CATIVO: 1
- ESPINHO DE VIDRO: 1

## Quem mais tirou vida (todas as partidas)

- ATIRADOR DE VIDRO: 480
- GUARDA DA CASA: 242
- ESPINHO DE VIDRO: 159
- INQUISIDOR PROFETA: 106
- PEREGRINO CINZENTO: 88
- QUEIMADURA: 88
- SENTINELA DE GELO: 88
- ?: 67
- PENITENTE: 50
- ASSASSINO DA DUNA: 36
- LOBO PÁLIDO: 36
- FERREIRO CATIVO: 35

## Partidas

| # | Semente | Resultado | Onde | Tempo | Morto por | Caminho |
|---|---|---|---|---|---|---|
| 1 | 1000 | tempo esgotado | mar_de_cinzas | 7:00 |  | mar_de_cinzas |
| 2 | 1001 | morte | saloes | 5:12 | GUARDA DA CASA | mar_de_cinzas > saloes |
| 3 | 1002 | morte | forja_rubra | 3:29 | FERREIRO CATIVO | mar_de_cinzas > forja_rubra |
| 4 | 1003 | tempo esgotado | mar_de_cinzas | 7:00 |  | mar_de_cinzas |
| 5 | 1004 | morte | forja_rubra | 4:38 | GUARDA DA CASA | mar_de_cinzas > forja_rubra |
| 6 | 1005 | morte | mar_de_cinzas | 6:13 | ESPINHO DE VIDRO | mar_de_cinzas |
| 7 | 1006 | tempo esgotado | mar_de_cinzas | 7:00 |  | mar_de_cinzas |
| 8 | 1007 | tempo esgotado | saloes | 9:59 |  | mar_de_cinzas > saloes |

## Onde o robô ficou preso

Cada linha é um ponto em que ele não conseguiu seguir o caminho por 11 s e foi empurrado para a frente. Muitos no mesmo andar podem ser sala ruim ou só o robô.

- semente 1000, mar_de_cinzas: (36, 32) combate_dunas
- semente 1001, mar_de_cinzas: (23, 65) inicio_portao, (26, 65) inicio_portao, (40, 65) combate_dunas, (178, 31) combate_fortaleza
- semente 1001, saloes: (131, 41) combate_cripta, (157, 40) dom_fossos_1
- semente 1002, mar_de_cinzas: (83, 45) dom_varandas_2
- semente 1002, forja_rubra: (67, 72) combate_fosso
- semente 1003, mar_de_cinzas: (53, 58) combate_poco, (75, 58) dom_vertical_0, (78, 58) dom_vertical_0
- semente 1004, mar_de_cinzas: (50, 64) dom_fossos_1, (74, 64) dom_fossos_1, (130, 46) dom_terracos_5
- semente 1004, forja_rubra: (32, 73) inicio, (29, 73) inicio
- semente 1005, mar_de_cinzas: (40, 43) dom_vertical_6, (51, 31) dom_vertical_6, (139, 47) dom_ilhas_4, (130, 47) dom_ilhas_4, (148, 47) dom_varandas_2, (150, 47) dom_varandas_2
- semente 1006, mar_de_cinzas: (46, 31) dom_vertical_3, (100, 43) dom_ilhas_4, (102, 40) dom_ilhas_4, (87, 34) dom_vertical_3, (98, 28) dom_vertical_3, (96, 25) dom_vertical_3, (98, 22) dom_vertical_3, (87, 27) dom_vertical_3
- semente 1007, mar_de_cinzas: (63, 25) dom_vertical_3, (73, 22) dom_vertical_3, (156, 54) dom_terracos_5
- semente 1007, saloes: (64, 54) dom_pilares_0, (70, 54) dom_pilares_0, (78, 51) dom_pilares_0, (82, 54) dom_pilares_0, (62, 54) dom_pilares_0, (69, 54) dom_pilares_0, (74, 54) dom_pilares_0, (69, 54) dom_pilares_0, (64, 54) dom_pilares_0, (66, 54) dom_pilares_0, (72, 54) dom_pilares_0, (80, 51) dom_pilares_0, (82, 54) dom_pilares_0, (77, 51) dom_pilares_0, (85, 54) dom_pilares_0, (54, 54) combate_cripta

### Salas onde ele prende (em quantas partidas)

- combate_dunas: 2
- combate_cripta: 2
- dom_fossos_1: 2
- dom_varandas_2: 2
- dom_terracos_5: 2
- dom_ilhas_4: 2
- dom_vertical_3: 2
- inicio_portao: 1
- combate_fortaleza: 1
- combate_fosso: 1
- combate_poco: 1
- dom_vertical_0: 1
- inicio: 1
- dom_vertical_6: 1
- dom_pilares_0: 1
