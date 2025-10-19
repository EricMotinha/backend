-- migrate:up

-- extensões necessárias (idempotente):
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- usuários básicos
CREATE TABLE IF NOT EXISTS public.users (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email            citext UNIQUE NOT NULL,
  phone            text UNIQUE,
  is_active        boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

-- credenciais (hash/salt)
CREATE TABLE IF NOT EXISTS public.user_credentials (
  user_id          uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  password_hash    text NOT NULL,
  password_algo    text NOT NULL DEFAULT 'argon2id',
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

-- refresh tokens
CREATE TABLE IF NOT EXISTS public.refresh_tokens (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token_hash       text NOT NULL,
  user_agent       text,
  ip               inet,
  expires_at       timestamptz NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  revoked_at       timestamptz
);

-- índices úteis
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users (email);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON public.refresh_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON public.refresh_tokens (expires_at);

-- gatilho updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_credentials_updated
BEFORE UPDATE ON public.user_credentials
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- migrate:down
DROP TRIGGER IF EXISTS trg_user_credentials_updated ON public.user_credentials;
DROP TRIGGER IF EXISTS trg_users_updated ON public.users;
DROP FUNCTION IF EXISTS set_updated_at;

DROP INDEX IF EXISTS idx_refresh_tokens_expires_at;
DROP INDEX IF EXISTS idx_refresh_tokens_user_id;
DROP INDEX IF EXISTS idx_users_email;

DROP TABLE IF EXISTS public.refresh_tokens;
DROP TABLE IF EXISTS public.user_credentials;
DROP TABLE IF EXISTS public.users;
