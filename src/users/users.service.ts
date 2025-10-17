import { Injectable, NotFoundException } from "@nestjs/common";
import { UsersRepository } from "./users.repository";

@Injectable()
export class UsersService {
  constructor(private readonly repo: UsersRepository) {}

  async get(id: string) {
    const u = await this.repo.findById(id);
    if (!u) throw new NotFoundException("user not found");
    return u;
  }

  list(limit?: number) {
    return this.repo.list(limit);
  }

  create(email: string) {
    return this.repo.create(email);
  }
}
