import { Injectable, UnauthorizedException } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import * as argon2 from "argon2";
import { randomUUID } from "crypto";
import { AuthRepository } from "./auth.repository";

const ACCESS_TTL = "15m";
const REFRESH_TTL_SECONDS = 60 * 60 * 24 * 7; // 7d

@Injectable()
export class AuthService {
  constructor(
    private readonly jwt: JwtService,
    private readonly repo: AuthRepository
  ) {}

  async signup(email: string, password: string) {
    const existing = await this.repo.findUserByEmail(email);
    if (existing) throw new UnauthorizedException("email already registered");

    const user = await this.repo.createUser(email);
    const hash = await argon2.hash(password);
    await this.repo.upsertCredential(user.id, hash);

    const { accessToken, refreshToken, refreshId, refreshExp } = await this.issueTokens(user.id, user.email);
    const refreshHash = await argon2.hash(refreshToken);
    await this.repo.createRefresh(user.id, refreshId, refreshHash, new Date(refreshExp * 1000));

    return { user, accessToken, refreshToken, refreshId };
  }

  async login(email: string, password: string) {
    const user = await this.repo.findUserByEmail(email);
    if (!user) throw new UnauthorizedException("invalid credentials");

    const pwdHash = await this.repo.getPasswordHash(user.id);
    if (!pwdHash) throw new UnauthorizedException("invalid credentials");

    const ok = await argon2.verify(pwdHash, password);
    if (!ok) throw new UnauthorizedException("invalid credentials");

    const { accessToken, refreshToken, refreshId, refreshExp } = await this.issueTokens(user.id, user.email);
    const refreshHash = await argon2.hash(refreshToken);
    await this.repo.createRefresh(user.id, refreshId, refreshHash, new Date(refreshExp * 1000));

    return { user, accessToken, refreshToken, refreshId };
  }

  async refresh(userId: string, jti: string, refreshToken: string) {
    const row = await this.repo.getRefresh(userId, jti);
    if (!row) throw new UnauthorizedException("refresh not found");
    const ok = await argon2.verify(row.token_hash, refreshToken);
    if (!ok) throw new UnauthorizedException("invalid refresh");
    if (new Date(row.expires_at).getTime() < Date.now()) throw new UnauthorizedException("expired refresh");

    const user = { id: userId, email: "" }; // email não é necessário pra emitir
    const { accessToken } = await this.issueAccess(userId, user.email);
    return { accessToken };
  }

  async logout(userId: string, jti: string) {
    await this.repo.deleteRefresh(userId, jti);
  }

  private async issueTokens(userId: string, email: string) {
    const accessToken = await this.issueAccess(userId, email).then(r => r.accessToken);

    const refreshId = randomUUID();
    const refreshPayload = { sub: userId, jti: refreshId };
    const refreshSecret = process.env.REFRESH_SECRET as string;
    const refreshToken = await this.jwt.signAsync(refreshPayload, {
      secret: refreshSecret,
      expiresIn: REFRESH_TTL_SECONDS,
    });

    const refreshExp = Math.floor(Date.now() / 1000) + REFRESH_TTL_SECONDS;
    return { accessToken, refreshToken, refreshId, refreshExp };
  }

  private async issueAccess(userId: string, email: string) {
    const accessPayload = { sub: userId, email };
    const secret = process.env.JWT_SECRET as string;
    const accessToken = await this.jwt.signAsync(accessPayload, {
      secret,
      expiresIn: ACCESS_TTL,
    });
    return { accessToken };
  }
}
