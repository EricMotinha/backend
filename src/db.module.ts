// src/db.module.ts
import { Module } from "@nestjs/common";
import { Pool } from "pg";

@Module({
  providers: [
    {
      provide: "PG_POOL",
      useFactory: async () => {
        const pool = new Pool({
          connectionString: process.env.DATABASE_URL,
          ssl: { rejectUnauthorized: false }, // Neon
        });
        // valida rápido sem derrubar app caso falhe
        // await pool.query("select 1");  <-- só ligue quando quiser falhar no boot
        return pool;
      },
    },
  ],
  exports: ["PG_POOL"],
})
export class DbModule {}
