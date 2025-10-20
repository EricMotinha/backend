import { Global, Module } from "@nestjs/common";
import { DbService } from "./db.service";
import { Pool } from "pg";
import { LoggerModule } from "nestjs-pino"; // <-- novo
import { ThrottlerModule, ThrottlerGuard } from "@nestjs/throttler"; // rate-limit
import { APP_GUARD } from "@nestjs/core";

@Global()
@Module({
  imports: [
    // Logs: pretty no dev, JSON no prod
    LoggerModule.forRoot({
      pinoHttp: process.env.NODE_ENV === "production"
        ? {
            // exemplos: gerar id por req e esconder headers sensíveis
            genReqId: (req) => req.headers["x-request-id"] as string || crypto.randomUUID(),
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

    // Rate-limit global simples: 100 req/min por IP
    ThrottlerModule.forRoot({
      ttl: 60,
      limit: 100,
    }),
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
          idleTimeoutMillis: 30000,
        });
      },
    },
    // aplica rate-limit globalmente
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
  exports: [DbService, "PG_POOL"],
})
export class DbModule {}
