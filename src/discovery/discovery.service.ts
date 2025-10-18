import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class DiscoveryService {
  constructor(private readonly db: DbService) {}

  async getCandidates(userId: string) {
    const { rows } = await this.db.query<{
      candidate_id: string; distance_km: number; reason: string;
    }>(`SELECT * FROM public.get_discovery_candidates_cached($1)`, [userId]);
    return rows;
  }
}
