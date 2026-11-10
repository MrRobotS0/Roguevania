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
