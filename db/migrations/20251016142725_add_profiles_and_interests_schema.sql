-- migrate:up
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Helper neutro de identidade (funciona com JWT claims ou GUC manual)
CREATE SCHEMA IF NOT EXISTS app;

CREATE OR REPLACE FUNCTION app.uid() RETURNS uuid
LANGUAGE plpgsql STABLE AS $$
DECLARE
  claims text := current_setting('request.jwt.claims', true);
  guc    text := current_setting('app.user_id', true);
  sub    text;
BEGIN
  IF claims IS NOT NULL AND claims <> '' THEN
    sub := (claims::jsonb ->> 'sub');
    IF sub IS NOT NULL AND sub <> '' THEN
      RETURN sub::uuid;
    END IF;
  END IF;

  IF guc IS NOT NULL AND guc <> '' THEN
    RETURN guc::uuid;
  END IF;

  RETURN NULL;
END $$;

-- PERFIS
CREATE TABLE IF NOT EXISTS profiles (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL,
  display_name text,
  bio          text,
  avatar_url   text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT profiles_user_unique UNIQUE (user_id)
  -- Se for Supabase:
  -- ,FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
  -- Se for users local:
  -- ,FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- INTERESSES
CREATE TABLE IF NOT EXISTS interests (
  id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL
);

-- JUNÇÃO
CREATE TABLE IF NOT EXISTS profile_interests (
  profile_id  uuid NOT NULL,
  interest_id uuid NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, interest_id),
  FOREIGN KEY (profile_id)  REFERENCES profiles(id)  ON DELETE CASCADE,
  FOREIGN KEY (interest_id) REFERENCES interests(id) ON DELETE CASCADE
);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS profiles_read_own        ON profiles;
DROP POLICY IF EXISTS profiles_write_own_insert ON profiles;
DROP POLICY IF EXISTS profiles_write_own_update ON profiles;

CREATE POLICY profiles_read_own
  ON profiles FOR SELECT
  USING (user_id = app.uid());

CREATE POLICY profiles_write_own_insert
  ON profiles FOR INSERT
  WITH CHECK (user_id = app.uid());

CREATE POLICY profiles_write_own_update
  ON profiles FOR UPDATE
  USING (user_id = app.uid())
  WITH CHECK (user_id = app.uid());

ALTER TABLE interests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS interests_read_all ON interests;
-- leitura liberada (ajuste se quiser exigir autenticado)
CREATE POLICY interests_read_all
  ON interests FOR SELECT
  USING (true);

ALTER TABLE profile_interests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS profile_interests_read_own   ON profile_interests;
DROP POLICY IF EXISTS profile_interests_write_own  ON profile_interests;
DROP POLICY IF EXISTS profile_interests_update_own ON profile_interests;
DROP POLICY IF EXISTS profile_interests_delete_own ON profile_interests;

CREATE POLICY profile_interests_read_own
  ON profile_interests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = profile_id AND p.user_id = app.uid()
    )
  );

CREATE POLICY profile_interests_write_own
  ON profile_interests FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = profile_id AND p.user_id = app.uid()
    )
  );

CREATE POLICY profile_interests_update_own
  ON profile_interests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = profile_id AND p.user_id = app.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = profile_id AND p.user_id = app.uid()
    )
  );

CREATE POLICY profile_interests_delete_own
  ON profile_interests FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = profile_id AND p.user_id = app.uid()
    )
  );

-- migrate:down
-- Remover policies antes de dropar as tabelas
DROP POLICY IF EXISTS profile_interests_delete_own ON profile_interests;
DROP POLICY IF EXISTS profile_interests_update_own ON profile_interests;
DROP POLICY IF EXISTS profile_interests_write_own  ON profile_interests;
DROP POLICY IF EXISTS profile_interests_read_own   ON profile_interests;

DROP POLICY IF EXISTS interests_read_all           ON interests;

DROP POLICY IF EXISTS profiles_write_own_update    ON profiles;
DROP POLICY IF EXISTS profiles_write_own_insert    ON profiles;
DROP POLICY IF EXISTS profiles_read_own            ON profiles;

DROP TABLE IF EXISTS profile_interests;
DROP TABLE IF EXISTS interests;
DROP TABLE IF EXISTS profiles;

-- (opcional) só apague o helper se ele tiver sido criado aqui e não for reutilizado
-- DROP FUNCTION IF EXISTS app.uid();
-- DROP SCHEMA IF EXISTS app;
