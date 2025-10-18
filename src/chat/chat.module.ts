import { Module } from '@nestjs/common';
import { DbModule } from '../db.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { ChatEvents } from './chat.gateway';

@Module({
  imports: [DbModule, NotificationsModule, ConversationsModule],
  controllers: [ChatController],
  providers: [ChatService, ChatEvents],
})
export class ChatModule {}
