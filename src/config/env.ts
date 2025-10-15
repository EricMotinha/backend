import * as path from 'node:path';
import * as fs from 'node:fs';
import dotenv from 'dotenv';
import { z } from 'zod';

// 1) Base .env (opcional)
const baseEnvPath = path.resolve(process.cwd(), '.env');
if (fs.existsSync(baseEnvPath)) {
  dotenv.config({ path: baseEnvPath });
}

// 2) Ambiente (APP_ENV -> development|staging|production)
const APP_ENV = process.env.APP_ENV || 'development';
const envFile = `.env.${APP_ENV}`;
const envPath = path.resolve(process.cwd(), envFile);

if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
}

// 3) Esquema de validação
const EnvSchema = z.object({
  APP_ENV: z.enum(['development', 'staging', 'production']).default('development'),
  HOST: z.string().min(1).default('0.0.0.0'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().url({ message: 'DATABASE_URL inválida' }),
  JWT_SECRET: z.string().min(8, 'JWT_SECRET precisa de pelo menos 8 chars'),
});

const parsed = EnvSchema.safeParse({
  APP_ENV: process.env.APP_ENV ?? 'development',
  HOST: process.env.HOST ?? '0.0.0.0',
  PORT: process.env.PORT ?? '3000',
  DATABASE_URL: process.env.DATABASE_URL,
  JWT_SECRET: process.env.JWT_SECRET ?? 'change_me',
});

if (!parsed.success) {
  // Mostra quais variáveis faltaram/estão inválidas
  console.error('[env] Erro ao validar variáveis de ambiente:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
