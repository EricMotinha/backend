import { createParamDecorator, ExecutionContext } from "@nestjs/common";

export const RequestUserId = createParamDecorator((_data: unknown, ctx: ExecutionContext) => {
  const req = ctx.switchToHttp().getRequest();
  // placeholder: pega do header x-user-id
  const headerId = req.headers["x-user-id"];
  if (!headerId || Array.isArray(headerId)) {
    throw new Error("x-user-id header required for now (temporary until JWT is wired)");
  }
  return String(headerId);
});
