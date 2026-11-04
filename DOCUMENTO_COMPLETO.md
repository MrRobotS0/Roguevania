# O Legado dos Deuses: documento completo

Tudo sobre o jogo num lugar só: o que ele é, como jogar e testar, cada sistema,
cada inimigo, cada número que importa, como o código está organizado, as
ferramentas, a história de como foi feito, os erros encontrados, as decisões, o
que falta e, no fim, o GDD original.

- **Pasta:** `C:\Users\guilhermebelinelo\Projetos\Roguevania`
- **GitHub:** https://github.com/MrRobotS0/Roguevania (público, branch `master`)
- **Motor:** Godot 4.7.2 (GDScript), renderizador Compatibility
- **Situação em 03/11/2026:** jogo completo de ponta a ponta, com 8 andares por partida,
  7 domínios, 7 chefes, 7 elites, 31 tipos de criatura, 8 armas, 7 habilidades,
  música, sons, história, opções e desafio do dia. **Ainda não foi jogado por uma
  pessoa:** foi verificado por 52 testes automáticos, um verificador de salas e
  simulações sem tela.

---

## Índice

1. [O que é o jogo](#1-o-que-é-o-jogo)
2. [Como jogar, testar e levar para outro computador](#2-como-jogar-testar-e-levar-para-outro-computador)
3. [Regras de trabalho combinadas](#3-regras-de-trabalho-combinadas)
4. [Linha do tempo: como o jogo foi feito](#4-linha-do-tempo-como-o-jogo-foi-feito)
5. [Uma partida, do começo ao fim](#5-uma-partida-do-começo-ao-fim)
6. [Movimento e combate](#6-movimento-e-combate)
7. [Equipamento e progressão](#7-equipamento-e-progressão)
8. [Os 7 domínios](#8-os-7-domínios)
9. [Bestiário completo](#9-bestiário-completo)
10. [Os chefes em detalhe](#10-os-chefes-em-detalhe)
11. [História: abertura, final e Códice](#11-história-abertura-final-e-códice)
12. [Interface](#12-interface)
13. [Arte e visual](#13-arte-e-visual)
14. [Música e sons](#14-música-e-sons)
15. [Arquitetura do código](#15-arquitetura-do-código)
16. [Ferramentas (tools/)](#16-ferramentas-tools)
17. [Testes e verificação](#17-testes-e-verificação)
18. [Problemas encontrados e corrigidos](#18-problemas-encontrados-e-corrigidos)
19. [Armadilhas técnicas aprendidas](#19-armadilhas-técnicas-aprendidas)
20. [Decisões de design](#20-decisões-de-design)
21. [O que falta e ideias não feitas](#21-o-que-falta-e-ideias-não-feitas)
22. [Histórico de commits](#22-histórico-de-commits)
23. [Apêndice: GDD original](#23-apêndice-gdd-original)

---

## 1. O que é o jogo

Ação roguelite / metroidvania 2D em pixel art, no gênero do Dead Cells, com
universo próprio. **Premissa:** havia sete deuses, cada um com um domínio. Numa
noite todos sumiram, e os domínios ficaram, apodrecendo cada um do jeito do seu
deus. Você acorda na beira do Mar de Cinzas sem lembrar de nada e atravessa os
domínios até o Trono, onde está a resposta.

**O ciclo (como no Dead Cells):**
- Cada partida monta mapas novos, juntando salas feitas à mão em ordem sorteada.
- Morreu, volta tudo para o começo.
- O que foi desbloqueado fica para sempre: plantas de itens, bênçãos,
  aparências, runas e dificuldades.

**Nome, arte e sons:**
- O nome é **provisório**.
- A arte é pixel art **gerada por scripts Python**: personagens posados quadro
  a quadro, com luz e contorno automáticos.
- Os sons e a música são **sintetizados** por código.

Tudo pode ser trocado por arte e som feitos à mão sem mexer no jogo.

---

## 2. Como jogar, testar e levar para outro computador

### Nesta máquina
- **Jogar:** `Jogar.bat` (procura o Godot em `Desktop\Godot_v4.7.2-stable_win64.exe`).
  Ou abra a pasta no Godot e aperte F5.
- **Testar:** `Testar.bat` roda o verificador de salas (Python) e depois os 52
  testes do jogo, sem abrir janela.

### Em outro computador
1. `git clone https://github.com/MrRobotS0/Roguevania.git`
2. Instale o Godot **4.7.2**.
3. Abra o projeto no Godot e aperte F5, ou use o `Jogar.bat` se o Godot estiver na Área de Trabalho.
4. Para os scripts de `tools/`: Python 3 com Pillow e numpy.

### Comandos

| Ação | Teclado | Controle |
|---|---|---|
| Andar | A/D ou setas | analógico / direcional |
| Pular (segure = mais alto) | Espaço | A |
| Pulo duplo (com a runa Asa de Cinza) | Espaço no ar | A no ar |
| Arma 1 / Arma 2 | J / K (ou mouse esquerdo/direito) | X / Y |
| Habilidade 1 / 2 | U / I | LB / RB |
| Rolar (invencível) | Shift ou L | B ou RT |
| Mergulho | S + J no ar | baixo + X no ar |
| Descer da plataforma | S + Espaço | baixo + A |
| Frasco de cura | Q | LT |
| Usar / pegar / ler | E | cima |
| Mapa (segure) | M ou Tab | Select |
| Pausa | Esc | Start |
| Debug (caixas e estados) | F1 | — |
| Nova partida | F5 | — |

As teclas podem ser trocadas em **Opções → Teclas**. As dicas na tela mudam
sozinhas entre teclado e controle, conforme o último aparelho usado.

### Saves
- **Save real:** `user://legado.save` (pasta de dados do Godot no Windows:
  `%APPDATA%\Godot\app_userdata\Roguevania\`).
- **Testes:** usam `user://teste.save` e **nunca** tocam o save real.

---

## 3. Regras de trabalho combinadas

- **Ele decide quando começa cada escopo novo.** No começo, comecei a construir
  sem ordem e fui parado ("para de ficar criando o jogo cara eu ja falei que vou
  decidir só depois"). Dentro de um plano autorizado, eu decido sozinho e registro.
- **Nunca abrir o jogo com janela**, nem escondida. Ele usa a máquina enquanto
  eu trabalho ("para de fica abrindo o jogo cara ta me atrapalhando"; depois,
  "mas nao fique abrindo o jogo por favor isso esta me atrapalhando").
  - Para verificar, só o Godot sem tela (`--headless`).
  - Para ver arte, gero imagens PNG com Python e abro as imagens.
- **Projeto pessoal:** as notas vão para o **MegaBrain Pessoal**
  (`Documents\MegaBrain Pessoal`), nunca para o MegaBrain da empresa, e não há
  link entre os dois.
- **Código com cara de feito por gente:** sem comentário óbvio nem banner gerado.
- **GitHub:** subir ao fim de cada rodada para ele poder jogar depois.

---

## 4. Linha do tempo: como o jogo foi feito

Tudo aconteceu em 03/11/2026.

1. **Conversa inicial.** Ele queria um jogo "igual Dead Cells" (metroidvania +
   roguelike, 2D, pixel art, combate parecido), mas com nome, arte, tema e
   história próprios, e queria que eu fizesse quase tudo. Recomendei o Godot e
   ele baixou.
2. **Protótipo** (feito antes da hora, e ele me parou): movimento, combo,
   rolagem, beirada, mergulho, 2 inimigos e testes.
3. **GDD.** Ele colou o documento "O Legado dos Deuses" (apêndice) e disse "pode
   fazer o que achar melhor, mas vamos começar faça o plano inteiro".
4. **Vertical slice do Mar de Cinzas:**
   - arquitetura modular, com arma, habilidade e bioma como dados;
   - gerador de fases;
   - 6 inimigos e o chefe Imperador Cego;
   - Essência, Vigia e save;
   - menus e sons sintetizados;
   - 29 testes.
5. **"O que podemos melhorar no visual?"** Listei 7 pontos e ele mandou fazer
   todos, mais um sistema de skins:
   - luz e brilho, contorno, cachecol com física;
   - inimigos virando cinza ao morrer, cenário com objetos;
   - fundo com névoa e primeiro plano;
   - fonte com acentos e HUD com ícones;
   - 6 aparências.
6. **"Se dedicar ao máximo para ficar muito foda visualmente."** Toda a arte
   virou pixel art gerada (herói, inimigos, tileset, fundo pintado, objetos),
   com troca de paleta por aparência. A verificação foi só por imagens geradas,
   porque ele pediu para eu não abrir o jogo.
7. **"Tem que ser igual Dead Cells."**
   - rota de andares com escolha;
   - passagens com a Vigia e mutações;
   - mapa, ouro, mercador, baús e baú maldito, Porta do Relógio;
   - plantas, runas (pulo duplo, parede rachada) e Brasas do Deus;
   - Forja Rubra e Salões.
8. **"Faça 1 2 3 4 7 e 8."**
   - opções completas, 11 trilhas de música, 4 habilidades e afixos;
   - um chefe por domínio;
   - os 4 domínios restantes do GDD;
   - desafio do dia, estatísticas e recorde.
9. **"Faz 6 7 8 10."**
   - verificador de salas com o pulo real, que achou salas impossíveis e lugares onde se ficava preso; tudo corrigido;
   - 7 salas próprias por domínio e um elite por domínio;
   - 29 sons novos;
   - história (abertura, final, final verdadeiro, Códice).
10. **GitHub.** O projeto subiu para `MrRobotS0/Roguevania`.
11. **Este documento.**

---

## 5. Uma partida, do começo ao fim

### Rota (10 andares, desde o grande update de 04/11)

```
Mar de Cinzas ─┬─ Salões ── Lobo da Longa Noite ─┬─ Torre de Babel ── Arquiteto Mudo ─┬─ Carcosa ───── Rei sem Rosto ───┬─ Penhascos do Sonho ─ Dragão Sonhado ──┬─ Trono do
               ├─ Forja ─── Colosso da Bigorna ──┤  Jardim Primordial ─ Mãe-Raiz ──────┤  Observatório ─ Último Astrônomo ┤  Cavernas Fundas ──── Serpe do Fundo ───┤  Imperador Cego
               └─ Necrópole ─ Rei Esquecido ─────┘  Catedral Submersa ─ O Que Responde ┘  Ventre ──────── O Insaciável ────┘  Bosque Errante ────── Raposa de 9 Caudas ┘
```
Cada passagem oferece **três** caminhos (antes eram dois).

- O **Mar de Cinzas** é sempre o primeiro andar. A saída dele leva à passagem.
- Cada **domínio** termina numa saída "Enfrentar o guardião", que leva à arena
  do chefe daquele domínio.
- Vencido o guardião, a saída leva à **passagem**. Ela tem a Vigia, o altar de
  mutação e as duas saídas para os próximos domínios, com uma dica de como cada
  um é ("mais calmo", "mais perigoso, paga melhor").
- O **Trono** é a última arena. Vencido o Imperador Cego, vem o final da
  história e a tela de vitória.
- A rota está em `scripts/autoload/run.gd`, na constante `STAGES`.

### Profundidade
Cada andar tem um "tier" (Mar 0, Salões 1, Forja 2, Torre/Jardim 3,
Carcosa/Observatório 4, arenas = tier do domínio + 1, Trono 6).

| O que muda | Quanto |
|---|---|
| Vida dos inimigos comuns e elites | +20% por tier |
| Dano que o herói recebe | +10% por tier |
| Itens que caem | qualidade maior (+15% de dano por nível do item) |
| Ouro dos inimigos | sobe com o tier |

Os chefes têm vida fixa, que não escala com o tier.

### Dentro de um andar gerado
- **Caminho principal:** início → 6 ou 7 salas de combate/corredor (com uma
  sala de elite perto do fim) → saída.
- **Desvios presos nas portas livres, em ordem de importância:**
  1. sala da runa, se o domínio tem runa e você ainda não pegou;
  2. **cofre**, que entra por **parede rachada**;
  3. **loja** (mercador);
  4. fragmento divino;
  5. tesouros;
  6. uma **sala secreta** atrás de parede falsa.
- **Porta do Relógio:** fica na sala de saída e só abre se você chegar a tempo
  (150 s + 30 s por tier). Atrás dela há baú e item. O HUD mostra a contagem.
- **Baús:** ouro e, às vezes, item ou planta. Com 18% de chance, a partir do
  segundo domínio, o baú é **maldito**: ele pergunta antes de abrir; aberto,
  paga muito melhor, mas **qualquer golpe mata** até você derrotar 10 inimigos.
- **Mapa:** segure M/Tab. Mostra só o que o herói já viu, com você, as saídas,
  a Vigia, os baús, os altares e o mercador.
- **Clima e perigo próprios** de cada domínio (seção 8).

### Economia
| Moeda | De onde vem | Para que serve | Ao morrer |
|---|---|---|---|
| **Ouro** | todo inimigo derrubado, baús | mercador (itens, cura, frasco extra) | perde |
| **Essência** | inimigos (mais nos elites e chefes) | Vigia: desbloqueios, bênçãos, aparências | perde o que carrega |
| **Plantas** | 3,5% dos inimigos, todo elite, todo chefe, baús | levar viva até a Vigia libera o item para compra | perde as que carrega |

### O que dura uma partida e o que dura para sempre
| Dura uma partida | Dura para sempre |
|---|---|
| armas e habilidades achadas | plantas entregues à Vigia |
| níveis de Fúria/Astúcia/Vigor | itens comprados (passam a aparecer nas partidas) |
| mutações (até 3) | bênçãos |
| ouro, frascos extras | aparências |
| maldição | runas (Asa de Cinza, Punho do Ferreiro) |
| | Brasas do Deus liberadas |
| | estatísticas, recorde, Códice |

### Brasas do Deus (dificuldade)
Cada vitória libera a próxima brasa, até 4. Quem já venceu escolhe a brasa ao
apertar Começar.

| Brasas | Efeito |
|---|---|
| 0 | como da primeira vez |
| 1 | inimigos +40% de vida, +25% de dano |
| 2 | +80% de vida, +50% de dano, um frasco a menos |
| 3 | +120% de vida, +75% de dano, um frasco a menos |
| 4 | +160% de vida, +100% de dano, um frasco a menos; **libera o final verdadeiro** |

### Desafio do dia
Usa a semente do dia (a mesma para qualquer um na mesma data), sem brasas. Fica
registrado: tentativas do dia, andar mais fundo e melhor tempo se venceu.

---

## 6. Movimento e combate

### Herói
| Coisa | Valor |
|---|---|
| Vida inicial | 100 (+10 por nível de Fúria/Astúcia, +20 por nível de Vigor) |
| Velocidade de corrida | 150 px/s (o bloco tem 16 px) |
| Altura do pulo | ~3,3 blocos; soltar cedo dá pulo curto |
| Tolerância na beirada (coyote) | 0,10 s |
| Pulo antecipado (buffer) | 0,12 s |
| Agarrar a beirada | sobe muro de 4 blocos |
| Rolagem | 0,32 s, invencível em 0,27 s |
| Invencibilidade após apanhar | 0,8 s |
| Frasco | cura 50% da vida; 2 frascos de base (+1 por Cálice) |
| Janela de aparo do escudo | 0,18 s |
| Mergulho | cai rápido, machuca quem está embaixo (18 × Fúria) |

### Atributos
- **Fúria, Astúcia e Vigor.** Cada arma e habilidade cresce com um deles: +15% de dano por nível.
- Sobem nos **Fragmentos Divinos** (altares), escolhendo um a cada altar.

### Dano e críticos
- **Pacote de dano** (`Damage`): valor, direção, empurrão, levantamento, crítico,
  pausa no impacto, tremor, status, origem, dano contínuo, se não pode ser bloqueado,
  se foi aparado ou bloqueado.
- **Críticos situacionais**, cada arma com o seu:
  - **pelas costas:** lança, adagas;
  - **de longe:** arco das dunas;
  - **alvo queimando:** arco de brasa, martelo da forja;
  - **alvo atordoado:** machado, arco do inverno, lança de vidro;
  - **último golpe do combo:** espada.
- **Status:** queimadura (3 de dano a cada 0,5 s) e atordoamento.
- **Sensação de impacto:** pausa no impacto, tremor de tela, partículas, números de
  dano, risco na direção do golpe e estrela de impacto.

### Inimigos (regra geral)
- **Todo ataque é avisado:** a roupa pisca em laranja e aparece um "!".
- **Golpe durante o aviso interrompe**, a não ser que o inimigo tenha firmeza
  (poise). Os chefes não são interrompidos.
- **Elite:** 2,5× a vida, firmeza, 4× a Essência, contorno em brasa, faíscas e luz
  vermelha. Ao morrer, deixa um item e uma planta.

---

## 7. Equipamento e progressão

### Armas
| Arma | Tipo | Atributo | Crítico | Dano (combo / tiro) | Custo na Vigia | Texto |
|---|---|---|---|---|---|---|
| Espada Cerimonial | corpo a corpo | Fúria | último golpe | 10 / 12 / 15 | inicial | Forjada para os desfiles das Casas do Mar de Cinzas. Nunca devia ter visto sangue. Viu. |
| Lança do Peregrino | corpo a corpo | Astúcia | pelas costas | 13 / 17 | 30 | Os peregrinos caminham até o centro do deserto apoiados nela. Poucos voltam. As lanças sempre voltam. |
| Machado do Carrasco | corpo a corpo | Vigor | atordoado | 26 / 34 | 40 | Na Casa Vesper, a sentença era lida pelo cego e executada pelo surdo. Assim ninguém ouvia o perdão. |
| Adagas Gêmeas | corpo a corpo | Astúcia | pelas costas | 6 / 6 / 7 / 10 | 45 | Um par de assassinos da duna usava uma cada. Quando um morreu, o outro passou a usar as duas. |
| Martelo da Forja | corpo a corpo | Vigor | queimando | 28 / 36 (queima) | 55 | Os ferreiros cativos não largam os seus. Este foi tirado de uma mão que ainda estava quente. |
| Arco das Dunas | arco | Astúcia | de longe | 12 | inicial | Corda de tendão de besta-de-areia. Acerta melhor quem tem paciência para esperar a distância certa. |
| Arco de Brasa | arco | Astúcia | queimando | 9 (queima) | 35 | As pontas são mergulhadas em Cinza Sagrada. O que ela toca lembra que um deus ardeu aqui. |
| Arco do Último Inverno | arco | Astúcia | atordoado | 11 (atordoa) | 50 | A corda é um fio de gelo que nunca derrete. A flecha chega antes do frio. |

**Kit inicial:** Espada Cerimonial, Arco das Dunas e Granada de Cinzas.

### Habilidades
| Habilidade | Tipo | Atributo | Recarga | Dano | Custo | Texto |
|---|---|---|---|---|---|---|
| Granada de Cinzas | arremesso que explode e queima | Astúcia | 6 s | 22 | inicial | Um punhado de Cinza Sagrada num jarro de barro. Os sacerdotes chamam de heresia. Os soldados, de munição. |
| Égide de Bronze | escudo; na hora certa apara e **devolve projéteis** | Vigor | — | — | 35 | Escudo da guarda pessoal do Imperador. O polimento é um espelho: quem ataca vê a si mesmo antes do golpe. |
| Lança de Vidro | atravessa até 4 inimigos e atordoa | Fúria | 5 s | 24 | 35 | Arrancada do corpo de um fulgurante. Ainda vibra quando passa perto da areia. |
| Armadilha de Lâminas | lâminas no chão por 8 s | Astúcia | 9 s | 7 por toque | 40 | Os caçadores da duna enterram isto na cinza e esperam. A cinza é paciente; eles também. |
| Torreta de Vidro | atira sozinha por 12 s | Astúcia | 14 s | 7 por tiro | 50 | Um olho de fulgurante preso num tripé. Atira em tudo que se mexe, menos em quem o montou. |
| Espírito de Cinza | aliado que persegue e queima, 10 s | Fúria | 16 s | 10 | 55 | O que sobra de um peregrino que ardeu acreditando. Ainda quer lutar. |
| Corrente do Ferreiro | puxa o inimigo e atordoa | Vigor | 6 s | 12 | 45 | Prendia os cativos à bigorna. Agora puxa quem estiver longe demais. |

### Afixos (armas que caem)
Uma arma pode vir com 0 a 2 afixos, mais prováveis em andares fundos. O nome mostra o primeiro (ex.: "Espada Cerimonial Afiada +1").

| Afixo | Efeito |
|---|---|
| de Brasa | golpes queimam |
| da Geada | 25% de chance de atordoar |
| Vampira | cada acerto cura 1 |
| Explosiva | crítico explode em volta (metade do dano) |
| Afiada | +15% de dano |
| Ligeira | golpes 20% mais rápidos |
| Carrasca | +50% de dano em quem tem menos de 30% de vida |
| do Eco | 20% de chance de acertar de novo (metade do dano) |

### Mutações (nas passagens, até 3 por partida)
| Mutação | Efeito |
|---|---|
| Sangue Quente | cada abate cura 3% da vida |
| Pés Leves | rola de novo sem esperar |
| Pólvora Seca | habilidades recarregam 35% mais rápido |
| Vingança | +40% de dano por 3 s depois de apanhar |
| Frieza | críticos causam +25% de dano |
| Lâmina Plena | +20% de dano com a vida acima de 80% |
| Colecionador | +50% de Essência e ouro dos inimigos |
| Fôlego | +1 frasco nesta partida |

### Bênçãos (Vigia, para sempre)
| Bênção | Custo | Efeito |
|---|---|---|
| Cálice Extra | 50 | +1 frasco em toda partida |
| Bênção da Vigia | 40 | começa com +1 num atributo ao acaso |
| Segundo Cálice | 110 | +1 frasco (requer o primeiro) |
| Bolsa de Viagem | 45 | começa a partida com 60 de ouro |

### Mercador (ouro)
O estoque é sorteado em cada andar:
- 3 itens um nível acima do andar, por 55 + 30 × nível + 10 × tier;
- Pão de Cinza (cura metade), por 40 + 10 × tier;
- Frasco Extra, por 75 + 15 × tier.

### Aparências (skins)
Só mudam o visual. O jogo pinta a mesma folha de sprites com outra paleta.

| Aparência | Como ganhar | Texto |
|---|---|---|
| O Andarilho | inicial | Você acordou com ele. Ninguém lembra de costurar. |
| Manto de Cinza | Vigia, 60 de Essência | Tecido com a cinza do deus que ardeu. Ainda morno. |
| Herdeiro Vesper | Vigia, 90 | As cores da Casa Vesper. A Casa caiu; o orgulho não. |
| Casca de Vidro | Vigia, 140 | Um fulgurante tentou te engolir. Ficou com a forma. |
| Olhos Fechados | derrotar o Imperador Cego | O futuro se vê de olhos fechados. Ele tinha razão. |
| Saco de Penitente | morrer 10 vezes | Dez vezes na cinza. Agora você começa a ouvir. |

### Runas (poderes para sempre)
| Runa | Onde | Efeito |
|---|---|---|
| Asa de Cinza | sala da runa nos Salões | pulo duplo; alcança nichos altos com baús (7 blocos acima do chão) |
| Punho do Ferreiro | sala da runa na Forja | golpes quebram paredes rachadas, que escondem cofres |

---

## 8. Os 7 domínios

Cada domínio tem cores próprias (blocos e céu), fundo pintado em 4 camadas,
clima, perigo de cenário, inimigos, elite, guardião, música, inscrições e salas.

| Domínio | Subtítulo | Tier | Clima | Perigo | Inimigos | Elite | Guardião | Música |
|---|---|---|---|---|---|---|---|---|
| **Mar de Cinzas** | Domínio do deus que ardeu | 0 | tempestade de cinzas (vento + visão curta) | fulgurantes (espinho de vidro sobe do chão) | Penitente, Guarda da Casa, Peregrino Cinzento, Assassino da Duna, Atirador de Vidro | Inquisidor Profeta | (o Imperador, no fim) | 96 bpm, Ré frígio |
| **Salões do Último Inverno** | Domínio do deus que esperava | 1 | neve e aurora | estalactites que caem | Lobo Pálido, Sentinela de Gelo, Penitente (gelo), Guarda, Assassino | Caçador do Inverno | Lobo da Longa Noite | 72 bpm, Mi menor |
| **Forja Rubra** | Domínio do deus que trabalhava | 2 | brasas subindo | jatos de fogo | Ferreiro Cativo, Escória Viva, Guarda (forja), Penitente, Atirador | Mestre-Ferreiro | Colosso da Bigorna | 132 bpm, Dó menor harmônica |
| **Torre de Babel** | Domínio do deus que falava todas as línguas | 3 | poeira dourada | pedras que caem do teto | Gárgula, Escriba Mudo, Guarda, Penitente | Bibliotecário Cego | Arquiteto Mudo | 110 bpm, Lá dórico |
| **Jardim Primordial** | Domínio do deus que plantou o mundo | 3 | esporos subindo | casulos de esporos | Fera-Musgo, Espinheiro, Lobo (cores do musgo), Peregrino | Guardiã de Espinhos | Mãe-Raiz | 88 bpm, Sol lídio |
| **Carcosa** | Domínio do deus que usava máscara | 4 | flocos de sombra | tentáculos do chão | Mascarado, Arauto Pálido, Assassino, Penitente | Duelista Amarelo | Rei sem Rosto | 80 bpm, Si♭ lócrio |
| **Observatório Celeste** | Domínio do deus que contava as estrelas | 4 | estrelas piscando | meteoros | Autômato Astral, Estrela Caída, Sentinela de Gelo, Guarda | Sentinela de Latão | Último Astrônomo | 100 bpm, Fá♯ lídio |

### Fundos pintados
| Domínio | O que aparece no fundo |
|---|---|
| Mar de Cinzas | céu em faixas pontilhadas, sol com halo, véus de cinza, colossos em ruína (gigante ajoelhado com espada quebrada, mão gigante saindo da areia, arco partido, obelisco tombado, cabeça de estátua), dunas com crista iluminada |
| Salões | aurora no céu, lua pálida, colunata caída, um gigante preso num bloco de gelo, pinheiros congelados |
| Forja | céu vermelho sem sol, chaminés soltando fumaça, bigorna gigante, martelo cravado, engrenagem enterrada |
| Torre | a Torre de Babel em degraus, andaimes |
| Jardim | árvores colossais, samambaias, capim |
| Carcosa | dois sóis negros com coroa amarela, cidade de torres tortas, arcos |
| Observatório | céu de estrelas com faixa da galáxia, cúpula com telescópio, anéis de latão |

### Salas
- **Mar de Cinzas:** 18 salas feitas à mão, mais as peças comuns (saída com
  relógio, lojas, cofres). Todas passaram no verificador sem correção.
- **Outros domínios:**
  - um conjunto base: início, ponte sobre fosso, degraus, galeria com nicho de pulo duplo, torre, fosso, cripta, corredores, salão do elite;
  - desvios em 4 versões, uma para cada lado de porta;
  - **7 salas próprias** geradas por plantas no estilo do lugar (fossos, pilares
    do teto, terraços, vertical, varandas, ilhas flutuantes, ruelas).
- **Arena de guardião:** `content/arena.txt`, com plataformas em dois níveis.
- **Passagem:** `content/passagem.txt`, com a Vigia, o altar de mutação e duas saídas.
- **Total:** 241 salas, todas aprovadas pelo verificador.

### Inscrições (todas)
**Mar de Cinzas**
- Aqui ardeu um deus. Não se sabe qual. As Casas dizem que foi o delas.
- Quem respira a Cinza Sagrada ouve a voz que ela guardou. Os sacerdotes chamam de profecia. Os médicos, de febre.
- As Casas Vesper, Oram e Kael lutam pela cinza há trezentos anos. O deserto não cresce. Só as covas.
- O Imperador arrancou os próprios olhos para não ver o presente. Disse que o futuro era mais bonito.
- Os fulgurantes nasceram onde os raios caíram na cinza. Não são animais. São o vidro lembrando de ter sido fogo.
- Os peregrinos não vêm rezar. Vêm arder. Acreditam que quem queima vira parte do deus.
- Na última página do livro profético há uma única frase, escrita em todas as línguas: ELE NÃO VOLTA.

**Salões do Último Inverno**
- O deus do Inverno prometeu voltar na primavera. Ninguém aqui viu outra estação desde então.
- Os lobos pálidos guardam a porta como se o dono ainda fosse passar por ela.
- As sentinelas foram gente. O gelo não lembra quem.
- No salão maior há uma mesa posta para mil. Os pratos ainda estão quentes, por baixo do gelo.
- Escrito com a unha numa coluna: esperar também é uma forma de morrer.

**Forja Rubra**
- O deus da Forja nunca descansou. Quando sumiu, as bigornas continuaram batendo sozinhas por um ano.
- Os ferreiros cativos esqueceram o próprio nome. Lembram só da medida certa do aço.
- A escória viva é o que sobra do metal que não quis virar arma.
- Daqui saíram as coroas das Casas. E as correntes.
- Na parede do fundo, alguém gravou: o fogo não perdoa, mas também não mente.

**Torre de Babel**
- A Torre foi feita para chegar ao deus. Chegou. Ele já tinha ido embora.
- Cada andar fala uma língua. Quem sobe esquece a de baixo.
- Os escribas copiam o mesmo livro há mil anos. Ninguém sabe ler o original.
- As gárgulas eram guardas. Ficaram de pedra esperando a ordem de parar.
- No topo há uma porta. Do lado de dentro, só céu.

**Jardim Primordial**
- Aqui tudo nasceu primeiro. Por isso tudo aqui é mais velho que a morte.
- As feras-musgo não comem. Só crescem por cima do que encontram.
- O deus do Jardim não sumiu. Virou raiz. Ainda sente cada passo.
- Os espinheiros apontam sempre para quem respira.
- Uma placa coberta de musgo: NÃO ARRANQUE NADA. ELA LEMBRA.

**Carcosa**
- Em Carcosa os sóis são negros e ninguém estranha.
- Todo morador usa máscara. Por baixo, a mesma máscara.
- O Arauto anuncia um rei que nunca chega. Os sinos tocam assim mesmo.
- Quem tira a máscara aqui some. Ninguém tira.
- Escrito na parede, em amarelo: VOCÊ JÁ ESTEVE AQUI.

**Observatório Celeste**
- O último astrônomo contou as estrelas até elas acabarem. Depois contou de novo.
- Os autômatos medem o céu. Não sabem mais para quem.
- Cada estrela caída é um nome que o deus esqueceu.
- A luneta aponta para um ponto vazio. Lá estava o deus.
- No caderno de bordo, a última linha: ELE OLHOU DE VOLTA.

---

## 9. Bestiário completo

Vida **base**: comuns e elites ganham +20% por tier, elites ×2,5, e as brasas
somam por cima.

| Criatura | Vida base | Onde | Como luta / como vencer |
|---|---|---|---|
| Penitente | 60 | Mar, Salões (gelo), Forja, Torre, Carcosa | clava avisada; bata no aviso para interromper |
| Guarda da Casa | 70 | Mar, Salões, Forja (forja), Torre, Observatório | escudo de frente bloqueia tudo; vira devagar: ataque pelas costas ou durante o golpe dele |
| Peregrino Cinzento | 26 | Mar, Jardim | se incendeia e explode (queima); matar no aviso explode mesmo assim |
| Assassino da Duna | 40 | Mar, Salões, Carcosa | nada sob a cinza (invulnerável enterrado); emerge e corta |
| Atirador de Vidro | 34 | Mar, Forja | mira visível que trava antes do tiro; role através |
| Inquisidor Profeta (elite) | 90 | Mar | dois cortes de incensário; salto com onda de choque |
| Fulgurante (perigo) | — | Mar | o chão estala e um espinho de vidro sobe embaixo de você |
| Lobo Pálido | 44 | Salões, Jardim | corre, abaixa (aviso) e dá o bote em linha reta |
| Sentinela de Gelo | 40 | Salões, Observatório | três lascas em leque |
| Ferreiro Cativo | 110 | Forja | martelada lenta com faíscas que queimam dos dois lados; firme |
| Escória Viva | 30 | Forja | pula atrás de você, encostar queima, morta vira poça |
| Gárgula | 38 | Torre | voa, paira e mergulha em diagonal; depois sobe devagar |
| Escriba Mudo | 46 | Torre | fica de longe e escreve um glifo que persegue |
| Fera-Musgo | 80 | Jardim | investida em linha reta; batendo na parede, fica tonta |
| Espinheiro | 34 | Jardim | planta parada; três espinhos em arco |
| Mascarado | 52 | Carcosa | some e aparece atrás de você, e corta |
| Arauto Pálido | 40 | Carcosa | o sino chama duas almas que flutuam e explodem |
| Autômato Astral | 70 | Observatório | o olho acende e solta um raio na horizontal |
| Estrela Caída | 16 | Observatório (e as almas do Arauto) | flutua até você, pisca e explode |
| Caçador do Inverno (elite) | 130 | Salões | lanças de gelo, investida, corte |
| Mestre-Ferreiro (elite) | 160 | Forja | martelada que queima, ondas no chão, chuva de fogo |
| Bibliotecário Cego (elite) | 120 | Torre | anel de glifos, glifos teleguiados, teleporte |
| Guardiã de Espinhos (elite) | 140 | Jardim | cipós sobem do chão, anel de espinhos, corte |
| Duelista Amarelo (elite) | 120 | Carcosa | teleporte com corte, golpes rápidos, investida |
| Sentinela de Latão (elite) | 150 | Observatório | raio, anéis de estrelas, colunas de luz |
| O Lobo da Longa Noite | 1100 | arena dos Salões | ver seção 10 |
| O Colosso da Bigorna | 1400 | arena da Forja | ver seção 10 |
| O Arquiteto Mudo | 1500 | arena da Torre | ver seção 10 |
| A Mãe-Raiz | 1600 | arena do Jardim | ver seção 10 |
| O Rei sem Rosto | 1700 | arena de Carcosa | ver seção 10 |
| O Último Astrônomo | 1800 | arena do Observatório | ver seção 10 |
| O Imperador Cego | 2200 | Trono (final) | ver seção 10 |

---

## 10. Os chefes em detalhe

**Regras comuns** (base `Boss` em `scripts/enemies/boss.gd`):
- **Entrada:** apresentação de 1,6 s, com som próprio.
- **Ciclo de cada golpe:** aviso → golpe → respiro.
- **Exaustão:** a cada 3 golpes o chefe fica exausto ("EXAUSTO") e leva +50% de dano. É a janela.
- **Fase 2:** com metade da vida ele se enfurece; tudo fica 25% mais rápido e entram golpes novos.
- **Não é interrompido** e ignora empurrão.

**Tipos de golpe da base:**
- corpo a corpo;
- salto com onda de choque;
- investida até a parede;
- rajada (mirada, em leque, em anel, em arco ou teleguiada);
- chuva de perigos (prevendo para onde você vai);
- invocação;
- teleporte com golpe;
- raio horizontal na sua altura;
- ondas que correm pelo chão.

| Chefe | Fase 1 | Entra na fase 2 |
|---|---|---|
| **Lobo da Longa Noite** | investida, mordida, leque de lascas de gelo | uivo que chama 2 lobos, chuva de estalactites prevendo você, salto |
| **Colosso da Bigorna** | martelada que queima, ondas de choque pelo chão, chuva de fogo | salto, invoca 3 escórias |
| **Arquiteto Mudo** | glifos teleguiados, colunas de luz prevendo você, anel duplo de glifos | teleporte, raio horizontal, invoca escribas |
| **Mãe-Raiz** (não se move) | cipós sobem do chão prevendo você, espinhos em arco, nuvens de esporos | invoca espinheiros, anel de 12 espinhos |
| **Rei sem Rosto** | teleporte com corte, corte, glifos rápidos, tentáculos prevendo você | invoca mascarados, investida |
| **Último Astrônomo** | anéis de estrelas, raio horizontal, colunas de luz | estrelas teleguiadas, invoca estrelas caídas, teleporte |
| **Imperador Cego** (final, classe própria) | **profecia:** a coluna de luz cai onde você **vai estar** (ele lê sua velocidade); varredura de cetro (dá para aparar) | some e reaparece, **Três Visões** (onde você está, onde vai e onde estaria se voltasse), chama peregrinos; ajoelha exausto depois das profecias |

---

## 11. História: abertura, final e Códice

### Abertura (primeira partida; pode pular; revê no Códice)
1. Houve um tempo em que sete deuses dividiam o mundo. Cada um tinha um domínio, e cada domínio tinha a cara do seu deus.
2. Numa noite sem nome, todos sumiram. Ao mesmo tempo. Ninguém viu para onde foram.
3. Os domínios ficaram. Sem dono, apodreceram do jeito de cada um: a cinza ficou sagrada, o inverno não acabou, a forja não parou.
4. Você acordou na beira do Mar de Cinzas, com um manto que não lembra de ter vestido. A Vigia diz que você já esteve aqui antes. Muitas vezes.
5. Em algum lugar, no fim de tudo, está o Trono. Quem senta nele sabe o que aconteceu com os deuses.

### Final (depois do Imperador)
1. O Imperador Cego caiu. Pela primeira vez em mil anos, o Trono ficou vazio.
2. Você se senta. Por um instante, vê o que ele via: sete deuses, de mãos dadas, entrando numa porta de luz.
3. Não foram embora. Foram dormir. E o sonho deles é este mundo: cada domínio, um pesadelo de quem sonha.
4. Atrás da porta, uma voz que não é de deus nenhum: "Ainda não. Volte quando a brasa queimar mais."
5. A Vigia te encontra de novo na beira do Mar de Cinzas. "Você de novo. Ou outro igual a você."

### Final verdadeiro (só vencendo com as 4 brasas)
6. Com todas as brasas acesas, a porta não resiste. Do outro lado, sete cadeiras vazias.
7. E uma oitava, menor, de frente para as outras. Na madeira, alguém gravou o seu nome. Faz muito tempo.
8. Você entende, enfim, por que a Vigia sempre te reconhece. Você não chegou depois dos deuses. Você é o que eles deixaram para trás.

### Falas da Vigia
- "Você de novo. Ou outro igual a você. É difícil dizer."
- "A Essência é o que sobra quando algo morre acreditando. Traga mais."
- "Eu vigio a passagem desde que os deuses saíram por ela."

### Códice (título)
- **Inscrições:** todas as que você já leu, de qualquer partida.
- **Bestiário:** 31 verbetes. Aparecem as criaturas que você já derrotou; o resto fica "???".
- **Rever a abertura.**

---

## 12. Interface

- **HUD:**
  - **canto superior esquerdo:** vida (com a faixa amarela do dano recente), frascos, tecla de cura e maldição (caveira + contagem);
  - **canto superior direito:** ouro, Essência, níveis de Fúria (espada), Astúcia (olho) e Vigor (escudo), plantas carregadas;
  - **rodapé:** 4 slots (2 armas, 2 habilidades) com recarga e tecla;
  - **no alto:** faixas de título e avisos, contagem da Porta do Relógio;
  - **embaixo:** barra do chefe;
  - **com o cronômetro ligado:** tempo total e do andar.
- **Título:**
  - opções Começar, Desafio do Dia, Aparência, Códice, Estatísticas, Opções, Comandos e Sair;
  - brasas subindo na tela;
  - estatísticas resumidas.
- **Pausa:** Continuar, Opções, Comandos e Desistir. Mostra as mutações e as brasas.
- **Opções:**
  - volume geral, da música e dos efeitos (barramentos de áudio separados);
  - tela cheia;
  - intensidade do tremor (0 a 100%);
  - piscadas fortes (normais/reduzidas);
  - vibração do controle;
  - cronômetro na tela;
  - **troca de teclas** (aperte uma tecla para cada ação; "voltar ao padrão").
- **Estatísticas:**
  - partidas, vitórias e mortes;
  - andar mais fundo e tempo jogado;
  - melhor vitória;
  - quem mais te matou, quem você mais matou, armas favoritas;
  - resultado do desafio de hoje.
- **Menus:** texto longo rola; listas longas rolam; miniatura do herói ao escolher aparência.
- **Fonte:** duas fontes desenhadas pixel a pixel, 3x5 (números, HUD) e 5x7 (texto), com todos os acentos do português.
- **Telas:**
  - morte: lugar, abates, tempo e Essência perdida;
  - vitória: tempo, caminho percorrido, "NOVO RECORDE", brasas liberadas.

---

## 13. Arte e visual

- **Resolução interna:** 480x270, ampliada em escala inteira (sem borrar); filtro de textura "nearest".
- **Personagens:**
  - folhas de sprite com animação quadro a quadro;
  - geradas por um esqueleto posado: membros, capuz, manto, arma na pose;
  - duas passadas automáticas, luz por parte e contorno escuro.
- **Paleta por índice:** cada pixel da imagem guarda um **índice** (canal vermelho = índice × 16 + 8), e o jogo pinta com a paleta certa ao carregar (`SpriteSheet.texture`).
  - Uma folha serve para todas as aparências e para as versões recoloridas de inimigos (Penitente do gelo, Guarda da forja, lobo do musgo).
  - Também dá a versão branca (piscar de dano) e a versão "aviso" (laranja).
- **Herói:**
  - animações: parado, corrida (8 quadros), pulo, queda, rolagem (6), preparo, corte, volta, arco, escudo, cura, dano, escalada, mergulho e morte;
  - a arma é desenhada na mão de cada quadro;
  - o cachecol tem física (vento, queda);
  - o rastro da rolagem e do mergulho usa a silhueta.
- **Inimigos:**
  - poses de aviso que piscam em laranja e ficam brancos ao apanhar;
  - ao morrer, os pixels do quadro viram cinza que sobe;
  - o Assassino emerge recortando o sprite.
- **Blocos:**
  - tileset de pedra com 16 encaixes (lados abertos) x 4 variações, mais rocha funda (8 variações; ossos e veios de vidro raros) e prancha;
  - recolorido por domínio;
  - a rocha escurece com a profundidade.
- **Cenário:**
  - objetos: árvores mortas, colunas, ossos, montes de cinza, cacos que piscam, estandartes, correntes;
  - braseiros com luz que tremula;
  - cinza acumulada no pé das paredes.
- **Luz:**
  - o mundo fica na penumbra (`CanvasModulate`, tom por domínio) e luzes de verdade (`PointLight2D`) devolvem a cor;
  - fontes de luz: herói, fogo, Essência, itens, altares, portal, chefes, quem queima;
  - brilho (bloom) por `WorldEnvironment` nas camadas do mundo (o HUD fica fora).
- **Profundidade:** fundo pintado em 4 camadas de paralaxe, mais apagado que o mundo, e silhuetas no primeiro plano passando mais rápido (pedra pendurada, panos, entulho).
- **Acabamento:**
  - fio de luz na borda do golpe, estrela de impacto, risco do golpe;
  - vinheta nos cantos;
  - entrada de andar em pontilhado;
  - partículas e números numa camada fora da penumbra.
- **Prévias sem abrir o jogo:** `tools/previews/*.png` e `tools/mock_frame.py`, que monta um quadro com a mesma conta de luz do jogo. A pasta de prévias não vai para o git.

---

## 14. Música e sons

### Música (`tools/gen_music.py`, autoload `Music`)
- **Composição:** sintetizada com numpy.
- **Instrumentos:** baixo triangular, pulso, arpejo, sino FM, pad de dente-de-serra filtrado, coro, bumbo, caixa, chimbal, tambor grave, bigorna e chocalho.
- **Melodia:** passeio aleatório com semente fixa, que cai em nota do acorde nos tempos fortes.
- **Loop:** sem emenda; o rabo da faixa é dobrado sobre o começo.
- **Troca:** suave, por cruzamento de volume.
- **Formato:** mono, 22 kHz, cerca de 17 MB no total.

| Faixa | Tempo | Tom | Quando toca |
|---|---|---|---|
| titulo | 66 bpm | Ré menor | título, vitória |
| passagem | 60 bpm | Fá lídio | passagens, abertura, final |
| mar_de_cinzas | 96 | Ré frígio | Mar de Cinzas |
| saloes | 72 | Mi menor | Salões |
| forja_rubra | 132 | Dó menor harmônica | Forja |
| torre_babel | 110 | Lá dórico | Torre |
| jardim_primordial | 88 | Sol lídio | Jardim |
| carcosa | 80 | Si♭ lócrio | Carcosa |
| observatorio | 100 | Fá♯ lídio | Observatório |
| chefe | 150 | Ré menor harmônica | arenas dos guardiões |
| chefe_final | 140 | Mi frígio dominante | Trono |
| necropole | 60 | Dó menor | Necrópole |
| catedral | 70 | Sol dórico | Catedral Submersa |
| ventre | 90 | Dó♯ frígio | O Ventre |
| penhascos | 84 | Lá lídio | Penhascos do Sonho |
| cavernas | 76 | Si lócrio | Cavernas Fundas |
| bosque | 104 | Sol Hijaz, 7/8 | Bosque Errante |

**Trilha nova (04/11, pedido dele: "inspirar na trilha de Duna do Villeneuve"):** composição original, no clima desértico-ritual — drones graves, BRAAM de metais distorcidos, voz feminina por formantes (vogais a/e/i/o/u com vibrato e ornamentos), canto gutural, duduk/gaita de fole, taiko e frame drum em grupos irregulares, raspados metálicos, reverb sintético. Nenhuma melodia de Duna é usada. 17 faixas, 37,5 MB.

**Verificação:** como eu não podia ouvir, as trilhas foram conferidas por números: volume médio, pico, emenda do loop e energia acima de 6 kHz. Isso pegou um sino com aliasing (chiado), que foi corrigido.

### Sons (`tools/gen_sfx.py`, autoload `Sfx`, 66 sons)
`bell block blueprint boom boss_die boss_intro boss_phase bow burrow chain_pull chain_throw coin crack crit curse death door_close drink enemy_die essence fragment fuse gargoyle_screech glyph hammer_slam hit howl hurt jump land laser_charge laser_fire merchant_buy moss_charge mutation omen page parry pickup pillar portal roar roll rune secret shield_up slag_hop slam spike spirit_call star_pop swing swing_heavy teleport thorn_shoot throw trap_cut trap_set turret_shot ui_move ui_ok ui_open unlock wall_break wind wolf_bite`

Cada chefe e elite tem um mapa próprio de som por tipo de golpe (`sounds` no script).

---

## 15. Arquitetura do código

```
project.godot        autoloads: Controls, Fx, Sfx, Meta, Run, Options, Music
scenes/main.tscn     -> scripts/main.gd (fluxo: título → andares → morte/vitória)
scripts/
  core/      Damage (pacote de dano), Actor (base de quem tem vida, contorno),
             PlayerInput, SpriteSheet (pinta folhas de índice com paleta)
  combat/    WeaponData, SkillData, Gear (item + nível + afixos), Projectile,
             Combat (atributos, críticos), Catalog (lista oficial de tudo),
             Deployable (armadilha/torreta/espírito), Story (textos)
  actors/    Player, SkinData, HeroLook (paleta e miniatura do herói)
  enemies/   Enemy (base com sprite, aviso, firmeza, morte em cinza),
             Boss (base dos chefes e elites), cada inimigo, cada chefe (boss_*),
             cada elite (elite_*), BlindEmperor, Hazard (perigo com aviso),
             HazardEmitter + subclasses (tentáculo, esporo, meteoro),
             FireVent, Icicle, FallingStone, Fulgurant, EnemyLooks (paletas)
  world/     Room (mapa, colisão, paredes falsas e rachadas, profundidade, enfeites),
             RoomTemplate + LevelGen (gerador), Level (monta o andar, drops, mapa),
             Interactable + Pickup, Altar, MutationAltar, RuneAltar, Inscription,
             ExitGate, Keeper (Vigia), Merchant, Chest, TimedDoor, BlueprintDrop,
             EssenceOrb (Essência e ouro), Brazier, Glow (luzes), CameraRig,
             Backdrop, Foreground, Weather, Sparks (partículas e números)
  biomes/    BiomeData (tudo que faz um bioma ser ele mesmo)
  ui/        Hud, Menu, Screen (título/morte/vitória), OptionsScreen, MapView,
             Cutscene, Vignette, Curtain, PixelFont, Palette
  autoload/  Controls (comandos e dicas), Fx, Sfx, Music, Meta (save permanente),
             Run (partida atual, rota, dificuldade, desafio do dia), Options
  debug/     ScriptedInput (controle por roteiro nos testes)
content/
  weapons/ skills/ skins/        .tres gerados por tools/gen_content.py
  biomes/<id>/biome.tres         cores, céu, fundo, clima, inimigos, elite, chefe, perigo, runa, textos
  biomes/<id>/rooms/*.txt        salas
  biomes/mar_de_cinzas/chefe/trono.txt, arena.txt, passagem.txt
assets/sprites/  folhas de índice (.png) + animações (.json)
assets/music/    trilhas .wav      assets/sfx/  sons .wav
tests/           run_tests (52 testes), shots (prints com janela; NÃO usar sem ele pedir)
tools/           geradores (seção 16)
docs/            PLANO_EXPANSAO.md (checklists das rodadas)
```

### Princípios
- **Bioma é dado, não código.** Os sistemas não conhecem nenhum bioma: leem o `biome.tres`.
- **Arma e habilidade são dados.** Combos, críticos e parâmetros ficam em `.tres`.
- **Chefe é uma lista de golpes** (dicionários) executada pela base `Boss`. Elite é um `Boss` em modo elite (`aggro_range`).
- **Teste nunca toca o save real.**

### Formato das salas (`.txt`)
- **Cabeçalho:** `; tipo: inicio|combate|corredor|elite|tesouro|fragmento|saida|loja|cofre|runa|chefe|passagem` e `; peso: N`.
- **Blocos:**

| Caractere | Significado |
|---|---|
| `#` | pedra |
| `=` | plataforma (atravessa por baixo; S+pulo desce) |
| `F` | parede falsa (sala secreta) |
| `K` | parede rachada (Punho do Ferreiro) |
| `.` | vazio |
| `D` | porta, na borda |

- **Marcadores:**

| Caractere | Significado |
|---|---|
| `P` | início |
| `e` | inimigo |
| `r` | inimigo de longe |
| `E` | elite |
| `B` | chefe |
| `i` | item |
| `f` | fragmento divino |
| `L` | inscrição |
| `X` | saída |
| `V` | Vigia |
| `w` | perigo do domínio |
| `M` | altar de mutação |
| `c` | baú |
| `$` | mercador |
| `T` | Porta do Relógio |
| `U` | altar de runa |
| `g`/`a` | inimigos fixos (testes) |

- **Portas:** na esquerda/direita, uma coluna de `D` com 4 de altura no chão; no teto/chão, uma fileira de `D`. Porta não usada vira parede.
- **Encaixe:** o gerador alinha as portas pela base (laterais) ou pela esquerda (teto/chão).

### Como acrescentar
- **Arma, habilidade ou aparência:** editar `tools/gen_content.py`, rodar e pôr o caminho em `Catalog`.
- **Sala:** um `.txt` na pasta do bioma, e depois rodar `python tools/validar_salas.py`.
- **Inimigo:**
  - script que estende `Enemy`, com `telegraphing()`, `sprite_anim()` e folha em `gen_enemies.py`/`gen_bestiary.py`;
  - paleta em `EnemyLooks`;
  - entrada no `enemies` do bioma;
  - verbete em `Story.BESTIARY` (um teste cobra isso).
- **Chefe:** script que estende `Boss` com a lista `moves` (e `moves2` para a fase 2).
- **Bioma:** `tools/biomas.py` + fundo em `backdrop_dominios.py` + salas + trilha em `gen_music.py` + entrada em `Run.STAGES` e `Catalog`.

---

## 16. Ferramentas (tools/)

| Script | O que faz |
|---|---|
| `pixelrig.py` | base do desenho: formas, luz por parte, contorno, folha de índices, prévia colorida |
| `gen_sprites.py` | herói (todas as animações) |
| `gen_enemies.py` | inimigos do Mar, Salões, Forja e o Imperador; paletas |
| `gen_bestiary.py` | inimigos, chefes e elites dos domínios (humanoide com escala, planta, gárgula, estrela, fera, lobo-rei) |
| `gen_tiles.py` | tileset de pedra |
| `gen_backdrop.py` + `backdrop_dominios.py` | fundos pintados dos 7 domínios |
| `gen_props.py` | Vigia, altares, pedestal, estela, portal, braseiro, baús, mercador, Porta do Relógio |
| `mock_frame.py` | quadro de mentira com a luz do jogo, para avaliar a arte sem abrir o jogo |
| `gen_content.py` | armas, habilidades e aparências (.tres) |
| `biomas.py` | `biome.tres` dos domínios (elite, chefe, perigo, textos) |
| `salas_mar_de_cinzas.py` | salas originais do Mar e o Trono |
| `salas_andares.py` | conjunto base dos domínios, desvios em 4 versões, peças comuns, arena, passagem, escada automática até portas do teto |
| `salas_dominios.py` | 7 salas próprias por domínio, geradas por plantas e aprovadas pelo verificador |
| `validar_salas.py` | confere todas as salas com o pulo real |
| `gen_music.py` | as 11 trilhas |
| `gen_sfx.py` | os 66 sons |

**Depois de gerar arte ou som:** rodar o Godot uma vez com `--headless --import`
(`Godot_console.exe --headless --import --path .`) para reimportar.

---

## 17. Testes e verificação

### 52 testes automáticos (`tests/run_tests.gd`, física de verdade, controle por roteiro)

**Movimento**
- pulo sobe ~3 blocos;
- soltar o pulo cedo dá pulo curto;
- ainda pula logo depois de sair da beirada;
- não pula no ar depois da tolerância;
- rolagem deixa invencível;
- agarra a beirada e sobe muro de 4 blocos;
- S + pulo desce da plataforma.

**Combate e equipamento**
- combo da espada tira 10+12+26;
- estilhaço acerta quem fica parado e atravessa quem rola;
- mergulho machuca quem está embaixo;
- frasco cura metade da vida;
- arco atira e crítico de longe vale mais;
- granada explode e queima;
- atributo aumenta o dano da arma certa;
- guarda defende de frente e apanha pelas costas;
- aparo devolve o estilhaço;
- armadilha, torreta, espírito e corrente acertam;
- afixos: afiada dá mais dano, vampira cura.

**Inimigos e chefes**
- penitente avisa e acerta; golpe no aviso interrompe;
- peregrino explode e queima;
- assassino enterrado não leva dano;
- profecia do Imperador mira à frente do herói;
- ferreiro, escória, lobo e sentinela acertam;
- jato de fogo e estalactite machucam;
- os 7 guardiões lutam, acertam e entram na fase 2;
- os 8 inimigos dos domínios novos acertam;
- os 6 elites atacam e acertam.

**Progressão e partida**
- altar sobe o atributo;
- matar inimigo solta Essência;
- desbloqueio fica salvo;
- aparências: trancadas, compradas, feitos e salvas;
- rota completa do Mar ao Trono (8 andares);
- passagem tem Vigia, altar e as saídas certas;
- altar de mutação e Sangue Quente;
- baú maldito mata no primeiro golpe;
- Porta do Relógio abre a tempo e fecha atrasada;
- planta cai, a Vigia guarda e passa a vender;
- Asa de Cinza dá pulo duplo;
- parede rachada só cede com o Punho;
- brasas: inimigo mais forte e bate mais;
- mercador vende e o item aparece;
- desafio do dia, estatísticas e recorde;
- história: abertura, final verdadeiro, Códice e verbete para todo inimigo.

**Conteúdo e interface**
- armas e habilidades carregam;
- gerador: 20 mapas com caminho;
- gerador dos 7 domínios com loja, cofre, runa e relógio;
- sala do chefe carrega; sala de treino carrega;
- fonte tem toda letra dos textos;
- opções: volume, tremor e troca de tecla.

### Verificador de salas (`tools/validar_salas.py`)
- **Modelo do herói:** anda, cai, pula até 3 blocos (4 agarrando a beirada) e atravessa plataforma por baixo.
- **Exige:**
  - todas as portas alcançáveis a partir da entrada;
  - quem entra por qualquer porta consegue sair (ninguém fica preso);
  - porta no teto com chão a até 2 blocos abaixo;
  - todo marcador importante alcançável (nichos de pulo duplo viram aviso).
- **Situação:** 241 salas, 0 problemas. Roda no `Testar.bat`.

### Sondas sem tela
Durante o trabalho, simulações rodaram:
- o fluxo inteiro: título, aparência, Códice, abertura, andares, chefes, final verdadeiro e vitória;
- as duas rotas completas de 8 andares, matando tudo e usando todos os objetos;
- medição de tempo por quadro: o trabalho real ficou bem abaixo de 1 ms.

### O que NÃO foi verificado
- ninguém jogou de verdade com teclado ou controle;
- a imagem real do jogo rodando com a arte final;
- a música e os sons de ouvido;
- o equilíbrio (vida, dano, preços, ouro).

---

## 18. Problemas encontrados e corrigidos

**Física e mapa**
- O teste do "pulo no ar" passava por engano (o fosso era raso).
- A arena do chefe colava o chão na borda da tela, debaixo do HUD; ganhou chão extra.
- A granada passava por cima dos inimigos; o arco foi ajustado para explodir em qualquer contato.

**Combate**
- O aparo destruía o projétil em vez de devolver.
- O assassino aparecia atravessando o chão; o sprite agora é recortado.

**Telas e textos**
- A tela de morte mostrava o lugar errado.
- A fonte não tinha acentos ("FURIA", "NIVEL", "DOMINIO").
- Um texto longo vazava da caixa do menu de aparências.

**Arte e visual**
- O fundo ficou mais claro que o mundo depois da penumbra; foi escurecido.
- As silhuetas do primeiro plano pareciam borrões; foram refeitas com borda de luz.
- A cabeça do martelo do Ferreiro saía do quadro.
- A venda do Imperador sumia no rosto escuro.
- O arco quebrado do fundo parecia a letra "f".
- O gigante congelado parecia um bloco com um "O".

**Economia e menus**
- A Vigia e o Mercador não conferiam o saldo dentro da compra (ouro e Essência negativos numa simulação).
- O menu podia chamar uma escolha antiga depois de mostrar texto.
- O baú maldito não abria (lista de opções com tipo errado).
- O cofre quase nunca aparecia: faltava porta livre, então os desvios foram reordenados e ganharam portas extras.

**Salas** (achados pelo verificador)
- portas no teto inalcançáveis;
- desvios abaixo do caminho onde quem caía ficava preso;
- item 5 blocos acima do chão;
- fragmento flutuando sobre buraco;
- degraus da torre altos demais.

**Som**
- Sino com aliasing (chiado agudo) e quinas de onda quadrada.
- Emenda do loop da música com salto.

**Código**
- `match` dentro de função anônima não compilava (`main.gd`).
- Quebra de linha literal dentro de string.
- Caractere de controle no caminho do `Testar.bat`.
- `advance()` da cena de história estourava depois da última página.

---

## 19. Armadilhas técnicas aprendidas

- **Inferência de tipo:** o projeto trata "tipo inferido de Variant" como erro. Use `var x: String = dict[...]`, nunca `:=` em leitura de Dictionary.
- **`match` em lambda:** dentro de função anônima passada como argumento, não compila. Use método nomeado.
- **Script novo:** depois de criar ou mover um script, rode `--headless --import` antes, senão o `class_name` novo não resolve.
- **Variáveis de classe:** declaração repetida (`var` duplicada) quebra o carregamento da classe e de todos os scripts que a usam.
- **Sondas sem tela:** sem `--fixed-fps`, os quadros de desenho correm à frente da física. Espere `physics_frame`, não `process_frame`.
- **Captura com janela:** se parar no meio, quase certamente a janela foi minimizada (o `frame_post_draw` não chega). Não é travamento.
- **Brilho no Compatibility:** o brilho do `WorldEnvironment` funciona; sem HDR 2D, use `glow_hdr_threshold` abaixo de 1.
- **Áudio WAV:** o Godot importa WAV comprimido em QOA. O fim do loop é `get_length() * mix_rate`, não o tamanho dos dados.
- **Bash do Windows:** heredoc com `\\`, `\t` ou `\v` dentro de Python quebra o comando ou vira caractere de controle. Escreva o script num arquivo e rode.
- **Pastas fora do Godot:** um `.gdignore` em `tools/` impede o Godot de importar as prévias.
- **Salas:** o teste antigo de "caminho pelo ar" não pegava salas impossíveis. Toda sala nova passa por `validar_salas.py`.

---

## 20. Decisões de design

- **Mar de Cinzas sem cara de Duna:** o recurso disputado são as **Cinzas Sagradas** (restos de um deus que ardeu), e as criaturas sob a areia são de **vidro fundido** (fulgurantes), não vermes.
- **Nomes próprios em tudo:** Essência, Fragmentos Divinos, Vigia, Fúria/Astúcia/Vigor, Brasas do Deus, plantas, runas. Nenhum termo do Dead Cells.
- **Rota:** o Imperador Cego (deus-imperador do Mar) virou o chefe **final** no Trono; cada outro domínio tem o seu guardião.
- **Dois caminhos por camada**, como no Dead Cells: um mais calmo e um mais perigoso que paga melhor.
- **Plantas só valem se chegarem à Vigia**, para dar peso a morrer com elas.
- **Baú maldito pergunta antes**, para nunca matar por surpresa.
- **Nichos de pulo duplo** e **cofres atrás de parede rachada** dão motivo para voltar com as runas (a parte metroidvania).
- **Arte gerada por código, com paleta por índice:** trocar por arte feita à mão depois não exige mexer no jogo.
- **Todo ataque avisado** e golpe no aviso interrompe: essa é a regra de leitura do combate.
- **Verificação sem tela:** imposta pela regra de não abrir janela; por isso há tantos testes, sondas e prévias.

---

## 21. O que falta e ideias não feitas

**Depende dele**
- **Jogar.** Sensação do pulo, da rolagem e do peso dos golpes; dificuldade dos chefes; ritmo dos andares; preços; música.
- **Penumbra:** ver se o mundo não ficou escuro demais (o ajuste é `Level.AMBIENT` e o `ambient` de cada bioma).
- **Arte final:** se alguém for desenhar, troca as folhas em `assets/sprites/`. O tamanho dos personagens (~22 px de altura) é o que vale hoje.
- **Nome definitivo do jogo.**
- **O repositório é público:** mudar para privado se quiser.

**Sugerido e ainda não feito**
1. **Robô que joga sozinho:** dezenas de partidas sem tela, medindo onde morre, quanto tempo leva e onde trava.
2. **Equilíbrio medido** com os dados desse robô.
3. **Exportar:**
   - `.exe` para Windows;
   - versão web no GitHub Pages, para jogar no navegador.

   Os dois precisam dos modelos de exportação do Godot.
4. **Salvar no meio da partida** e continuar depois.
5. **Primeira partida guiada:** dicas no contexto (rolar, Vigia, plantas, runas).
6. **Mais variedade:**
   - mais armas e habilidades;
   - mais mutações;
   - mais salas feitas à mão nos domínios novos (hoje base genérica + 7 geradas por domínio);
   - inimigos próprios para trocar os reaproveitados.

---

## 22. Histórico de commits

| Commit | Hora | O que |
|---|---|---|
| 5adc192 | 11:38 | Protótipo: movimento, combo, rolagem, beirada, mergulho, 2 inimigos e testes |
| 445eed3 | 11:38 | gitattributes |
| 8302fa5 | 11:59 | Arquitetura modular: dano, armas e habilidades como dados, Mar de Cinzas (inimigos, gerador, chefe), progressão e menus |
| 6a9d44a | 12:03 | Sons sintetizados, prints de verificação, arena do chefe com chão, README e lançadores |
| 685359c | 12:03 | bat com CRLF |
| 3c04e90 | 14:45 | Visual: luz e brilho, contorno, cachecol, morte em cinza, cenário, névoa, primeiro plano, fonte com acentos, HUD com ícones; aparências |
| 6338147 | 15:20 | Arte em pixel: herói e inimigos animados, tileset, fundo pintado, objetos |
| 6edf871 | 15:22 | Acabamento: fio de luz no golpe, estrela de impacto, vinheta, entrada em pontilhado |
| ff29b19 | 15:55 | Andares no estilo Dead Cells: rota, passagens, mapa, ouro, mercador, baús, relógio, plantas, runas, brasas; Salões e Forja |
| 0851d9f | 15:55 | Três armas novas e README da partida completa |
| 48127b0 | 16:10 | Opções completas |
| c5583f7 | 16:14 | Música: 11 trilhas |
| af80a59 | 16:33 | Habilidades novas e afixos |
| 1f11b31 | 16:45 | Chefes por andar e 4 domínios novos (rota de 8 andares) |
| 4e5b389 | 16:47 | Desafio do dia, estatísticas, recorde |
| bca4bef | 16:48 | README da expansão |
| dfd6237 | 16:57 | Plano da segunda rodada |
| e26e9c5 | 17:03 | Salas próprias por domínio e verificador de salas com o pulo real |
| 34cdd81 | 17:04 | Testar.bat: caminho do verificador |
| f0b883d | 17:05 | Elite próprio em cada domínio |
| 0d88885 | 17:07 | Sons novos |
| dcd00c2 | 17:11 | História: abertura, final, final verdadeiro, Códice |

---

## 23. Apêndice: GDD original

Documento que ele colou no começo, sem alteração. Ele definiu a visão; a
seção 20 registra onde o jogo seguiu ou adaptou.

### O LEGADO DOS DEUSES
#### Documento de visão do jogo — Game Design Document (GDD)

##### 1. VISÃO GERAL

**Nome provisório:** O Legado dos Deuses  
**Gênero:** Action Roguelite / Metroidvania  
**Referência de gameplay:** Dead Cells  
**Ambientação:** Dark Fantasy, mitologia, ficção científica e horror cósmico.  
**Perspectiva:** 2D, plataforma e combate lateral.

O objetivo é desenvolver um jogo inspirado na estrutura de Dead Cells, especialmente na exploração de diferentes biomas, progressão por fases, combate dinâmico, chefes e caminhos alternativos.

Entretanto, o universo, a história, os personagens, os inimigos, os cenários e a identidade visual devem ser completamente originais.

A principal característica do jogo será a diversidade de seus biomas. Cada região terá uma ambientação visual, arquitetura, cultura, criaturas, inimigos e atmosfera próprias, mas todas estarão conectadas por uma narrativa central.

---

##### 2. PREMISSA NARRATIVA

Durante milhares de anos, os deuses governaram a existência.

Cada divindade possuía seu próprio domínio, representando diferentes aspectos da existência: guerra, morte, vida, destino, conhecimento, ambição e criação.

Sob a influência dessas divindades, civilizações inteiras prosperaram, desenvolveram religiões, construíram impérios e estabeleceram suas próprias formas de organização.

Entretanto, em algum momento, os deuses desapareceram misteriosamente.

Antes de desaparecerem, deixaram seus domínios sob responsabilidade das civilizações que governavam.

Com o passar dos séculos, esses territórios seguiram caminhos completamente diferentes. Alguns prosperaram, outros entraram em decadência, enquanto outros foram consumidos por forças desconhecidas.

O mundo passou a ser formado por territórios muito distintos, cada um carregando as consequências do legado de uma divindade.

O protagonista deverá atravessar esses territórios, enfrentando criaturas, guerreiros, entidades e antigos guardiões, buscando descobrir o que aconteceu com os deuses.

A narrativa deve ser construída gradualmente, através de exploração, diálogos, inscrições, documentos, personagens e acontecimentos ambientais.

**Mistério central:** por que os deuses desapareceram e o que realmente aconteceu com seus domínios?

---

##### 3. IDENTIDADE ARTÍSTICA

O jogo deverá combinar diferentes estilos visuais sem perder sua identidade geral.

Principais referências artísticas e conceituais:

- Dune: desertos monumentais, civilizações imperiais, profecias, messianismo, disputas políticas e criaturas colossais.
- Star Wars: mundos visualmente distintos, ordens de guerreiros, conflitos entre civilizações e tragédias pessoais.
- Mitologia grega e nórdica: divindades, titãs, monstros, templos e narrativas épicas.
- Robert Eggers: atmosfera sombria, folclore, simbolismo, arquitetura antiga e horror.
- True Detective: mistério, cultos, decadência e horror psicológico.
- Nietzsche: ambição, vontade de poder, decadência, superação e natureza humana.

Essas referências devem servir como inspiração temática e estética, nunca como reprodução de personagens, cenários ou propriedades intelectuais existentes.

---

##### 4. BIOMAS PRINCIPAIS

Cada bioma representa o antigo domínio de uma divindade e deve possuir identidade própria.

###### BIOMA 1 — O MAR DE CINZAS
**Tema:** deserto, impérios e messianismo.

Um território desértico gigantesco, governado por diferentes casas aristocráticas que disputam o controle de um recurso extremamente raro.

A população acredita em uma antiga profecia sobre o retorno de uma figura divina.

Características:
- Dunas gigantescas.
- Tempestades de areia.
- Fortalezas imperiais.
- Templos proféticos.
- Criaturas colossais subterrâneas.
- Guerreiros tribais e assassinos.

Referências: Dune, Paul Atreides, política imperial e messianismo.

Chefe sugerido: O Imperador Cego, um antigo governante que sacrificou sua humanidade para enxergar o futuro.

###### BIOMA 2 — A FORJA RUBRA
**Tema:** guerra, fogo e corrupção.

Um território vulcânico onde existia uma antiga ordem de guerreiros dedicados à divindade da guerra.

Após conflitos internos, a ordem foi destruída e suas fortalezas foram tomadas por guerreiros corrompidos.

Características:
- Vulcões ativos.
- Rios de lava.
- Fortalezas de obsidiana.
- Templos destruídos.
- Máquinas de guerra.
- Guerreiros e criaturas de fogo.

Referências: tragédias de Star Wars, Anakin Skywalker e mitologia grega.

Chefe sugerido: O Herdeiro Caído, um guerreiro que destruiu sua própria ordem acreditando estar salvando aqueles que amava.

###### BIOMA 3 — OS SALÕES DO ÚLTIMO INVERNO
**Tema:** morte, honra e destino.

Um antigo reino inspirado nas civilizações nórdicas.

Os deuses desapareceram e seus guerreiros continuam lutando, sem perceber que a guerra divina terminou há séculos.

Características:
- Montanhas congeladas.
- Vilarejos vikings.
- Fortalezas de pedra.
- Cemitérios monumentais.
- Salões dos mortos.
- Criaturas mitológicas.

Referências: mitologia nórdica, Ragnarök e folclore europeu.

Chefe sugerido: O Último Einherjar, um guerreiro que continua esperando uma batalha que nunca acontecerá.

###### BIOMA 4 — A TORRE DE BABEL
**Tema:** ambição, conhecimento e arrogância humana.

Uma civilização ancestral que tentou construir uma estrutura capaz de alcançar os céus e desafiar a própria divindade.

Características:
- Zigurates gigantescos.
- Jardins suspensos.
- Bibliotecas ancestrais.
- Arenas imperiais.
- Distritos aristocráticos.
- Estruturas monumentais.

Referências: Mesopotâmia, mitologia bíblica, história antiga e filosofia política.

Chefe sugerido: O Primeiro Rei, um soberano que acredita que a humanidade deve superar os próprios deuses.

###### BIOMA 5 — CARCOSA
**Tema:** loucura, esquecimento e horror cósmico.

Uma cidade misteriosa onde as leis da realidade parecem não funcionar corretamente.

Seus habitantes desenvolveram cultos em torno de uma entidade desconhecida.

O tempo parece circular, pessoas encontram versões de si mesmas e a arquitetura muda constantemente.

Características:
- Pântanos decadentes.
- Igrejas abandonadas.
- Vilarejos isolados.
- Teatros antigos.
- Ruínas impossíveis.
- Templos de uma entidade desconhecida.

Referências: True Detective, Rei de Amarelo, Lovecraft e horror psicológico.

Chefe sugerido: O Rei Amarelo, uma entidade cuja existência desafia a compreensão humana.

###### BIOMA 6 — O JARDIM PRIMORDIAL
**Tema:** vida, evolução e natureza.

Um território onde a vida evoluiu sem interferência humana.

Florestas cobrem continentes inteiros, organismos desenvolveram inteligência e a própria natureza parece possuir uma consciência coletiva.

Características:
- Árvores gigantescas.
- Ruínas tomadas pela vegetação.
- Ecossistemas subterrâneos.
- Criaturas biológicas.
- Plantas predatórias.
- Organismos parasitas.

Referências: biologia evolutiva, horror corporal e mitologia da criação.

Chefe sugerido: A Primeira Vida, uma consciência biológica que considera qualquer forma de existência independente uma ameaça.

###### BIOMA 7 — O OBSERVATÓRIO CELESTE
**Tema:** tempo, conhecimento e destino.

Uma estrutura monumental dedicada à divindade do conhecimento.

Seus habitantes estudavam as possibilidades do futuro e acreditavam que todos os acontecimentos poderiam ser previstos.

Características:
- Observatórios gigantescos.
- Bibliotecas cósmicas.
- Máquinas astronômicas.
- Salas que desafiam a gravidade.
- Estruturas suspensas.
- Criaturas relacionadas ao tempo.

Referências: cosmologia, física, determinismo e filosofia da consciência.

Chefe sugerido: O Observador, uma entidade que conhece todos os futuros possíveis.

---

##### 5. ESTRUTURA DE GAMEPLAY

A estrutura deve seguir a filosofia de progressão de Dead Cells.

O jogador percorre diferentes mapas, enfrenta inimigos, encontra equipamentos, coleta recursos, derrota chefes e desbloqueia novos caminhos.

Características desejadas:

- Combate 2D dinâmico.
- Movimentação fluida.
- Saltos, esquivas e habilidades especiais.
- Armas de diferentes categorias.
- Habilidades ofensivas e defensivas.
- Equipamentos com atributos e efeitos distintos.
- Inimigos específicos para cada bioma.
- Chefes únicos.
- Rotas alternativas entre regiões.
- Progressão permanente através de desbloqueios.
- Segredos, salas escondidas e recompensas de exploração.

A progressão deverá permitir que o jogador escolha diferentes caminhos entre os biomas, criando variações entre as partidas.

Cada região deverá possuir múltiplos mapas ou salas conectados, evitando que o bioma seja apenas uma única tela ou cenário.

A geração dos mapas deverá priorizar variedade, exploração, rejogabilidade e posicionamento interessante de inimigos e recompensas.

---

##### 6. DIREÇÃO DE COMBATE

O combate deverá ser rápido, responsivo e baseado em habilidade.

Categorias de equipamentos desejadas:

- Espadas e armas corpo a corpo.
- Lanças e armas de longo alcance.
- Machados e armas pesadas.
- Arcos e armas de projéteis.
- Magias e habilidades divinas.
- Relíquias e artefatos ancestrais.

Cada bioma poderá oferecer equipamentos tematicamente relacionados à sua divindade.

Exemplos:
- Armas de fogo e obsidiana na Forja Rubra.
- Armas cerimoniais no Mar de Cinzas.
- Armas rúnicas nos Salões do Último Inverno.
- Artefatos astronômicos no Observatório Celeste.

---

##### 7. IDENTIDADE DOS INIMIGOS E CHEFES

Os inimigos não devem ser simplesmente reutilizados com aparências diferentes.

Cada bioma deverá possuir:
- Inimigos comuns.
- Inimigos de elite.
- Criaturas ambientais.
- Mini chefes.
- Um chefe principal.

Os chefes deverão ter personalidade, história, design visual e padrões de combate próprios.

A intenção é que cada encontro importante tenha peso narrativo e mecânico.

---

##### 8. NARRATIVA E LORE

A história não deve ser explicada inteiramente através de diálogos ou textos extensos.

Utilizar principalmente:
- Inscrições antigas.
- Documentos encontrados.
- Diálogos com personagens.
- Cenários que contam histórias.
- Estátuas e monumentos.
- Relíquias divinas.
- Eventos ambientais.
- Descrições de equipamentos.

Cada bioma deverá contar parte da história de sua divindade e da civilização que herdou seu domínio.

O mistério sobre o desaparecimento dos deuses deve permanecer como fio condutor da campanha.

A explicação definitiva da história ainda deverá ser desenvolvida, evitando estabelecer um final prematuramente.

---

##### 9. DIRETRIZES DE DESENVOLVIMENTO

O projeto deve ser desenvolvido de maneira modular e escalável.

Requisitos:

1. Cada bioma deve ser independente em termos de identidade visual, inimigos, objetos, música e ambientação.
2. Os sistemas de combate, movimentação, inventário, progressão e geração de mapas devem ser reutilizáveis.
3. Novos biomas devem poder ser adicionados sem exigir a reconstrução dos sistemas centrais.
4. A arquitetura do projeto deve permitir expansão futura.
5. Utilizar placeholders quando não houver assets definitivos.
6. Priorizar desempenho e responsividade.
7. Não implementar todos os biomas simultaneamente.

---

##### 10. PRIMEIRA ETAPA DO PROJETO

Antes de desenvolver o jogo completo, estabelecer uma versão inicial jogável (Vertical Slice).

Prioridades:

1. Implementar movimentação do protagonista.
2. Implementar combate básico.
3. Criar sistema de inimigos.
4. Criar sistema de armas.
5. Implementar câmera e colisões.
6. Criar estrutura de salas e transições.
7. Desenvolver o primeiro bioma: O Mar de Cinzas.
8. Criar um conjunto inicial de inimigos.
9. Implementar o primeiro chefe.
10. Validar a qualidade e a sensação do gameplay.

Somente depois de validar essa primeira experiência, expandir a arquitetura para os outros biomas.

---

##### 11. INSTRUÇÃO FINAL

Quero desenvolver um jogo com a qualidade de gameplay, progressão e rejogabilidade de Dead Cells, mas com uma identidade narrativa e artística própria.

Não quero uma simples cópia de Dead Cells com personagens e cenários diferentes.

O principal diferencial deve ser a diversidade dos biomas, a riqueza do universo, a mitologia original e a sensação de explorar civilizações completamente distintas, todas conectadas por uma história maior.

Antes de implementar qualquer coisa, analise a estrutura atual do projeto, identifique as tecnologias utilizadas e apresente um plano de desenvolvimento organizado.

Não sobrescreva funcionalidades existentes sem necessidade. Não tente implementar o jogo inteiro de uma vez.

Priorize uma arquitetura limpa, modular, expansível e uma primeira versão jogável de alta qualidade.

**O objetivo é construir um universo que possa crescer com o desenvolvimento do jogo.**


---

## 24. Rodada de 04/11/2026: MOKSHA

**Nome:** MOKSHA (o herói também se chama Moksha). O título fica em inglês; o resto alterna entre inglês e português em OPÇÕES > IDIOMA. A tradução fica em `content/lang/en.txt`, e `tools/textos.py` lista o que falta.

**Variedade**
- **Armas novas:** Chicote de Espinhos, Foice do Inverno, Punhos de Bronze, Besta de Carcosa e Cetro do Astrônomo.
- **Habilidades novas:** Sino de Carcosa, Raiz Viva e Estrela Cadente.
- **Mutações novas:**
  - Couraça de Escória: estilhaços em quem está colado;
  - Teimosia: 1 de vida uma vez por andar;
  - Sede de Batalha;
  - Passo do Lobo: esquiva perfeita deixa o próximo golpe crítico;
  - Língua de Mercador;
  - Rastro de Brasa.
- **Inimigos próprios:** Pedreiro da Torre, Broto Espinhento, Dançarino Amarelo e Lente Viva.
- **Combos mais longos** e uma animação própria para cada golpe (7 formatos × 6 quadros).

**Movimento**
- pulo duplo para todos (a runa Asa de Cinza dá o terceiro);
- esquiva no ar;
- rolagem que emenda no pulo, mantendo o embalo;
- golpe e tiro cancelados por pulo;
- mergulho que quica em quem acerta;
- velocidade 165.

**Inimigos:** aceleração, pulo de degrau, descida de plataforma atrás do herói, perseguição mais rápida.

**Fases em teia**
- `RoomTemplate.links()` usa o `JumpMap` (`scripts/world/jump_map.gd`) para saber que portas se ligam com o pulo real.
- O caminho principal sorteia a direção (direita, baixo, cima, esquerda).
- Os desvios têm 1 a 3 salas, e há portais (`scripts/world/portal.gd`).

**Verificador de salas**
- Ninguém atravessa parede no ar.
- Quem entra por L ou T tem que chegar a todas as portas.
- Com essas regras, 7 salas que travavam foram corrigidas.
- Ordem dos geradores de sala: `salas_mar_de_cinzas` → `salas_andares` (apaga a pasta!) → `salas_dominios` → `salas_artesanais`.

**Partida salva e dicas**
- Cada andar grava a partida; CONTINUAR fica no título e SALVAR E SAIR na pausa.
- As dicas são só a tecla de cada comando, uma vez cada.
- Saíram os textos que explicavam o jogo.

**HUD por domínio:** `scripts/ui/hud_theme.gd`. A prévia sai em `tools/previa_hud.py`.

**Fundos:** `tools/pintar_fundos.py` gera camadas em cor cheia (`assets/sprites/*_cor_*.png`), e o jogo prefere essas às silhuetas.

**Bugs corrigidos**
- O projétil de um inimigo morto não acertava ninguém, porque a cópia do dano guardava quem atirou e esse inimigo já não existia.
- A troca de andar acontecia no meio da física do herói (agora é adiada para o fim do quadro).

**Robô:** `tests/robo.tscn -- --partidas=N --brasas=H --reflexo=0.75 [--rastro=1]` grava `docs/ROBO.md`. Pendente: nas fases em teia ele visita todos os desvios e estoura o tempo.

**Distribuição**
- Exportar: `Godot_console --headless --path . --export-release "Windows Desktop" build/Moksha.exe`. Os modelos ficam em `%APPDATA%\Godot\export_templates.7.2.stable`, e a pasta `build/` está fora do git.
- A landing page fica em `site/` (Three.js, GSAP, EN/PT). O botão aponta para `releases/latest/download/Moksha-windows.zip`.
- Falta criar o Release e ligar o Pages.

---

## 25. Troca da arte (04/11/2026, em andamento) — LER AO RETOMAR

O desenho gerado por código bateu no teto. Agora o jogo usa arte **profissional e gratuita, com licença comercial**: a série Gothicvania do ansimuz e alguns pacotes de outros autores do OpenGameArt.

**Ferramentas, na ordem:**
1. `python tools/baixar_arte.py` baixa 25 pacotes para `arte_externa/` (fora do git, ~73 MB). Ele confere a licença de cada página e grava `arte_externa/LICENCAS.md`.
   - 20 pacotes são CC0.
   - 5 são CC-BY e exigem crédito: hell-hound, dark-emperor, dark-fantasy-platformer-bestiary, living-tissue.
2. `python tools/importar_heroi.py` monta `assets/sprites/hero_g.png` e `.json` com o herói gótico, nos nomes de animação do jogo e com os pés alinhados. É uma folha em cor cheia (`"color": true`).
3. `python tools/importar_cenarios.py` monta os fundos `assets/sprites/<prefixo>_cor_{sky,far,mid,near}.png`:

   | Domínio | Cenário de origem |
   |---|---|
   | Mar de Cinzas | rocky pass |
   | Salões | fort of illusion |
   | Forja | industrial, recolorido para vermelho |
   | Torre | gothicvania town |
   | Jardim | swamp |
   | Carcosa | junk wasteland, recolorido para amarelo-oliva |
   | Observatório | espaço, montado em escala 2× |

**Já feito no código:**
- `SpriteSheet` aceita folha em cor cheia. Nela, a paleta recolore só os tons perto de `key_hue` (a capa vermelha) para a cor da aparência ou do croma.
- O herói usa `SHEET := "hero_g"`.
  - Com arte desenhada, não desenha mais a lâmina, o cachecol nem a arma nas costas; os arcos de golpe continuam.
  - Os rastros de esquiva usam o tamanho novo.
  - A miniatura nos menus usa o herói novo.
- A aparência padrão "O Andarilho" tem a capa vermelha da arte.
- O pacote de skills `gamedev@awesome-gamedev-agent-skills` está instalado (precisa reiniciar o Claude Code). As skills úteis aqui: `create-game-assets`, `game-feel`, `godot-shaders`, `godot-tilemap`, `platformer`, `camera-systems`.

**Feito em 04/11 (tarde):**
- **Ambiência ligada**: `Ambience` na CanvasLayer -10, depois do fundo; `main._use_biome` chama `ambience.use(b.id)`.
- **Tremor de tela** (`camera_rig.gd`): agora usa senoides em frequências que não se repetem, em vez de `randf`. A amplitude cai ao quadrado, e cada pedido novo recomeça do pico.
- **HUD inteiro por domínio, com arte de kits CC0** (ver a seção 26).

**Pendente, nesta ordem:**
1. ~~Ambiência~~ e 2. ~~Tremor~~ (feitos).
3. **Blocos do chão:** mapear os tilesets do Gothicvania (16 px, igual ao jogo) para os blocos de cada domínio em `room.gd` (`_draw_stone`, atlas).
4. **Inimigos e chefes** com a arte nova:
   - Hell Beast, Nightmare, Dark Emperor e o demônio do Bestiary como chefes;
   - caveira de fogo, fantasma, cão infernal, lobo, anjo, mago, aranha e golem como inimigos;
   - importar em folhas `"color": true` com os nomes de animação de cada script.
5. **Créditos** dos CC-BY no jogo (Códice ou título) e no site.
6. **Site:** refazer as tiras com a arte nova (`tools/site_assets.py`), trocar as imagens dos domínios e publicar o `gh-pages` com `git subtree push --prefix site origin gh-pages`.
7. **Soltar a versão:** `python tools/lancar_versao.py 0.3.0 "Arte nova"`. O Release precisa ser rodado por ele com `!`, porque o classificador bloqueia.
8. **Pendências antigas:**
   - o robô estoura o tempo nas fases em teia;
   - o equilíbrio medido ainda não saiu;
   - a troca de pacote do atualizador nunca foi testada com janela.

**Regras que continuam valendo:**
- nunca abrir o jogo com janela; conferir só em headless e por PNG;
- commit sem "Co-Authored-By: Claude";
- para ver o site, usar Playwright (`shots.py` no scratchpad) com `python -m http.server`.

---

## 26. HUD por domínio com arte de kits (04/11/2026)

Ele pediu: "mude absolutamente tudo a temática do HUD de acordo com o mapa, tente pegar de graça em algum kit".

**Kits** (todos CC0, baixados por `tools/baixar_arte.py`, que confere a licença):
- **Tiny RPG Dragon Regalia GUI** e **Mana Soul GUI**, de Gabriel "tiopalada" Lima. São a base, porque estão na escala certa para 480x270.
- Também foram baixados, para uso futuro: fantasy-ui-borders, pixel-ui-pack e 1-bit-pack (Kenney); golden-ui e sci-fi-user-interface (Buch); pixel-uihud 1 e 2 e pixel-hearts (TokyoGeisha); entre outros.
- O site do Kenney recusa download automático (403). As cópias no OpenGameArt servem.

**Ferramenta:** `python tools/importar_hud.py`. Para cada domínio, monta seis peças:

| Peça | O que é |
|---|---|
| panel | 9 fatias |
| bar | moldura da vida, com miolo translúcido |
| boss | moldura da barra do chefe |
| header | fita atrás dos títulos |
| slot | moldura de equipamento |
| gem | enfeite ao lado da vida |

- Recolore separando os pixels pela matiz: ouro e prata viram metal, vermelho e verde viram destaque, o resto vira escuro. Cada classe usa a rampa do domínio.
- O recheio dos painéis e das fitas vira o escuro do domínio, para o texto ler.
- Nas abas do Mana Soul, o painel é a metade direita espelhada, porque a esquerda traz a marca de "selecionada".
- Grava `assets/sprites/hud_<domínio>.png` e `.json`. O `.json` guarda as tampas, a coluna do meio, o enfeite central e o miolo, tudo detectado sozinho.

**Jogo:**
- `scripts/ui/hud_skin.gd` (`HudSkin.of(id)`) desenha as peças: o painel com `StyleBoxTexture`; barra e fita com tampas, meio esticado de 1 coluna e enfeite central.
- `hud.gd` usa a pele em tudo:
  - vida com enfeite e número na cor do domínio;
  - frascos e teclas na cor do domínio;
  - slots no tamanho da moldura;
  - aviso de interação;
  - barra do chefe com o nome numa fita; a barra começa depois dos slots e o aviso sobe durante o chefe;
  - faixa do nome do bioma numa fita.
- O `HudTheme` ficou só com as cores; o desenho antigo das molduras saiu.

**Prévia sem abrir o jogo:** `python tools/previa_hud.py` gera `tools/previews/hud_temas.png`, com os 7 HUDs sobre os fundos de cada domínio.

**Teste:** "HUD: cada domínio tem a sua pele e ela cabe na tela" (62 testes).

---

## 27. A lista do §25 inteira (04/11/2026, noite)

**Blocos do chão:** `python tools/importar_blocos.py` grava `assets/sprites/tiles_<domínio>.png` no formato do atlas antigo (16 máscaras × 4, enterrados, tábuas). Cada domínio lê um bloco do tileset como 9 fatias de 16 px; a borda da arte vira a borda do bloco. O `Room` usa o atlas do domínio (`tiles_id`) e, com ele, não desenha musgo nem cinza por cima. Prévia em `tools/previews/blocos.png`.

| Domínio | Tileset de origem |
|---|---|
| Mar | rocky pass |
| Salões | fort of illusion |
| Forja | gothic castle, avermelhado |
| Torre | lajes da igreja em arenito |
| Jardim | swamp |
| Carcosa | cemitério, amarelado |
| Observatório | cristal roxo do junk wasteland |

**Inimigos e chefes:** `python tools/importar_inimigos.py` refaz as 34 folhas em cor cheia, com os mesmos nomes de animação.
- Rodar DEPOIS de `gen_enemies.py`, se ele for rodado de novo, porque ele sobrescreve as folhas.
- Idle, andar e voar têm vários quadros; preparo e golpe têm o quadro-chave.
- Opções por folha: scale, hue, flip e key.
- Chefes:

  | Chefe | Arte |
  |---|---|
  | Imperador | Dark Emperor 2× |
  | Rei Lobo | cão infernal 2× gelado |
  | Colosso | Hell Beast 2× |
  | Mãe-Raiz | dragão 2× |
  | Arquiteto | demônio |
  | Rei sem Rosto | Nightmare |
  | Astrônomo | fantasma 2× |

- O `Enemy` aceita folha colorida: o aviso de golpe tinge (paleta de 1 cor = tingir), e `sprite_parts` usa a mesma paleta.
- Prévias: `tools/previews/inimigos.png`.

**Herói:** a âncora agora é fixa por tira. O corpo pulava até 25 px para os lados na corrida e entre parado e correndo.

**Créditos:** opção CRÉDITOS no título (`content/creditos.txt` e `creditos_en.txt`) e no rodapé do site.

**Site:** `tools/site_assets.py` gera as camadas, a imagem de cada domínio, o herói e as tiras a partir das folhas coloridas. Publicado no `gh-pages`; o Pages está ligado em https://mrrobots0.github.io/Roguevania/.

**Robô:**
- Novos comportamentos: explora até 360 px e 150 s, usa portal, mira quem mira nele, desvia no ar e não cai da borda perseguindo.
- Resultado: ainda morre no Mar de Cinzas, quase sempre pelo ATIRADOR DE VIDRO. É igual no commit anterior à sessão, então não é regressão. Fica para ele julgar jogando, antes de mexer no equilíbrio.

**Falta (só ele pode):**
- `! python tools/lancar_versao.py 0.3.0 "Arte nova ..."`: o classificador bloqueia criar o Release.
- Testar com janela a troca de pacote do atualizador.

---

## 28. O grande update de conteúdo (04/11/2026, noite) — v0.4.0

Pedido dele: "o maior update de conteúdo da história: mapas, skins, inimigos, bosses, história, deuses, itens, melhorias — tudo com arte pronta garimpada". Feito em duas partes (commits 74312f7 e b28acf9) + Wiki.

**Domínios e deuses (7 → 13):** Necrópole (deus que lembrava os mortos), Catedral Submersa (que ouvia as preces), O Ventre (que devorava), Penhascos do Sonho (que sonhava), Cavernas Fundas (que se escondia), Bosque Errante (que caminhava). Cada um com: fundo garimpado (cemitério, igreja em tons de água, tecido vivo, magic cliffs em lilás, cavern, parallax forest), blocos de chão próprios, pele de HUD, névoa/partículas, perigo de cenário novo (mão de osso, jorro, bile, lampejo do sonho, ponta de rocha, espinheiro), 5 inscrições, 34 salas (conjunto base + 7 salas próprias geradas e validadas), trilha própria.

**Rota:** 10 andares, 3 escolhas por passagem (Run.STAGES); Trono passou a tier 7.

**Criaturas (30 novas, todas com arte escolhida pelo desenho):** ver tabela em docs/ACERVO_ARTE.md. Comuns herdam comportamentos existentes (ex.: Carpideira = Gárgula, Morto Desperto = Assassino, Escavador = Peregrino que explode); elites e chefes são listas de golpes (Boss). Chefes: Rei Esquecido, O Que Responde (Cthulhu da chierit), O Insaciável (Demon Slime), Dragão Sonhado, Serpe do Fundo, Raposa de Nove Caudas.
**Armadilha aprendida:** no Godot 4.7 o `_init` da classe-pai NÃO roda quando a filha define o seu — toda criatura que herda chama `super._init()` primeiro (a Carpideira andava no chão com gravidade).

**Equipamento:** armas 13 → 33, habilidades 10 → 22, aparências 6 → 18 (com cromas novas), mutações 14 → 20 (Luto, Prece Atendida, Fome sem Fim, Sono Leve, Pele de Pedra, Última Prece). **Ícones em pixel art garimpada** (496 RPG icons, Henrique Lazarini, CC0) em todo o equipamento: HUD, pedestal, Vigia, Mercador (GearIcon; `icon` em WeaponData/SkillData; versão 16 px gerada em tools/gen_content.py).

**História:** treze deuses; o final ganhou a página do décimo terceiro ("o que se escondia viu tudo e não contou a ninguém"); o final verdadeiro tem treze cadeiras. Tudo traduzido para o inglês.

**Menu:** a tecla que abria/fechava uma tela vazava para a próxima no mesmo quadro (Enter em Opções mexia na 1ª opção; Esc/Enter ao fechar confirmava COMEÇAR; clique do mouse no título começava a partida). Agora há `Controls.lock_ui()` / `ui_ready()` nas trocas de tela e o clique não escolhe nada no título.

**Wiki:** `tools/gerar_wiki.py` + `tools/wiki_modelo.html` geram `site/wiki.html` direto dos arquivos do jogo (história, 13 deuses, rota, domínios com inscrições e criaturas animadas, guardiões, armas/habilidades com ícone, aparências com o herói recolorido, mutações, bênçãos, brasas, comandos), PT/EN, busca. Botão **Wiki** no topo do site.

**Testes:** 63 casos (agora cobrindo as 30 criaturas e 6 chefes acertando o herói, as 25 armas novas machucando, ícones de todo o equipamento, mutações novas, trava do menu).
