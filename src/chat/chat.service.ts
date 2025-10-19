// chat.service.ts
import { Injectable, ForbiddenException } from '@nestjs/common';
import { DbService } from '../db.service';
import { ConversationsService } from '../conversations/conversations.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ChatEvents } from './chat.gateway';

type PageOpts = {
  limit?: number;
  before?: string;     // ISO datetime de created_at
  beforeId?: number;   // tie-breaker para created_at iguais
};

@Injectable()
export class ChatService {
  constructor(
    private readonly db: DbService,
    private readonly convs: ConversationsService,
    private readonly notifications: NotificationsService,
    private readonly events: ChatEvents,
  ) {}

  async getMessagesByConversationId(conversationId: number, opts: PageOpts = {}) {
    const limit = Math.min(Math.max(opts.limit ?? 50, 1), 200);

    const params: any[] = [conversationId];
    let where = 'WHERE conversation_id = $1';

    if (opts.before) {
      // created_at < before  OR (created_at == before AND id < beforeId)
      params.push(opts.before);
      where += ` AND (created_at < $${params.length}`;
      if (opts.beforeId != null) {
        params.push(opts.beforeId);
        where += ` OR (created_at = $${params.length - 1} AND id < $${params.length}))`;
      } else {
        where += `)`;
      }
    }

    params.push(limit);
    const limitPos = params.length;

    // Ordena DESC para paginação "para trás" e reverte para devolver ASC
    const { rows } = await this.db.query(
      `
      SELECT id, conversation_id, sender_id, body, created_at
        FROM messages
        ${where}
        ORDER BY created_at DESC, id DESC
        LIMIT $${limitPos}
      `,
      params,
    );

    const items = rows.reverse();

    // Calcula nextCursor a partir do PRIMEIRO item da página *descendente*,
    // ou do último após reverter (items[0] em ASC é o mais antigo; para "carregar mais" use o mais antigo).
    // Aqui vamos usar o mais antigo retornado para continuar “para trás”.
    let nextCursor: string | undefined;
    if (items.length === limit) {
      const oldest = items[0];
      nextCursor = `${new Date(oldest.created_at).toISOString()}_${oldest.id}`;
    }

    return { items, nextCursor };
  }

  async sendMessage(matchId: number, senderId: string, body: string) {
    // segurança: garante que quem envia pertence ao match
    const { rowCount } = await this.db.query(
      `SELECT 1
         FROM matches
        WHERE id = $1
          AND ($2::uuid = user_a OR $2::uuid = user_b)`,
      [matchId, senderId],
    );
    if (!rowCount) throw new ForbiddenException('sender not in match');

    const conv = await this.convs.getOrCreateByMatch(matchId);

    const { rows } = await this.db.query(
      `INSERT INTO messages (conversation_id, sender_id, body)
       VALUES ($1, $2::uuid, $3)
       RETURNING id, conversation_id, sender_id, body, created_at`,
      [conv.id, senderId, body],
    );
    const msg = rows[0];

    const { rows: mRows } = await this.db.query(
      `SELECT user_a, user_b FROM matches WHERE id = $1`,
      [matchId],
    );
    const m = mRows[0];
    const recipient = m.user_a === senderId ? m.user_b : m.user_a;

    await this.notifications.create(recipient, 'message', {
      matchId,
      conversationId: conv.id,
      preview: body.slice(0, 120),
      from: senderId,
    });

    this.events.publish({
      conversationId: conv.id,
      payload: { type: 'message', data: msg },
    });

    return msg;
  }
}
