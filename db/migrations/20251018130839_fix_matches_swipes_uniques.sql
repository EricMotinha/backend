-- migrate:up
BEGIN;

-- matches: normaliza e dedup
UPDATE matches
SET user_a = LEAST(user_a, user_b),
    user_b = GREATEST(user_a, user_b);

DELETE FROM matches m
USING matches d
WHERE m.user_a = d.user_a
  AND m.user_b = d.user_b
  AND m.id > d.id;

-- matches: índice único nas colunas
CREATE UNIQUE INDEX IF NOT EXISTS matches_user_pair_uidx
  ON public.matches (user_a, user_b);

-- matches: remove índice por expressão legado
DROP INDEX IF EXISTS uq_match_pair;

-- swipes: limpa índices/constraints antigas e garante um único índice canônico
ALTER TABLE swipes DROP CONSTRAINT IF EXISTS uq_swipe_once_cols;
DROP INDEX IF EXISTS uq_swipe_once;
DROP INDEX IF EXISTS uq_swipe_once_cols;

CREATE UNIQUE INDEX IF NOT EXISTS swipes_swiper_target_uidx
  ON public.swipes (swiper_id, target_id);

COMMIT;

-- migrate:down
BEGIN;
DROP INDEX IF EXISTS swipes_swiper_target_uidx;
-- opcional recriar legado (não recomendo), então só deixo o down “no-op” para matches:
-- DROP INDEX IF EXISTS matches_user_pair_uidx;
COMMIT;
