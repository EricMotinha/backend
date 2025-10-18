import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { AppController } from "./app.controller";
import { DbModule } from "./db.module";
import { UsersModule } from "./users/users.module";`nimport { ProfilesModule } from "./profiles/profiles.module";
import { AuthModule } from "./auth/auth.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DbModule,
    UsersModule, ProfilesModule,
    AuthModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
