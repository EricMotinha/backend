-- migrate:up

-- ENUMs (cria só se não existir)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'swipe_direction') THEN
    CREATE TYPE swipe_direction AS ENUM ('left','right');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_status') THEN
    CREATE TYPE match_status AS ENUM ('active','blocked');
  END IF;
END$$;

-- SWIPES
CREATE TABLE IF NOT EXISTS public.swipes (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  to_user_id        uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  direction         swipe_direction NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT swipes_from_to_unique UNIQUE (from_user_id, to_user_id)
);

-- índices úteis
CREATE INDEX IF NOT EXISTS swipes_from_user_idx ON public.swipes (from_user_id);
CREATE INDEX IF NOT EXISTS swipes_to_user_idx   ON public.swipes (to_user_id);

-- MATCHES
CREATE TABLE IF NOT EXISTS public.matches (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id    uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_b_id    uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status       match_status NOT NULL DEFAULT 'active',
  created_at   timestamptz NOT NULL DEFAULT now(),
  -- evita duplicar match invertido (A,B) / (B,A)
  CONSTRAINT matches_users_pair_unique UNIQUE (
    LEAST(user_a_id, user_b_id),
    GREATEST(user_a_id, user_b_id)
  )
);

CREATE INDEX IF NOT EXISTS matches_user_a_idx ON public.matches (user_a_id);
CREATE INDEX IF NOT EXISTS matches_user_b_idx ON public.matches (user_b_id);

-- migrate:down
DROP TABLE IF EXISTS public.matches;
DROP TABLE IF EXISTS public.swipes;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_status') THEN
    DROP TYPE match_status;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'swipe_direction') THEN
    DROP TYPE swipe_direction;
  END IF;
END$$;
