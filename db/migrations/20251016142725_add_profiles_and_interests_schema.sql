-- migrate:up
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- PERFIS
CREATE TABLE IF NOT EXISTS profiles (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL,
  display_name text,
  bio         text,
  avatar_url  text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
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

-- RLS (exemplo comum em Supabase)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_read_own"
  ON profiles FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "profiles_write_own_insert"
  ON profiles FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "profiles_write_own_update"
  ON profiles FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

ALTER TABLE interests ENABLE ROW LEVEL SECURITY;
-- leitura liberada a usuários autenticados (ajuste se quiser público anônimo)
CREATE POLICY "interests_read_all"
  ON interests FOR SELECT USING (true);

ALTER TABLE profile_interests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profile_interests_read_own"
  ON profile_interests FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = profile_id AND p.user_id = auth.uid()
  ));
CREATE POLICY "profile_interests_write_own"
  ON profile_interests FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = profile_id AND p.user_id = auth.uid()
  ));
CREATE POLICY "profile_interests_update_own"
  ON profile_interests FOR UPDATE USING (EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = profile_id AND p.user_id = auth.uid()
  )) WITH CHECK (EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = profile_id AND p.user_id = auth.uid()
  ));
CREATE POLICY "profile_interests_delete_own"
  ON profile_interests FOR DELETE USING (EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = profile_id AND p.user_id = auth.uid()
  ));

-- migrate:down
DROP TABLE IF EXISTS profile_interests;
DROP TABLE IF EXISTS interests;
DROP TABLE IF EXISTS profiles;
