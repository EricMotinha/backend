import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { Logger } from 'nestjs-pino';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,   // permite logger antes do app estar pronto
  });
  app.useLogger(app.get(Logger)); // pino como logger do Nest

  // Segurança básica
  app.use(helmet());

  // CORS (ajusta origins depois)
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    allowedHeaders: 'Content-Type,Authorization,x-user-id',
    exposedHeaders: 'x-next-cursor',
    credentials: false,
    maxAge: 600,
  });

  // Swagger em /docs
  const config = new DocumentBuilder()
    .setTitle('Casamenteiro API v1')
    .setDescription('Endpoints da API v1 do Casamenteiro')
    .setVersion('1.0.0')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = Number(process.env.PORT) || 8080;
  await app.listen(port, '0.0.0.0');

  const url = await app.getUrl();
  const logger = app.get(Logger);
  logger.log(`API up on ${url} — Swagger at /docs`);
}
bootstrap();
