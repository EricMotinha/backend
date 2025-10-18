// src/discovery/discovery.service.ts
import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class DiscoveryService {
  constructor(private readonly db: DbService) {}

  async getCandidates(userId: string) {
    const sql = `select * from public.get_discovery_candidates_cached($1::uuid)`;
    const { rows } = await this.db.query(sql, [userId]);
    return rows;
  }
}
