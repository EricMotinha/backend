-- migrate:up

-- extensão usada em e-mails case-insensitive (ok repetir)
CREATE EXTENSION IF NOT EXISTS citext;

-- Garante colunas em refresh_tokens mesmo que a tabela já exista de migrações antigas
ALTER TABLE IF EXISTS public.refresh_tokens
  ADD COLUMN IF NOT EXISTS token_hash   text,
  ADD COLUMN IF NOT EXISTS user_agent   text,
  ADD COLUMN IF NOT EXISTS ip           inet,
  ADD COLUMN IF NOT EXISTS expires_at   timestamptz,
  ADD COLUMN IF NOT EXISTS created_at   timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS revoked_at   timestamptz;

-- Se expires_at ficou nula em linhas antigas, define um padrão (opcional)
UPDATE public.refresh_tokens
SET expires_at = now() + interval '30 days'
WHERE expires_at IS NULL;

-- Índices estáveis (sem predicate)
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_expires ON public.refresh_tokens(user_id, expires_at);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_revoked_at   ON public.refresh_tokens(revoked_at);

-- migrate:down
-- (mantemos estrutura; reversão não remove colunas para evitar perda de dados)
