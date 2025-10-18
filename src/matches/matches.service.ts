// src/matches/matches.service.ts
import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class MatchesService {
  constructor(private readonly db: DbService) {}

  async listForUser(userId: string) {
    const { rows } = await this.db.query(
      `select id, user_a, user_b, created_at
       from matches
       where user_a = $1::uuid or user_b = $1::uuid
       order by created_at desc`,
      [userId]
    );
    return rows;
  }
}
