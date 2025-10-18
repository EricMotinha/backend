-- migrate:up

-- Preferências do parceiro(a)
CREATE TABLE IF NOT EXISTS public.partner_preferences (
  user_id               uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  min_age               int  CHECK (min_age IS NULL OR min_age BETWEEN 18 AND 120),
  max_age               int  CHECK (max_age IS NULL OR max_age BETWEEN 18 AND 120),
  max_distance_km       int  CHECK (max_distance_km IS NULL OR max_distance_km BETWEEN 1 AND 1000),
  genders               text[] DEFAULT NULL,            -- ex: {'male','female','nonbinary'}
  interests             text[] DEFAULT NULL,            -- alinhado ao que você já tem em profiles/interests
  updated_at            timestamptz NOT NULL DEFAULT now(),
  created_at            timestamptz NOT NULL DEFAULT now()
);

-- Localização atual do usuário (último ping)
CREATE TABLE IF NOT EXISTS public.user_location (
  user_id     uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  lat         double precision NOT NULL,
  lng         double precision NOT NULL,
  city        text,
  region      text,
  country     text,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- bons índices
CREATE INDEX IF NOT EXISTS idx_user_location_updated_at ON public.user_location(updated_at);

-- (stub) função de discovery — mais pra frente trocamos pela real
CREATE OR REPLACE FUNCTION public.get_discovery_candidates_cached(p_user uuid, p_limit int DEFAULT 50)
RETURNS TABLE (candidate_id uuid)
LANGUAGE sql
AS $$
  -- por enquanto, devolve ninguém. Só para termos a função presente no schema.
  SELECT NULL::uuid WHERE FALSE;
$$;

-- migrate:down
DROP FUNCTION IF EXISTS public.get_discovery_candidates_cached(uuid, int);
DROP TABLE IF EXISTS public.user_location;
DROP TABLE IF EXISTS public.partner_preferences;
