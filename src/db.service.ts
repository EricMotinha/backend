import { Injectable, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { Pool, PoolClient, QueryResult } from "pg";

@Injectable()
export class DbService implements OnModuleInit, OnModuleDestroy {
  private pool: Pool;

  constructor() {
    const cs = process.env.DATABASE_URL;
    if (!cs) {
      throw new Error("DATABASE_URL not set");
    }
    // Fly/Neon: SSL exigido
    this.pool = new Pool({
      connectionString: cs,
      ssl: { rejectUnauthorized: false },
      max: 10,
      idleTimeoutMillis: 30000,
    });
  }

  async onModuleInit() {
    const c: PoolClient = await this.pool.connect();
    c.release();
  }

  async onModuleDestroy() {
    await this.pool.end();
  }

  query<T = any>(text: string, params?: any[]): Promise<QueryResult<T>> {
    return this.pool.query<T>(text, params);
  }
}