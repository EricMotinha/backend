import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

type Dir = "like" | "dislike";

@Injectable()
export class SwipesService {
  constructor(private readonly db: DbService) {}

  async createSwipe(swiperId: string, targetId: string, direction: Dir) {
    // UPSERT para evitar erro na uq_swipe_once
    await this.db.query(
      `
      INSERT INTO swipes (swiper_id, target_id, direction)
      VALUES ($1::uuid, $2::uuid, $3::swipe_dir)
      ON CONFLICT (swiper_id, target_id)
      DO UPDATE SET direction = EXCLUDED.direction, updated_at = now()
      `,
      [swiperId, targetId, direction]
    );

    // match só quando like recíproco
    if (direction === "like") {
      const recip = await this.db.query(
        `
        SELECT 1
        FROM swipes
        WHERE swiper_id = $1::uuid
          AND target_id = $2::uuid
          AND direction = 'like'::swipe_dir
        `,
        [targetId, swiperId]
      );

      if (recip.rowCount && recip.rowCount > 0) {
        await this.db.query(
          `
          INSERT INTO matches (user_a, user_b)
          VALUES (LEAST($1::uuid, $2::uuid), GREATEST($1::uuid, $2::uuid))
          ON CONFLICT (user_a, user_b) DO NOTHING
          `,
          [swiperId, targetId]
        );
      }
    }

    return { ok: true };
  }

  async listRecent(swiperId: string) {
    const { rows } = await this.db.query(
      `
      SELECT target_id, direction, created_at
      FROM swipes
      WHERE swiper_id = $1::uuid
      ORDER BY created_at DESC
      LIMIT 50
      `,
      [swiperId]
    );
    return rows;
  }
}
