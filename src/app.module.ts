import { Global, Module } from '@nestjs/common';
import { Pool } from 'pg';
import { DbService } from './db.service';
import { LoggerModule } from 'nestjs-pino';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Global()
@Module({
  imports: [
    LoggerModule.forRoot({
      // Em dev imprime “bonitinho”; em prod sai NDJSON estruturado
      pinoHttp: process.env.NODE_ENV === 'production'
        ? { level: process.env.LOG_LEVEL ?? 'info' }
        : {
            level: 'debug',
            transport: { target: 'pino-pretty', options: { colorize: true } },
          },
    }),
    ThrottlerModule.forRoot({
      ttl: 60,           // janela de 60s
      limit: 120,        // 120 req/min por IP (ajusta depois por rota se quiser)
      ignoreUserAgents: [/ELB-HealthChecker/i], // opcional
    }),
  ],
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
          idleTimeoutMillis: 30000,
        });
      },
    },
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
  exports: [DbService, 'PG_POOL', LoggerModule],
})
export class DbModule {}
