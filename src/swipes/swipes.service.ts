import { Injectable, BadRequestException } from "@nestjs/common";
import { DbService } from "../db.service";

type Dir = "like" | "dislike";

@Injectable()
export class SwipesService {
  constructor(private readonly db: DbService) {}

  async createSwipe(swiperId: string, targetId: string, direction: Dir) {
    if (swiperId === targetId) {
      throw new BadRequestException("Você não pode dar swipe em si mesmo.");
    }

    await this.db.query("BEGIN");
    try {
      // 1) UPSERT
      await this.db.query(
        `
        INSERT INTO swipes (swiper_id, target_id, direction)
        VALUES ($1::uuid, $2::uuid, $3::swipe_dir)
        ON CONFLICT (swiper_id, target_id)
        DO UPDATE SET direction = EXCLUDED.direction, updated_at = now()
        `,
        [swiperId, targetId, direction]
      );

      // 2) Se like, tenta criar match de forma idempotente+atômica
      let matchCreated = false;
      if (direction === "like") {
        const res = await this.db.query(
          `
          INSERT INTO matches (user_a, user_b)
          SELECT LEAST($1::uuid, $2::uuid), GREATEST($1::uuid, $2::uuid)
          WHERE EXISTS (
            SELECT 1 FROM swipes
            WHERE swiper_id = $1::uuid AND target_id = $2::uuid AND direction = 'like'::swipe_dir
          )
          AND EXISTS (
            SELECT 1 FROM swipes
            WHERE swiper_id = $2::uuid AND target_id = $1::uuid AND direction = 'like'::swipe_dir
          )
          ON CONFLICT (user_a, user_b) DO NOTHING
          RETURNING 1
          `,
          [swiperId, targetId]
        );
        matchCreated = res.rowCount > 0;
      }

      await this.db.query("COMMIT");
      return { ok: true, matchCreated };
    } catch (e) {
      await this.db.query("ROLLBACK");
      throw e;
    }
  }

  async listRecent(swiperId: string) {
    const { rows } = await this.db.query(
      `
      SELECT target_id, direction, created_at, updated_at
      FROM swipes
      WHERE swiper_id = $1::uuid
      ORDER BY GREATEST(created_at, updated_at) DESC
      LIMIT 50
      `,
      [swiperId]
    );
    return rows;
  }
}
