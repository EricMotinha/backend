// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { Logger } from 'nestjs-pino';

async function bootstrap() {
  // bufferLogs para capturar logs de bootstrap no Pino
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  // Logger Pino do nestjs-pino
  app.useLogger(app.get(Logger));

  // Segurança
  app.use(helmet());

  // CORS (Fly/SPA amigável)
  app.enableCors({
    origin: '*',
    methods: 'GET,POST,PUT,DELETE,OPTIONS',
    allowedHeaders: '*',
    exposedHeaders: ['x-next-cursor'],
    credentials: false,
  });

  // Métrica mínima por rota (em memória)
  const counts = new Map<string, number>();
  app.use((req, _res, next) => {
    // req.path = '/chat/3' etc.
    const key = `${req.method} ${req.path}`;
    counts.set(key, (counts.get(key) ?? 0) + 1);
    next();
  });

  // Endpoint /metrics simples (JSON) — Express adapter
  const http = app.getHttpAdapter();
  http.getInstance().get('/metrics', (_req, res) => {
    res.json(Object.fromEntries(counts.entries()));
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
  console.log(`API up on 0.0.0.0:${port} — Swagger at /docs`);
}
bootstrap();
