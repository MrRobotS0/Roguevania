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
    `SELECT u.id, u.email, c.name
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
    send(res, 200, { logado: true, email: u.email, nome: u.name || null });
  },

  "POST /api/cadastro": async (req, res) => {
    const b = await readJson(req);
    if (limited("cad:" + ip(req), 10, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
    const email = cleanEmail(b.email);
    if (!email) return fail(res, 400, "email_invalido");
    const p = passwordProblem(b.senha);
    if (p) return fail(res, 400, p);
    const hash = await hashPassword(b.senha);
    const { rows } = await pool.query(
      `INSERT INTO users (email, pass_hash) VALUES ($1, $2) ON CONFLICT (email) DO NOTHING RETURNING id`, [email, hash]);
    if (!rows[0]) return fail(res, 409, "email_em_uso");
    await startSession(res, rows[0].id, 201, { ok: true, nome: null });
  },

  "POST /api/entrar": async (req, res) => {
    const b = await readJson(req);
    const email = cleanEmail(b.email);
    if (limited("ent:" + ip(req), 30, 15 * 60_000) || (email && limited("ent:" + email, 10, 15 * 60_000)))
      return fail(res, 429, "muitas_tentativas");
    const { rows } = email ? await pool.query(
      `SELECT u.id, u.pass_hash, c.name FROM users u LEFT JOIN characters c ON c.user_id = u.id WHERE u.email = $1`, [email]) : { rows: [] };
    const u = rows[0];
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
    send(res, 200, { nome: u.name, data: rows[0] ? rows[0].data : null, rev: rows[0] ? Number(rows[0].rev) : 0 });
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
    const email = cleanEmail(b.email);
    if (limited("esq:" + ip(req), 5, 60 * 60_000)) return fail(res, 429, "muitas_tentativas");
    // a resposta é a mesma com ou sem conta: não dá para descobrir quem é cadastrado
    send(res, 200, { ok: true });
    if (!email || limited("esq:" + email, 3, 60 * 60_000)) return;
    const { rows } = await pool.query(`SELECT id FROM users WHERE email = $1`, [email]);
    if (!rows[0]) return;
    const token = newToken();
    await pool.query(
      `INSERT INTO password_resets (token_hash, user_id, expires_at) VALUES ($1, $2, now() + make_interval(mins => $3))`,
      [sha256(token), rows[0].id, RESET_MINUTES]);
    await sendReset(email, `${SITE}/conta.html#redefinir=${token}`).catch(e => console.error("e-mail falhou:", e.message));
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

const server = http.createServer(async (req, res) => {
  const path = req.url.split("?")[0];
  const handler = routes[`${req.method} ${path}`];
  if (!handler) return fail(res, 404, "nao_encontrado");
  if (req.method !== "GET" && !sameSiteWrite(req)) return fail(res, 403, "origem_invalida");
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
