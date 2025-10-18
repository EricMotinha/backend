import { z } from "zod";
import { createZodDto } from "nestjs-zod";

export const UpsertProfileSchema = z.object({
  display_name: z.string().min(1).max(80).optional(),
  bio: z.string().max(500).optional(),
});
export class UpsertProfileDto extends createZodDto(UpsertProfileSchema) {}
