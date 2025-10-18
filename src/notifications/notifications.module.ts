import { Module } from '@nestjs/common';
import { DbModule } from '../db.module';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';

@Module({
  imports: [DbModule],
  providers: [NotificationsService],
  controllers: [NotificationsController],
  exports: [NotificationsService], // <-- IMPORTANTE
})
export class NotificationsModule {}
