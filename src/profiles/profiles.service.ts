import { Injectable } from "@nestjs/common";
import { ProfilesRepository } from "./profiles.repository";

@Injectable()
export class ProfilesService {
  constructor(private readonly repo: ProfilesRepository) {}

  me(userId: string) {
    return this.repo.ensure(userId);
  }

  updateMe(userId: string, data: { display_name?: string; bio?: string }) {
    return this.repo.upsert(userId, data);
  }
}
