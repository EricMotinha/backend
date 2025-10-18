import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { cors: true });

  // prefixo global opcional (ex.: /api)
  // app.setGlobalPrefix('api');

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
  // log simples pra inspeção remota
  console.log(`API up on 0.0.0.0:${port} — Swagger at /docs`);
}
bootstrap();
