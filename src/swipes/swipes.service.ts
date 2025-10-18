import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

type SwipeDirection = "like" | "dislike" | "superlike";

@Injectable()
export class SwipesService {
  constructor(private readonly db: DbService) {}

  async createSwipe(swiperId: string, targetId: string, direction: SwipeDirection) {
    // grava respeitando o enum swipe_dir
    await this.db.query(
      `insert into swipes (swiper_id, target_id, direction)
       values ($1::uuid, $2::uuid, $3::swipe_dir)`,
      [swiperId, targetId, direction === "like" ? "like" : "dislike"]
    );

    // cria match se já houver "like" recíproco
    const match = await this.db.query<{ id: number }>(
      `with mutual as (
         select 1
         from swipes
         where swiper_id = $2::uuid
           and target_id = $1::uuid
           and direction = 'like'::swipe_dir
       )
       insert into matches (user_a, user_b)
       select least($1::uuid, $2::uuid), greatest($1::uuid, $2::uuid)
       where exists (select 1 from mutual)
       on conflict do nothing
       returning id`,
      [swiperId, targetId]
    );

    return { ok: true, matched: match.rowCount > 0, matchId: match.rows[0]?.id };
  }

  async recent(userId: string) {
    const { rows } = await this.db.query(
      `select id, swiper_id, target_id, direction, created_at
       from swipes
       where swiper_id = $1::uuid
       order by created_at desc
       limit 20`,
      [userId]
    );
    return rows;
  }
}
