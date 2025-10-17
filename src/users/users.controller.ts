import { Body, Controller, Get, Param, Post, Query, ParseUUIDPipe } from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { UsersService } from "./users.service";
import { CreateUserDto } from "./dtos/user.dto";

@ApiTags("users")
@Controller("users")
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get(":id")
  get(@Param("id", new ParseUUIDPipe({ version: "4" })) id: string) {
    return this.service.get(id);
  }

  @Get()
  list(@Query("limit") limit?: string) {
    const l = Number(limit ?? 50);
    return this.service.list(isNaN(l) ? 50 : l);
  }

  @Post()
  create(@Body() dto: CreateUserDto) {
    return this.service.create(dto.email);
  }
}
