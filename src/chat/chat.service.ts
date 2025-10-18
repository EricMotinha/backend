// src/chat/chat.service.ts
import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class ChatService {
  constructor(private readonly db: DbService) {}

  async sendMessage(matchId: number, authorId: string, body: string) {
    // valida se o author participa do match
    const ok = await this.db.query(
      `select 1
       from matches
       where id = $1::int
         and (user_a = $2::uuid or user_b = $2::uuid)`,
      [matchId, authorId]
    );
    if (ok.rowCount === 0) {
      throw new Error("not a match member");
    }

    // grava mensagem
    await this.db.query(
      `insert into messages (match_id, author_id, body)
       values ($1::int, $2::uuid, $3::text)`,
      [matchId, authorId, body]
    );

    return { ok: true };
  }
}
