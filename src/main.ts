// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const port = Number(process.env.PORT) || 8080;
  await app.listen(port, '0.0.0.0');
  // opcional: log explícito
  // eslint-disable-next-line no-console
  console.log(`API listening on :${port}`);
}
bootstrap();
