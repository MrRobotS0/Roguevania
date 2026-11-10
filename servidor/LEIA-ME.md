# moksha.com.br: site, contas e jogo

Quem abre `moksha.com.br` vê a landing (`site/index.html`). Para jogar é preciso
ter conta e personagem, criados em `conta.html`. O jogo fica em `/jogar/`, e o
nginx só entrega os arquivos dele depois de perguntar à API se há sessão válida
com personagem.

| No servidor | O que é | Vem de |
|---|---|---|
| `/var/www/moksha/` | landing, wiki e `conta.html` | `site/` |
| `/var/www/moksha/jogar/` | build web do Godot | `tools/publicar_web.py` |
| `/opt/moksha-api/` | API (Node 20), serviço `moksha-api`, porta 127.0.0.1:3310 | `servidor/api/` |
| `/etc/moksha-api.env` | banco e SMTP (fora do git) | `servidor/moksha-api.env.exemplo` |
| banco `moksha` (Postgres 16) | contas, personagens, sessões, saves | `servidor/api/schema.sql` |
| `/etc/nginx/sites-available/moksha.com.br` | nginx | `servidor/nginx_moksha.conf` |

## API

| Rota | Faz |
|---|---|
| `POST /api/cadastro` `{email, senha}` | cria a conta e já entra |
| `POST /api/entrar` `{email, senha}` | entra (cookie `moksha_sess`, 30 dias) |
| `POST /api/sair` | sai |
| `GET /api/me` | `{logado, email, nome}` |
| `POST /api/personagem` `{nome}` | cria o personagem (um por conta, nome único) |
| `GET /api/save` / `PUT /api/save` `{rev, data}` | o legado (`Meta.data`) do jogo |
| `POST /api/esqueci` `{email}` / `POST /api/redefinir` `{token, senha}` | recuperação de senha por e-mail |
| `GET /api/gate` | 204 ou 401, usado pelo nginx antes de `/jogar/` |

Sem `SMTP_HOST` no `.env`, o link de "esqueci a senha" só aparece em
`journalctl -u moksha-api`.

## O jogo no navegador

`scripts/autoload/meta.gd`: no navegador, o legado vem de `/api/save` ao abrir e
cada `save()` manda uma cópia para lá (com um número `rev` crescente, para o
servidor ignorar o que chegar fora de ordem). A tela de carregamento é
`web/shell.html` (html/custom_html_shell do preset Web); o ícone da aba vem de
`site/img/icone*.png`. O progresso que um navegador já
tinha antes das contas vai para a primeira conta que entrar nele. No Windows e
nos testes nada muda.

## Atualizar

- Jogo: `python tools/publicar_web.py` (troca `/var/www/moksha/jogar`).
- Site: copiar `site/` para `/var/www/moksha/` sem apagar `jogar/` nem os `.import`.
- API: copiar `servidor/api/` para `/opt/moksha-api/`, `npm ci --omit=dev` e
  `systemctl restart moksha-api`.
