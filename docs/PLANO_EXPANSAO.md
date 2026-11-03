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
- [ ] **G.** README, MegaBrain Pessoal, memória.

Regra: não abrir o jogo com janela. Arte conferida em PNG gerado (tools/previews).
