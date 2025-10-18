// notifications.module.ts
import { Module } from '@nestjs/common';
import { DbModule } from '../db.module';
import { NotificationsService } from './notifications.service';

@Module({
  imports: [DbModule],
  providers: [NotificationsService],
  exports: [NotificationsService], // <- importante
})
export class NotificationsModule {}
