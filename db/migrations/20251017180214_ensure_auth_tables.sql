-- migrate:up

-- Tabela de credenciais locais (senha)
CREATE TABLE IF NOT EXISTS public.user_credentials (
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  provider      text NOT NULL DEFAULT 'local',
  password_hash text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, provider)
);

-- Tabela de refresh tokens (armazenamos APENAS hash)
CREATE TABLE IF NOT EXISTS public.refresh_tokens (
  id          uuid PRIMARY KEY,
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token_hash  text NOT NULL,
  expires_at  timestamptz NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON public.refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON public.refresh_tokens(expires_at);

-- migrate:down
DROP TABLE IF EXISTS public.refresh_tokens;
DROP TABLE IF EXISTS public.user_credentials;
