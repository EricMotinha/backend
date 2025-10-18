-- migrate:up

-- Respostas a perguntas do onboarding (livre, para IA/compatibilidade)
CREATE TABLE IF NOT EXISTS public.user_answers (
  id            bigserial PRIMARY KEY,
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  question_key  text NOT NULL,          -- ex: 'life_goals', 'religion_importance'
  answer_json   jsonb NOT NULL,         -- livre/estruturado
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_answers_unique ON public.user_answers(user_id, question_key);

-- Swipes (like/dislike/superlike)
CREATE TYPE swipe_dir AS ENUM ('like','dislike','superlike');
CREATE TABLE IF NOT EXISTS public.swipes (
  id            bigserial PRIMARY KEY,
  swiper_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  direction     swipe_dir NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_swipe_once ON public.swipes(swiper_id, target_id);
CREATE INDEX IF NOT EXISTS idx_swipes_target ON public.swipes(target_id);

-- Matches (quando dois 'likes' se cruzam)
CREATE TABLE IF NOT EXISTS public.matches (
  id            bigserial PRIMARY KEY,
  user_a        uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_b        uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now(),
  archived      boolean NOT NULL DEFAULT false
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_match_pair ON public.matches(LEAST(user_a,user_b), GREATEST(user_a,user_b));

-- migrate:down
DROP TABLE IF EXISTS public.matches;
DROP TABLE IF EXISTS public.swipes;
DROP TYPE IF EXISTS swipe_dir;
DROP TABLE IF EXISTS public.user_answers;
