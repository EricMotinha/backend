-- migrate:up
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) profiles (um-para-um com users)
CREATE TABLE IF NOT EXISTS profiles (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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

-- migrate:down
-- rollback conservador (não derruba para não impactar dados já existentes)