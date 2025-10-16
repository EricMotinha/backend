-- migrate:up
-- Helper de "identidade" agnóstico (usa JWT claims ou um GUC manual)
CREATE SCHEMA IF NOT EXISTS app;

CREATE OR REPLACE FUNCTION app.uid() RETURNS uuid
LANGUAGE plpgsql STABLE AS $$
DECLARE
  claims text := current_setting('request.jwt.claims', true); -- se houver pgjwt/headers
  guc    text := current_setting('app.user_id', true);        -- fallback: SET app.user_id = '<uuid>'
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

-- (exemplo) recria as policies trocando auth.uid() -> app.uid()
-- ajuste os nomes das policies conforme as suas
DROP POLICY IF EXISTS profiles_owner_read  ON profiles;
DROP POLICY IF EXISTS profiles_owner_write ON profiles;

CREATE POLICY profiles_owner_read
  ON profiles FOR SELECT
  USING (user_id = app.uid());

CREATE POLICY profiles_owner_write
  ON profiles FOR UPDATE
  USING (user_id = app.uid())
  WITH CHECK (user_id = app.uid());

-- migrate:down
-- (opcional) rollback: remove policies e função/helper
DROP POLICY IF EXISTS profiles_owner_write ON profiles;
DROP POLICY IF EXISTS profiles_owner_read  ON profiles;
DROP FUNCTION IF EXISTS app.uid();
DROP SCHEMA IF EXISTS app;
