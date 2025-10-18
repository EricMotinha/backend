import { Injectable } from "@nestjs/common";
import { DbService } from "../db.service";

@Injectable()
export class DiscoveryService {
  constructor(private readonly db: DbService) {}

  async getCandidates(userId: string) {
    // força UUID p/ não cair em overload ambiguo
    const { rows } = await this.db.query(
      `select * from public.get_discovery_candidates_cached($1::uuid)`,
      [userId]
    );
    return rows;
  }
}
