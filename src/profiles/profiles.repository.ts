import { Inject, Injectable } from "@nestjs/common";
import type { Pool } from "pg";

@Injectable()
export class ProfilesRepository {
  constructor(@Inject("PG_POOL") private readonly pool: Pool) {}

  async getByUserId(userId: string) {
    const r = await this.pool.query(
      `SELECT user_id, display_name, bio, created_at, updated_at
       FROM profiles WHERE user_id = $1`,
      [userId]
    );
    return r.rows[0] ?? null;
  }

  async upsert(userId: string, data: { display_name?: string; bio?: string }) {
    const r = await this.pool.query(
      `INSERT INTO profiles (user_id, display_name, bio)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id) DO UPDATE
         SET display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
             bio = COALESCE(EXCLUDED.bio, profiles.bio),
             updated_at = now()
       RETURNING user_id, display_name, bio, created_at, updated_at`,
      [userId, data.display_name ?? null, data.bio ?? null]
    );
    return r.rows[0];
  }

  async ensure(userId: string) {
    const existing = await this.getByUserId(userId);
    if (existing) return existing;
    const r = await this.pool.query(
      `INSERT INTO profiles (user_id) VALUES ($1)
       ON CONFLICT (user_id) DO NOTHING
       RETURNING user_id, display_name, bio, created_at, updated_at`,
      [userId]
    );
    return r.rows[0] ?? { user_id: userId, display_name: null, bio: null };
  }
}
