// src/swipes/swipes.controller.ts
import { Controller, Post, Body, Get } from '@nestjs/common';
import { DbService } from '../db.service';

type Direction = 'left' | 'right';

@Controller('swipes')
export class SwipesController {
  constructor(private readonly db: DbService) {}

  @Post()
  async create(
    @Body() dto: { swiper_id: string; target_user_id: string; direction: Direction },
  ) {
    // TODO: trocar para SwipesService quando estiver pronto
    const { rows } = await this.db.query(
      `INSERT INTO swipes (swiper_id, target_user_id, direction)
       VALUES ($1::uuid, $2::uuid, $3)
       RETURNING id, swiper_id, target_user_id, direction, created_at`,
      [dto.swiper_id, dto.target_user_id, dto.direction],
    );
    return rows[0];
  }

  @Get('recent')
  async recent() {
    const { rows } = await this.db.query(
      `SELECT id, swiper_id, target_user_id, direction, created_at
         FROM swipes
        ORDER BY created_at DESC
        LIMIT 50`,
      [],
    );
    return rows;
  }
}
