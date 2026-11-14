// API das contas do moksha.com.br: cadastro, login, personagem e progresso.
// Roda atrás do nginx (só escuta em 127.0.0.1). Configuração em variáveis de
// ambiente (ver moksha-api.env.exemplo).
"use strict";

const http = require("node:http");
const crypto = require("node:crypto");
const { promisify } = require("node:util");
const { Pool } = require("pg");

const PORT = Number(process.env.PORT || 3310);
const SITE = (process.env.SITE_URL || "https://moksha.com.br").replace(/\/$/, "");
const COOKIE = "moksha_sess";
const SESSION_DAYS = 30;
const RESET_MINUTES = 60;
const MAX_BODY = 512 * 1024;

const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 5 });
const scrypt = promisify(crypto.scrypt);

// --- senhas e tokens ----------------------------------------------------------------

async function hashPassword(pw) {
  const salt = crypto.randomBytes(16);
  const key = await scrypt(pw.normalize("NFKC"), salt, 64, { N: 16384, r: 8, p: 1 });
  return `scrypt$${salt.toString("base64")}$${key.toString("base64")}`;
}

async function checkPassword(pw, stored) {
  const [kind, salt, hash] = String(stored).split("$");
  if (kind !== "scrypt" || !salt || !hash) return false;
  const want = Buffer.from(hash, "base64");
  const got = await scrypt(pw.normalize("NFKC"), Buffer.from(salt, "base64"), want.length, { N: 16384, r: 8, p: 1 });
  return crypto.timingSafeEqual(want, got);
}

// quem não existe também paga o custo do scrypt: o tempo de resposta não entrega quais e-mails têm conta
let DUMMY_HASH = null;
hashPassword("senha-que-ninguem-usa").then(h => { DUMMY_HASH = h; });

const newToken = () => crypto.randomBytes(32).toString("base64url");
const sha256 = s => crypto.createHash("sha256").update(s).digest("hex");

// --- limite de tentativas (memória; reinicia com o serviço, e tudo bem) ----------------

const hits = new Map();
function limited(key, max, windowMs) {
  const now = Date.now();
  let h = hits.get(key);
  if (!h || h.reset < now) h = { n: 0, reset: now + windowMs };
  h.n++;
  hits.set(key, h);
  return h.n > max;
}
setInterval(() => {
  const now = Date.now();
  for (const [k, h] of hits) if (h.reset < now) hits.delete(k);
}, 60_000).unref();

// --- validação ---------------------------------------------------------------------

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
// letras (com acento do português), números, espaço e hífen: é o que a fonte do jogo desenha
const NAME_RE = /^[A-Za-z0-9ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç](?:[A-Za-z0-9ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç -]*[A-Za-z0-9ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç])?$/;

function cleanEmail(v) {
  const e = String(v || "").trim().toLowerCase();
  return e.length <= 254 && EMAIL_RE.test(e) ? e : null;
}

// usuário para entrar: 3 a 20 letras sem acento, números, ponto, hífen ou sublinhado
const USER_RE = /^[A-Za-z0-9][A-Za-z0-9._-]{1,18}[A-Za-z0-9]$/;
function cleanUsername(v) {
  const u = String(v || "").trim();
  return USER_RE.test(u) ? u : null;
}

// quem entra digita o e-mail ou o usuário: com @ é e-mail
async function findAccount(login) {
  const l = String(login || "").trim();
  if (!l || l.length > 254) return null;
  const email = l.includes("@") ? cleanEmail(l) : null;
  if (l.includes("@") && !email) return null;
  const { rows } = await pool.query(
    `SELECT u.id, u.email, u.pass_hash, c.name FROM users u LEFT JOIN characters c ON c.user_id = u.id
      WHERE ${email ? "u.email = $1" : "lower(u.username) = lower($1)"}`, [email || l]);
  return rows[0] || null;
}

function passwordProblem(pw) {
  if (typeof pw !== "string" || pw.length < 8) return "senha_curta";
  if (pw.length > 200) return "senha_longa";
  return null;
}

function cleanName(v) {
  const n = String(v || "").normalize("NFC").replace(/\s+/g, " ").trim();
  if (n.length < 3 || n.length > 16 || !NAME_RE.test(n)) return null;
  return n;
}

// --- HTTP --------------------------------------------------------------------------

function send(res, status, body, headers = {}) {
  const data = body === undefined ? "" : JSON.stringify(body);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    ...headers,
  });
  res.end(data);
}

const fail = (res, status, code) => send(res, status, { erro: code });

function readJson(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on("data", c => {
      size += c.length;
      if (size > MAX_BODY) { reject(Object.assign(new Error("grande"), { status: 413 })); req.destroy(); return; }
      chunks.push(c);
    });
    req.on("end", () => {
      try { resolve(chunks.length ? JSON.parse(Buffer.concat(chunks).toString("utf8")) : {}); }
      catch { reject(Object.assign(new Error("json"), { status: 400 })); }
    });
    req.on("error", reject);
  });
}

function cookies(req) {
  const out = {};
  for (const part of String(req.headers.cookie || "").split(";")) {
    const i = part.indexOf("=");
    if (i > 0) out[part.slice(0, i).trim()] = decodeURIComponent(part.slice(i + 1).trim());
  }
  return out;
}

function sessionCookie(token, maxAgeSec) {
  return `${COOKIE}=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${maxAgeSec}`;
}

const ip = req => String(req.headers["x-real-ip"] || req.socket.remoteAddress || "");

// Pedidos que mudam algo precisam vir em JSON e do próprio site: um formulário
// de outro site não consegue mandar JSON sem pedir licença ao navegador antes.
function sameSiteWrite(req) {
  if (!String(req.headers["content-type"] || "").startsWith("application/json")) return false;
  const origin = req.headers.origin;
  return !origin || origin === SITE;
}

async function currentUser(req) {
  const token = cookies(req)[COOKIE];
  if (!token || token.length > 100) return null;
  const { rows } = await pool.query(
    `SELECT u.id, u.email, u.username, c.name
       FROM sessions s JOIN users u ON u.id = s.user_id
       LEFT JOIN characters c ON c.user_id = u.id
      WHERE s.token_hash = $1 AND s.expires_at > now()`, [sha256(token)]);
  return rows[0] || null;
}

async function startSession(res, userId, status, body) {
  const token = newToken();
  await pool.query(
    `INSERT INTO sessions (token_hash, user_id, expires_at) VALUES ($1, $2, now() + make_interval(days => $3))`,
    [sha256(token), userId, SESSION_DAYS]);
  send(res, status, body, { "Set-Cookie": sessionCookie(token, SESSION_DAYS * 86400) });
}

// --- e-mail -------------------------------------------------------------------------

let mailer = null;
if (process.env.SMTP_HOST) {
  mailer = require("nodemailer").createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: Number(process.env.SMTP_PORT) === 465,
    auth: process.env.SMTP_USER ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } : undefined,
  });
}

async function sendReset(email, link) {
  if (!mailer) {
    // sem SMTP configurado o link só aparece no log (journalctl -u moksha-api)
    console.log(`[redefinir senha] SMTP não configurado. Link para ${email}: ${link}`);
    return;
  }
  await mailer.sendMail({
    from: process.env.MAIL_FROM || "MOKSHA <nao-responda@moksha.com.br>",
    to: email,
    subject: "MOKSHA: redefinir sua senha",
    text: `Alguém (talvez você) pediu para redefinir a senha da sua conta no MOKSHA.\n\n` +
      `Para criar uma senha nova, abra este link em até ${RESET_MINUTES} minutos:\n${link}\n\n` +
      `Se não foi você, ignore este e-mail: sua senha continua a mesma.`,
  });
}

// --- rotas --------------------------------------------------------------------------

const routes = {
  // o nginx pergunta isto antes de entregar qualquer arquivo de /jogar/
  "GET /api/gate": async (req, res) => {
    const u = await currentUser(req);
    res.writeHead(u && u.name ? 204 : 401, { "Cache-Control": "no-store" });
    res.end();
  },

  "GET /api/me": async (req, res) => {
    const u = await currentUser(req);
    if (!u) return send(res, 200, { logado: false });
    send(res, 200, { logado: true, email: u.email, usuario: u.username || null, nome: u.name || null });
  },

  "POST /api/cadastro": async (req, res) => {
    const b = await readJson(req);
    if (limited("cad:" + ip(req), 10, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
    const email = cleanEmail(b.email);
    if (!email) return fail(res, 400, "email_invalido");
    const username = cleanUsername(b.usuario);
    if (!username) return fail(res, 400, "usuario_invalido");
    const p = passwordProblem(b.senha);
    if (p) return fail(res, 400, p);
    const hash = await hashPassword(b.senha);
    let rows;
    try {
      ({ rows } = await pool.query(
        `INSERT INTO users (email, username, pass_hash) VALUES ($1, $2, $3) RETURNING id`, [email, username, hash]));
    } catch (e) {
      if (e.code === "23505") return fail(res, 409, String(e.constraint).includes("username") ? "usuario_em_uso" : "email_em_uso");
      throw e;
    }
    await startSession(res, rows[0].id, 201, { ok: true, nome: null });
  },

  "POST /api/entrar": async (req, res) => {
    const b = await readJson(req);
    const login = String(b.login || b.email || "").trim().toLowerCase();
    if (limited("ent:" + ip(req), 30, 15 * 60_000) || (login && limited("ent:" + login, 10, 15 * 60_000)))
      return fail(res, 429, "muitas_tentativas");
    const u = await findAccount(login);
    const ok = await checkPassword(String(b.senha || ""), u ? u.pass_hash : DUMMY_HASH);
    if (!u || !ok) return fail(res, 401, "login_invalido");
    await startSession(res, u.id, 200, { ok: true, nome: u.name || null });
  },

  "POST /api/sair": async (req, res) => {
    const token = cookies(req)[COOKIE];
    if (token) await pool.query(`DELETE FROM sessions WHERE token_hash = $1`, [sha256(token)]);
    send(res, 200, { ok: true }, { "Set-Cookie": sessionCookie("", 0) });
  },

  "POST /api/personagem": async (req, res) => {
    const u = await currentUser(req);
    if (!u) return fail(res, 401, "sem_sessao");
    if (u.name) return fail(res, 409, "ja_tem_personagem");
    const b = await readJson(req);
    const name = cleanName(b.nome);
    if (!name) return fail(res, 400, "nome_invalido");
    try {
      await pool.query(`INSERT INTO characters (user_id, name) VALUES ($1, $2)`, [u.id, name]);
    } catch (e) {
      if (e.code === "23505") return fail(res, 409, e.constraint === "characters_pkey" ? "ja_tem_personagem" : "nome_em_uso");
      throw e;
    }
    send(res, 201, { ok: true, nome: name });
  },

  "GET /api/save": async (req, res) => {
    const u = await currentUser(req);
    if (!u) return fail(res, 401, "sem_sessao");
    if (!u.name) return fail(res, 403, "sem_personagem");
    const { rows } = await pool.query(`SELECT data, rev FROM saves WHERE user_id = $1`, [u.id]);
    // cada abertura do jogo fica anotada (só a hora): mede quem volta e os primeiros minutos
    pool.query(`INSERT INTO openings (user_id) VALUES ($1)`, [u.id]).catch(() => {});
    // compras: aparências da loja. Vêm sempre daqui (o save do jogador não decide o que ele comprou).
    send(res, 200, { nome: u.name, data: rows[0] ? rows[0].data : null, rev: rows[0] ? Number(rows[0].rev) : 0,
      compras: await ownedSkins(u.id) });
  },

  "PUT /api/save": async (req, res) => {
    const u = await currentUser(req);
    if (!u) return fail(res, 401, "sem_sessao");
    if (!u.name) return fail(res, 403, "sem_personagem");
    const b = await readJson(req);
    const rev = Number(b.rev);
    if (!b.data || typeof b.data !== "object" || Array.isArray(b.data) || !Number.isSafeInteger(rev) || rev < 1)
      return fail(res, 400, "save_invalido");
    // os salvamentos podem chegar fora de ordem: só fica o mais novo
    const { rowCount } = await pool.query(
      `INSERT INTO saves (user_id, data, rev, updated_at) VALUES ($1, $2, $3, now())
       ON CONFLICT (user_id) DO UPDATE SET data = EXCLUDED.data, rev = EXCLUDED.rev, updated_at = now()
       WHERE saves.rev < EXCLUDED.rev`, [u.id, b.data, rev]);
    send(res, 200, { ok: true, gravado: rowCount > 0 });
  },

  "POST /api/esqueci": async (req, res) => {
    const b = await readJson(req);
    const login = String(b.login || b.email || "").trim().toLowerCase();
    if (limited("esq:" + ip(req), 5, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
    // a resposta é a mesma com ou sem conta: não dá para descobrir quem é cadastrado
    send(res, 200, { ok: true });
    if (!login || limited("esq:" + login, 3, 60 * 60_000)) return;
    const acc = await findAccount(login);
    if (!acc) return;
    const token = newToken();
    await pool.query(
      `INSERT INTO password_resets (token_hash, user_id, expires_at) VALUES ($1, $2, now() + make_interval(mins => $3))`,
      [sha256(token), acc.id, RESET_MINUTES]);
    await sendReset(acc.email, `${SITE}/conta.html#redefinir=${token}`).catch(e => console.error("e-mail falhou:", e.message));
  },

  "POST /api/redefinir": async (req, res) => {
    const b = await readJson(req);
    if (limited("red:" + ip(req), 10, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
    const p = passwordProblem(b.senha);
    if (p) return fail(res, 400, p);
    const { rows } = await pool.query(
      `UPDATE password_resets SET used_at = now()
        WHERE token_hash = $1 AND used_at IS NULL AND expires_at > now() RETURNING user_id`, [sha256(String(b.token || ""))]);
    if (!rows[0]) return fail(res, 400, "link_expirado");
    const uid = rows[0].user_id;
    await pool.query(`UPDATE users SET pass_hash = $1 WHERE id = $2`, [await hashPassword(b.senha), uid]);
    // senha nova derruba as sessões abertas em outros lugares
    await pool.query(`DELETE FROM sessions WHERE user_id = $1`, [uid]);
    const { rows: c } = await pool.query(`SELECT name FROM characters WHERE user_id = $1`, [uid]);
    await startSession(res, uid, 200, { ok: true, nome: c[0] ? c[0].name : null });
  },
};

// --- conta: trocar senha e excluir ---------------------------------------------------

routes["POST /api/trocar-senha"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u) return fail(res, 401, "sem_sessao");
  const b = await readJson(req);
  if (limited("troca:" + u.id, 10, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
  const p = passwordProblem(b.nova);
  if (p) return fail(res, 400, p);
  const { rows } = await pool.query(`SELECT pass_hash FROM users WHERE id = $1`, [u.id]);
  if (!(await checkPassword(String(b.atual || ""), rows[0].pass_hash))) return fail(res, 401, "senha_atual_errada");
  await pool.query(`UPDATE users SET pass_hash = $1 WHERE id = $2`, [await hashPassword(b.nova), u.id]);
  // as outras sessões caem; esta continua
  const token = cookies(req)[COOKIE];
  await pool.query(`DELETE FROM sessions WHERE user_id = $1 AND token_hash <> $2`, [u.id, sha256(token)]);
  send(res, 200, { ok: true });
};

// LGPD: apaga conta, personagem, saves, partidas e sessões (ON DELETE CASCADE)
routes["POST /api/excluir-conta"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u) return fail(res, 401, "sem_sessao");
  const b = await readJson(req);
  if (limited("exc:" + u.id, 5, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
  const { rows } = await pool.query(`SELECT pass_hash FROM users WHERE id = $1`, [u.id]);
  if (!(await checkPassword(String(b.senha || ""), rows[0].pass_hash))) return fail(res, 401, "senha_atual_errada");
  await pool.query(`DELETE FROM users WHERE id = $1`, [u.id]);
  console.log(`[conta excluída] id ${u.id}`);
  send(res, 200, { ok: true }, { "Set-Cookie": sessionCookie("", 0) });
};

// --- telemetria: um resumo por partida ------------------------------------------------

routes["POST /api/partida"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u || !u.name) return fail(res, 401, "sem_sessao");
  if (limited("part:" + u.id, 120, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
  const b = await readJson(req);
  if (!b || typeof b !== "object" || Array.isArray(b) || JSON.stringify(b).length > 8000) return fail(res, 400, "pedido_invalido");
  await pool.query(`INSERT INTO runs (user_id, data) VALUES ($1, $2)`, [u.id, b]);
  send(res, 201, { ok: true });
};

// --- ranking (vem dos saves: o jogo já guarda o melhor de cada desafio) -----------------

const RANK_LIMIT = 50;
routes["GET /api/ranking"] = async (req, res) => {
  const q = new URL(req.url, "http://x").searchParams;
  const tipo = q.get("tipo");
  let rows;
  if (tipo === "ondas") {
    ({ rows } = await pool.query(
      `SELECT c.name AS nome, (s.data->>'best_wave')::int AS wave
         FROM saves s JOIN characters c USING (user_id)
        WHERE (s.data->>'best_wave')::int > 0
        ORDER BY wave DESC, s.updated_at ASC LIMIT ${RANK_LIMIT}`));
  } else if (tipo === "dia" || tipo === "semana") {
    const chave = String(q.get("chave") || "");
    if (!(tipo === "dia" ? /^\d{4}-\d{2}-\d{2}$/ : /^S\d{3,6}$/).test(chave)) return fail(res, 400, "chave_invalida");
    const campo = tipo === "dia" ? "daily" : "weekly";
    // quem venceu vem primeiro (menor tempo); depois quem foi mais fundo
    ({ rows } = await pool.query(
      `SELECT c.name AS nome,
              NULLIF((s.data->'${campo}'->$1->>'best_time')::float, 0) AS tempo,
              (s.data->'${campo}'->$1->>'best_depth')::int AS andares,
              (s.data->'${campo}'->$1->>'tries')::int AS tentativas
         FROM saves s JOIN characters c USING (user_id)
        WHERE s.data->'${campo}' ? $1
        ORDER BY tempo ASC NULLS LAST, andares DESC, tentativas ASC LIMIT ${RANK_LIMIT}`, [chave]));
  } else {
    return fail(res, 400, "tipo_invalido");
  }
  send(res, 200, { tipo, linhas: rows });
};

// --- perfil público do personagem ----------------------------------------------------

routes["GET /api/perfil"] = async (req, res) => {
  const nome = String(new URL(req.url, "http://x").searchParams.get("nome") || "").normalize("NFC").trim();
  if (!nome || nome.length > 16) return fail(res, 404, "nao_encontrado");
  const { rows } = await pool.query(
    `SELECT c.name, c.created_at, s.data FROM characters c LEFT JOIN saves s USING (user_id) WHERE lower(c.name) = lower($1)`, [nome]);
  if (!rows[0]) return fail(res, 404, "nao_encontrado");
  const d = rows[0].data || {};
  const st = d.stats || {};
  const sum = o => Object.values(o || {}).reduce((a, v) => a + Number(v || 0), 0);
  send(res, 200, {
    nome: rows[0].name,
    desde: rows[0].created_at,
    partidas: Number(d.runs || 0), vitorias: Number(d.wins || 0), mortes: Number(d.deaths || 0),
    abates: sum(st.kills_by), andar_mais_fundo: Number(st.deepest || 0), tempo_jogado: Number(st.time || 0),
    melhor_tempo: Number(d.best_time || 0), melhor_wave: Number(d.best_wave || 0),
    brasas: Number(d.heat || 0), ciclo: Number(d.plus || 0), desperto: Boolean(d.awake),
    conquistas: Array.isArray(d.feats) ? d.feats : [],
    aparencia: d.skin || "andarilho",
    guardioes: Object.keys(st.kills_by || {}),
  });
};

// --- feedback e bugs (do jogo e do site) ---------------------------------------------

routes["POST /api/feedback"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u) return fail(res, 401, "sem_sessao");
  if (limited("fb:" + u.id, 10, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
  const b = await readJson(req);
  const tipo = ["bug", "ideia", "outro"].includes(b.tipo) ? b.tipo : "outro";
  const texto = String(b.texto || "").trim().slice(0, 4000);
  if (texto.length < 5) return fail(res, 400, "texto_curto");
  const info = String(b.info || "").slice(0, 500);
  await pool.query(`INSERT INTO feedback (user_id, kind, text, info) VALUES ($1, $2, $3, $4)`, [u.id, tipo, texto, info]);
  send(res, 201, { ok: true });
  if (process.env.DISCORD_WEBHOOK) {
    const content = `**${tipo.toUpperCase()}** de **${u.name || u.email}**\n${texto}`.slice(0, 1900);
    fetch(process.env.DISCORD_WEBHOOK, { method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content, allowed_mentions: { parse: [] } }) }).catch(e => console.error("discord:", e.message));
  }
};

// --- painel do dono (e-mails em ADMIN_EMAILS) -----------------------------------------

const ADMINS = String(process.env.ADMIN_EMAILS || "").toLowerCase().split(",").map(s => s.trim()).filter(Boolean);
routes["GET /api/admin/resumo"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u || !ADMINS.includes(u.email)) return fail(res, 403, "proibido");
  const one = async (sql, args = []) => (await pool.query(sql, args)).rows;
  const [contas] = await one(`SELECT
      (SELECT count(*) FROM users)::int AS contas,
      (SELECT count(*) FROM characters)::int AS personagens,
      (SELECT count(*) FROM users WHERE created_at > now() - interval '1 day')::int AS contas_24h,
      (SELECT count(*) FROM users WHERE created_at > now() - interval '7 days')::int AS contas_7d,
      (SELECT count(DISTINCT user_id) FROM openings WHERE at > now() - interval '1 day')::int AS jogaram_24h,
      (SELECT count(DISTINCT user_id) FROM openings WHERE at > now() - interval '7 days')::int AS jogaram_7d,
      (SELECT count(*) FROM runs)::int AS partidas,
      (SELECT count(*) FROM runs WHERE created_at > now() - interval '1 day')::int AS partidas_24h`);
  const onde = await one(`SELECT data->>'onde' AS onde, count(*)::int AS mortes FROM runs
      WHERE NOT (data->>'venceu')::boolean AND created_at > now() - interval '30 days' GROUP BY 1 ORDER BY 2 DESC LIMIT 15`);
  const quem = await one(`SELECT data->>'morto_por' AS quem, count(*)::int AS mortes FROM runs
      WHERE coalesce(data->>'morto_por', '') <> '' AND created_at > now() - interval '30 days' GROUP BY 1 ORDER BY 2 DESC LIMIT 15`);
  const andares = await one(`SELECT (data->>'andares')::int AS andares, count(*)::int AS partidas FROM runs
      WHERE data->>'modo' = 'normal' AND created_at > now() - interval '30 days' GROUP BY 1 ORDER BY 1`);
  // primeiros minutos: quanto tempo da primeira abertura até a primeira partida terminada, e quem nunca terminou uma
  const [inicio] = await one(`WITH f AS (
        SELECT u.id, (SELECT min(at) FROM openings o WHERE o.user_id = u.id) AS abriu,
               (SELECT min(created_at) FROM runs r WHERE r.user_id = u.id) AS jogou
          FROM users u JOIN characters c ON c.user_id = u.id)
      SELECT count(*) FILTER (WHERE abriu IS NOT NULL)::int AS abriram_o_jogo,
             count(*) FILTER (WHERE abriu IS NOT NULL AND jogou IS NULL)::int AS nunca_terminaram_partida,
             round(extract(epoch FROM percentile_cont(0.5) WITHIN GROUP (ORDER BY jogou - abriu)) / 60)::int AS minutos_ate_1a_partida
        FROM f`);
  const fb = await one(`SELECT f.id, f.kind AS tipo, f.text AS texto, f.info, f.created_at AS em, c.name AS nome
      FROM feedback f LEFT JOIN characters c USING (user_id) ORDER BY f.id DESC LIMIT 50`);
  send(res, 200, { contas, mortes_por_andar: onde, quem_mais_mata: quem, andares_alcancados: andares, primeiros_minutos: inicio, feedback: fb });
};

// --- loja: aparências (só visual) pagas com Pix ou cartão pelo Mercado Pago ------------
// O preço vale o que está AQUI, nunca o que o navegador manda. Sem MP_ACCESS_TOKEN
// a vitrine aparece, mas o botão de comprar avisa que ainda não abriu.
// Fluxo: POST /api/loja/comprar cria o pedido e a preferência do Checkout Pro →
// o jogador paga no Mercado Pago → o webhook avisa → buscamos o pagamento na API
// deles (a fonte da verdade) e marcamos o pedido como aprovado (ou estornado).

// tipo: "pacote" | "conjunto" | "manto" | "lamina" | "rastro" | "filtro". conteudo: ids que o jogo entende
// (aparências em content/skins, efeitos em scripts/combat/cosmetics.gd).
const MANTOS = {
  casa_oram: ["Estandarte de Oram", "Banner of Oram"], casa_kael: ["Estandarte de Kael", "Banner of Kael"],
  cinza_sagrada: ["Cinza Sagrada", "Sacred Ash"], ouro_imperador: ["Ouro do Imperador", "Emperor's Gold"],
  fulgurante: ["Fulgurante", "Fulgurite"], ultima_pagina: ["A Última Página", "The Last Page"],
  abissal: ["Abissal", "Abyssal"], coral_morto: ["Coral Morto", "Dead Coral"], voz_do_fundo: ["Voz do Fundo", "Voice from Below"],
  constelacao: ["Constelação", "Constellation"], aurora: ["Aurora", "Aurora"], sol_negro: ["Sol Negro", "Black Sun"],
};
const LAMINAS = {
  lamina_brasa: ["Corte de Brasa", "Ember Cut"], lamina_geada: ["Corte de Geada", "Frost Cut"], lamina_vazio: ["Corte do Vazio", "Void Cut"],
  lamina_ouro: ["Corte Dourado", "Golden Cut"], lamina_sangue: ["Corte de Sangue", "Blood Cut"], lamina_espectro: ["Corte Espectral", "Spectral Cut"],
};
const RASTROS = {
  rastro_brasa: ["Rastro de Brasas", "Ember Trail"], rastro_geada: ["Rastro de Geada", "Frost Trail"], rastro_petalas: ["Rastro de Pétalas", "Petal Trail"],
  rastro_vazio: ["Rastro do Vazio", "Void Trail"], rastro_ouro: ["Rastro Dourado", "Golden Trail"], rastro_estrelas: ["Rastro de Estrelas", "Star Trail"],
};
const FILTROS = {
  filtro_pergaminho: ["Filtro Pergaminho", "Parchment Filter"], filtro_luto: ["Filtro Luto", "Mourning Filter"],
  filtro_fosforo: ["Filtro Fósforo", "Phosphor Filter"], filtro_sonho: ["Filtro Sonho", "Dream Filter"],
  filtro_brasa: ["Filtro Brasa", "Ember Filter"], filtro_inverno: ["Filtro Inverno", "Winter Filter"],
};
const SO_CONJUNTO = ["brasa_eterna", "inverno_longo"];   // mantos que só vêm nos conjuntos
const LOJA = {
  "pacote:casas": { tipo: "pacote", pt: "Pacote Guerra das Casas", en: "War of the Houses Pack", centavos: 990, conteudo: ["casa_oram", "casa_kael", "cinza_sagrada"] },
  "pacote:profecia": { tipo: "pacote", pt: "Pacote Profecia", en: "Prophecy Pack", centavos: 990, conteudo: ["ouro_imperador", "fulgurante", "ultima_pagina"] },
  "pacote:abismo": { tipo: "pacote", pt: "Pacote Abismo", en: "Abyss Pack", centavos: 990, conteudo: ["abissal", "coral_morto", "voz_do_fundo"] },
  "pacote:ceu": { tipo: "pacote", pt: "Pacote Céu Antigo", en: "Old Sky Pack", centavos: 990, conteudo: ["constelacao", "aurora", "sol_negro"] },
  "pacote:laminas": { tipo: "pacote", pt: "Arsenal de Lâminas", en: "Blade Arsenal", centavos: 990, conteudo: Object.keys(LAMINAS) },
  "pacote:rastros": { tipo: "pacote", pt: "Coleção de Rastros", en: "Trail Collection", centavos: 990, conteudo: Object.keys(RASTROS) },
  "pacote:filtros": { tipo: "pacote", pt: "Caixa de Filtros", en: "Filter Box", centavos: 690, conteudo: Object.keys(FILTROS) },
  "conjunto:brasa": { tipo: "conjunto", pt: "Conjunto Brasa Eterna", en: "Eternal Ember Set", centavos: 1290,
    conteudo: ["brasa_eterna", "lamina_brasa", "rastro_brasa", "filtro_brasa"] },
  "conjunto:geada": { tipo: "conjunto", pt: "Conjunto Inverno Longo", en: "Long Winter Set", centavos: 1290,
    conteudo: ["inverno_longo", "lamina_geada", "rastro_geada", "filtro_inverno"] },
  "pacote:completo": { tipo: "pacote", pt: "Tudo da Loja", en: "Everything", centavos: 3990,
    conteudo: [...Object.keys(MANTOS), ...SO_CONJUNTO, ...Object.keys(LAMINAS), ...Object.keys(RASTROS), ...Object.keys(FILTROS)] },
};
for (const [grupo, tipo, centavos] of [[MANTOS, "manto", 490], [LAMINAS, "lamina", 290], [RASTROS, "rastro", 290], [FILTROS, "filtro", 190]])
  for (const [id, [pt, en]] of Object.entries(grupo)) LOJA[`${tipo}:${id}`] = { tipo, pt, en, centavos, conteudo: [id] };
// os pedidos antigos usavam "skin:<id>"
for (const id of Object.keys(MANTOS)) LOJA[`skin:${id}`] = { ...LOJA[`manto:${id}`], oculto: true };
const MP_TOKEN = process.env.MP_ACCESS_TOKEN || "";
const MP_API = "https://api.mercadopago.com";

// aparências que a conta tem (pedidos aprovados)
async function ownedSkins(userId) {
  const { rows } = await pool.query(`SELECT item FROM purchases WHERE user_id = $1 AND status = 'aprovado'`, [userId]);
  const out = new Set();
  for (const r of rows) for (const s of (LOJA[r.item] || { conteudo: [] }).conteudo) out.add(s);
  return [...out];
}

async function mp(method, path, body) {
  const r = await fetch(MP_API + path, {
    method, headers: { Authorization: `Bearer ${MP_TOKEN}`, "Content-Type": "application/json",
      ...(method === "POST" ? { "X-Idempotency-Key": crypto.randomUUID() } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await r.json().catch(() => ({}));
  if (!r.ok) throw Object.assign(new Error(`mercado pago ${r.status}: ${JSON.stringify(data).slice(0, 300)}`), { mp: true });
  return data;
}

routes["GET /api/loja"] = async (req, res) => {
  const u = await currentUser(req);
  const itens = Object.entries(LOJA).filter(([, i]) => !i.oculto)
    .map(([id, i]) => ({ id, tipo: i.tipo, pt: i.pt, en: i.en, centavos: i.centavos, conteudo: i.conteudo }));
  send(res, 200, { itens, aberta: Boolean(MP_TOKEN), logado: Boolean(u), nome: u ? u.name : null,
    tem: u ? await ownedSkins(u.id) : [] });
};

routes["POST /api/loja/comprar"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u) return fail(res, 401, "sem_sessao");
  if (!u.name) return fail(res, 403, "sem_personagem");
  if (!MP_TOKEN) return fail(res, 503, "loja_fechada");
  if (limited("loja:" + u.id, 20, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
  const b = await readJson(req);
  const item = LOJA[b.item];
  if (!item || item.oculto) return fail(res, 400, "item_invalido");
  const tem = new Set(await ownedSkins(u.id));
  if (item.conteudo.every(s => tem.has(s))) return fail(res, 409, "ja_tem");
  const { rows } = await pool.query(
    `INSERT INTO purchases (user_id, item, amount_cents) VALUES ($1, $2, $3) RETURNING id`, [u.id, b.item, item.centavos]);
  const id = rows[0].id;
  const volta = `${SITE}/loja.html?pedido=${id}`;
  const pref = await mp("POST", "/checkout/preferences", {
    items: [{ id: b.item, title: `MOKSHA · ${item.pt}`, description: "Item cosmético para o herói (só visual)",
      quantity: 1, currency_id: "BRL", unit_price: item.centavos / 100 }],
    payer: { email: u.email },
    external_reference: String(id),
    notification_url: `${SITE}/api/loja/webhook`,
    back_urls: { success: volta, pending: volta, failure: volta },
    auto_return: "approved",
    statement_descriptor: "MOKSHA",
  });
  await pool.query(`UPDATE purchases SET mp_preference = $1 WHERE id = $2`, [pref.id, id]);
  send(res, 201, { ok: true, pedido: Number(id), url: pref.init_point });
};

// situação de um pedido (a página volta do Mercado Pago com ?pedido=N)
routes["GET /api/loja/pedido"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u) return fail(res, 401, "sem_sessao");
  const id = Number(new URL(req.url, "http://x").searchParams.get("id"));
  if (!Number.isSafeInteger(id)) return fail(res, 400, "pedido_invalido");
  let { rows } = await pool.query(`SELECT id, item, status FROM purchases WHERE id = $1 AND user_id = $2`, [id, u.id]);
  if (!rows[0]) return fail(res, 404, "nao_encontrado");
  // o webhook pode demorar: enquanto pendente, pergunta direto ao Mercado Pago
  if (rows[0].status === "pendente" && MP_TOKEN && !limited("ped:" + id, 30, 10 * 60_000)) {
    const busca = await mp("GET", `/v1/payments/search?external_reference=${id}&sort=date_created&criteria=desc`).catch(() => null);
    for (const p of (busca && busca.results) || []) await applyPayment(p);
    ({ rows } = await pool.query(`SELECT id, item, status FROM purchases WHERE id = $1`, [id]));
  }
  send(res, 200, { pedido: Number(rows[0].id), item: rows[0].item, situacao: rows[0].status });
};

// o pagamento (vindo da API do Mercado Pago) muda o pedido
async function applyPayment(p) {
  const id = Number(p.external_reference);
  if (!Number.isSafeInteger(id)) return;
  const { rows } = await pool.query(`SELECT item, amount_cents, status FROM purchases WHERE id = $1`, [id]);
  if (!rows[0]) return;
  let status = null;
  if (p.status === "approved") {
    const pago = Math.round(Number(p.transaction_amount) * 100);
    if (p.currency_id !== "BRL" || pago < rows[0].amount_cents) {
      console.error(`[loja] pedido ${id}: valor não confere (${p.transaction_amount} ${p.currency_id})`);
      return;
    }
    status = "aprovado";
  } else if (p.status === "refunded" || p.status === "charged_back") {
    status = "estornado";
  } else if ((p.status === "rejected" || p.status === "cancelled") && rows[0].status === "pendente") {
    status = "recusado";
  }
  if (!status || status === rows[0].status) return;
  await pool.query(`UPDATE purchases SET status = $1, mp_payment = $2, updated_at = now() WHERE id = $3`, [status, String(p.id), id]);
  console.log(`[loja] pedido ${id} (${rows[0].item}): ${status}`);
}

// aviso do Mercado Pago. Não confiamos no conteúdo: só no id, que buscamos na API deles.
routes["POST /api/loja/webhook"] = async (req, res) => {
  const q = new URL(req.url, "http://x").searchParams;
  const b = await readJson(req).catch(() => ({}));
  const tipo = b.type || q.get("type") || q.get("topic");
  const pid = String((b.data && b.data.id) || q.get("data.id") || q.get("id") || "");
  send(res, 200, { ok: true });
  if (!MP_TOKEN || tipo !== "payment" || !/^\d{1,20}$/.test(pid)) return;
  try { await applyPayment(await mp("GET", `/v1/payments/${pid}`)); }
  catch (e) { console.error("[loja] webhook:", e.message); }
};

// o dono dá um item de presente (testes, sorteios, suporte): vira um pedido aprovado de R$ 0
routes["POST /api/admin/presentear"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u || !ADMINS.includes(u.email)) return fail(res, 403, "proibido");
  const b = await readJson(req);
  if (!LOJA[b.item]) return fail(res, 400, "item_invalido");
  const { rows } = await pool.query(`SELECT user_id FROM characters WHERE lower(name) = lower($1)`, [String(b.nome || "").trim()]);
  if (!rows[0]) return fail(res, 404, "nao_encontrado");
  await pool.query(`INSERT INTO purchases (user_id, item, amount_cents, status, mp_payment) VALUES ($1, $2, 0, 'aprovado', 'presente')`,
    [rows[0].user_id, b.item]);
  console.log(`[loja] presente ${b.item} para ${b.nome} (por ${u.email})`);
  send(res, 201, { ok: true });
};

routes["GET /api/admin/vendas"] = async (req, res) => {
  const u = await currentUser(req);
  if (!u || !ADMINS.includes(u.email)) return fail(res, 403, "proibido");
  const { rows } = await pool.query(`SELECT p.id, p.item, p.amount_cents AS centavos, p.status AS situacao, p.created_at AS em, c.name AS nome
      FROM purchases p LEFT JOIN characters c USING (user_id) ORDER BY p.id DESC LIMIT 100`);
  const { rows: [tot] } = await pool.query(`SELECT coalesce(sum(amount_cents), 0)::int AS centavos, count(*)::int AS pedidos
      FROM purchases WHERE status = 'aprovado'`);
  send(res, 200, { total: tot, pedidos: rows });
};

const server = http.createServer(async (req, res) => {
  const path = req.url.split("?")[0];
  const handler = routes[`${req.method} ${path}`];
  if (!handler) return fail(res, 404, "nao_encontrado");
  // o webhook vem do Mercado Pago (outro site); ele não confia no corpo, só no id que busca na API deles
  if (req.method !== "GET" && path !== "/api/loja/webhook" && !sameSiteWrite(req)) return fail(res, 403, "origem_invalida");
  try {
    await handler(req, res);
  } catch (e) {
    if (res.headersSent) return console.error(e);
    if (e.status) return fail(res, e.status, e.status === 413 ? "grande_demais" : "pedido_invalido");
    console.error(e);
    fail(res, 500, "erro_interno");
  }
});

// limpeza diária do que venceu
setInterval(() => {
  pool.query(`DELETE FROM sessions WHERE expires_at < now()`).catch(() => {});
  pool.query(`DELETE FROM password_resets WHERE expires_at < now() - interval '1 day'`).catch(() => {});
}, 24 * 3600_000).unref();

server.listen(PORT, "127.0.0.1", () => console.log(`moksha-api ouvindo em 127.0.0.1:${PORT}`));
