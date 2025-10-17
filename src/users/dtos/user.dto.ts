import { createZodDto } from "nestjs-zod";
import { z } from "zod";

export const CreateUserSchema = z.object({
  email: z.string().email(),
});

export class CreateUserDto extends createZodDto(CreateUserSchema) {}

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  created_at: z.string(),
  updated_at: z.string(),
});
