import { Injectable } from "@nestjs/common";
import { PreferencesRepository } from "./preferences.repository";

@Injectable()
export class PreferencesService {
  constructor(private readonly repo: PreferencesRepository) {}
  me(userId: string) { return this.repo.ensure(userId); }
  updateMe(userId: string, dto: any) { return this.repo.upsert(userId, dto); }
}
