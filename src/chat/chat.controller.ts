// chat.controller.ts
import {
  Controller, Get, Post, Body, Param, ParseIntPipe, Headers, Sse, MessageEvent, BadRequestException,
} from '@nestjs/common';
import { Observable, from } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { ChatService } from './chat.service';
import { ConversationsService } from '../conversations/conversations.service';
import { ChatEvents } from './chat.gateway';

@Controller('chat')
export class ChatController {
  constructor(
    private readonly chat: ChatService,
    private readonly convs: ConversationsService,
    private readonly events: ChatEvents,
  ) {}

  @Get(':matchId')
  async listMessages(@Param('matchId', ParseIntPipe) matchId: number) {
    const conv = await this.convs.getOrCreateByMatch(matchId);
    return this.chat.getMessagesByConversationId(conv.id);
  }

  @Post(':matchId/message')
  async send(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Headers('x-user-id') userId: string,
    @Body('body') body: string,
  ) {
    if (!userId) throw new BadRequestException('x-user-id header required');
    if (!body?.trim()) throw new BadRequestException('body is required');
    return this.chat.sendMessage(matchId, userId, body.trim());
  }

  @Sse(':matchId/stream')
  stream(@Param('matchId', ParseIntPipe) matchId: number): Observable<MessageEvent> {
    return from(this.convs.getOrCreateByMatch(matchId)).pipe(
      switchMap((conv) => this.events.stream(conv.id)),
    );
  }
}
