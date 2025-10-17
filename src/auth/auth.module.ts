import { Module } from "@nestjs/common";
import { JwtModule } from "@nestjs/jwt";
import { DbModule } from "../db.module";
import { AuthService } from "./auth.service";
import { AuthController } from "./auth.controller";
import { AuthRepository } from "./auth.repository";
import { JwtStrategy } from "./strategies/jwt.strategy";

@Module({
  imports: [DbModule, JwtModule.register({})],
  controllers: [AuthController],
  providers: [AuthService, AuthRepository, JwtStrategy],
  exports: [JwtModule], // opcional
})
export class AuthModule {}
