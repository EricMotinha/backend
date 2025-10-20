// src/app.module.ts
import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { Pool } from 'pg';
import { LoggerModule } from 'nestjs-pino';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { DbService } from './db.service';
import { HealthController } from './health.controller';
import { randomUUID } from 'node:crypto';

@Global()
@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp:
        process.env.NODE_ENV === 'production'
          ? {
              // id por request + ocultar headers sensíveis
              genReqId: (req) =>
                (req.headers['x-request-id'] as string) || randomUUID(),
              redact: ['req.headers.authorization', 'res.headers.set-cookie'],
            }
          : {
              transport: {
                target: 'pino-pretty',
                options: { translateTime: 'SYS:standard' },
              },
              redact: ['req.headers.authorization', 'res.headers.set-cookie'],
            },
    }),

    // Rate-limit (v5): ttl em milissegundos
    ThrottlerModule.forRoot({
      throttlers: [
        {
          ttl: 60_000, // 60s
          limit: 100,  // 100 req/IP por janela
        },
      ],
    }),
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
    // aplica rate-limit globalmente
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
  exports: [DbService, 'PG_POOL'],
})
export class AppModule {}
