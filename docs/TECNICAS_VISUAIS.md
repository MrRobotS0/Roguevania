# Técnicas visuais de pixel art

Levantamento de 26/11/2026: as técnicas que os jogos de pixel art usam para parecer mais vivos e
mais "3D", e onde cada uma está no MOKSHA.

Legenda:
- ✅ já existia;
- 🆕 entrou na v0.10.0;
- 🔜 dá para fazer depois;
- ⛔ não serve (com o motivo).

## Volume e luz

| Técnica | Status | Onde / por quê |
|---|---|---|
| Normal maps em pixel art (Dead Cells, The Siege and the Sandfox) | ✅ | `tools/gen_normais.py` → `<folha>_n.png`; `SpriteSheet.lit` |
| Luz principal por domínio + luz de contorno do lado oposto | ✅ | `Depth.KEYS` |
| Luzes pontuais com altura (acendem o lado virado para elas) | ✅ | `Glow`, clarões do `Fx` |
| **Mapas de emissão**: olhos, fogo, runas e cristais brilham no escuro | 🆕 | `tools/gen_emissao.py` → `<folha>_e.png` (49 folhas); `Enemy._attach_emission`, somando luz e fora da penumbra |
| Sombra de contato e sombra do terreno na parede do fundo | ✅ | `ContactShadows`, `Room.draw_depth` |
| Bloco com face de cima (2.5D: o herói pisa dentro dela) | ✅ | `Room._top_face` |
| **Sombra projetada pelas tochas** na parede do fundo: blocos e personagens perto do fogo | 🆕 v0.11 | `TorchShadows`, só em lugar fechado (Forja, Catedral, Cavernas, Ventre). As luzes 2D não chegam ao fundo pintado (outra camada), então a sombra é desenhada: a casca do bloco empurrada para longe do fogo e a silhueta de quem passa, maior e tremendo com a chama |
| **Sombra de nuvens** correndo pelo chão | 🆕 v0.11 | `CloudShadows`: uma luz que subtrai, com textura de ruído sem emenda, em 3x3 ladrilhos que andam com o vento. Só escurece a camada do mundo, nunca o céu. Em 6 domínios a céu aberto |
| Iluminação global 2D (radiance cascades, campo de distância) | ⛔ | pesada demais para WebGL; não existe pronta para Godot |

## 3D feito de 2D

| Técnica | Status | Onde / por quê |
|---|---|---|
| Sprite stacking de lado no herói (espessura) e no logo | ✅ | `HeroVolume`, título |
| **Sprite stacking de verdade**: objeto feito de fatias que gira em 3D | 🆕 | `Stack`: baú (3/4, cintas de ferro, fecho; pula e dá meia-volta ao abrir), moedas em pé girando, ícone do item no pedestal com espessura de 2 px, planta enrolada |
| Extrusão de ícone (cada linha do desenho vira uma fatia) | 🆕 | `Stack.from_image`: qualquer ícone do jogo ganha corpo |
| Pipeline do Dead Cells: modelo 3D → quadros em pixel art + normal map | 🔜 | bom para chefes novos; exige Blender e um modelo por personagem |
| Pixel art 3D estilo t3ssel8r (cena 3D em baixa resolução, toon, contorno pixel a pixel) | ⛔ | trocaria o motor visual inteiro do jogo |
| Texel splatting / cubemap de sonda (2026) | ⛔ | é para câmera 3D livre |

## Mundo vivo

| Técnica | Status | Onde / por quê |
|---|---|---|
| Paralaxe com névoa da distância (perspectiva atmosférica) | ✅ | `BackLayer`, `Backdrop.LIFE` |
| Fundo em fração de pixel (sem andar aos trancos) | ✅ | v0.9.2 |
| Balanço de vento, tremor de calor e ondulação de água no fundo | ✅ | shaders do `BackLayer` |
| Fauna de fundo (aves, morcegos, peixes, olhos) | ✅ | `Fauna` |
| **Grama interativa**: fios de 1 px que balançam com rajadas e se abrem quando alguém passa | 🆕 | `Grass`, em 8 domínios (grama, juncos de cinza, algas, cílios de carne...), uma camada atrás e outra cobrindo os pés |
| **Chão molhado com reflexo**: o que está em cima aparece espelhado, ondulando | 🆕 | `Reflection` (lê a tela), em Catedral, Cavernas, Ventre, Observatório e Salões |
| **Poças com superfície de molas** | 🆕 v0.11 | `Puddles`: nas valas rasas que as salas já têm (2 a 8 blocos, degrau de até 2). Colunas de 2 px ligadas por molas; quem entra caindo espirra, e quem anda deixa marola. Cobrem os pés. Fora da Forja (lava falsa enganaria) |
| Raios de luz e névoa lisos | ✅ | `Ambience` (sem pontilhado) |

## Movimento e impacto

| Técnica | Status | Onde / por quê |
|---|---|---|
| Squash & stretch, smear (arco do golpe), rastro na rolagem | ✅ | `Player` |
| Piscar branco, hitstop, tremor, aberração cromática, onda de choque | ✅ | `Fx`, `PostFx` |
| **Efeitos desenhados à mão** (pacote CC0) | 🆕 | `Vfx`: anel de impacto a cada golpe, estrela de quatro pontas no crítico, alma que sobe do corpo na morte, estouro de luz em elite/chefe, explosão de verdade nas bombas e no afixo explosivo, chama animada na queimadura |
| **Câmera lisa** (subpixel) | 🆕 v0.11 | a tela desenha na resolução real (`CONTENT_SCALE_MODE_CANVAS_ITEMS`, o mesmo da fonte lisa) e a câmera anda em quartos de pixel; o fundo volta a ser nítido nesse modo. Opções > Tela > CÂMERA: LISA (padrão) ou EM PIXEL. Medido: 60 qps a 1920x1080 nos dois |
| Girar pixel art sem serrilhar (RotSprite / cleanEdge) | 🔜 | para armas e objetos que giram |
| Dissolver por ruído na morte | ⛔ | a morte em cinza já faz isso, com as cores do corpo |
| Pontilhado (dithering) por cima do cenário | ⛔ | ele não gostou (v0.4.1): transparência sempre lisa |
| CRT / linhas de varredura | ⛔ | sujaria a arte; o site já tem o CRT dele |

## Arte garimpada nesta rodada

| Pacote | Autor / licença | Uso |
|---|---|---|
| ✅ Free Pixel Effects Pack (20 efeitos, 100x100) | CodeManu e Davit Masia · CC0 | 14 viraram `assets/sprites/vfx_*.png` (`tools/importar_efeitos.py`) |
| 🟢 Pixel FX Pack | CodeManu · CC0 | mesmo traço; reserva |
| 🟢 Animated Particle Effects #1 | para · CC0 | partículas grandes (1024 px), reserva |
| ⛔ Free VFX Asset Pack | CodeManu · CC0 | ilustração lisa de 437 px, não é pixel art |
| 🟢 Castle Platformer | Jetrel · CC0 | castelo escuro com paralaxe, para salas novas |
| 🟢 Whimsy Hallow | Crumpaloo · CC0 | plataforma medieval mais clara |
| 🟡 Grim Platformer / Starlit Sanctuary | Vitavit · CC0 | tudo em 16x16, menor que o nosso herói |
| 🟡 PVFX Foundry / Thirteen | nerijs · CC0 | efeitos bons, mas feitos com ajuda de IA (aviso na página) |
| 🟢 Kiln Shader Kit, Dynamic 2D Grass (MIT) | Godot Asset Library / itch | referência dos shaders de grama, água e dissolver |

## Fontes

- [Normal maps desenhados em The Siege and the Sandfox](https://www.gamedeveloper.com/art/adding-depth-to-2d-with-hand-drawn-normal-maps-in-i-the-siege-and-the-sandfox-i-)
- [Pipeline de personagens do Dead Cells (80.lv)](https://80.lv/articles/case-study-dead-cells-character-art-pipeline)
- [Usando um pipeline 3D para animação 2D no Dead Cells](https://www.jikguard.com/news/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-dead-cells)
- [Normal maps para pixel art: análise das técnicas (arXiv)](https://arxiv.org/pdf/2212.09692)
- [Sprite stacking para objetos em falso 3D](https://www.spritecook.ai/blog/sprite-stacking-pixel-art)
- [Técnica que faz pixel art 2D parecer 3D (Creative Bloq)](https://www.creativebloq.com/3d/video-game-design/this-technique-for-making-2d-pixel-art-look-3d-is-blowing-peoples-minds)
- [Renderização de pixel art 3D (David Holland, sobre t3ssel8r)](https://davidholland.netlify.app/articles/3d-pixel-art-rendering)
- [Graveyard Keeper: como os efeitos são feitos](https://www.gamedeveloper.com/programming/graveyard-keeper-how-the-graphics-effects-are-made)
- [Pixel art com luz dinâmica (80.lv)](https://80.lv/articles/exploring-next-gen-pixel-art-with-real-time-dynamic-lighting)
- [Radiance cascades em 2D](https://otaviopeixoto1.github.io/portfolio/2DRadianceCascades)
- [Animação em subpixel](https://tinywarriorgames.com/2019/01/04/game-development-pixel-art-sub-pixel-animation/)
- [Smear frames](https://www.bloopanimation.com/the-art-of-smear-frames/)
- [Godot Shaders: vento em pixel art](https://godotshaders.com/shader/2d-pixel-perfect-wind-sway-effect/)
- [Godot Shaders: água 2D com reflexo](https://godotshaders.com/shader/water-2d-reflection-4-x/)
- [Dynamic 2D Grass para Godot](https://jomoho.itch.io/dynamic-2d-grass)
- [Free Pixel Effects Pack (OpenGameArt)](https://opengameart.org/content/free-pixel-effects-pack)
- [Castle Platformer (OpenGameArt)](https://opengameart.org/content/castle-platformer)
