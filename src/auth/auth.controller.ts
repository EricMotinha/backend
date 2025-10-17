import { Body, Controller, Post, Req, Res, UnauthorizedException, UseGuards, Get } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { Request, Response } from "express";
import { AuthService } from "./auth.service";
import { LoginDto, SignupDto } from "./dtos/auth.dto";
import { JwtService } from "@nestjs/jwt";
import { JwtAuthGuard } from "./jwt.guard";

@ApiTags("auth")
@Controller("auth")
export class AuthController {
  constructor(private readonly svc: AuthService, private readonly jwt: JwtService) {}

  @Post("signup")
  async signup(@Body() dto: SignupDto, @Res({ passthrough: true }) res: Response) {
    const out = await this.svc.signup(dto.email, dto.password);
    this.setRefreshCookie(res, out.refreshToken);
    return { user: out.user, accessToken: out.accessToken };
  }

  @Post("login")
  async login(@Body() dto: LoginDto, @Res({ passthrough: true }) res: Response) {
    const out = await this.svc.login(dto.email, dto.password);
    this.setRefreshCookie(res, out.refreshToken);
    return { user: out.user, accessToken: out.accessToken };
  }

  @Post("refresh")
  async refresh(@Req() req: Request) {
    const cookie = req.cookies?.rt as string | undefined;
    if (!cookie) throw new UnauthorizedException("missing cookie");

    const payload = await this.jwt.verifyAsync<{ sub: string; jti: string }>(cookie, {
      secret: process.env.REFRESH_SECRET as string,
    });
    return this.svc.refresh(payload.sub, payload.jti, cookie);
  }

  @Post("logout")
  async logout(@Req() req: Request, @Res({ passthrough: true }) res: Response) {
    const cookie = req.cookies?.rt as string | undefined;
    if (cookie) {
      try {
        const payload = await this.jwt.verifyAsync<{ sub: string; jti: string }>(cookie, {
          secret: process.env.REFRESH_SECRET as string,
        });
        await this.svc.logout(payload.sub, payload.jti);
      } catch {}
    }
    res.clearCookie("rt");
    return { ok: true };
  }

  @Get("me")
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  me(@Req() req: Request) {
    const user = (req as any).user as { userId: string; email: string };
    return { userId: user.userId, email: user.email };
  }

  private setRefreshCookie(res: Response, token: string) {
    res.cookie("rt", token, {
      httpOnly: true,
      secure: true,
      sameSite: "none",
      maxAge: 1000 * 60 * 60 * 24 * 7, // 7d
      path: "/",
    });
  }
}
