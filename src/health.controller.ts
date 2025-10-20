// src/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';

@Controller()
export class HealthController {
  @Get('healthz')
  @SkipThrottle()
  health() {
    return { ok: true };
  }
}
