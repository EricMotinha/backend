-- migrate:up
CREATE OR REPLACE FUNCTION get_discovery_candidates_cached(
  p_user_id uuid,
  p_limit   int DEFAULT 20
) RETURNS TABLE (id uuid, name text)
LANGUAGE sql STABLE AS $$
  SELECT u.id, COALESCE(p.display_name, '') AS name
  FROM users u
  LEFT JOIN user_profile p ON p.user_id = u.id
  WHERE u.id <> p_user_id
    AND NOT EXISTS (
      SELECT 1 FROM swipes s
      WHERE s.swiper_id = p_user_id AND s.target_id = u.id
    )
  ORDER BY u.created_at DESC
  LIMIT p_limit
$$;
-- migrate:down
DROP FUNCTION IF EXISTS get_discovery_candidates_cached(uuid, int);
