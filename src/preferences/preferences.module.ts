import { Module } from "@nestjs/common";
import { DbModule } from "../db.module";
import { PreferencesController } from "./preferences.controller";
import { PreferencesService } from "./preferences.service";
import { PreferencesRepository } from "./preferences.repository";

@Module({
  imports: [DbModule],
  controllers: [PreferencesController],
  providers: [PreferencesService, PreferencesRepository],
  exports: [PreferencesService],
})
export class PreferencesModule {}
