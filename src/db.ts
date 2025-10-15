import { Pool } from "pg";
import dotenv from "dotenv";
dotenv.config();

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

export async function pingDB() {
  const { rows } = await pool.query("select now() as now");
  return rows[0]?.now as string;
}

export { pool };
