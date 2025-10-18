import { Inject, Injectable } from "@nestjs/common";
import type { Pool } from "pg";

@Injectable()
export class PreferencesRepository {
  constructor(@Inject("PG_POOL") private readonly pool: Pool) {}

  async getByUserId(userId: string) {
    const r = await this.pool.query(
      `SELECT user_id, min_age, max_age, max_distance_km, genders, interests, created_at, updated_at
       FROM partner_preferences WHERE user_id = $1`,
      [userId]
    );
    return r.rows[0] ?? null;
  }

  async upsert(userId: string, d: {
    min_age?: number; max_age?: number; max_distance_km?: number;
    genders?: string[]; interests?: string[];
  }) {
    const r = await this.pool.query(
      `INSERT INTO partner_preferences (user_id, min_age, max_age, max_distance_km, genders, interests)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id) DO UPDATE
         SET min_age = COALESCE(EXCLUDED.min_age, partner_preferences.min_age),
             max_age = COALESCE(EXCLUDED.max_age, partner_preferences.max_age),
             max_distance_km = COALESCE(EXCLUDED.max_distance_km, partner_preferences.max_distance_km),
             genders = COALESCE(EXCLUDED.genders, partner_preferences.genders),
             interests = COALESCE(EXCLUDED.interests, partner_preferences.interests),
             updated_at = now()
       RETURNING user_id, min_age, max_age, max_distance_km, genders, interests, created_at, updated_at`,
      [userId, d.min_age ?? null, d.max_age ?? null, d.max_distance_km ?? null, d.genders ?? null, d.interests ?? null]
    );
    return r.rows[0];
  }

  async ensure(userId: string) {
    const existing = await this.getByUserId(userId);
    if (existing) return existing;
    const r = await this.pool.query(
      `INSERT INTO partner_preferences (user_id) VALUES ($1)
       ON CONFLICT (user_id) DO NOTHING
       RETURNING user_id, min_age, max_age, max_distance_km, genders, interests, created_at, updated_at`,
      [userId]
    );
    return r.rows[0] ?? { user_id: userId, min_age: null, max_age: null, max_distance_km: null, genders: null, interests: null };
  }
}
