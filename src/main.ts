import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { Logger } from 'nestjs-pino';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { cors: true });

  // Helmet (security headers)
  app.use(helmet());

  // Logger do pino como logger da aplicação
  app.useLogger(app.get(Logger));

  // Swagger
  const config = new DocumentBuilder()
    .setTitle('Casamenteiro API v1')
    .setDescription('Endpoints da API v1 do Casamenteiro')
    .setVersion('1.0.0')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = Number(process.env.PORT) || 8080;
  await app.listen(port, "0.0.0.0");
  console.log(`API up on 0.0.0.0:${port} — Swagger at /docs`);
}
bootstrap();
