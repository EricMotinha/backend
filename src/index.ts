import express from "express";
import dotenv from "dotenv";
import pino from "pino";
import pinoHttp from "pino-http";
import helmet from "helmet";
import cors from "cors";
import { Pool } from "pg";
import swaggerUi from "swagger-ui-express";
import fs from "node:fs";
import path from "node:path";
import yaml from "yaml";

dotenv.config();

const app = express();
const logger = pino({ transport: { target: "pino-pretty" } });

app.use(pinoHttp({ logger }));
app.use(express.json());
app.use(helmet());
app.use(cors());

// ---- Swagger (/docs) ----
const openapiPath = path.join(process.cwd(), "openapi.yaml");
const openapiDoc = yaml.parse(fs.readFileSync(openapiPath, "utf8"));
app.use("/docs", swaggerUi.serve, swaggerUi.setup(openapiDoc));

// ---- DB pool (usa DATABASE_URL) ----
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // ssl: { rejectUnauthorized: false } // <— use isso se for DB com SSL obrigatório
});

// Health simples
app.get("/health", (_req, res) => {
  res.json({ ok: true, ts: new Date().toISOString() });
});

// Health do banco
app.get("/health/db", async (_req, res) => {
  try {
    const r = await pool.query("SELECT 1 as ok");
    res.json({ ok: true, db: r.rows[0].ok === 1 });
  } catch (err: any) {
    req.log?.error({ err }, "db health failed");
    res.status(500).json({ ok: false, error: err.message });
  }
});

const PORT = Number(process.env.PORT ?? 3000);
const HOST = process.env.HOST ?? "0.0.0.0";
app.listen(PORT, HOST, () => {
  console.log(`API ouvindo em http://${HOST}:${PORT}`);
  console.log(`Docs: http://localhost:${PORT}/docs`);
});
