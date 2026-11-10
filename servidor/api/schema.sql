-- Banco das contas do moksha.com.br. Pode rodar de novo sem estragar nada.
CREATE TABLE IF NOT EXISTS users (
  id          bigserial PRIMARY KEY,
  email       text NOT NULL UNIQUE,
  pass_hash   text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- um personagem por conta; o nome é único sem diferenciar maiúsculas
CREATE TABLE IF NOT EXISTS characters (
  user_id     bigint PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  name        text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS characters_name_lower ON characters (lower(name));

CREATE TABLE IF NOT EXISTS sessions (
  token_hash  text PRIMARY KEY,
  user_id     bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  expires_at  timestamptz NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user ON sessions (user_id);

-- o legado (Meta.data do jogo), inteiro, como JSON
CREATE TABLE IF NOT EXISTS saves (
  user_id     bigint PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  data        jsonb NOT NULL,
  rev         bigint NOT NULL DEFAULT 0,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS password_resets (
  token_hash  text PRIMARY KEY,
  user_id     bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at  timestamptz NOT NULL,
  used_at     timestamptz
);

-- telemetria: um resumo por partida terminada (venceu, morreu ou desistiu)
CREATE TABLE IF NOT EXISTS runs (
  id          bigserial PRIMARY KEY,
  user_id     bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  data        jsonb NOT NULL
);
CREATE INDEX IF NOT EXISTS runs_user ON runs (user_id);
CREATE INDEX IF NOT EXISTS runs_created ON runs (created_at);

-- cada vez que o jogo abre (GET /api/save)
CREATE TABLE IF NOT EXISTS openings (
  id          bigserial PRIMARY KEY,
  user_id     bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS openings_user ON openings (user_id, at);

CREATE TABLE IF NOT EXISTS feedback (
  id          bigserial PRIMARY KEY,
  user_id     bigint REFERENCES users(id) ON DELETE CASCADE,
  kind        text NOT NULL,
  text        text NOT NULL,
  info        text NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- nome de usuário para entrar (além do e-mail); único sem diferenciar maiúsculas
ALTER TABLE users ADD COLUMN IF NOT EXISTS username text;
CREATE UNIQUE INDEX IF NOT EXISTS users_username_lower ON users (lower(username));
