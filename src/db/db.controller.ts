import { Controller, Get, Inject } from "@nestjs/common";
import { Pool } from "pg";

@Controller("db")
export class DbController {
  constructor(@Inject("PG_POOL") private readonly pool: Pool) {}

  @Get("health")
  async health() {
    const { rows } = await this.pool.query("select now()");
    return { ok: true, now: rows[0].now };
  }
}
