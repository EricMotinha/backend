// src/conversations/conversations.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { DbService } from '../db.service';

@Injectable()
export class ConversationsService {
  constructor(private readonly db: DbService) {}

  async getOrCreateByMatch(matchId: number) {
    // 1) garante que o match existe
    const { rows: m } = await this.db.query(
      'SELECT id FROM matches WHERE id = $1',
      [matchId],
    );
    if (m.length === 0) {
      throw new NotFoundException(`match ${matchId} not found`);
    }

    // 2) cria se não existir e SEMPRE retorna a conversa
    const { rows } = await this.db.query(
      `INSERT INTO conversations (match_id)
       VALUES ($1)
       ON CONFLICT (match_id)
       DO UPDATE SET match_id = EXCLUDED.match_id
       RETURNING id, match_id`,
      [matchId],
    );

    return rows[0];
  }
}
