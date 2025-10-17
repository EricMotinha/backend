import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { AppController } from "./app.controller";
import { DbModule } from "./db/db.module";
import { DbController } from "./db/db.controller";

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), DbModule],
  controllers: [AppController, DbController],
})
export class AppModule {}
