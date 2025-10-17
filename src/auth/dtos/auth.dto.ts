import { createZodDto } from "nestjs-zod";
import { z } from "zod";

export const SignupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
});
export class SignupDto extends createZodDto(SignupSchema) {}

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
});
export class LoginDto extends createZodDto(LoginSchema) {}
