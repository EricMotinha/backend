-- migrate:up
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS rp
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'get_discovery_candidates_cached'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.rp || ' CASCADE';
  END LOOP;
END$$;

CREATE FUNCTION public.get_discovery_candidates_cached(p_user_id uuid)
RETURNS SETOF users
LANGUAGE sql
STABLE
AS $$
  SELECT * FROM public.get_discovery_candidates(p_user_id);
$$;

-- migrate:down
DROP FUNCTION IF EXISTS public.get_discovery_candidates_cached(uuid);