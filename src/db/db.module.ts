import { Module, Global } from "@nestjs/common";
import { Pool } from "pg";

@Global()
@Module({
  providers: [
    {
      provide: "PG_POOL",
      useFactory: async () => {
        const pool = new Pool({
          connectionString: process.env.DATABASE_URL,
          ssl: process.env.DATABASE_URL?.includes("neon.tech")
            ? { rejectUnauthorized: false }
            : undefined,
        });
        // conexão rápida pra falhar cedo
        await pool.query("select 1");
        return pool;
      },
    },
  ],
  exports: ["PG_POOL"],
})
export class DbModule {}
