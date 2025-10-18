import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { AppController } from "./app.controller";
import { DbModule } from "./db.module";
import { UsersModule } from "./users/users.module";
import { AuthModule } from "./auth/auth.module";
import { ProfilesModule } from "./profiles/profiles.module";`nimport { PreferencesModule } from "./preferences/preferences.module";`nimport { LocationsModule } from "./locations/locations.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DbModule,
    UsersModule,
    AuthModule,
    ProfilesModule, PreferencesModule, LocationsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
