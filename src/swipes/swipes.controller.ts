import { Body, Controller, Get, Post } from "@nestjs/common";
import { SwipesService } from "./swipes.service";
import { UserId } from "../auth/user-id.decorator";

type DirectionIn = "like" | "dislike" | "superlike" | "pass";

@Controller("swipes")
export class SwipesController {
  constructor(private readonly svc: SwipesService) {}

  @Post()
  create(
    @UserId() userId: string,
    @Body() dto: { targetId: string; direction: DirectionIn }
  ) {
    // Qualquer coisa diferente de "like" vira "dislike"
    const normalized: "like" | "dislike" =
      dto.direction === "like" ? "like" : "dislike";

    return this.svc.createSwipe(userId, dto.targetId, normalized);
  }

  @Get("recent")
  recent(@UserId() userId: string) {
    return this.svc.recent(userId);
  }
}
