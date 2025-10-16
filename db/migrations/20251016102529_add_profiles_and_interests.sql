-- migrate:up
-- PERFIS
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- para gen_random_uuid(), se ainda não tiver
CREATE TABLE IF NOT EXISTS profiles (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL UNIQUE,
  display_name text,
  bio          text,
  avatar_url   text,
  birth_date   date,
  gender       text,
  city         text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  -- AJUSTE AQUI: se usa Supabase, troque para auth.users; senão, para o schema/tabela de usuários do seu app
  CONSTRAINT fk_profiles_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  -- Exemplo Supabase:
  -- FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- INTERESSES (lista mestre)
CREATE TABLE IF NOT EXISTS interests (
  id    serial PRIMARY KEY,
  slug  text NOT NULL UNIQUE,
  label text NOT NULL UNIQUE
);

-- JUNÇÃO N:N entre profiles e interests
CREATE TABLE IF NOT EXISTS profile_interests (
  profile_id  uuid NOT NULL REFERENCES profiles(id)  ON DELETE CASCADE,
  interest_id int  NOT NULL REFERENCES interests(id) ON DELETE CASCADE,
  PRIMARY KEY (profile_id, interest_id)
);

-- gatilho para updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON profiles;
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- índices úteis
CREATE INDEX IF NOT EXISTS idx_profiles_city ON profiles (city);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles (created_at DESC);

-- opcional: seeds básicos de interesses
INSERT INTO interests (slug, label) VALUES
  ('music', 'Música'),
  ('movies', 'Filmes'),
  ('sports', 'Esportes'),
  ('travel', 'Viagens'),
  ('books', 'Livros')
ON CONFLICT DO NOTHING;

-- migrate:down
-- derruba na ordem inversa
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON profiles;
DROP FUNCTION IF EXISTS set_updated_at();

DROP TABLE IF EXISTS profile_interests;
DROP TABLE IF EXISTS interests;
DROP TABLE IF EXISTS profiles;
