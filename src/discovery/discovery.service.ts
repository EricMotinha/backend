import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class DiscoveryService {
  constructor(private readonly db: DbService) {}

  async getCandidates(userId: string) {
    const { rows } = await this.db.query(
      `
      select u.id, u.name, u.created_at
      from users u
      where u.id <> $1::uuid
        and not exists (
          select 1
          from swipes s
          where s.swiper_id = $1::uuid
            and s.target_id = u.id
        )
      order by u.created_at desc
      limit 20
      `,
      [userId]
    );
    return rows;
  }
}
