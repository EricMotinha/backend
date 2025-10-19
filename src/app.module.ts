// src/app.module.ts
import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';

import { DbModule } from './db.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ProfilesModule } from './profiles/profiles.module';
import { PreferencesModule } from './preferences/preferences.module';
import { DiscoveryModule } from './discovery/discovery.module';
import { SwipesModule } from './swipes/swipes.module';
import { MatchesModule } from './matches/matches.module';
import { LocationsModule } from './locations/locations.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ChatModule } from './chat/chat.module';

@Module({
  imports: [
    DbModule,

    // Rate limit (60s janela / 120 req)
    ThrottlerModule.forRoot([{ ttl: 60, limit: 120 }]),

    // Logs estruturados (Pino)
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL ?? 'info',
        transport:
          process.env.NODE_ENV === 'production'
            ? undefined
            : { target: 'pino-pretty', options: { singleLine: true } },
      },
    }),

    // Seus módulos de domínio
    AuthModule,
    UsersModule,
    ProfilesModule,
    PreferencesModule,
    DiscoveryModule,
    SwipesModule,
    MatchesModule,
    LocationsModule,
    NotificationsModule,
    ChatModule,
  ],
})
export class AppModule {}
