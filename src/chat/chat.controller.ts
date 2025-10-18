import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Sse,
  MessageEvent,
} from '@nestjs/common';
import { Observable, from } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { ChatService } from './chat.service';
import { ChatEvents } from './chat.gateway';
import { ConversationsService } from '../conversations/conversations.service';

@Controller('chat')
export class ChatController {
  constructor(
    private readonly chat: ChatService,
    private readonly events: ChatEvents,
    private readonly convs: ConversationsService, // <-- sem "?"
  ) {}

  @Post(':matchId/message')
  async postMessage(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Body('body') body: string,
  ) {
    // TODO: pegar senderId do seu guard/header (mantive exemplo simples)
    const senderId = '11111111-1111-1111-1111-111111111111';
    return this.chat.sendMessage(matchId, senderId, body);
  }

  @Get(':matchId')
  async listMessages(@Param('matchId', ParseIntPipe) matchId: number) {
    const conv = await this.convs.getOrCreateByMatch(matchId);
    // Se você já tem um método no service, use-o; senão, retorne algo simples
    return this.chat.getMessagesByConversationId
      ? this.chat.getMessagesByConversationId(conv.id)
      : { conversationId: conv.id };
  }

  @Sse(':matchId/stream')
  stream(
    @Param('matchId', ParseIntPipe) matchId: number,
  ): Observable<MessageEvent> {
    return from(this.convs.getOrCreateByMatch(matchId)).pipe(
      switchMap((conv) => this.events.stream(conv.id)),
    );
  }
}
