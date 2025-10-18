import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class MatchesService {
  constructor(private readonly db: DbService) {}

  async list(userId: string) {
    const { rows } = await this.db.query(`
      SELECT m.id, m.user_a, m.user_b, m.created_at, m.archived
      FROM public.matches m
      WHERE (m.user_a = $1 OR m.user_b = $1) AND m.archived = FALSE
      ORDER BY m.created_at DESC
      LIMIT 100
    `, [userId]);
    return rows;
  }
}
