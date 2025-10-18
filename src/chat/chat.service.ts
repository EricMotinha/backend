import { Injectable, ForbiddenException } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class ChatService {
  constructor(private readonly db: DbService) {}

  async ensureMembership(userId: string, matchId: number) {
    const { rows } = await this.db.query<{ allowed: boolean }>(`
      SELECT EXISTS(
        SELECT 1 FROM public.matches
        WHERE id = $1 AND (user_a = $2 OR user_b = $2) AND archived = FALSE
      ) AS allowed
    `, [matchId, userId]);
    if (!rows[0]?.allowed) throw new ForbiddenException("not a match member");
  }

  async listMessages(userId: string, matchId: number) {
    await this.ensureMembership(userId, matchId);
    const { rows } = await this.db.query(`
      SELECT msg.id, msg.sender_id, msg.body, msg.created_at
      FROM public.messages msg
      JOIN public.conversations c ON c.id = msg.conversation_id
      WHERE c.match_id = $1
      ORDER BY msg.created_at ASC
      LIMIT 200
    `, [matchId]);
    return rows;
  }

  async sendMessage(userId: string, matchId: number, body: string) {
    await this.ensureMembership(userId, matchId);
    const conv = await this.db.query<{ id: number }>(`
      INSERT INTO public.conversations (match_id)
      VALUES ($1)
      ON CONFLICT (match_id) DO UPDATE SET match_id = EXCLUDED.match_id
      RETURNING id
    `, [matchId]);
    const conversationId = conv.rows[0].id;

    const ins = await this.db.query<{ id: number }>(`
      INSERT INTO public.messages (conversation_id, sender_id, body)
      VALUES ($1,$2,$3)
      RETURNING id
    `, [conversationId, userId, body]);

    // notifica o outro usuário
    await this.db.query(`
      WITH m AS (
        SELECT user_a, user_b FROM public.matches WHERE id = $1
      )
      INSERT INTO public.notifications (user_id, type, payload)
      SELECT CASE WHEN $2 = m.user_a THEN m.user_b ELSE m.user_a END, 'message',
             jsonb_build_object('matchId',$1,'messageId',$3)
      FROM m
    `, [matchId, userId, ins.rows[0].id]);

    return { ok: true, id: ins.rows[0].id };
  }
}
