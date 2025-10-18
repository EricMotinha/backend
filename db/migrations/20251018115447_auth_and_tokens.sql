-- migrate:up

-- Credenciais (para login por email/senha; pode coexistir com OAuth no futuro)
CREATE TABLE IF NOT EXISTS public.user_credentials (
  user_id            uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  email              citext UNIQUE NOT NULL,
  password_hash      text NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

-- Refresh tokens (logout/rota /auth/refresh)
CREATE TABLE IF NOT EXISTS public.refresh_tokens (
  id                 bigserial PRIMARY KEY,
  user_id            uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token_hash         text NOT NULL,
  user_agent         text,
  ip                 inet,
  expires_at         timestamptz NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  revoked_at         timestamptz
);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON public.refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_valid ON public.refresh_tokens(user_id, expires_at) WHERE revoked_at IS NULL AND expires_at > now();

-- migrate:down
DROP TABLE IF EXISTS public.refresh_tokens;
DROP TABLE IF EXISTS public.user_credentials;
