import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import helmet from "helmet";
import * as cors from "cors";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  // segurança básica + CORS liberado por enquanto (ajustamos depois)
  app.use(helmet());
  app.use(cors());

  // Swagger
  const config = new DocumentBuilder()
    .setTitle("Casamenteiro API")
    .setDescription("API v1 - endpoints públicos da aplicação")
    .setVersion("1.0.0")
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup("docs", app, document);

  const port = process.env.PORT || 8080;
  await app.listen(port as number, "0.0.0.0");
  console.log(`API listening on :${port}`);
}

bootstrap();
