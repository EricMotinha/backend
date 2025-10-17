import { Inject, Injectable } from "@nestjs/common";
import type { Pool } from "pg";

@Injectable()
export class AuthRepository {
  constructor(@Inject("PG_POOL") private readonly pool: Pool) {}

  async findUserByEmail(email: string) {
    const r = await this.pool.query(
      "SELECT id, email, created_at, updated_at FROM users WHERE email = $1",
      [email]
    );
    return r.rows[0] ?? null;
  }

  async createUser(email: string) {
    const r = await this.pool.query(
      "INSERT INTO users (email) VALUES ($1) RETURNING id, email, created_at, updated_at",
      [email]
    );
    return r.rows[0];
  }

  async upsertCredential(userId: string, passwordHash: string) {
    await this.pool.query(
      `
      INSERT INTO user_credentials (user_id, provider, password_hash)
      VALUES ($1, 'local', $2)
      ON CONFLICT (user_id, provider) DO UPDATE SET password_hash = EXCLUDED.password_hash
      `,
      [userId, passwordHash]
    );
  }

  async getPasswordHash(userId: string) {
    const r = await this.pool.query(
      "SELECT password_hash FROM user_credentials WHERE user_id = $1 AND provider = 'local'",
      [userId]
    );
    return r.rows[0]?.password_hash ?? null;
  }

  async createRefresh(userId: string, tokenId: string, tokenHash: string, expiresAt: Date) {
    await this.pool.query(
      `
      INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at, created_at)
      VALUES ($1, $2, $3, $4, now())
      `,
      [tokenId, userId, tokenHash, expiresAt.toISOString()]
    );
  }

  async getRefresh(userId: string, tokenId: string) {
    const r = await this.pool.query(
      "SELECT id, token_hash, expires_at FROM refresh_tokens WHERE id = $1 AND user_id = $2",
      [tokenId, userId]
    );
    return r.rows[0] ?? null;
  }

  async deleteRefresh(userId: string, tokenId: string) {
    await this.pool.query(
      "DELETE FROM refresh_tokens WHERE id = $1 AND user_id = $2",
      [tokenId, userId]
    );
  }
}
