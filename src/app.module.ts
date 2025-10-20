// src/app.module.ts
import { Global, Module } from "@nestjs/common";
import { APP_GUARD } from "@nestjs/core";
import { Pool } from "pg";
import { randomUUID } from "node:crypto";

import { LoggerModule } from "nestjs-pino";
import { ThrottlerModule, ThrottlerGuard, seconds } from "@nestjs/throttler";

import { DbService } from "./db.service";

@Global()
@Module({
  imports: [
    // Logs: pretty no dev, JSON no prod
    LoggerModule.forRoot({
      pinoHttp: process.env.NODE_ENV === "production"
        ? {
            // id por requisição e ocultar headers sensíveis
            genReqId: (req) =>
              (req.headers["x-request-id"] as string) || randomUUID(),
            redact: ["req.headers.authorization", "res.headers.set-cookie"],
          }
        : {
            transport: {
              target: "pino-pretty",
              options: { translateTime: "SYS:standard" },
            },
            redact: ["req.headers.authorization", "res.headers.set-cookie"],
          },
    }),

    // Rate-limit global (novo formato do @nestjs/throttler)
    ThrottlerModule.forRoot({
      throttlers: [
        {
          ttl: seconds(60), // janela de 60s
          limit: 100,       // até 100 req/IP por janela
        },
      ],
    }),

    // Se você tiver outros módulos (AuthModule, UsersModule, etc.),
    // mantenha-os importados aqui também:
    // AuthModule,
    // UsersModule,
    // ProfilesModule,
    // PreferencesModule,
    // LocationsModule,
    // DiscoveryModule,
    // SwipesModule,
    // MatchesModule,
    // ChatModule,
    // NotificationsModule,
  ],
  providers: [
    DbService,
    {
      provide: "PG_POOL",
      useFactory: () => {
        const cs = process.env.DATABASE_URL;
        if (!cs) throw new Error("DATABASE_URL not set");
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
  exports: [DbService, "PG_POOL"],
})
export class AppModule {}
