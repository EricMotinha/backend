import { Module } from "@nestjs/common";
import { DbModule } from "../db.module";
import { LocationsController } from "./locations.controller";

@Module({
  imports: [DbModule],
  controllers: [LocationsController],
})
export class LocationsModule {}
