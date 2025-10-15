-- migrate:up
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) profiles (um-para-um com users) — sem FK direta
CREATE TABLE IF NOT EXISTS profiles (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid UNIQUE NOT NULL,
  name       text,
  birthdate  date,
  city       text,
  bio        text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2) interests_catalog (catálogo de interesses)
CREATE TABLE IF NOT EXISTS interests_catalog (
  id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug  text UNIQUE NOT NULL,
  label text NOT NULL
);

-- 3) profile_interests (N:N)
CREATE TABLE IF NOT EXISTS profile_interests (
  profile_id  uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  interest_id uuid NOT NULL REFERENCES interests_catalog(id) ON DELETE CASCADE,
  PRIMARY KEY (profile_id, interest_id)
);

-- 4) (Opcional) Adicionar FK para users SE a tabela existir (auth.users ou public.users)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='auth' AND table_name='users'
  ) THEN
    EXECUTE 'ALTER TABLE profiles
             ADD CONSTRAINT profiles_user_fk
             FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='public' AND table_name='users'
  ) THEN
    EXECUTE 'ALTER TABLE profiles
             ADD CONSTRAINT profiles_user_fk
             FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE';
  ELSE
    RAISE NOTICE 'Tabela users não encontrada (auth.users/public.users); mantendo profiles.user_id sem FK';
  END IF;
END $$;

-- migrate:down
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_user_fk'
  ) THEN
    ALTER TABLE IF EXISTS profiles DROP CONSTRAINT profiles_user_fk;
  END IF;
END $$;

DROP TABLE IF EXISTS profile_interests;
DROP TABLE IF EXISTS interests_catalog;
DROP TABLE IF EXISTS profiles;