import { Controller, Get, Post, Body, Headers } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly svc: NotificationsService) {}

  @Get()
  async list(@Headers('x-user-id') userId: string) {
    return this.svc.list(userId);
  }

  @Post()
  async create(
    @Headers('x-user-id') userId: string,
    @Body() body: { kind: string; payload?: any }
  ) {
    return this.svc.create(userId, body.kind, body.payload ?? {});
  }
}
