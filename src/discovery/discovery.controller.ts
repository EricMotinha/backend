import { Controller, Get } from "@nestjs/common";
import { DiscoveryService } from "./discovery.service";
import { RequestUserId } from "../common/request-user.decorator";

@Controller("discovery")
export class DiscoveryController {
  constructor(private readonly svc: DiscoveryService) {}

  @Get()
  async list(@RequestUserId() userId: string) {
    return this.svc.getCandidates(userId);
  }
}
