import { Inject, Injectable } from "@nestjs/common";
import type { Pool } from "pg";

@Injectable()
export class UsersRepository {
  constructor(@Inject("PG_POOL") private readonly pool: Pool) {}

  async findById(id: string) {
    const r = await this.pool.query("SELECT id, email, created_at, updated_at FROM users WHERE id = $1", [id]);
    return r.rows[0] ?? null;
  }

  async list(limit = 50) {
    const r = await this.pool.query(
      "SELECT id, email, created_at, updated_at FROM users ORDER BY created_at DESC LIMIT $1",
      [limit]
    );
    return r.rows;
  }

  async create(email: string) {
    // Por enquanto só cria user; credenciais/senha entram no módulo de auth
    const r = await this.pool.query(
      "INSERT INTO users (email) VALUES ($1) RETURNING id, email, created_at, updated_at",
      [email]
    );
    return r.rows[0];
  }
}
