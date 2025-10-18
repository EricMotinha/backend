import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { AppController } from "./app.controller";
import { DbModule } from "./db.module";
import { UsersModule } from "./users/users.module";
import { AuthModule } from "./auth/auth.module";
import { ProfilesModule } from "./profiles/profiles.module";
import { PreferencesModule } from "./preferences/preferences.module";
import { DiscoveryModule } from "./discovery/discovery.module";
import { SwipesModule } from "./swipes/swipes.module";
import { MatchesModule } from "./matches/matches.module";
import { ChatModule } from "./chat/chat.module";
import { LocationsModule } from "./locations/locations.module";
import { NotificationsModule } from './notifications/notifications.module';
import { ConversationsModule } from './conversations/conversations.module';


@Module({
  imports: [
  DbModule,
  NotificationsModule,
  ConversationsModule, // <-- aqui
  ChatModule,
  UsersModule,
  ProfilesModule,
  PreferencesModule,
  LocationsModule,
  DiscoveryModule,
  SwipesModule,
  MatchesModule,
  AuthModule,
],
  controllers: [AppController],
})
export class AppModule {}



