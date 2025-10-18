import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class ChatService {
  constructor(private readonly db: DbService) {}

  async listMessages(userId: string, matchId: number) {
    // valida participação
    const me = await this.db.query(
      `select 1 from matches
       where id = $1::int
         and (user_a = $2::uuid or user_b = $2::uuid)`,
      [matchId, userId]
    );
    if (me.rowCount === 0) throw new Error("not a match member");

    const { rows } = await this.db.query(
      `select id, match_id, author_id, body, created_at
       from messages
       where match_id = $1::int
       order by created_at asc`,
      [matchId]
    );
    return rows;
  }

  async sendMessage(matchId: number, authorId: string, body: string) {
    // valida participação
    const ok = await this.db.query(
      `select 1 from matches
       where id = $1::int
         and (user_a = $2::uuid or user_b = $2::uuid)`,
      [matchId, authorId]
    );
    if (ok.rowCount === 0) throw new Error("not a match member");

    const ins = await this.db.query<{ id: number }>(
      `insert into messages (match_id, author_id, body)
       values ($1::int, $2::uuid, $3::text)
       returning id`,
      [matchId, authorId, body]
    );
    return { ok: true, id: ins.rows[0].id };
  }
}
