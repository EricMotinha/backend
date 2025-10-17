// src/app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { DiscoveryModule } from './discovery/discovery.module';
import { SwipesModule } from './swipes/swipes.module';
import { MatchesModule } from './matches/matches.module';
import { ConversationsModule } from './conversations/conversations.module';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), AuthModule, UsersModule, DiscoveryModule, SwipesModule, MatchesModule, ConversationsModule],
  controllers: [AppController],
})
export class AppModule {}
