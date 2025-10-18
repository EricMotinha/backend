import { z } from "zod";
import { createZodDto } from "nestjs-zod";

export const UpsertPreferencesSchema = z.object({
  min_age: z.number().int().min(18).max(120).optional(),
  max_age: z.number().int().min(18).max(120).optional(),
  max_distance_km: z.number().int().min(1).max(1000).optional(),
  genders: z.array(z.string()).optional(),
  interests: z.array(z.string()).optional(),
});
export class UpsertPreferencesDto extends createZodDto(UpsertPreferencesSchema) {}
