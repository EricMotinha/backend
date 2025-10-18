import { Body, Controller, Get, Headers, Post } from "@nestjs/common";
import { SwipesService } from "./swipes.service";

type ApiDirection = "like" | "dislike" | "superlike";

class SwipeDto {
  targetId!: string;
  direction!: ApiDirection;
}

@Controller("swipes")
export class SwipesController {
  constructor(private readonly svc: SwipesService) {}

  @Post()
  async create(@Headers("x-user-id") userId: string, @Body() dto: SwipeDto) {
    // normaliza: dislike/superlike viram "pass" ou "like" conforme regra atual
    const normalized: "like" | "pass" =
      dto.direction === "like" ? "like" : "pass";
    return this.svc.createSwipe(userId, dto.targetId, normalized);
  }

  @Get("recent")
  recent(@Headers("x-user-id") userId: string) {
    return this.svc.recent(userId);
  }
}
