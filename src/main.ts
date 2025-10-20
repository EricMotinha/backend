import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from 'nestjs-pino';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const port = process.env.PORT ? Number(process.env.PORT) : 8080;
  await app.listen(port, '0.0.0.0');  // <— importante!
}
bootstrap();

  // Logger Pino integrado
  app.useLogger(app.get(Logger));

  // Segurança básica
  app.use(helmet());

  // CORS (ajuste origins conforme seu mobile/web)
  app.enableCors({
    origin: [
      'http://localhost:3000',
      'http://localhost:5173',
      'http://localhost:19006',
      // adicione seu domínio de staging/produção aqui
    ],
    credentials: true,
  });

  // Opcional: prefixo global
  // app.setGlobalPrefix('api');

  const port = parseInt(process.env.PORT ?? '8080', 10);
  await app.listen(port, '0.0.0.0');

  const url = await app.getUrl();
  const logger = app.get(Logger);
  logger.log(`API up on ${url.replace('0.0.0.0', 'localhost')} — Swagger at /docs`);
  logger.log(`Health check: ${url}/healthz`);
}

bootstrap();
