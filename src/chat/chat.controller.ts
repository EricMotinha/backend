import { Body, Controller, Get, Headers, Param, Post } from "@nestjs/common";
import { ChatService } from "./chat.service";

class MessageDto {
  body!: string;
}

@Controller("chat")
export class ChatController {
  constructor(private readonly svc: ChatService) {}

  @Get(":matchId")
  list(@Headers("x-user-id") userId: string, @Param("matchId") matchIdStr: string) {
    const matchId = Number(matchIdStr);
    return this.svc.listMessages(userId, matchId);
  }

  @Post(":matchId/message")
  async send(
    @Headers("x-user-id") userId: string,
    @Param("matchId") matchIdStr: string,
    @Body() dto: MessageDto
  ) {
    const matchId = Number(matchIdStr);
    const res = await this.svc.sendMessage(matchId, userId, dto.body);

    // se tiver SSE aberto, emite evento básico (opcional – deixe como estava)
    try {
      const s = (globalThis as any).__SSE__;
      if (s) s.next({ data: { type: "message", matchId, messageId: res.id } } as MessageEvent);
    } catch {}

    return res;
  }
}
