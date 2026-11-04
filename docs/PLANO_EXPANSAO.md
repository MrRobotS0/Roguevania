# Expansão pedida em 03/11/2026 ("faça 1 2 3 4 7 e 8, completo")

Ordem de execução (cada etapa termina com testes passando e commit):

- [x] **A. Opções** — volume geral/música/efeitos (barramentos de áudio), tela cheia,
      intensidade do tremor, reduzir piscadas, trocar teclas, vibração do controle,
      cronômetro na tela. Acessível pelo título e pela pausa. Salvo no Meta.
- [x] **B. Música** — `tools/gen_music.py` sintetiza uma trilha em loop por andar,
      chefe e título; autoload `Music` com troca suave.
- [x] **C. Equipamento** — 4 habilidades novas (armadilha, torreta, espírito, corrente)
      e afixos aleatórios nas armas (brasa, geada, vampira, explosiva, afiada,
      ligeira, carrasca, eco).
- [x] **D. Chefes por andar** — base de chefe reaproveitável; Lobo da Longa Noite
      (Salões) e Colosso da Bigorna (Forja). A rota passa a ter arena de chefe depois
      de cada andar escolhido.
- [x] **E. 4 domínios novos** — Torre de Babel, Jardim Primordial, Carcosa,
      Observatório Celeste: cores, salas, fundo, clima, perigo, 2 inimigos e chefe cada.
      Rota final:
      Mar → [Salões | Forja] → chefe → [Torre | Jardim] → chefe → [Carcosa | Observatório] → chefe → Trono
- [x] **F. Extras** — desafio do dia (semente da data), tela de estatísticas,
      cronômetro de speedrun com melhor tempo, vibração.
- [x] **G.** README, MegaBrain Pessoal, memória.

Regra: não abrir o jogo com janela. Arte conferida em PNG gerado (tools/previews).

# Segunda rodada (pedida depois: "faz 6 7 8 10")

- [x] **6. Salas próprias por domínio** — 6 a 8 salas com a cara de cada domínio
      (Salões, Forja, Torre, Jardim, Carcosa, Observatório) + verificador de salas
      com o alcance real do pulo (`tools/validar_salas.py`), aplicado em TODAS as salas.
- [x] **7. Elite próprio por domínio** — um elite novo em cada um dos 6 domínios.
- [x] **8. Sons novos** — chefes, habilidades novas, inimigos novos.
- [x] **10. História** — abertura curta, final de verdade, códice (inscrições lidas + bestiário).

# Terceira rodada (04/11: "vamos melhorar o jogo" e o que ele pediu jogando)

Feito:
- [x] **Variedade** — 5 armas (chicote, foice, punhos, besta, cetro), 3 habilidades
      (sino, raiz, estrela), 6 mutações (Couraça e Passo do Lobo viraram mecânica),
      4 inimigos próprios (pedreiro, broto, dançarino, lente), 24 salas feitas à mão
      nos domínios novos, Jardim orgânico, 7 nichos secretos.
- [x] **Salvar no meio** — cada andar grava; CONTINUAR no título; SALVAR E SAIR na pausa.
- [x] **Primeira partida guiada** — só a tecla de cada comando, uma vez, na hora certa.
- [x] **Robô que joga sozinho** — `tests/robo.tscn` (relatório em docs/ROBO.md).
- [x] **Verificador de salas honesto** — não atravessa parede no ar; entrada L/T
      chega a todas as portas. 7 salas que travavam corrigidas. 2 bugs do jogo.
- [x] **Menos texto na cara** — sem subtítulo no título, sem aviso na morte.
- [x] **Movimento fluido** — pulo duplo para todos, esquiva no ar, rolagem emenda
      no pulo, golpe cancela em pulo, mergulho quica.
- [x] **Inimigos fluidos (1ª passada)** — aceleração, pulam degrau, descem plataforma.
- [x] **Fases não lineares** — o gerador sabe que portas de cada sala se ligam
      (pulo real) e segue para os 4 lados; desvios de 1 a 3 salas; portais.

Fila (todos pedidos por ele):
- [x] Inimigos mais vivos (2ª passada): perseguição mais rápida, menos tempo parado.
- [x] HUD temático por domínio (cada domínio com a sua moldura).
- [~] Pixel art: feito animação por golpe do combo e fundos em cor cheia; faltam blocos do chão e inimigos.
- [x] Inglês e português, com o seletor nas opções. Nome: MOKSHA.
- [ ] Robô + equilíbrio medido (o robô ainda estoura o tempo nas fases em teia).
- [x] Exportar .exe (build/) e landing page 3D (site/). Falta publicar: Release com o zip + GitHub Pages.
