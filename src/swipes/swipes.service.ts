// src/swipes/swipes.service.ts
async createSwipe(swiperId: string, targetId: string, direction: "like" | "dislike") {
  // grava/atualiza o swipe
  await this.db.query(
    `
    insert into swipes (swiper_id, target_id, direction)
    values ($1::uuid, $2::uuid, $3::swipe_dir)
    on conflict (swiper_id, target_id)
    do update set direction = excluded.direction, updated_at = now()
    `,
    [swiperId, targetId, direction]
  );

  // se deu "like", verifica recíproco e cria match
  if (direction === "like") {
    const { rows: recip } = await this.db.query(
      `
      select 1
      from swipes
      where swiper_id = $1::uuid
        and target_id = $2::uuid
        and direction = 'like'::swipe_dir
      `,
      [targetId, swiperId]
    );

    if (recip.length > 0) {
      // cria o match se ainda não existir
      await this.db.query(
        `
        insert into matches (user_a, user_b)
        values (least($1::uuid, $2::uuid), greatest($1::uuid, $2::uuid))
        on conflict (user_a, user_b) do nothing
        `,
        [swiperId, targetId]
      );
    }
  }

  return { ok: true };
}
