import { Body, Controller, Get, Param, ParseIntPipe, Post, Sse } from "@nestjs/common";
import { ChatService } from "./chat.service";
import { RequestUserId } from "../common/request-user.decorator";
import { Observable, Subject } from "rxjs";

const streams = new Map<number, Subject<MessageEvent>>();

@Controller("chat")
export class ChatController {
  constructor(private readonly svc: ChatService) {}

  @Get(":matchId")
  async list(
    @RequestUserId() userId: string,
    @Param("matchId", ParseIntPipe) matchId: number
  ) {
    return this.svc.listMessages(userId, matchId);
  }

  @Post(":matchId/message")
  async send(
    @RequestUserId() userId: string,
    @Param("matchId", ParseIntPipe) matchId: number,
    @Body() dto: { body: string }
  ) {
    const res = await this.svc.sendMessage(userId, matchId, dto.body);
    // empurra para SSE da conversa
    const s = streams.get(matchId);
    if (s) s.next({ data: { type: "message", matchId, messageId: res.id } } as MessageEvent);
    return res;
  }

  @Sse(":matchId/stream")
  stream(@Param("matchId", ParseIntPipe) matchId: number): Observable<MessageEvent> {
    let s = streams.get(matchId);
    if (!s) {
      s = new Subject<MessageEvent>();
      streams.set(matchId, s);
    }
    return s.asObservable();
  }
}
