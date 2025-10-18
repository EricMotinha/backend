import { Module } from "@nestjs/common";
import { MatchesController } from "./matches.controller";
import { MatchesService } from "./matches.service";
import { DbModule } from "../db.module";

@Module({
  imports: [DbModule],
  controllers: [MatchesController],
  providers: [MatchesService],
})
export class MatchesModule {}
