// src/swipes/swipes.service.ts
import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class SwipesService {
  constructor(private readonly db: DbService) {}

  async createSwipe(swiperId: string, targetId: string, direction: "like" | "pass") {
    // grava o swipe
    await this.db.query(
      `insert into swipes (swiper_id, target_id, direction)
       values ($1::uuid, $2::uuid, $3::text)`,
      [swiperId, targetId, direction]
    );

    // se for "like", verifica match recíproco (target já deu like no swiper)
    const match = await this.db.query<{ id: number }>(
      `with mutual as (
         select 1
         from swipes
         where swiper_id = $2::uuid
           and target_id = $1::uuid
           and direction = 'like'
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
}
