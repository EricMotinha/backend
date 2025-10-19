// src/conversations/conversations.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { DbService } from '../db.service';

@Injectable()
export class ConversationsService {
  constructor(private readonly db: DbService) {}

  async getOrCreateByMatch(matchId: number) {
    const { rows } = await this.db.query(
      `
      WITH existing AS (
        SELECT id, match_id FROM conversations WHERE match_id = $1
      ),
      ins AS (
        INSERT INTO conversations (match_id)
        SELECT id FROM matches WHERE id = $1
        ON CONFLICT (match_id) DO NOTHING
        RETURNING id, match_id
      )
      SELECT id, match_id FROM existing
      UNION ALL
      SELECT id, match_id FROM ins
      `,
      [matchId],
    );

    if (rows.length === 0) {
      throw new NotFoundException(`match ${matchId} not found`);
    }
    return rows[0];
  }
}
