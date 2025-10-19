-- migrate:up
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Respostas do questionário
CREATE TABLE IF NOT EXISTS public.user_answers (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  question_id  text NOT NULL,
  answer       jsonb NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_answers_user ON public.user_answers (user_id);
CREATE INDEX IF NOT EXISTS idx_user_answers_question ON public.user_answers (question_id);

-- Swipes (left/right)
-- direction: -1 = left; 1 = right
CREATE TABLE IF NOT EXISTS public.swipes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id    uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_id    uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  direction    smallint NOT NULL CHECK (direction IN (-1, 1)),
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (swiper_id, target_id)
);
CREATE INDEX IF NOT EXISTS idx_swipes_swiper_created ON public.swipes (swiper_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_swipes_target ON public.swipes (target_id);

-- Matches (par único ordenado)
CREATE TABLE IF NOT EXISTS public.matches (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_b       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CHECK (user_a <> user_b),
  CONSTRAINT uq_match_pair UNIQUE (LEAST(user_a,user_b), GREATEST(user_a,user_b))
);
CREATE INDEX IF NOT EXISTS idx_matches_created ON public.matches (created_at DESC);

-- migrate:down
DROP INDEX IF EXISTS idx_matches_created;
DROP TABLE IF EXISTS public.matches;

DROP INDEX IF EXISTS idx_swipes_target;
DROP INDEX IF EXISTS idx_swipes_swiper_created;
DROP TABLE IF EXISTS public.swipes;

DROP INDEX IF EXISTS idx_user_answers_question;
DROP INDEX IF EXISTS idx_user_answers_user;
DROP TABLE IF EXISTS public.user_answers;
