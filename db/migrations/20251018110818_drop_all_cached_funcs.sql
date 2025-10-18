-- migrate:up
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT n.nspname, p.oid::regprocedure AS rp
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'get_discovery_candidates_cached'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.rp || ' CASCADE';
  END LOOP;
END$$;

-- migrate:down
-- (intencionalmente vazio)