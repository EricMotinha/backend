import { Body, Controller, Get, Headers, Param, Post, ParseIntPipe } from '@nestjs/common';
import { DbService } from '../db.service';
import { ChatService } from './chat.service';
import { ConversationsService } from '../conversations/conversations.service';

@Controller('chat')
export class ChatController {
  constructor(
    private readonly chat: ChatService,
    private readonly convs: ConversationsService,
    private readonly db: DbService,
  ) {}

  @Post(':matchId/message')
  async send(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Headers('x-user-id') userId: string,
    @Body() body: { body: string },
  ) {
    return this.chat.sendMessage(matchId, userId, body.body);
  }

  @Get(':matchId')
  async history(
    @Param('matchId', ParseIntPipe) matchId: number,
  ) {
    const conv = await this.convs.findByMatch(matchId);
    if (!conv) return [];
    return this.convs.listMessages(conv.id, 50);
  }
}
