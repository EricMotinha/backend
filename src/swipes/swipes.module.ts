import { Module } from "@nestjs/common";
import { SwipesController } from "./swipes.controller";
import { SwipesService } from "./swipes.service";
import { DbModule } from "../db.module";

@Module({
  imports: [DbModule],
  controllers: [SwipesController],
  providers: [SwipesService],
})
export class SwipesModule {}
