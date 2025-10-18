import { Body, Controller, Get, Param, Post } from "@nestjs/common";
import { ChatService } from "./chat.service";
import { UserId } from "../auth/user-id.decorator";
import { DbService } from "../db.service";

@Controller("chat")
export class ChatController {
  constructor(private readonly svc: ChatService, private readonly db: DbService) {}

  @Post(":matchId/message")
  async send(
    @Param("matchId") matchId: string,
    @UserId() userId: string,
    @Body() dto: { body: string }
  ) {
    await this.svc.sendMessage(Number(matchId), userId, dto.body);
    return { ok: true };
  }

  // opcional: listar mensagens p/ debugar rápido
  @Get(":matchId")
  async list(@Param("matchId") matchId: string, @UserId() userId: string) {
    // (mesma checagem de participação)
    const ok = await this.db.query(
      `select 1 from matches where id=$1::int and ($2::uuid=user_a or $2::uuid=user_b)`,
      [matchId, userId]
    );
    if (ok.rowCount === 0) throw new Error("not a match member");

    const { rows } = await this.db.query(
      `select id, sender_id, body, created_at from messages where match_id=$1::int order by created_at asc`,
      [matchId]
    );
    return rows;
  }
}
