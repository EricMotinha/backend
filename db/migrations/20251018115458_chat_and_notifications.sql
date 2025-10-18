-- migrate:up

-- Conversas (uma por match)
CREATE TABLE IF NOT EXISTS public.conversations (
  id            bigserial PRIMARY KEY,
  match_id      bigint NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_conversation_match ON public.conversations(match_id);

-- Mensagens
CREATE TABLE IF NOT EXISTS public.messages (
  id            bigserial PRIMARY KEY,
  conversation_id bigint NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body          text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  read_at       timestamptz
);
CREATE INDEX IF NOT EXISTS idx_messages_convo ON public.messages(conversation_id, created_at);

-- Notificações simples (in-app)
CREATE TYPE notification_type AS ENUM ('match','message','like','system');
CREATE TABLE IF NOT EXISTS public.notifications (
  id            bigserial PRIMARY KEY,
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type          notification_type NOT NULL,
  payload       jsonb NOT NULL,  -- ex: { matchId: 1 } / { conversationId: 2, messageId: 10 }
  created_at    timestamptz NOT NULL DEFAULT now(),
  read_at       timestamptz
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id) WHERE read_at IS NULL;

-- migrate:down
DROP TABLE IF EXISTS public.notifications;
DROP TYPE IF EXISTS notification_type;
DROP TABLE IF EXISTS public.messages;
DROP TABLE IF EXISTS public.conversations;
