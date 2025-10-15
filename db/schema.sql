--
-- PostgreSQL database dump
--

\restrict FU4DbpbAXHq2h4vo3PLDz8UBFgwfBs1BFxghfo9eCtpA8d7A9WIip7ayGnk9cl1

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


--
-- Name: content_entity_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.content_entity_type_enum AS ENUM (
    'photo',
    'bio',
    'message'
);


--
-- Name: match_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.match_status_enum AS ENUM (
    'active',
    'unmatched',
    'blocked'
);


--
-- Name: message_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.message_status_enum AS ENUM (
    'sent',
    'delivered',
    'read'
);


--
-- Name: moderation_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.moderation_status_enum AS ENUM (
    'pending',
    'approved',
    'rejected'
);


--
-- Name: notification_channel_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_channel_enum AS ENUM (
    'push',
    'email',
    'sms',
    'in_app'
);


--
-- Name: notification_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_type_enum AS ENUM (
    'match',
    'message',
    'like',
    'system'
);


--
-- Name: payment_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_status_enum AS ENUM (
    'paid',
    'refunded',
    'failed'
);


--
-- Name: provider_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.provider_enum AS ENUM (
    'email',
    'google',
    'apple',
    'facebook',
    'instagram',
    'tiktok'
);


--
-- Name: report_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.report_status_enum AS ENUM (
    'open',
    'reviewing',
    'closed'
);


--
-- Name: subscription_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_status_enum AS ENUM (
    'active',
    'past_due',
    'canceled'
);


--
-- Name: swipe_action_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.swipe_action_enum AS ENUM (
    'like',
    'pass',
    'superlike'
);


--
-- Name: user_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_status_enum AS ENUM (
    'active',
    'blocked',
    'deleted',
    'pending_verification'
);


--
-- Name: verification_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.verification_status_enum AS ENUM (
    'pending',
    'approved',
    'rejected'
);


--
-- Name: verification_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.verification_type_enum AS ENUM (
    'selfie',
    'id_document',
    'video'
);


--
-- Name: enqueue_discovery_refresh(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_discovery_refresh(p_viewer uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO discovery_refresh_queue(viewer_user_id)
  VALUES (p_viewer)
  ON CONFLICT (viewer_user_id) DO UPDATE SET queued_at = now();
END$$;


--
-- Name: enqueue_stale_viewers(interval, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_stale_viewers(threshold interval DEFAULT '01:00:00'::interval, max_users integer DEFAULT 5000) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_count int := 0;
BEGIN
  INSERT INTO discovery_refresh_queue(viewer_user_id, queued_at)
  SELECT viewer_user_id, now()
  FROM discovery_cache_health_user
  WHERE age_seconds > EXTRACT(EPOCH FROM threshold)
  ORDER BY age_seconds DESC
  LIMIT max_users
  ON CONFLICT (viewer_user_id) DO UPDATE SET queued_at = EXCLUDED.queued_at;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END$$;


--
-- Name: fn_age_years(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_age_years(born date) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT COALESCE(date_part('year', age(current_date, born))::int, NULL)
$$;


--
-- Name: get_discovery_candidates_cached(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_discovery_candidates_cached(p_viewer uuid, p_limit integer DEFAULT 50) RETURNS TABLE(viewer_user_id uuid, candidate_user_id uuid, candidate_name text, candidate_gender text, candidate_birth_date date, candidate_age integer, candidate_city text, candidate_state text, candidate_country text, viewer_gender text, viewer_birth_date date, viewer_age integer, distance_km double precision, distance_model_km double precision, compatibility_score real, compatibility_breakdown jsonb, computed_at timestamp with time zone, candidate_status public.user_status_enum, candidate_has_approved_photo boolean, rank_score double precision)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM discovery_candidates_cache c
  WHERE c.viewer_user_id = p_viewer;

  IF v_count = 0 THEN
    PERFORM refresh_discovery_cache_for_user(p_viewer, GREATEST(p_limit, 200));
  END IF;

  RETURN QUERY
  SELECT
    c.viewer_user_id,
    c.candidate_user_id,
    c.candidate_name,
    c.candidate_gender,
    c.candidate_birth_date,
    c.candidate_age,
    c.candidate_city,
    c.candidate_state,
    c.candidate_country,
    c.viewer_gender,
    c.viewer_birth_date,
    c.viewer_age,
    c.distance_km,
    c.distance_model_km,
    c.compatibility_score,
    c.compatibility_breakdown,
    c.computed_at,
    c.candidate_status,
    c.candidate_has_approved_photo,
    c.rank_score
  FROM discovery_candidates_cache c
  WHERE c.viewer_user_id = p_viewer
  ORDER BY c.rank_score DESC, c.distance_km ASC, c.computed_at DESC
  LIMIT p_limit;
END$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: compatibility_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.compatibility_scores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    candidate_id uuid NOT NULL,
    score real NOT NULL,
    breakdown jsonb,
    distance_km real,
    computed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT compatibility_scores_score_check CHECK (((score >= (0)::double precision) AND (score <= (1)::double precision)))
);


--
-- Name: partner_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partner_preferences (
    user_id uuid NOT NULL,
    age_min smallint,
    age_max smallint,
    max_distance_km smallint,
    genders text[],
    has_children_allowed boolean,
    wants_children_allowed text[],
    religions text[],
    smoking_allowed text[],
    drinking_allowed text[],
    interests_required uuid[],
    education_levels text[],
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_blocks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    blocker_user_id uuid NOT NULL,
    blocked_user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_location; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_location (
    user_id uuid NOT NULL,
    geo public.geography(Point,4326) NOT NULL,
    city text,
    state text,
    country text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_photos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    url text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    moderation_status public.moderation_status_enum DEFAULT 'pending'::public.moderation_status_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profile (
    user_id uuid NOT NULL,
    full_name text,
    birth_date date,
    gender text,
    bio text,
    height_cm smallint,
    marital_status text,
    has_children boolean,
    wants_children text,
    education_level text,
    occupation text,
    religion text,
    smoking text,
    drinking text,
    profile_completion_pct smallint DEFAULT 0 NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email public.citext,
    phone text,
    password_hash text,
    status public.user_status_enum DEFAULT 'pending_verification'::public.user_status_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_email_or_phone_chk CHECK (((email IS NOT NULL) OR (phone IS NOT NULL)))
);


--
-- Name: discovery_candidates; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.discovery_candidates AS
 SELECT cs.user_id AS viewer_user_id,
    cs.candidate_id AS candidate_user_id,
    up.full_name AS candidate_name,
    up.gender AS candidate_gender,
    up.birth_date AS candidate_birth_date,
    public.fn_age_years(up.birth_date) AS candidate_age,
    ul.city AS candidate_city,
    ul.state AS candidate_state,
    ul.country AS candidate_country,
    pv.gender AS viewer_gender,
    pv.birth_date AS viewer_birth_date,
    public.fn_age_years(pv.birth_date) AS viewer_age,
    (public.st_distance(lv.geo, ul.geo) / (1000.0)::double precision) AS distance_km,
    cs.distance_km AS distance_model_km,
    cs.score AS compatibility_score,
    cs.breakdown AS compatibility_breakdown,
    cs.computed_at,
    u_candidate.status AS candidate_status,
    (EXISTS ( SELECT 1
           FROM public.user_photos p
          WHERE ((p.user_id = cs.candidate_id) AND (p.moderation_status = 'approved'::public.moderation_status_enum))
         LIMIT 1)) AS candidate_has_approved_photo,
    ((cs.score * (0.8)::double precision) + (LEAST((1.0)::double precision, GREATEST((0.0)::double precision, ((1.0)::double precision / ((1.0)::double precision + (public.st_distance(lv.geo, ul.geo) / (1000.0)::double precision))))) * (0.2)::double precision)) AS rank_score
   FROM ((((((((public.compatibility_scores cs
     JOIN public.users u_viewer ON (((u_viewer.id = cs.user_id) AND (u_viewer.status = 'active'::public.user_status_enum))))
     JOIN public.users u_candidate ON (((u_candidate.id = cs.candidate_id) AND (u_candidate.status = 'active'::public.user_status_enum))))
     JOIN public.user_location lv ON ((lv.user_id = cs.user_id)))
     JOIN public.user_location ul ON ((ul.user_id = cs.candidate_id)))
     LEFT JOIN public.user_profile pv ON ((pv.user_id = cs.user_id)))
     LEFT JOIN public.user_profile up ON ((up.user_id = cs.candidate_id)))
     LEFT JOIN public.partner_preferences pp_viewer ON ((pp_viewer.user_id = cs.user_id)))
     LEFT JOIN public.partner_preferences pp_candidate ON ((pp_candidate.user_id = cs.candidate_id)))
  WHERE ((NOT (EXISTS ( SELECT 1
           FROM public.user_blocks b
          WHERE (((b.blocker_user_id = cs.user_id) AND (b.blocked_user_id = cs.candidate_id)) OR ((b.blocker_user_id = cs.candidate_id) AND (b.blocked_user_id = cs.user_id)))))) AND ((pp_viewer.max_distance_km IS NULL) OR public.st_dwithin(lv.geo, ul.geo, ((pp_viewer.max_distance_km)::double precision * (1000.0)::double precision))) AND ((pp_viewer.age_min IS NULL) OR (public.fn_age_years(up.birth_date) >= pp_viewer.age_min)) AND ((pp_viewer.age_max IS NULL) OR (public.fn_age_years(up.birth_date) <= pp_viewer.age_max)) AND ((pp_viewer.genders IS NULL) OR (up.gender = ANY (pp_viewer.genders))) AND ((pp_candidate.age_min IS NULL) OR (public.fn_age_years(pv.birth_date) >= pp_candidate.age_min)) AND ((pp_candidate.age_max IS NULL) OR (public.fn_age_years(pv.birth_date) <= pp_candidate.age_max)) AND ((pp_candidate.genders IS NULL) OR (pv.gender = ANY (pp_candidate.genders))) AND (EXISTS ( SELECT 1
           FROM public.user_photos p
          WHERE ((p.user_id = cs.candidate_id) AND (p.moderation_status = 'approved'::public.moderation_status_enum))
         LIMIT 1)));


--
-- Name: discovery_candidates_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.discovery_candidates_mv AS
 SELECT viewer_user_id,
    candidate_user_id,
    candidate_name,
    candidate_gender,
    candidate_birth_date,
    candidate_age,
    candidate_city,
    candidate_state,
    candidate_country,
    viewer_gender,
    viewer_birth_date,
    viewer_age,
    distance_km,
    distance_model_km,
    compatibility_score,
    compatibility_breakdown,
    computed_at,
    candidate_status,
    candidate_has_approved_photo,
    rank_score
   FROM public.discovery_candidates
  WITH NO DATA;


--
-- Name: get_discovery_candidates_mv(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_discovery_candidates_mv(p_viewer uuid, p_limit integer DEFAULT 50) RETURNS SETOF public.discovery_candidates_mv
    LANGUAGE sql STABLE
    AS $$
  SELECT *
  FROM discovery_candidates_mv
  WHERE viewer_user_id = p_viewer
  ORDER BY rank_score DESC, distance_km ASC, computed_at DESC
  LIMIT p_limit
$$;


--
-- Name: process_discovery_refresh_queue(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.process_discovery_refresh_queue(p_batch integer DEFAULT 200, p_limit integer DEFAULT 200) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_processed int := 0;
  v_user uuid;
BEGIN
  FOR v_user IN
    SELECT viewer_user_id
    FROM discovery_refresh_queue
    ORDER BY queued_at
    LIMIT p_batch
  LOOP
    PERFORM refresh_discovery_cache_for_user(v_user, p_limit);
    DELETE FROM discovery_refresh_queue WHERE viewer_user_id = v_user;
    v_processed := v_processed + 1;
  END LOOP;
  RETURN v_processed;
END$$;


--
-- Name: prune_discovery_cache(interval); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prune_discovery_cache(retention interval DEFAULT '48:00:00'::interval) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE v_deleted bigint;
BEGIN
  DELETE FROM discovery_candidates_cache
  WHERE cached_at < now() - retention;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END$$;


--
-- Name: prune_discovery_queue(interval); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prune_discovery_queue(retention interval DEFAULT '24:00:00'::interval) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE v_deleted bigint;
BEGIN
  DELETE FROM discovery_refresh_queue
  WHERE queued_at < now() - retention;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END$$;


--
-- Name: refresh_discovery_cache_for_user(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_discovery_cache_for_user(p_viewer uuid, p_limit integer DEFAULT 200) RETURNS void
    LANGUAGE sql
    AS $$
  WITH src AS (
    SELECT *
    FROM discovery_candidates
    WHERE viewer_user_id = p_viewer
    ORDER BY rank_score DESC, distance_km ASC, computed_at DESC
    LIMIT p_limit
  )
  INSERT INTO discovery_candidates_cache AS c (
    viewer_user_id, candidate_user_id,
    candidate_name, candidate_gender, candidate_birth_date, candidate_age,
    candidate_city, candidate_state, candidate_country,
    viewer_gender, viewer_birth_date, viewer_age,
    distance_km, distance_model_km, compatibility_score, compatibility_breakdown,
    computed_at, candidate_status, candidate_has_approved_photo, rank_score,
    cached_at, source
  )
  SELECT
    viewer_user_id, candidate_user_id,
    candidate_name, candidate_gender, candidate_birth_date, candidate_age,
    candidate_city, candidate_state, candidate_country,
    viewer_gender, viewer_birth_date, viewer_age,
    distance_km, distance_model_km, compatibility_score, compatibility_breakdown,
    computed_at, candidate_status, candidate_has_approved_photo, rank_score,
    now(), 'live'
  FROM src
  ON CONFLICT (viewer_user_id, candidate_user_id) DO UPDATE
  SET candidate_name = EXCLUDED.candidate_name,
      candidate_gender = EXCLUDED.candidate_gender,
      candidate_birth_date = EXCLUDED.candidate_birth_date,
      candidate_age = EXCLUDED.candidate_age,
      candidate_city = EXCLUDED.candidate_city,
      candidate_state = EXCLUDED.candidate_state,
      candidate_country = EXCLUDED.candidate_country,
      viewer_gender = EXCLUDED.viewer_gender,
      viewer_birth_date = EXCLUDED.viewer_birth_date,
      viewer_age = EXCLUDED.viewer_age,
      distance_km = EXCLUDED.distance_km,
      distance_model_km = EXCLUDED.distance_model_km,
      compatibility_score = EXCLUDED.compatibility_score,
      compatibility_breakdown = EXCLUDED.compatibility_breakdown,
      computed_at = EXCLUDED.computed_at,
      candidate_status = EXCLUDED.candidate_status,
      candidate_has_approved_photo = EXCLUDED.candidate_has_approved_photo,
      rank_score = EXCLUDED.rank_score,
      cached_at = now(),
      source = 'live';

  -- limpa candidatos que sa├¡ram do TOP-N
  DELETE FROM discovery_candidates_cache c2
  WHERE c2.viewer_user_id = p_viewer
    AND NOT EXISTS (
      SELECT 1 FROM discovery_candidates d
      WHERE d.viewer_user_id = p_viewer
        AND d.candidate_user_id = c2.candidate_user_id
      ORDER BY d.rank_score DESC, d.distance_km ASC, d.computed_at DESC
      LIMIT p_limit
    );
$$;


--
-- Name: refresh_discovery_mv(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_discovery_mv() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY discovery_candidates_mv;

  -- m├®trica simples (timestamp do ├║ltimo refresh)
  INSERT INTO discovery_runtime_metrics(key, value)
  VALUES ('mv_last_refresh_at', jsonb_build_object('ts', now()))
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
END$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END$$;


--
-- Name: trg_ai_profile_enqueue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_ai_profile_enqueue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM enqueue_discovery_refresh(NEW.user_id);
  RETURN NEW;
END$$;


--
-- Name: trg_partner_prefs_enqueue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_partner_prefs_enqueue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM enqueue_discovery_refresh(NEW.user_id);
  RETURN NEW;
END$$;


--
-- Name: trg_swipes_enqueue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_swipes_enqueue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM enqueue_discovery_refresh(NEW.actor_user_id);
  RETURN NEW;
END$$;


--
-- Name: trg_user_answers_enqueue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_user_answers_enqueue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM enqueue_discovery_refresh(NEW.user_id);
  RETURN NEW;
END$$;


--
-- Name: trg_user_location_enqueue(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_user_location_enqueue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND NEW.geo IS DISTINCT FROM OLD.geo) THEN
    PERFORM enqueue_discovery_refresh(NEW.user_id);
  END IF;
  RETURN NEW;
END$$;


--
-- Name: ai_profile_analysis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_profile_analysis (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    source text NOT NULL,
    model text,
    summary text,
    traits jsonb,
    embedding public.vector(768),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_settings (
    key text NOT NULL,
    value jsonb
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    action text NOT NULL,
    entity_type text,
    entity_id uuid,
    ip inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
)
PARTITION BY RANGE (created_at);


--
-- Name: audit_logs_y2025m10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs_y2025m10 (
    id uuid DEFAULT gen_random_uuid() CONSTRAINT audit_logs_id_not_null NOT NULL,
    user_id uuid,
    action text CONSTRAINT audit_logs_action_not_null NOT NULL,
    entity_type text,
    entity_id uuid,
    ip inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() CONSTRAINT audit_logs_created_at_not_null NOT NULL
);


--
-- Name: auth_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_identities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider public.provider_enum NOT NULL,
    provider_user_id text NOT NULL,
    access_token text,
    refresh_token text,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: content_moderation_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_moderation_queue (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    entity_type public.content_entity_type_enum NOT NULL,
    entity_id uuid NOT NULL,
    status public.moderation_status_enum DEFAULT 'pending'::public.moderation_status_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    match_id uuid NOT NULL,
    proposed_by uuid NOT NULL,
    status text DEFAULT 'proposed'::text NOT NULL,
    scheduled_for timestamp with time zone,
    place_name text,
    place_geo public.geography(Point,4326),
    notes text
);


--
-- Name: discovery_candidates_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discovery_candidates_cache (
    viewer_user_id uuid NOT NULL,
    candidate_user_id uuid NOT NULL,
    candidate_name text,
    candidate_gender text,
    candidate_birth_date date,
    candidate_age integer,
    candidate_city text,
    candidate_state text,
    candidate_country text,
    viewer_gender text,
    viewer_birth_date date,
    viewer_age integer,
    distance_km double precision,
    distance_model_km double precision,
    compatibility_score real,
    compatibility_breakdown jsonb,
    computed_at timestamp with time zone,
    candidate_status public.user_status_enum,
    candidate_has_approved_photo boolean,
    rank_score double precision,
    cached_at timestamp with time zone DEFAULT now() NOT NULL,
    source text DEFAULT 'live'::text NOT NULL
);


--
-- Name: discovery_cache_health_user; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.discovery_cache_health_user AS
 SELECT viewer_user_id,
    count(*) AS entries,
    max(cached_at) AS last_cached_at,
    EXTRACT(epoch FROM (now() - max(cached_at))) AS age_seconds,
    avg(rank_score) AS avg_rank_score,
    avg(distance_km) AS avg_distance_km,
    percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY distance_km) AS p50_distance_km,
    percentile_cont((0.9)::double precision) WITHIN GROUP (ORDER BY distance_km) AS p90_distance_km
   FROM public.discovery_candidates_cache
  GROUP BY viewer_user_id;


--
-- Name: discovery_refresh_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discovery_refresh_queue (
    viewer_user_id uuid NOT NULL,
    queued_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: discovery_runtime_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discovery_runtime_metrics (
    key text NOT NULL,
    value jsonb NOT NULL
);


--
-- Name: discovery_cache_health_global; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.discovery_cache_health_global AS
 WITH u AS (
         SELECT discovery_cache_health_user.viewer_user_id,
            discovery_cache_health_user.entries,
            discovery_cache_health_user.last_cached_at,
            discovery_cache_health_user.age_seconds,
            discovery_cache_health_user.avg_rank_score,
            discovery_cache_health_user.avg_distance_km,
            discovery_cache_health_user.p50_distance_km,
            discovery_cache_health_user.p90_distance_km
           FROM public.discovery_cache_health_user
        ), mv AS (
         SELECT ((discovery_runtime_metrics.value ->> 'ts'::text))::timestamp with time zone AS mv_last_refresh_at,
            EXTRACT(epoch FROM (now() - ((discovery_runtime_metrics.value ->> 'ts'::text))::timestamp with time zone)) AS mv_age_seconds
           FROM public.discovery_runtime_metrics
          WHERE (discovery_runtime_metrics.key = 'mv_last_refresh_at'::text)
        )
 SELECT ( SELECT count(*) AS count
           FROM u) AS viewers_cached,
    ( SELECT COALESCE(avg(u.entries), (0)::numeric) AS "coalesce"
           FROM u) AS avg_entries_per_viewer,
    ( SELECT COALESCE(avg(u.age_seconds), (0)::numeric) AS "coalesce"
           FROM u) AS avg_cache_age_seconds,
    ( SELECT count(*) AS count
           FROM u
          WHERE (u.age_seconds > (3600)::numeric)) AS stale_viewers_gt_1h,
    ( SELECT count(*) AS count
           FROM public.discovery_refresh_queue) AS refresh_queue_size,
    ( SELECT mv.mv_last_refresh_at
           FROM mv) AS mv_last_refresh_at,
    ( SELECT mv.mv_age_seconds
           FROM mv) AS mv_age_seconds;


--
-- Name: feature_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feature_flags (
    key text NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    metadata jsonb
);


--
-- Name: interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    category text
);


--
-- Name: matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.matches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_a_id uuid NOT NULL,
    user_b_id uuid NOT NULL,
    matched_at timestamp with time zone DEFAULT now() NOT NULL,
    status public.match_status_enum DEFAULT 'active'::public.match_status_enum NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_id uuid NOT NULL,
    sender_user_id uuid NOT NULL,
    content text,
    media_url text,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    status public.message_status_enum DEFAULT 'sent'::public.message_status_enum NOT NULL
)
PARTITION BY RANGE (sent_at);


--
-- Name: messages_y2025m10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages_y2025m10 (
    id uuid DEFAULT gen_random_uuid() CONSTRAINT messages_id_not_null NOT NULL,
    conversation_id uuid CONSTRAINT messages_conversation_id_not_null NOT NULL,
    sender_user_id uuid CONSTRAINT messages_sender_user_id_not_null NOT NULL,
    content text,
    media_url text,
    sent_at timestamp with time zone DEFAULT now() CONSTRAINT messages_sent_at_not_null NOT NULL,
    status public.message_status_enum DEFAULT 'sent'::public.message_status_enum CONSTRAINT messages_status_not_null NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    type public.notification_type_enum NOT NULL,
    payload jsonb,
    channel public.notification_channel_enum DEFAULT 'in_app'::public.notification_channel_enum NOT NULL,
    status text DEFAULT 'queued'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sent_at timestamp with time zone,
    read_at timestamp with time zone
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    amount_cents integer NOT NULL,
    currency text NOT NULL,
    provider text NOT NULL,
    provider_payment_id text NOT NULL,
    status public.payment_status_enum NOT NULL,
    paid_at timestamp with time zone
);


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    price_cents integer NOT NULL,
    currency text NOT NULL,
    features jsonb,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: question_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_options (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    question_id uuid NOT NULL,
    label text NOT NULL,
    value text NOT NULL,
    score_map jsonb
);


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    text text NOT NULL,
    category text,
    answer_type text NOT NULL,
    weight real DEFAULT 1.0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporter_user_id uuid NOT NULL,
    reported_user_id uuid NOT NULL,
    reason text NOT NULL,
    details text,
    status public.report_status_enum DEFAULT 'open'::public.report_status_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: social_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider public.provider_enum NOT NULL,
    handle text,
    profile_url text,
    connected_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'connected'::text NOT NULL
);


--
-- Name: social_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_snapshots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    social_account_id uuid NOT NULL,
    raw_json jsonb,
    taken_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    provider text NOT NULL,
    provider_sub_id text NOT NULL,
    status public.subscription_status_enum DEFAULT 'active'::public.subscription_status_enum NOT NULL,
    current_period_start timestamp with time zone NOT NULL,
    current_period_end timestamp with time zone NOT NULL
);


--
-- Name: user_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_answers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    question_id uuid NOT NULL,
    option_ids uuid[],
    scale_value smallint,
    free_text text,
    answered_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_interests (
    user_id uuid NOT NULL,
    interest_id uuid NOT NULL,
    proficiency smallint
);


--
-- Name: user_languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_languages (
    user_id uuid NOT NULL,
    language_code text NOT NULL,
    level text NOT NULL
);


--
-- Name: user_location_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_location_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    geo public.geography(Point,4326) NOT NULL,
    recorded_at timestamp with time zone NOT NULL
)
PARTITION BY RANGE (recorded_at);


--
-- Name: user_location_history_y2025m10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_location_history_y2025m10 (
    id uuid DEFAULT gen_random_uuid() CONSTRAINT user_location_history_id_not_null NOT NULL,
    user_id uuid CONSTRAINT user_location_history_user_id_not_null NOT NULL,
    geo public.geography(Point,4326) CONSTRAINT user_location_history_geo_not_null NOT NULL,
    recorded_at timestamp with time zone CONSTRAINT user_location_history_recorded_at_not_null NOT NULL
);


--
-- Name: user_swipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_swipes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    actor_user_id uuid NOT NULL,
    target_user_id uuid NOT NULL,
    action public.swipe_action_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: verifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    type public.verification_type_enum NOT NULL,
    status public.verification_status_enum DEFAULT 'pending'::public.verification_status_enum NOT NULL,
    review_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_logs_y2025m10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ATTACH PARTITION public.audit_logs_y2025m10 FOR VALUES FROM ('2025-10-01 00:00:00-03') TO ('2025-11-01 00:00:00-03');


--
-- Name: messages_y2025m10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ATTACH PARTITION public.messages_y2025m10 FOR VALUES FROM ('2025-10-01 00:00:00-03') TO ('2025-11-01 00:00:00-03');


--
-- Name: user_location_history_y2025m10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_location_history ATTACH PARTITION public.user_location_history_y2025m10 FOR VALUES FROM ('2025-10-01 00:00:00-03') TO ('2025-11-01 00:00:00-03');


--
-- Name: ai_profile_analysis ai_profile_analysis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_profile_analysis
    ADD CONSTRAINT ai_profile_analysis_pkey PRIMARY KEY (id);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (key);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id, created_at);


--
-- Name: audit_logs_y2025m10 audit_logs_y2025m10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs_y2025m10
    ADD CONSTRAINT audit_logs_y2025m10_pkey PRIMARY KEY (id, created_at);


--
-- Name: auth_identities auth_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_identities
    ADD CONSTRAINT auth_identities_pkey PRIMARY KEY (id);


--
-- Name: auth_identities auth_identities_provider_provider_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_identities
    ADD CONSTRAINT auth_identities_provider_provider_user_id_key UNIQUE (provider, provider_user_id);


--
-- Name: compatibility_scores compatibility_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compatibility_scores
    ADD CONSTRAINT compatibility_scores_pkey PRIMARY KEY (id);


--
-- Name: compatibility_scores compatibility_scores_user_id_candidate_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compatibility_scores
    ADD CONSTRAINT compatibility_scores_user_id_candidate_id_key UNIQUE (user_id, candidate_id);


--
-- Name: content_moderation_queue content_moderation_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_moderation_queue
    ADD CONSTRAINT content_moderation_queue_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_match_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_match_id_key UNIQUE (match_id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: dates dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dates
    ADD CONSTRAINT dates_pkey PRIMARY KEY (id);


--
-- Name: discovery_candidates_cache discovery_candidates_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovery_candidates_cache
    ADD CONSTRAINT discovery_candidates_cache_pkey PRIMARY KEY (viewer_user_id, candidate_user_id);


--
-- Name: discovery_refresh_queue discovery_refresh_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovery_refresh_queue
    ADD CONSTRAINT discovery_refresh_queue_pkey PRIMARY KEY (viewer_user_id);


--
-- Name: discovery_runtime_metrics discovery_runtime_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovery_runtime_metrics
    ADD CONSTRAINT discovery_runtime_metrics_pkey PRIMARY KEY (key);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (key);


--
-- Name: interests interests_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests
    ADD CONSTRAINT interests_name_key UNIQUE (name);


--
-- Name: interests interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests
    ADD CONSTRAINT interests_pkey PRIMARY KEY (id);


--
-- Name: matches matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, sent_at);


--
-- Name: messages_y2025m10 messages_y2025m10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_y2025m10
    ADD CONSTRAINT messages_y2025m10_pkey PRIMARY KEY (id, sent_at);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: partner_preferences partner_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_preferences
    ADD CONSTRAINT partner_preferences_pkey PRIMARY KEY (user_id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: plans plans_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_name_key UNIQUE (name);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: question_options question_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_options
    ADD CONSTRAINT question_options_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: social_accounts social_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_accounts
    ADD CONSTRAINT social_accounts_pkey PRIMARY KEY (id);


--
-- Name: social_accounts social_accounts_user_id_provider_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_accounts
    ADD CONSTRAINT social_accounts_user_id_provider_key UNIQUE (user_id, provider);


--
-- Name: social_snapshots social_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_snapshots
    ADD CONSTRAINT social_snapshots_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: user_answers user_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_pkey PRIMARY KEY (id);


--
-- Name: user_answers user_answers_user_id_question_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_user_id_question_id_key UNIQUE (user_id, question_id);


--
-- Name: user_blocks user_blocks_blocker_user_id_blocked_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_blocker_user_id_blocked_user_id_key UNIQUE (blocker_user_id, blocked_user_id);


--
-- Name: user_blocks user_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_pkey PRIMARY KEY (id);


--
-- Name: user_interests user_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_interests
    ADD CONSTRAINT user_interests_pkey PRIMARY KEY (user_id, interest_id);


--
-- Name: user_languages user_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_languages
    ADD CONSTRAINT user_languages_pkey PRIMARY KEY (user_id, language_code);


--
-- Name: user_location_history user_location_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_location_history
    ADD CONSTRAINT user_location_history_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: user_location_history_y2025m10 user_location_history_y2025m10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_location_history_y2025m10
    ADD CONSTRAINT user_location_history_y2025m10_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: user_location user_location_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_location
    ADD CONSTRAINT user_location_pkey PRIMARY KEY (user_id);


--
-- Name: user_photos user_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_photos
    ADD CONSTRAINT user_photos_pkey PRIMARY KEY (id);


--
-- Name: user_profile user_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile
    ADD CONSTRAINT user_profile_pkey PRIMARY KEY (user_id);


--
-- Name: user_swipes user_swipes_actor_user_id_target_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_swipes
    ADD CONSTRAINT user_swipes_actor_user_id_target_user_id_key UNIQUE (actor_user_id, target_user_id);


--
-- Name: user_swipes user_swipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_swipes
    ADD CONSTRAINT user_swipes_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: verifications verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifications
    ADD CONSTRAINT verifications_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_logs_user_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user_time ON ONLY public.audit_logs USING btree (user_id, created_at DESC);


--
-- Name: audit_logs_y2025m10_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_y2025m10_user_id_created_at_idx ON public.audit_logs_y2025m10 USING btree (user_id, created_at DESC);


--
-- Name: gist_dates_place; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gist_dates_place ON public.dates USING gist (place_geo);


--
-- Name: gist_user_location_geo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gist_user_location_geo ON public.user_location USING gist (geo);


--
-- Name: gist_user_location_history_geo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gist_user_location_history_geo ON ONLY public.user_location_history USING gist (geo);


--
-- Name: idx_ai_profile_user_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ai_profile_user_time ON public.ai_profile_analysis USING btree (user_id, created_at DESC);


--
-- Name: idx_compat_user_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_compat_user_score ON public.compatibility_scores USING btree (user_id, score DESC);


--
-- Name: idx_content_mod_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_mod_queue ON public.content_moderation_queue USING btree (entity_type, status, created_at DESC);


--
-- Name: idx_disc_cache_viewer_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_disc_cache_viewer_rank ON public.discovery_candidates_cache USING btree (viewer_user_id, rank_score DESC);


--
-- Name: idx_matches_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_matches_status ON public.matches USING btree (status);


--
-- Name: idx_messages_conv_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_conv_time ON ONLY public.messages USING btree (conversation_id, sent_at);


--
-- Name: idx_messages_sender_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_sender_time ON ONLY public.messages USING btree (sender_user_id, sent_at);


--
-- Name: idx_notifications_user_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_time ON public.notifications USING btree (user_id, created_at DESC);


--
-- Name: idx_payments_user_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_user_time ON public.payments USING btree (user_id, paid_at DESC);


--
-- Name: idx_question_options_q; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_question_options_q ON public.question_options USING btree (question_id);


--
-- Name: idx_reports_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reports_status ON public.reports USING btree (status, created_at DESC);


--
-- Name: idx_social_snapshots_acc_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_social_snapshots_acc_time ON public.social_snapshots USING btree (social_account_id, taken_at DESC);


--
-- Name: idx_subscriptions_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_user_status ON public.subscriptions USING btree (user_id, status);


--
-- Name: idx_swipes_actor_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_swipes_actor_time ON public.user_swipes USING btree (actor_user_id, created_at DESC);


--
-- Name: idx_user_answers_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_answers_user ON public.user_answers USING btree (user_id);


--
-- Name: idx_user_location_history_user_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_location_history_user_time ON ONLY public.user_location_history USING btree (user_id, recorded_at DESC);


--
-- Name: idx_verifications_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verifications_user ON public.verifications USING btree (user_id);


--
-- Name: ivff_ai_profile_embedding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ivff_ai_profile_embedding ON public.ai_profile_analysis USING ivfflat (embedding public.vector_cosine_ops);


--
-- Name: messages_y2025m10_conversation_id_sent_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_y2025m10_conversation_id_sent_at_idx ON public.messages_y2025m10 USING btree (conversation_id, sent_at);


--
-- Name: messages_y2025m10_sender_user_id_sent_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_y2025m10_sender_user_id_sent_at_idx ON public.messages_y2025m10 USING btree (sender_user_id, sent_at);


--
-- Name: user_location_history_y2025m10_geo_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_location_history_y2025m10_geo_idx ON public.user_location_history_y2025m10 USING gist (geo);


--
-- Name: user_location_history_y2025m10_user_id_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_location_history_y2025m10_user_id_recorded_at_idx ON public.user_location_history_y2025m10 USING btree (user_id, recorded_at DESC);


--
-- Name: ux_discovery_candidates_mv; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_discovery_candidates_mv ON public.discovery_candidates_mv USING btree (viewer_user_id, candidate_user_id);


--
-- Name: ux_matches_unordered_pair; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_matches_unordered_pair ON public.matches USING btree (LEAST(user_a_id, user_b_id), GREATEST(user_a_id, user_b_id));


--
-- Name: ux_user_photos_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_user_photos_primary ON public.user_photos USING btree (user_id) WHERE is_primary;


--
-- Name: audit_logs_y2025m10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.audit_logs_pkey ATTACH PARTITION public.audit_logs_y2025m10_pkey;


--
-- Name: audit_logs_y2025m10_user_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_audit_logs_user_time ATTACH PARTITION public.audit_logs_y2025m10_user_id_created_at_idx;


--
-- Name: messages_y2025m10_conversation_id_sent_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_messages_conv_time ATTACH PARTITION public.messages_y2025m10_conversation_id_sent_at_idx;


--
-- Name: messages_y2025m10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.messages_pkey ATTACH PARTITION public.messages_y2025m10_pkey;


--
-- Name: messages_y2025m10_sender_user_id_sent_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_messages_sender_time ATTACH PARTITION public.messages_y2025m10_sender_user_id_sent_at_idx;


--
-- Name: user_location_history_y2025m10_geo_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.gist_user_location_history_geo ATTACH PARTITION public.user_location_history_y2025m10_geo_idx;


--
-- Name: user_location_history_y2025m10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.user_location_history_pkey ATTACH PARTITION public.user_location_history_y2025m10_pkey;


--
-- Name: user_location_history_y2025m10_user_id_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_user_location_history_user_time ATTACH PARTITION public.user_location_history_y2025m10_user_id_recorded_at_idx;


--
-- Name: ai_profile_analysis t_ai_profile_enqueue; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER t_ai_profile_enqueue AFTER INSERT OR UPDATE ON public.ai_profile_analysis FOR EACH ROW EXECUTE FUNCTION public.trg_ai_profile_enqueue();


--
-- Name: partner_preferences t_partner_prefs_enqueue; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER t_partner_prefs_enqueue AFTER INSERT OR UPDATE ON public.partner_preferences FOR EACH ROW EXECUTE FUNCTION public.trg_partner_prefs_enqueue();


--
-- Name: user_swipes t_swipes_enqueue; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER t_swipes_enqueue AFTER INSERT ON public.user_swipes FOR EACH ROW EXECUTE FUNCTION public.trg_swipes_enqueue();


--
-- Name: user_answers t_user_answers_enqueue; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER t_user_answers_enqueue AFTER INSERT OR UPDATE ON public.user_answers FOR EACH ROW EXECUTE FUNCTION public.trg_user_answers_enqueue();


--
-- Name: user_location t_user_location_enqueue; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER t_user_location_enqueue AFTER INSERT OR UPDATE ON public.user_location FOR EACH ROW EXECUTE FUNCTION public.trg_user_location_enqueue();


--
-- Name: partner_preferences trg_partner_preferences_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_partner_preferences_updated_at BEFORE UPDATE ON public.partner_preferences FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: user_profile trg_user_profile_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_user_profile_updated_at BEFORE UPDATE ON public.user_profile FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: ai_profile_analysis ai_profile_analysis_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_profile_analysis
    ADD CONSTRAINT ai_profile_analysis_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: auth_identities auth_identities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_identities
    ADD CONSTRAINT auth_identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: compatibility_scores compatibility_scores_candidate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compatibility_scores
    ADD CONSTRAINT compatibility_scores_candidate_id_fkey FOREIGN KEY (candidate_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: compatibility_scores compatibility_scores_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compatibility_scores
    ADD CONSTRAINT compatibility_scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: content_moderation_queue content_moderation_queue_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_moderation_queue
    ADD CONSTRAINT content_moderation_queue_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: conversations conversations_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: dates dates_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dates
    ADD CONSTRAINT dates_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: dates dates_proposed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dates
    ADD CONSTRAINT dates_proposed_by_fkey FOREIGN KEY (proposed_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: matches matches_user_a_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_user_a_id_fkey FOREIGN KEY (user_a_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: matches matches_user_b_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_user_b_id_fkey FOREIGN KEY (user_b_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: messages messages_sender_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.messages
    ADD CONSTRAINT messages_sender_user_id_fkey FOREIGN KEY (sender_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: partner_preferences partner_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_preferences
    ADD CONSTRAINT partner_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: payments payments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: question_options question_options_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_options
    ADD CONSTRAINT question_options_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- Name: reports reports_reported_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: reports reports_reporter_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reporter_user_id_fkey FOREIGN KEY (reporter_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: social_accounts social_accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_accounts
    ADD CONSTRAINT social_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: social_snapshots social_snapshots_social_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_snapshots
    ADD CONSTRAINT social_snapshots_social_account_id_fkey FOREIGN KEY (social_account_id) REFERENCES public.social_accounts(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_answers user_answers_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- Name: user_answers user_answers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_answers
    ADD CONSTRAINT user_answers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_blocks user_blocks_blocked_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_blocked_user_id_fkey FOREIGN KEY (blocked_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_blocks user_blocks_blocker_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_blocker_user_id_fkey FOREIGN KEY (blocker_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_interests user_interests_interest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_interests
    ADD CONSTRAINT user_interests_interest_id_fkey FOREIGN KEY (interest_id) REFERENCES public.interests(id) ON DELETE CASCADE;


--
-- Name: user_interests user_interests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_interests
    ADD CONSTRAINT user_interests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_languages user_languages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_languages
    ADD CONSTRAINT user_languages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_location_history user_location_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.user_location_history
    ADD CONSTRAINT user_location_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_location user_location_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_location
    ADD CONSTRAINT user_location_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_photos user_photos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_photos
    ADD CONSTRAINT user_photos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_profile user_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile
    ADD CONSTRAINT user_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_swipes user_swipes_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_swipes
    ADD CONSTRAINT user_swipes_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_swipes user_swipes_target_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_swipes
    ADD CONSTRAINT user_swipes_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: verifications verifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifications
    ADD CONSTRAINT verifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict FU4DbpbAXHq2h4vo3PLDz8UBFgwfBs1BFxghfo9eCtpA8d7A9WIip7ayGnk9cl1

