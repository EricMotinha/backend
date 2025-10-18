import { Injectable } from '@nestjs/common';
import { DbService } from '../db.service';

@Injectable()
export class ConversationsService {
  constructor(private readonly db: DbService) {}

  async getOrCreateByMatch(matchId: number) {
    const found = await this.db.query(
      `SELECT id, match_id, created_at FROM conversations WHERE match_id=$1`,
      [matchId],
    );
    if (found.rowCount) return found.rows[0];

    const created = await this.db.query(
      `INSERT INTO conversations (match_id) VALUES ($1) RETURNING id, match_id, created_at`,
      [matchId],
    );
    return created.rows[0];
  }

  async findByMatch(matchId: number) {
    const { rows } = await this.db.query(
      `SELECT id, match_id, created_at FROM conversations WHERE match_id=$1`,
      [matchId],
    );
    return rows[0] ?? null;
  }

  async listMessages(conversationId: number, limit = 50) {
    const { rows } = await this.db.query(
      `SELECT id, sender_id, body, created_at
       FROM messages
       WHERE conversation_id=$1
       ORDER BY created_at DESC
       LIMIT $2`,
      [conversationId, limit],
    );
    return rows.reverse();
  }
}
