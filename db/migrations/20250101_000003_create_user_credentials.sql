-- +migrate Up
CREATE TABLE IF NOT EXISTS user_credentials (
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider      text NOT NULL DEFAULT 'local',
  password_hash text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, provider)
);

-- +migrate Down
DROP TABLE IF EXISTS user_credentials;
