# MOKSHA

> Antes chamado *O Legado dos Deuses*. Jogo em inglês e português (Opções > Idioma).


Ação roguelite / metroidvania 2D em pixel art. Godot 4.7.2, GDScript.
Nome e sons são **provisórios**. A arte é pixel art gerada por scripts Python
(`tools/`): o herói, os inimigos, os blocos, o fundo e os objetos saem como
folhas de sprite, e dá para trocar por arte desenhada à mão sem mexer no jogo.

## Jogar

- `Jogar.bat` abre o jogo (espera o Godot em `Desktop\Godot_v4.7.2-stable_win64.exe`).
- Ou abra a pasta no Godot e aperte F5.

| Ação | Teclado | Controle |
|---|---|---|
| Andar | A/D ou setas | analógico / direcional |
| Pular (segure = mais alto) | Espaço | A |
| Arma 1 / Arma 2 | J / K (ou mouse esq./dir.) | X / Y |
| Habilidade 1 / 2 | U / I | LB / RB |
| Rolar (invencível) | Shift | B ou RT |
| Mergulho | S + J no ar | baixo + X no ar |
| Descer da plataforma | S + Espaço | baixo + A |
| Frasco de cura | Q | LT |
| Usar / pegar / ler | E | cima |
| Mapa (segure) | M ou Tab | Select |
| Pausa | Esc | Start |
| Debug (caixas de colisão e estados) | F1 | — |
| Nova partida | F5 | — |

## Como é uma partida

Cada partida monta mapas novos. Morreu, recomeça do zero, mas o que foi
desbloqueado fica para sempre.

8 andares por partida. Cada domínio termina no guardião dele, e depois do
guardião você escolhe o próximo domínio:

```
Mar de Cinzas ─┬─ Salões ─ Lobo da Longa Noite ─┬─ Torre de Babel ─ Arquiteto Mudo ─┬─ Carcosa ───── Rei sem Rosto ───┬─ Trono do
               └─ Forja ── Colosso da Bigorna ──┘  Jardim Primordial ─ Mãe-Raiz ────┘  Observatório ─ Último Astrônomo ┘  Imperador Cego
```

Cada domínio é mais fundo que o anterior: os inimigos ficam mais fortes e os
itens que caem, melhores. Cada um tem música, fundo, clima e perigo próprios.

- **Depois de cada guardião há uma passagem**, com a Vigia (gasta Essência e
  guarda as plantas), um altar de mutação e as saídas para os próximos domínios.
- **Guardiões:** golpes avisados, fase 2 com metade da vida (mais rápido, golpes
  novos) e, depois de alguns golpes, uma pausa exausto em que apanham 50% a mais.
- **Dentro do andar:**
  - salas feitas à mão encaixadas a cada partida, com desvios:
    - tesouro e fragmento divino;
    - mercador;
    - cofre atrás de parede rachada;
    - sala da runa;
    - sala secreta atrás de parede falsa;
  - a Porta do Relógio, perto da saída, fica aberta só para quem chega a tempo;
  - baús, e às vezes um baú maldito: paga melhor, mas qualquer golpe mata até
    você derrotar 10 inimigos;
  - ouro (gasto na partida) e Essência (gasta com a Vigia);
  - mapa: segure **M** ou **Tab**.

### O que dura uma partida

| Coisa | Como funciona |
|---|---|
| Armas e habilidades que você pega | trocam no chão |
| Fragmentos Divinos | sobem Fúria, Astúcia ou Vigor |
| Mutações | até 3, nas passagens |
| Ouro | gasto com o mercador |

### O que dura para sempre

| Coisa | Como funciona |
|---|---|
| Plantas | caem dos inimigos e só valem se você levar até a Vigia viva; aí ela vende o item |
| Desbloqueios e bênçãos | comprados com Essência |
| Aparências | 6 visuais para o herói |
| Runas | **Asa de Cinza** (pulo duplo, nos Salões) e **Punho do Ferreiro** (quebra parede rachada, na Forja). Abrem caminhos que antes estavam fechados |
| Brasas do Deus | dificuldade: cada vitória libera mais uma, até 4 (inimigos mais fortes, menos frascos) |

### Inimigos

| Andar | Inimigos |
|---|---|
| Mar de Cinzas | Penitente, Guarda da Casa, Peregrino Cinzento, Assassino da Duna, Atirador de Vidro, fulgurantes |
| Salões do Último Inverno | Lobo Pálido, Sentinela de Gelo, estalactites; o Penitente e a Guarda aparecem com cores do gelo |
| Forja Rubra | Ferreiro Cativo, Escória Viva, jatos de fogo; a Guarda aparece com cores da forja |
| Elites | Inquisidor Profeta (Mar), Caçador do Inverno (Salões), Mestre-Ferreiro (Forja), Bibliotecário Cego (Torre), Guardiã de Espinhos (Jardim), Duelista Amarelo (Carcosa), Sentinela de Latão (Observatório) |
| Torre de Babel | Gárgula (voa e mergulha), Escriba Mudo (glifo que persegue), pedras que caem |
| Jardim Primordial | Fera-Musgo (investida), Espinheiro (espinhos em arco), casulos de esporos |
| Carcosa | Mascarado (some e aparece atrás), Arauto Pálido (chama almas que explodem), tentáculos do chão |
| Observatório Celeste | Autômato Astral (raio na horizontal), Estrela Caída (explode perto), meteoros |
| Elites | Inquisidor Profeta (Mar), Caçador do Inverno (Salões), Mestre-Ferreiro (Forja), Bibliotecário Cego (Torre), Guardiã de Espinhos (Jardim), Duelista Amarelo (Carcosa), Sentinela de Latão (Observatório) |
| Fim | O Imperador Cego |

**Armas:** espada, lança, machado, adagas gêmeas, martelo da forja, e os arcos das
dunas, de brasa e do inverno. Armas que caem podem vir com **afixos**: de Brasa
(queima), da Geada (atordoa), Vampira (cura), Explosiva (crítico explode),
Afiada, Ligeira, Carrasca (mais dano em quem está quase morto) e do Eco (acerta
duas vezes).

**Habilidades:** granada, escudo (o aparo devolve projéteis), lança de vidro,
armadilha de lâminas, torreta de vidro, espírito de cinza e corrente do ferreiro
(puxa e atordoa).

### História

Na primeira partida, uma abertura curta conta o que aconteceu com os deuses.
Vencer o Imperador mostra o final, e quem vence com as 4 brasas vê um final a
mais. O **Códice** (no título) guarda as inscrições lidas e um bestiário de tudo
que você já derrotou.

### No título

- **Desafio do dia:** a mesma semente para todo mundo no mesmo dia.
- **Estatísticas:** quem mais te matou, quem você mais matou, armas favoritas,
  andar mais fundo e melhor tempo.
- **Opções:** volume geral, da música e dos efeitos, tela cheia, intensidade do
  tremor, piscadas fortes, vibração do controle, cronômetro de speedrun e troca
  de teclas.

## Estrutura

```
scripts/
  core/       Damage (pacote de dano), Actor (base de quem tem vida), PlayerInput
  combat/     WeaponData, SkillData, Gear, Projectile, Combat (críticos), Catalog
  actors/     Player, SkinData (aparência), HeroLook (miniatura nos menus)
  enemies/    Enemy (base) + cada inimigo, Hazard, Fulgurant, BlindEmperor
  world/      Room (mapa), RoomTemplate + LevelGen (gerador), Level (monta a fase),
              objetos de interação, câmera, fundo, primeiro plano, clima,
              partículas, luzes (Glow), braseiros
  biomes/     BiomeData
  ui/         Hud, Menu, Screen, PixelFont, Palette
  autoload/   Controls, Fx, Sfx, Meta (save permanente), Run (partida atual)
content/
  weapons/ skills/ skins/   armas, habilidades e aparências (.tres)
  biomes/mar_de_cinzas/     biome.tres, rooms/*.txt, chefe/trono.txt
assets/sfx/                 sons gerados por tools/gen_sfx.py
tests/                      testes automáticos e roteiro de prints
tools/                      geradores de conteúdo (armas, salas, sons)
```

## Arte (tools/)

Cada script desenha a partir de poses e formas, com luz e contorno automáticos,
e salva **índices de paleta** em vez de cores: o jogo pinta com a paleta certa
(aparência do herói, cores do bioma). Também sai uma prévia colorida em
`tools/previews/` para conferir sem abrir o jogo.

| Script | Gera |
|---|---|
| `gen_bestiary.py` | inimigos e chefes dos domínios novos (humanoide com escala para os chefes) |
| `gen_music.py` | as 11 trilhas: título, passagem, cada domínio, chefe e chefe final |
| `biomas.py` | os `biome.tres` dos domínios novos |
| `gen_sprites.py` | herói (parado, corrida, pulo, queda, rolagem, golpe, arco, escudo, cura...) |
| `gen_enemies.py` | os inimigos dos 3 andares e o Imperador Cego |
| `gen_tiles.py` | blocos de pedra (16 encaixes x 4 variações), rocha funda e prancha |
| `gen_backdrop.py` | fundo em camadas de cada andar (céu, ruínas ao longe, dunas ou neve) |
| `gen_props.py` | Vigia, altares, pedestal, estela, portal, braseiro, baús, mercador, Porta do Relógio |
| `salas_dominios.py` | 7 salas com a cara de cada domínio, geradas por plantas e aprovadas pelo verificador |
| `validar_salas.py` | confere TODAS as salas com o alcance real do pulo (roda no `Testar.bat`) |
| `salas_andares.py` | salas dos andares novos, a passagem e as peças comuns (saída com relógio, loja, cofre, runa) |
| `mock_frame.py` | um quadro de mentira montado com tudo isso, com a mesma luz do jogo |

Depois de gerar, rode o Godot uma vez com `--headless --import` para ele
reimportar as imagens.

## Como acrescentar coisas

- **Aparência**: acrescente em `SKINS` de `tools/gen_content.py`, rode o script e
  ponha o caminho em `Catalog.SKINS`.
- **Arma ou habilidade**: acrescente em `tools/gen_content.py` e rode
  `python tools/gen_content.py` (ou crie o `.tres` direto); ponha o caminho em
  `scripts/combat/catalog.gd`.
- **Sala**: um `.txt` em `content/biomes/<bioma>/rooms/`. A legenda está no topo
  de `scripts/world/room.gd`; as portas (`D` na borda) em `room_template.gd`.
- **Inimigo**: um script que estende `Enemy`, com o golpe sempre avisado
  (`telegraphing()`), registrado em `enemies` do `biome.tres`.
- **Bioma novo**: uma pasta em `content/biomes/` com `biome.tres` (cores, fundo,
  clima, inimigos, chefe, saídas, textos) e as salas; registre em `Catalog.BIOMES`
  e em `Run.ROUTE`. Os sistemas não mudam.

## Testes

`Testar.bat` (ou `Godot_console.exe --headless --fixed-fps 60 --path . res://tests/run_tests.tscn`):
52 testes que rodam a física de verdade — pulo, tolerâncias, rolagem, combo,
escudo, aparo, cada inimigo, chefe, gerador (20 mapas com caminho do início à
saída), save, aparências e se a fonte tem desenho para toda letra dos textos. Os testes usam `user://teste.save`, nunca o save real.

`tests/shots.tscn` abre o jogo, encena situações e salva prints (`-- --out=<pasta>`).
