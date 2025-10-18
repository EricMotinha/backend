import { Global, Module } from "@nestjs/common";
import { DbService } from "./db.service";
import { Pool } from "pg";

@Global()
@Module({
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
  ],
  exports: [DbService, "PG_POOL"],
})
export class DbModule {}