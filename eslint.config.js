/* eslint.config.js - ESLint v9 flat config */
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    ignores: [
      "dist/**",
      "node_modules/**"
    ],
  },
  {
    files: ["**/*.ts"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
    },
    rules: {
      "no-unused-vars": "off", // TS já cobre
      "@typescript-eslint/no-unused-vars": ["warn", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }],
      "no-console": "off"
    }
  }
);
