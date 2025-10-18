import { Body, Controller, Get, Post, Headers } from "@nestjs/common";
import { SwipesService } from "./swipes.service";

type DirectionIn = "like" | "dislike" | "superlike" | "pass";

@Controller("swipes")
export class SwipesController {
  constructor(private readonly svc: SwipesService) {}

  @Post()
  create(
    @Headers("x-user-id") userId: string,
    @Body() dto: { targetId: string; direction: DirectionIn }
  ) {
    // Qualquer coisa diferente de "like" vira "dislike"
    const normalized: "like" | "dislike" =
      dto.direction === "like" ? "like" : "dislike";

    return this.svc.createSwipe(userId, dto.targetId, normalized);
  }

  @Get("recent")
  recent(@Headers("x-user-id") userId: string) {
    return this.svc.recent(userId);
  }
}
