// src/chat/chat.service.ts
async sendMessage(matchId: number, userId: string, body: string) {
  // verifica participação
  const { rows: m } = await this.db.query(
    `
    select 1
    from matches
    where id = $1::int
      and ($2::uuid = user_a or $2::uuid = user_b)
    `,
    [matchId, userId]
  );

  if (m.length === 0) {
    // pode devolver 403/404, mas aqui só padronizei o mesmo erro
    throw new Error("not a match member");
  }

  // insere mensagem
  await this.db.query(
    `
    insert into messages (match_id, sender_id, body)
    values ($1::int, $2::uuid, $3::text)
    `,
    [matchId, userId, body]
  );

  return { ok: true };
}
