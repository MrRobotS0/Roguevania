# Divulgação

## itch.io (página pronta para colar)

Em itch.io → Dashboard → **Create new project**. Os campos aparecem nesta ordem.

### Topo

| Campo | O que pôr |
|---|---|
| **Title** | MOKSHA |
| **Project URL** | `moksha` (fica `<seu-usuario>.itch.io/moksha`) |
| **Short description or tagline** | Treze deuses sumiram. Você é o que eles deixaram. (ou a versão em inglês: Thirteen gods vanished. You are what they left behind.) |
| **Classification** | **Games** |
| **Kind of project** | **HTML**: o jogo é de navegador. A página do itch mostra uma tela de entrada com o botão JOGAR, que abre o moksha.com.br em outra aba (lá ficam conta, loja e ranking). |
| **Release status** | **In development**: a versão é 0.9.x. Mude para Released quando sair a 1.0. |

### Pricing

**No payments**. O jogo é grátis e a loja de aparências já cobra pelo Stripe
no moksha.com.br. Para receber gorjeta também pelo itch, use **Donate**, com
sugestão de US$ 2. O itch fica com uma parte do que entrar por ele (a parte é
você quem define, e o padrão é 10%).

### Uploads

1. Rode `python tools/empacotar_itch.py`. Ele gera `build/itch/moksha-itch.zip`
   (a tela de entrada, com uns 30 KB) e `build/itch/capa.png`.
2. **Upload files** → `moksha-itch.zip` e marque **This file will be played in
   the browser**.
3. **Embed options**:
   - **Embed in page** (não use "Click to launch in fullscreen": seria um clique
     a mais antes do botão JOGAR);
   - **Viewport dimensions**: 960 × 540;
   - **Mobile friendly**: marcado, com **Orientation: Landscape**;
   - **Fullscreen button**: desmarcado (a tela não é o jogo).

Não precisa subir de novo a cada versão: o botão sempre abre o jogo atualizado
no moksha.com.br. O código da tela fica em `itch/index.html`. Ela fica em
português, ou em inglês quando o navegador não está em português.

O itch pode deixar fora das buscas uma página que só manda para outro site. Se
o jogo não aparecer nas buscas, a saída é rodar o build web dentro do próprio
itch, e para isso é preciso uma versão sem conta.

### Details

| Campo | O que pôr |
|---|---|
| **Description** | os textos abaixo (português e inglês) |
| **Genre** | **Action** |
| **Tags** (máx. 10) | roguelite, roguelike, pixel-art, metroidvania, 2d, platformer, dark-fantasy, procedural-generation, singleplayer, godot |
| **App store links** | deixe vazio |
| **Custom noun** | deixe vazio (fica "game") |
| **Community** | **Comments**. Com o fórum (Discussion board) ligado, é você quem precisa responder. |
| **Visibility & access** | **Draft** enquanto monta; **Public** quando quiser lançar. |

### "Metadata" (em *Edit more* / *Engines & tools*, salve uma vez antes para aparecer)

| Campo | O que pôr |
|---|---|
| **Platforms** | HTML5 (sai do arquivo marcado como "played in the browser") |
| **Made with** | Godot |
| **Inputs** | Keyboard, Mouse, Xbox controller, Gamepad (any) |
| **Accessibility** | Configurable controls (as teclas mudam em Opções > Teclas) |
| **Languages** | Portuguese (Brazil), English |
| **Multiplayer** | nenhum (Single player) |
| **Average session** | About a half-hour |
| **Links** | https://moksha.com.br e a Wiki (https://moksha.com.br/wiki.html) |
| **Mature content** | não marcar (tem violência de fantasia, nada explícito) |
| **AI generation disclosure** | O itch pergunta se o projeto tem conteúdo gerado por IA. A resposta honesta é **sim**: o código e os textos foram escritos com o Claude. A arte vem de kits CC0 e de scripts de pixel art, e a música é gerada por um script procedural (não é IA generativa). Marque as categorias que o formulário mostrar de acordo com isso. A decisão é sua, mas responder errado pode tirar o jogo das buscas. |

### Imagens e vídeo

- **Cover image**: `build/itch/capa.png` (630×500, gerada pelo `empacotar_itch.py`).
- **Screenshots**: de 3 a 5, tiradas jogando (título, Beira, combate, um guardião).
- **Gameplay video or trailer**: link do YouTube do trailer (roteiro abaixo).
- Depois de salvar, **Edit theme** muda cor e fundo da página: use o fundo
  escuro e o dourado do site.

**Description:**

> **MOKSHA** é um roguelite de ação em pixel art. Atravesse os domínios de 13
> deuses desaparecidos até o Trono do Imperador Cego. Cada partida monta mapas
> novos em 10 andares, e depois de cada guardião você escolhe entre três
> caminhos. Quando morre, renasce na Beira, onde o que desbloqueou fica para
> sempre.
>
> - 13 domínios, 13 guardiões, dezenas de criaturas
> - 45 armas e habilidades, mutações, runas e aparências
> - Desafio do Dia, Desafio da Semana e Modo Waves, com ranking
> - Português e inglês · teclado, controle ou toque
>
> **Jogue grátis no navegador: https://moksha.com.br**

> **MOKSHA** is a pixel-art action roguelite. Cross the domains of 13 vanished
> gods to the Throne of the Blind Emperor. Every run builds new maps across 10
> floors, and after each guardian you pick one of three paths. When you die
> you are reborn at the Brink, and what you unlocked stays forever.
>
> **Play free in your browser: https://moksha.com.br**

## Trailer (30 s)

Roteiro curto, gravado do jogo no navegador em tela cheia (OBS, 60 fps):

1. 0–3 s: logo MOKSHA sobre o Mar de Cinzas, música do título.
2. 3–12 s: corrida e combate no Mar de Cinzas (combo, rolagem, pulo duplo).
3. 12–20 s: cortes rápidos de 4 domínios (Forja, Carcosa, Observatório, Ventre).
4. 20–26 s: um guardião (Lobo da Longa Noite ou Colosso), golpe final.
5. 26–30 s: morte → renasce na Beira → "Jogue grátis: moksha.com.br".

## Link compartilhado

`site/img/og.png` (1200×630) é a imagem que aparece no WhatsApp, Discord e
redes ao mandar o link. Para ver como fica: https://www.opengraph.xyz/
