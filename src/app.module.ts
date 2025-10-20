// src/app.module.ts
import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

import { DbModule } from './db.module';
// importe seus módulos já existentes (AuthModule, UsersModule etc.)

@Module({
  imports: [
    DbModule,
    LoggerModule.forRoot({
      pinoHttp: {
        transport:
          process.env.NODE_ENV !== 'production'
            ? { target: 'pino-pretty', options: { singleLine: true } }
            : undefined,
        // exemplo de redaction:
        redact: ['req.headers.authorization', 'req.headers.cookie'],
      },
    }),
    ThrottlerModule.forRoot([ // 100 req/1min por IP (ajuste se quiser)
      { ttl: 60_000, limit: 100 },
    ]),
    // ...seus outros módulos
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard }, // rate-limit global
  ],
})
export class AppModule {}
