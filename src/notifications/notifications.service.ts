import { Injectable } from '@nestjs/common';
import { DbService } from '../db.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly db: DbService) {}

  async list(userId: string) {
    const { rows } = await this.db.query(
      `
      SELECT id, kind, payload, read_at, created_at
      FROM notifications
      WHERE user_id = $1::uuid
      ORDER BY created_at DESC
      LIMIT 50
      `,
      [userId]
    );
    return rows;
  }

  async create(userId: string, kind: string, payload: any) {
    const { rows } = await this.db.query(
      `
      INSERT INTO notifications (user_id, kind, payload)
      VALUES ($1::uuid, $2::text, $3::jsonb)
      RETURNING id, user_id, kind, payload, created_at
      `,
      [userId, kind, payload]
    );
    return rows[0];
  }
}
