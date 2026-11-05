# MOKSHA

Um jogo de ação em pixel art onde morrer faz parte do caminho.

Você atravessa os domínios de 13 deuses até o Trono do Imperador Cego. Cada partida monta mapas novos e tem 10 andares. Depois de cada guardião, você escolhe entre três caminhos, então uma partida raramente se parece com a outra. Quando você morre, recomeça do zero, mas o que desbloqueou fica para sempre.

Dá para jogar em português ou inglês (Opções > Idioma).

**[Baixar o jogo](https://mrrobots0.github.io/Roguevania/)** · **[Ler a Wiki](https://mrrobots0.github.io/Roguevania/wiki.html)**

A Wiki tem tudo: história, deuses, criaturas, armas e aparências.

## Controles

| Ação | Teclado | Controle |
|---|---|---|
| Andar | A/D ou setas | analógico / direcional |
| Pular | Espaço | A |
| Armas | J / K ou mouse | X / Y |
| Habilidades | U / I | LB / RB |
| Rolar | Shift | B ou RT |
| Curar | Q | LT |
| Usar / pegar / ler | E | cima |
| Mapa (segure) | M ou Tab | Select |
| Pausa | Esc | Start |

Dá para trocar as teclas nas Opções.

## Para quem quer mexer no código

O jogo é feito em Godot 4.7.2 com GDScript. Abra a pasta no Godot e aperte F5, ou use `Jogar.bat`, que espera o Godot em `Desktop\Godot_v4.7.2-stable_win64.exe`.

- `scripts/`: o código do jogo
- `content/`: armas, habilidades, aparências, domínios e salas
- `tools/`: scripts que geram e importam arte, salas, músicas e a Wiki
- `tests/`: testes automáticos, que rodam com `Testar.bat`
- `DOCUMENTO_COMPLETO.md`: o projeto em detalhes

## Créditos

Parte da arte vem de artistas que disponibilizaram seus trabalhos. Os nomes e as licenças estão em [`content/creditos.txt`](content/creditos.txt).
