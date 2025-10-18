import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class DiscoveryService {
  constructor(private readonly db: DbService) {}

  async getCandidates(userId: string) {
    const { rows } = await this.db.query(
      `
      SELECT u.id, COALESCE(p.display_name, '') AS name
      FROM users u
      LEFT JOIN profiles p ON p.user_id = u.id	
      WHERE u.id <> $1::uuid
        AND NOT EXISTS (
          SELECT 1 FROM swipes s
          WHERE s.swiper_id = $1::uuid
            AND s.target_id = u.id
        )
      ORDER BY u.created_at DESC
      LIMIT 20
      `,
      [userId]
    );
    return rows;
  }
}
