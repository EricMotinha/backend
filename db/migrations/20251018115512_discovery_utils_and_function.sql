-- migrate:up

-- Função Haversine (km)
CREATE OR REPLACE FUNCTION public.haversine_km(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision
) RETURNS double precision
LANGUAGE plpgsql IMMUTABLE
AS $h$
DECLARE
  dlat double precision := radians(lat2 - lat1);
  dlng double precision := radians(lng2 - lng1);
  a double precision := sin(dlat/2)^2 + cos(radians(lat1))*cos(radians(lat2))*sin(dlng/2)^2;
BEGIN
  RETURN 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
END;
$h$;

-- Versão mínima: filtra só por raio máximo (se houver) e ordena por distância
CREATE OR REPLACE FUNCTION public.get_discovery_candidates_cached(p_user_id uuid)
RETURNS TABLE (
  candidate_id uuid,
  distance_km double precision,
  reason text
)
LANGUAGE sql STABLE
AS $f$
WITH me AS (
  SELECT u.id,
         COALESCE(l.lat, 0) AS lat,
         COALESCE(l.lng, 0) AS lng
  FROM public.users u
  LEFT JOIN public.user_location l ON l.user_id = u.id
  WHERE u.id = p_user_id
),
pool AS (
  SELECT u.id AS candidate_id,
         l.lat, l.lng
  FROM public.users u
  LEFT JOIN public.user_location l ON l.user_id = u.id
  WHERE u.id <> p_user_id
),
enriched AS (
  SELECT
    pool.candidate_id,
    COALESCE(haversine_km(me.lat, me.lng, pool.lat, pool.lng), 99999) AS distance_km
  FROM pool CROSS JOIN me
),
filtered AS (
  SELECT
    e.candidate_id,
    e.distance_km,
    CASE
      WHEN p.max_distance_km IS NOT NULL AND e.distance_km > p.max_distance_km THEN 'too_far'
      ELSE 'ok'
    END AS reason
  FROM enriched e
  LEFT JOIN public.partner_preferences p ON p.user_id = p_user_id
)
SELECT candidate_id, distance_km, reason
FROM filtered
WHERE reason = 'ok'
ORDER BY distance_km NULLS LAST
LIMIT 100;
$f$;

-- migrate:down
DROP FUNCTION IF EXISTS public.get_discovery_candidates_cached(uuid);
DROP FUNCTION IF EXISTS public.haversine_km(double precision, double precision, double precision, double precision);