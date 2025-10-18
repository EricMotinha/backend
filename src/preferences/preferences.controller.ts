import { Body, Controller, Get, Put, Req, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { Request } from "express";
import { JwtAuthGuard } from "../auth/jwt.guard";
import { PreferencesService } from "./preferences.service";
import { UpsertPreferencesDto } from "./dtos/preferences.dto";

@ApiTags("preferences")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("preferences")
export class PreferencesController {
  constructor(private readonly svc: PreferencesService) {}

  @Get("me")
  me(@Req() req: Request) {
    const user = (req as any).user as { userId: string };
    return this.svc.me(user.userId);
  }

  @Put("me")
  updateMe(@Req() req: Request, @Body() dto: UpsertPreferencesDto) {
    const user = (req as any).user as { userId: string };
    return this.svc.updateMe(user.userId, dto);
  }
}
