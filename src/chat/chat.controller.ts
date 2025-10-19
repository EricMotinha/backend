// chat.controller.ts
import {
  Controller, Get, Post, Body, Param, ParseIntPipe, Headers, Sse,
  MessageEvent, BadRequestException, Query, Res,
} from '@nestjs/common';
import type { Response } from 'express';
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
  async list(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Query('limit') limitRaw?: string,
    @Query('before') before?: string,
    @Query('beforeId') beforeIdRaw?: string,
    @Res({ passthrough: true }) res?: Response,
  ) {
    const limit = Math.min(Math.max(parseInt(limitRaw ?? '50', 10), 1), 200);
    const beforeId = beforeIdRaw ? parseInt(beforeIdRaw, 10) : undefined;

    const conv = await this.convs.getOrCreateByMatch(matchId);
    const { items, nextCursor } = await this.chat.getMessagesByConversationId(
      conv.id,
      { limit, before, beforeId },
    );

    if (nextCursor) res?.setHeader('x-next-cursor', nextCursor);
    return items; // mantém compatível com seu uso atual via curl
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
