import { Injectable, BadRequestException } from "@nestjs/common";
import { DbService } from "../db.service";

type Dir = "like" | "dislike" | "superlike";

@Injectable()
export class SwipesService {
  constructor(private readonly db: DbService) {}

  async createSwipe(swiperId: string, targetId: string, direction: Dir) {
    if (swiperId === targetId) throw new BadRequestException("cannot swipe self");

    // 1) registra swipe (idempotente por índice único)
    await this.db.query(`
      INSERT INTO public.swipes (swiper_id, target_id, direction)
      VALUES ($1,$2,$3)
      ON CONFLICT (swiper_id, target_id) DO UPDATE SET direction = EXCLUDED.direction
    `, [swiperId, targetId, direction]);

    // 2) se for LIKE/SUPERLIKE, verifica reciprocidade
    if (direction !== "dislike") {
      const { rows } = await this.db.query<{ exists: boolean }>(`
        SELECT EXISTS(
          SELECT 1 FROM public.swipes s
          WHERE s.swiper_id = $1 AND s.target_id = $2 AND s.direction IN ('like','superlike')
        ) AS exists
      `, [targetId, swiperId]);

      if (rows[0]?.exists) {
        // 3) cria match se ainda não existe
        const r = await this.db.query<{ id: number }>(`
          INSERT INTO public.matches (user_a, user_b)
          VALUES (LEAST($1,$2), GREATEST($1,$2))
          ON CONFLICT (LEAST(user_a,user_b), GREATEST(user_a,user_b)) DO UPDATE SET archived = FALSE
          RETURNING id
        `, [swiperId, targetId]);
        const matchId = r.rows[0].id;

        // 4) cria conversation se não existir
        await this.db.query(`
          INSERT INTO public.conversations (match_id)
          VALUES ($1)
          ON CONFLICT (match_id) DO NOTHING
        `, [matchId]);

        // 5) notifica ambos (in-app)
        await this.db.query(`
          INSERT INTO public.notifications (user_id, type, payload)
          VALUES ($1,'match', jsonb_build_object('matchId',$3)),
                 ($2,'match', jsonb_build_object('matchId',$3))
        `, [swiperId, targetId, matchId]);

        return { ok: true, matched: true, matchId };
      }
    }

    return { ok: true, matched: false };
  }

  async recent(userId: string) {
    const { rows } = await this.db.query(`
      SELECT id, target_id, direction, created_at
      FROM public.swipes
      WHERE swiper_id = $1
      ORDER BY created_at DESC
      LIMIT 50
    `, [userId]);
    return rows;
  }
}
