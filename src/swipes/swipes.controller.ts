@Post()
create(
  @UserId() userId: string,
  @Body() dto: { targetId: string; direction: "like" | "dislike" | "superlike" | "pass" }
) {
  // Qualquer coisa que não seja "like" vira "dislike"
  const normalized: "like" | "dislike" =
    dto.direction === "like" ? "like" : "dislike";

  return this.svc.createSwipe(userId, dto.targetId, normalized);
}
