import { Module } from '@nestjs/common';
import { DbModule } from '../db.module';
import { ConversationsService } from './conversations.service';

@Module({
  imports: [DbModule],
  providers: [ConversationsService],
  exports: [ConversationsService], // <-- IMPORTANTE
})
export class ConversationsModule {}