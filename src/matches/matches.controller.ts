import { Controller, Get } from "@nestjs/common";
import { MatchesService } from "./matches.service";
import { RequestUserId } from "../common/request-user.decorator";

@Controller("matches")
export class MatchesController {
  constructor(private readonly svc: MatchesService) {}

  @Get()
  async list(@RequestUserId() userId: string) {
    return this.svc.list(userId);
  }
}
