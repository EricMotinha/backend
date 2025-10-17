// src/db/db.module.ts
import { Module, Global } from '@nestjs/common';
import { ConfigService, ConfigModule } from '@nestjs/config';
import { Pool } from 'pg';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: 'PG_POOL',
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => {
        const cs = cfg.get<string>('DATABASE_URL');
        if (!cs) {
          // não derruba a app: loga e cria um stub que lança ao usar
          console.warn('[DB] DATABASE_URL ausente; Pool não será inicializado.');
          return null;
        }
        return new Pool({
          connectionString: cs,
          ssl: { rejectUnauthorized: false }, // Neon requer SSL
        });
      },
    },
  ],
  exports: ['PG_POOL'],
})
export class DbModule {}
