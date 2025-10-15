import express from "express";
import dotenv from "dotenv";
import pino from "pino";
import pinoHttp from "pino-http";
import cors from "cors";
import helmet from "helmet";
import { Pool } from "pg";
import swaggerUi from "swagger-ui-express";
import fs from "node:fs";
import yaml from "yaml";

dotenv.config();

const logger = pino({ transport: { target: "pino-pretty" } });
const app = express();

app.use(pinoHttp({ logger }));
app.use(helmet());
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Health
app.get("/health", (_req, res) => res.json({ ok: true, ts: new Date().toISOString() }));
app.get("/health/db", async (req, res) => {
  try {
    const r = await pool.query("select 1 as ok");
    res.json({ ok: true, db: r.rows[0].ok === 1 });
  } catch (e) {
    req.log.error(e);
    res.status(500).json({ ok: false, error: (e as Error).message });
  }
});

// Swagger
const raw = fs.readFileSync("openapi.yaml", "utf8");
const spec = yaml.parse(raw);
app.use("/docs", swaggerUi.serve, swaggerUi.setup(spec));

// Stub auth
app.post("/auth/register", (_req, res) => res.status(201).json({ ok: true }));

// 404 & erro
app.use((_req, res) => res.status(404).json({ error: "Not found" }));
app.use((err: any, _req: any, res: any, _next: any) => {
  logger.error(err);
  res.status(500).json({ error: "Internal error" });
});

const PORT = Number(process.env.PORT ?? 3000);
const HOST = process.env.HOST ?? "0.0.0.0";
app.listen(PORT, HOST, () => {
  console.log(`API ouvindo em http://${HOST}:${PORT}`);
});
