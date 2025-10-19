import { Body, Controller, Get, Post } from "@nestjs/common";
import { UserId } from "../auth/user-id.decorator";
import { SwipesService } from "./swipes.service";
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // ajuste o caminho
import { CurrentUser } from '../auth/current-user.decorator';
import { Controller, Post, Body, UseGuards } from '@nestjs/common';

type AnyDir = "like" | "dislike" | "superlike" | "pass";
@UseGuards(JwtAuthGuard)
@Controller('swipes')
export class SwipesController {
  constructor(private readonly service: SwipesService) {}

  @Post()
  create(
    @CurrentUser() user: { id: string },
    @Body() dto: { targetId: string; direction: 1 | -1 },
  ) {
    return this.service.create({
      swiperId: user.id,
      targetId: dto.targetId,
      direction: dto.direction,
    });
  }
}
@Controller("swipes")
export class SwipesController {
  constructor(private readonly svc: SwipesService) {}

  @Post()
  async create(
    @UserId() userId: string,
    @Body() dto: { targetId: string; direction: AnyDir }
  ) {
    // normaliza: tudo que não for "like" vira "dislike"
    const normalized: "like" | "dislike" = dto.direction === "like" ? "like" : "dislike";
    return this.svc.createSwipe(userId, dto.targetId, normalized);
  }

  @Get("recent")
  recent(@UserId() userId: string) {
    return this.svc.listRecent(userId);
  }
}
