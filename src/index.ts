import express from "express";
import dotenv from "dotenv";
import pino from "pino";
import pinoHttp from "pino-http";

dotenv.config();

const app = express();
const logger = pino({ transport: { target: "pino-pretty" } });

app.use(pinoHttp({ logger }));
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true, ts: new Date().toISOString() });
});

const PORT = Number(process.env.PORT ?? 3000);
const HOST = process.env.HOST ?? "0.0.0.0"; // <- aqui

app.listen(PORT, HOST, () => {
  console.log(`API ouvindo em http://${HOST}:${PORT}`);
});
