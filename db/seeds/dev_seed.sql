-- db/seeds/dev_seed.sql
-- Seed seguro para DEV/STAGING (NÃO usar em produção)
-- Requer: extensões e tabelas criadas pelas migrações iniciais

BEGIN;

-- Extensão para UUIDs (se já existir, ok)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Usuários base (emails devem ser únicos)
INSERT INTO users (id, email, password_hash, created_at)
VALUES
  (gen_random_uuid(), 'demo+no-reply@casamenteiro.app', '.3m5eQy1Xb7v2bU3Ck0m5C1v3o6f0x8iQm5G', now()),
  (gen_random_uuid(), 'eric+teste@casamenteiro.app',     '.3m5eQy1Xb7v2bU3Ck0m5C1v3o6f0x8iQm5H', now())
ON CONFLICT (email) DO NOTHING;

-- Perfis (um por usuário)
INSERT INTO profiles (id, user_id, name, birthdate, city, bio, created_at)
SELECT gen_random_uuid(), u.id,
       CASE WHEN u.email LIKE 'eric%' THEN 'Eric' ELSE 'Demo' END,
       DATE '1995-01-01', 'Belo Horizonte',
       'Perfil inicial para testes do Casamenteiro.',
       now()
FROM users u
WHERE u.email IN ('demo+no-reply@casamenteiro.app','eric+teste@casamenteiro.app')
  AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.user_id = u.id);

-- Catálogo de interesses
INSERT INTO interests_catalog (id, slug, label)
VALUES
  (gen_random_uuid(), 'running', 'Corrida'),
  (gen_random_uuid(), 'reading', 'Leitura'),
  (gen_random_uuid(), 'cinema',  'Cinema')
ON CONFLICT (slug) DO NOTHING;

-- Vincular alguns interesses aos perfis
INSERT INTO profile_interests (profile_id, interest_id)
SELECT p.id, ic.id
FROM profiles p
JOIN users u ON u.id = p.user_id
JOIN interests_catalog ic ON ic.slug IN ('running','reading')
WHERE u.email IN ('demo+no-reply@casamenteiro.app','eric+teste@casamenteiro.app')
  AND NOT EXISTS (
    SELECT 1 FROM profile_interests pi
    WHERE pi.profile_id = p.id AND pi.interest_id = ic.id
  );

COMMIT;
