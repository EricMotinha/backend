import { Controller, Get, Headers } from "@nestjs/common";
import { MatchesService } from "./matches.service";

@Controller("matches")
export class MatchesController {
  constructor(private readonly svc: MatchesService) {}

  @Get()
  list(@Headers("x-user-id") userId: string) {
    return this.svc.list(userId);
  }
}
