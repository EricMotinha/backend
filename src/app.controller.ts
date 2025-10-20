import { Controller, Get } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';

@Controller()
export class AppController {
  @Get('/healthz')
  @SkipThrottle()
  healthz() { return { ok: true }; }
}
