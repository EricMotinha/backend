import { Body, Controller, Post, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { Request } from "express";
import { JwtAuthGuard } from "../auth/jwt.guard";
import { Inject } from "@nestjs/common";
import type { Pool } from "pg";

@ApiTags("locations")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("locations")
export class LocationsController {
  constructor(@Inject("PG_POOL") private readonly pool: Pool) {}

  @Post("me")
  async upsert(@Req() req: Request, @Body() body: { lat: number; lng: number; city?: string; region?: string; country?: string }) {
    const user = (req as any).user as { userId: string };
    const r = await this.pool.query(
      `INSERT INTO user_location (user_id, lat, lng, city, region, country)
       VALUES ($1,$2,$3,$4,$5,$6)
       ON CONFLICT (user_id) DO UPDATE
         SET lat = EXCLUDED.lat, lng = EXCLUDED.lng,
             city = COALESCE(EXCLUDED.city, user_location.city),
             region = COALESCE(EXCLUDED.region, user_location.region),
             country = COALESCE(EXCLUDED.country, user_location.country),
             updated_at = now()
       RETURNING user_id, lat, lng, city, region, country, created_at, updated_at`,
      [user.userId, body.lat, body.lng, body.city ?? null, body.region ?? null, body.country ?? null]
    );
    return r.rows[0];
  }
}
