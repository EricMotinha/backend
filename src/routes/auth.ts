import { Router } from "express";
const router = Router();

router.post("/register", (req, res) => {
  const { email, password } = req.body ?? {};
  if (!email || !password) return res.status(400).json({ error: "missing fields" });
  // TODO: validar, salvar no banco etc.
  return res.status(201).json({ ok: true });
});

export default router;
