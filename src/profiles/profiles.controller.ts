import { Body, Controller, Get, Put, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { Request } from "express";
import { ProfilesService } from "./profiles.service";
import { JwtAuthGuard } from "../auth/jwt.guard";
import { UpsertProfileDto } from "./dtos/profile.dto";

@ApiTags("profiles")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("profiles")
export class ProfilesController {
  constructor(private readonly svc: ProfilesService) {}

  @Get("me")
  me(@Req() req: Request) {
    const user = (req as any).user as { userId: string };
    return this.svc.me(user.userId);
  }

  @Put("me")
  updateMe(@Req() req: Request, @Body() dto: UpsertProfileDto) {
    const user = (req as any).user as { userId: string };
    return this.svc.updateMe(user.userId, dto);
  }
}
