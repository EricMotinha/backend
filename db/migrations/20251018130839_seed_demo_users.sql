-- migrate:up
-- seed demo: USERS A/B + profiles + location + prefs

WITH u AS (
  INSERT INTO public.users (id, email)
  VALUES
    ('11111111-1111-1111-1111-111111111111', 'user_a@example.com'),
    ('22222222-2222-2222-2222-222222222222', 'user_b@example.com')
  ON CONFLICT (id) DO NOTHING
  RETURNING id
),
p AS (
  INSERT INTO public.profiles (user_id)
  VALUES
    ('11111111-1111-1111-1111-111111111111'),
    ('22222222-2222-2222-2222-222222222222')
  ON CONFLICT (user_id) DO NOTHING
  RETURNING user_id
),
l AS (
  INSERT INTO public.user_location (user_id, lat, lng)
  VALUES
    ('11111111-1111-1111-1111-111111111111', -23.5505, -46.6333),
    ('22222222-2222-2222-2222-222222222222', -23.5614, -46.6559)
  ON CONFLICT (user_id) DO NOTHING
  RETURNING user_id
)
INSERT INTO public.partner_preferences (user_id, min_age, max_age, max_distance_km, genders)
VALUES
  ('11111111-1111-1111-1111-111111111111', 18, 99, 50, NULL),
  ('22222222-2222-2222-2222-222222222222', 18, 99, 50, NULL)
ON CONFLICT (user_id) DO NOTHING;

-- migrate:down
-- (sem down)