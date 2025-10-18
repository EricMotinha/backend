import { Body, Controller, Get, Post } from "@nestjs/common";
import { SwipesService } from "./swipes.service";
import { RequestUserId } from "../common/request-user.decorator";

class CreateSwipeDto {
  targetId!: string;
  direction!: "like" | "dislike" | "superlike";
}

@Controller("swipes")
export class SwipesController {
  constructor(private readonly svc: SwipesService) {}

  @Post()
  async create(@RequestUserId() userId: string, @Body() dto: CreateSwipeDto) {
    return this.svc.createSwipe(userId, dto.targetId, dto.direction);
  }

  @Get("recent")
  async recent(@RequestUserId() userId: string) {
    return this.svc.recent(userId);
  }
}
