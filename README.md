# O Legado dos Deuses (nome provisório)

Ação roguelite / metroidvania 2D em pixel art. Godot 4.7.2, GDScript.
Arte, nome e sons são **provisórios**: tudo é desenhado e sintetizado em código
até a arte final existir.

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
| Pausa | Esc | Start |
| Debug (caixas de colisão e estados) | F1 | — |
| Nova partida | F5 | — |

## O que tem na demonstração

- **Mar de Cinzas**: fase gerada a cada partida a partir de 18 salas feitas à mão,
  com desvios (tesouro, fragmento, sala secreta atrás de parede falsa) e
  tempestades de cinzas que empurram e cegam.
- **Inimigos**: Penitente, Guarda da Casa (escudo frontal), Peregrino Cinzento
  (se incendeia), Assassino da Duna (nada sob a cinza), Atirador de Vidro,
  Inquisidor Profeta (elite) e os fulgurantes (espinhos de vidro do chão).
- **Chefe**: O Imperador Cego — as colunas de luz caem onde você *vai estar*.
- **Armas**: Espada Cerimonial, Arco das Dunas, Lança do Peregrino, Machado do
  Carrasco, Arco de Brasa. **Habilidades**: Granada de Cinzas, Égide de Bronze
  (aparo devolve projéteis), Lança de Vidro.
- **Progressão**: Fragmentos Divinos (Fúria / Astúcia / Vigor) durante a partida;
  Essência gasta com a Vigia em desbloqueios permanentes.

## Estrutura

```
scripts/
  core/       Damage (pacote de dano), Actor (base de quem tem vida), PlayerInput
  combat/     WeaponData, SkillData, Gear, Projectile, Combat (críticos), Catalog
  actors/     Player
  enemies/    Enemy (base) + cada inimigo, Hazard, Fulgurant, BlindEmperor
  world/      Room (mapa), RoomTemplate + LevelGen (gerador), Level (monta a fase),
              objetos de interação, câmera, fundo, clima, partículas
  biomes/     BiomeData
  ui/         Hud, Menu, Screen, PixelFont, Palette
  autoload/   Controls, Fx, Sfx, Meta (save permanente), Run (partida atual)
content/
  weapons/ skills/          armas e habilidades (.tres)
  biomes/mar_de_cinzas/     biome.tres, rooms/*.txt, chefe/trono.txt
assets/sfx/                 sons gerados por tools/gen_sfx.py
tests/                      testes automáticos e roteiro de prints
tools/                      geradores de conteúdo (armas, salas, sons)
```

## Como acrescentar coisas

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
29 testes que rodam a física de verdade — pulo, tolerâncias, rolagem, combo,
escudo, aparo, cada inimigo, chefe, gerador (20 mapas com caminho do início à
saída), save. Os testes usam `user://teste.save`, nunca o save real.

`tests/shots.tscn` abre o jogo, encena situações e salva prints (`-- --out=<pasta>`).
