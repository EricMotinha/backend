-- +migrate Up
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- +migrate Down
DROP EXTENSION IF EXISTS pgcrypto;
