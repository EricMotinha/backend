-- migrate:up

-- Função Haversine (km)
CREATE OR REPLACE FUNCTION public.haversine_km(
  lat1 double precision, lon1 double precision,
  lat2 double precision, lon2 double precision
) RETURNS double precision
LANGUAGE plpgsql IMMUTABLE AS -- migrate:up

-- Conversas (uma por match)
CREATE TABLE IF NOT EXISTS public.conversations (
  id            bigserial PRIMARY KEY,
  match_id      bigint NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_conversation_match ON public.conversations(match_id);

-- Mensagens
CREATE TABLE IF NOT EXISTS public.messages (
  id            bigserial PRIMARY KEY,
  conversation_id bigint NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body          text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  read_at       timestamptz
);
CREATE INDEX IF NOT EXISTS idx_messages_convo ON public.messages(conversation_id, created_at);

-- Notificações simples (in-app)
CREATE TYPE notification_type AS ENUM ('match','message','like','system');
CREATE TABLE IF NOT EXISTS public.notifications (
  id            bigserial PRIMARY KEY,
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type          notification_type NOT NULL,
  payload       jsonb NOT NULL,  -- ex: { matchId: 1 } / { conversationId: 2, messageId: 10 }
  created_at    timestamptz NOT NULL DEFAULT now(),
  read_at       timestamptz
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id) WHERE read_at IS NULL;

-- migrate:down
DROP TABLE IF EXISTS public.notifications;
DROP TYPE IF EXISTS notification_type;
DROP TABLE IF EXISTS public.messages;
DROP TABLE IF EXISTS public.conversations;
DECLARE
  dlat double precision := radians(lat2 - lat1);
  dlon double precision := radians(lon2 - lon1);
  a double precision := sin(dlat/2)^2 + cos(radians(lat1))*cos(radians(lat2))*sin(dlon/2)^2;
BEGIN
  RETURN 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
END;
-- migrate:up

-- Conversas (uma por match)
CREATE TABLE IF NOT EXISTS public.conversations (
  id            bigserial PRIMARY KEY,
  match_id      bigint NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_conversation_match ON public.conversations(match_id);

-- Mensagens
CREATE TABLE IF NOT EXISTS public.messages (
  id            bigserial PRIMARY KEY,
  conversation_id bigint NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body          text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  read_at       timestamptz
);
CREATE INDEX IF NOT EXISTS idx_messages_convo ON public.messages(conversation_id, created_at);

-- Notificações simples (in-app)
CREATE TYPE notification_type AS ENUM ('match','message','like','system');
CREATE TABLE IF NOT EXISTS public.notifications (
  id            bigserial PRIMARY KEY,
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type          notification_type NOT NULL,
  payload       jsonb NOT NULL,  -- ex: { matchId: 1 } / { conversationId: 2, messageId: 10 }
  created_at    timestamptz NOT NULL DEFAULT now(),
  read_at       timestamptz
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id) WHERE read_at IS NULL;

-- migrate:down
DROP TABLE IF EXISTS public.notifications;
DROP TYPE IF EXISTS notification_type;
DROP TABLE IF EXISTS public.messages;
DROP TABLE IF EXISTS public.conversations;;

-- Descoberta de candidatos (filtro simples por idade/gênero/distância)
-- Retorna: candidate_id, distance_km, reason (texto/diagnóstico)
CREATE OR REPLACE FUNCTION public.get_discovery_candidates_cached(p_user_id uuid)
RETURNS TABLE (
  candidate_id uuid,
  distance_km double precision,
  reason text
) LANGUAGE sql STABLE AS $
  WITH me AS (
    SELECT p_user.id,
           COALESCE(l.lat, 0) AS lat, COALESCE(l.lon, 0) AS lon,
           pr.birthdate,
           pr.gender
    FROM public.users p_user
    LEFT JOIN public.user_location l ON l.user_id = p_user.id
    LEFT JOIN public.user_profile pr ON pr.user_id = p_user.id
    WHERE p_user.id = p_user_id
  ),
  prefs AS (
    SELECT pp.user_id, pp.min_age, pp.max_age, pp.max_distance_km, pp.genders
    FROM public.partner_preferences pp WHERE pp.user_id = p_user_id
  ),
  pool AS (
    SELECT u.id AS candidate_id,
           pr.birthdate,
           pr.gender,
           l.lat, l.lon
    FROM public.users u
    LEFT JOIN public.user_profile pr ON pr.user_id = u.id
    LEFT JOIN public.user_location l ON l.user_id = u.id
    WHERE u.id <> p_user_id
  ),
  enriched AS (
    SELECT
      pool.candidate_id,
      COALESCE(haversine_km(me.lat, me.lon, pool.lat, pool.lon), 99999) AS distance_km,
      pool.birthdate,
      pool.gender,
      me.*
    FROM pool CROSS JOIN me
  ),
  age_filtered AS (
    SELECT e.*,
           date_part('year', age(now(), e.birthdate))::int AS age
    FROM enriched e
  ),
  filtered AS (
    SELECT af.candidate_id,
           af.distance_km,
           CASE
             WHEN p.genders IS NOT NULL AND array_length(p.genders,1) > 0 AND af.gender IS DISTINCT FROM ANY(p.genders) THEN 'gender_mismatch'
             WHEN p.min_age IS NOT NULL AND af.age < p.min_age THEN 'age_below_min'
             WHEN p.max_age IS NOT NULL AND af.age > p.max_age THEN 'age_above_max'
             WHEN p.max_distance_km IS NOT NULL AND af.distance_km > p.max_distance_km THEN 'too_far'
             ELSE 'ok'
           END AS reason
    FROM age_filtered af
    LEFT JOIN prefs p ON p.user_id = af.id
  )
  SELECT candidate_id, distance_km, reason FROM filtered WHERE reason = 'ok'
  ORDER BY distance_km NULLS LAST
  LIMIT 100;
$;

-- migrate:down
DROP FUNCTION IF EXISTS public.get_discovery_candidates_cached(uuid);
DROP FUNCTION IF EXISTS public.haversine_km(double precision, double precision, double precision, double precision);
