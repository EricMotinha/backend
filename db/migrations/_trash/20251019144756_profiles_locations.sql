-- migrate:up
-- extensões úteis (idempotente)
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

-- Perfil do usuário
CREATE TABLE IF NOT EXISTS public.user_profile (
  user_id        uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  name           text NOT NULL,
  birthdate      date,
  gender         text,              -- ex: 'male','female','nonbinary','other'
  bio            text,
  photos         jsonb DEFAULT '[]'::jsonb,  -- array de URLs/objetos
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

-- Localização do usuário (simplificada: lat/lon; pode evoluir para PostGIS depois)
CREATE TABLE IF NOT EXISTS public.user_location (
  user_id        uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  lat            double precision,
  lon            double precision,
  updated_at     timestamptz NOT NULL DEFAULT now()
);

-- preferências do parceiro(a) (se já não existir no seu repo; mantenho idempotente)
CREATE TABLE IF NOT EXISTS public.partner_preferences (
  user_id               uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  min_age               int  CHECK (min_age IS NULL OR min_age BETWEEN 18 AND 120),
  max_age               int  CHECK (max_age IS NULL OR max_age BETWEEN 18 AND 120),
  max_distance_km       int  CHECK (max_distance_km IS NULL OR max_distance_km BETWEEN 1 AND 1000),
  genders               text[] DEFAULT NULL,            -- ex: {'male','female','nonbinary'}
  interests             text[] DEFAULT NULL,            -- tags livres
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

-- gatilho updated_at (reuso caso já exista)
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_profile_updated
BEFORE UPDATE ON public.user_profile
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_partner_preferences_updated
BEFORE UPDATE ON public.partner_preferences
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- índices úteis
CREATE INDEX IF NOT EXISTS idx_user_profile_name ON public.user_profile (name);
CREATE INDEX IF NOT EXISTS idx_user_location_updated_at ON public.user_location (updated_at);

-- migrate:down
DROP INDEX IF EXISTS idx_user_location_updated_at;
DROP INDEX IF EXISTS idx_user_profile_name;

DROP TRIGGER IF EXISTS trg_partner_preferences_updated ON public.partner_preferences;
DROP TRIGGER IF EXISTS trg_user_profile_updated ON public.user_profile;

-- NÃO derrubo a function set_updated_at aqui pois outras tabelas podem usar.
-- (Se quiser, remova no down da última migração do pacote.)

DROP TABLE IF EXISTS public.partner_preferences;
DROP TABLE IF EXISTS public.user_location;
DROP TABLE IF EXISTS public.user_profile;
