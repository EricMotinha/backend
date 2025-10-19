-- migrate:up
-- Índices extras em users / profiles para discovery
CREATE INDEX IF NOT EXISTS idx_users_created ON public.users (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_profile_updated ON public.user_profile (updated_at DESC);

-- Função de discovery (versão inicial, sem distância/idade)
-- Retorna candidatos que:
--  - não são o próprio user
--  - ainda não foram swipados por ele
--  - ainda não deram match com ele
-- Ordena por perfis mais recentes/atualizados
CREATE OR REPLACE FUNCTION public.get_discovery_candidates_cached(
  p_user_id uuid,
  p_limit   int DEFAULT 20
) RETURNS TABLE (
  candidate_id uuid,
  candidate_email citext,
  candidate_name text
) AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.email, up.name
  FROM public.users u
  LEFT JOIN public.user_profile up ON up.user_id = u.id
  WHERE u.id <> p_user_id
    AND NOT EXISTS (
      SELECT 1 FROM public.swipes s
      WHERE s.swiper_id = p_user_id AND s.target_id = u.id
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.matches m
      WHERE (m.user_a = p_user_id AND m.user_b = u.id)
         OR (m.user_b = p_user_id AND m.user_a = u.id)
    )
  ORDER BY COALESCE(up.updated_at, u.created_at) DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- migrate:down
DROP FUNCTION IF EXISTS public.get_discovery_candidates_cached(uuid, int);
DROP INDEX IF EXISTS idx_user_profile_updated;
DROP INDEX IF EXISTS idx_users_created;
