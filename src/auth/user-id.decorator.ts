import { createParamDecorator, ExecutionContext, BadRequestException } from "@nestjs/common";

export const UserId = createParamDecorator((_data: unknown, ctx: ExecutionContext) => {
  const req = ctx.switchToHttp().getRequest();
  const id = (req.headers["x-user-id"] as string | undefined) ?? (req.headers["X-User-Id"] as string | undefined);
  if (!id) throw new BadRequestException("x-user-id header required");
  return id;
});
