import { Body, Controller, Get, Post } from "@nestjs/common";
import { UserId } from "../auth/user-id.decorator";
import { SwipesService } from "./swipes.service";

type AnyDir = "like" | "dislike" | "superlike" | "pass";

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
