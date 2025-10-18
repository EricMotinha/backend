import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class ChatService {
  constructor(private readonly db: DbService) {}

  async sendMessage(matchId: number, userId: string, body: string) {
    // confere se o user participa do match
    const m = await this.db.query(
      `
      SELECT 1
      FROM matches
      WHERE id = $1::int AND ($2::uuid = user_a OR $2::uuid = user_b)
      `,
      [matchId, userId]
    );

    if (m.rowCount === 0) {
      throw new Error("not a match member");
    }

    await this.db.query(
      `
      INSERT INTO messages (match_id, sender_id, body)
      VALUES ($1::int, $2::uuid, $3::text)
      `,
      [matchId, userId, body]
    );

    return { ok: true };
  }
}
