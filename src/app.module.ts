// src/app.module.ts
import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';
import { Pool } from 'pg';

import { DbService } from './db.service';
import { HealthController } from './health.controller';

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp:
        process.env.NODE_ENV === 'production'
          ? { level: process.env.LOG_LEVEL ?? 'info' }
          : {
              level: 'debug',
              transport: { target: 'pino-pretty', options: { colorize: true } },
            },
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60_000, // 60s em ms
        limit: 120,
        ignoreUserAgents: [/ELB-HealthChecker/i],
      },
    ]),
  ],
  controllers: [HealthController],
  providers: [
    DbService,
    {
      provide: 'PG_POOL',
      useFactory: () => {
        const cs = process.env.DATABASE_URL;
        if (!cs) throw new Error('DATABASE_URL not set');
        return new Pool({
          connectionString: cs,
          ssl: { rejectUnauthorized: false },
          max: 10,
          idleTimeoutMillis: 30_000,
        });
      },
    },
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
  exports: [DbService, 'PG_POOL', LoggerModule],
})
export class AppModule {}
