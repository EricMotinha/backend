import { Injectable } from '@nestjs/common';
import { DbService } from '../db.service';
import { ConversationsService } from '../conversations/conversations.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ChatEvents } from './chat.gateway';

@Injectable()
export class ChatService {
  constructor(
    private readonly db: DbService,
    private readonly convs: ConversationsService, // <-- sem "?"
    private readonly notifications: NotificationsService,
    private readonly events: ChatEvents,
  ) {}

 async getMessagesByConversationId(conversationId: number) {
  // IMPLEMENTAÇÃO REAL (se você usa Prisma):
  // return this.db.message.findMany({
  //   where: { conversationId },
  //   orderBy: { createdAt: 'asc' },
  // });

  // Placeholder temporário para compilar e subir:
  return [];
 }
  async sendMessage(matchId: number, senderId: string, body: string) {
    const conv = await this.convs.getOrCreateByMatch(matchId);

    const { rows } = await this.db.query(
      `INSERT INTO messages (conversation_id, sender_id, body)
       VALUES ($1, $2::uuid, $3)
       RETURNING id, conversation_id, sender_id, body, created_at`,
      [conv.id, senderId, body],
    );
    const msg = rows[0];

    const { rows: mRows } = await this.db.query(
      `SELECT user_a, user_b FROM matches WHERE id=$1`,
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

    // publicar no SSE
    this.events.publish({
      conversationId: conv.id,
      payload: { type: 'message', data: msg },
    });

    return msg;
  }
}
