// src/db.service.ts
import { Inject, Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Pool, QueryResult } from 'pg';

@Injectable()
export class DbService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DbService.name);

  constructor(@Inject('PG_POOL') private readonly pool: Pool) {}

  async onModuleInit() {
    // sanity check: abre conexão e testa 1 query
    await this.pool.query('select 1');
    this.logger.log('Database pool ready');
  }

  async onModuleDestroy() {
    await this.pool.end();
    this.logger.log('Database pool closed');
  }

  /** Exponha um query tipado igual ao do pg.Pool */
  query<T = any>(text: string, params?: any[]): Promise<QueryResult<T>> {
    return this.pool.query<T>(text, params);
  }

  /** Se precisar de acesso direto ao Pool */
  getClient(): Pool {
    return this.pool;
  }
}
