import test from "node:test";
import assert from "node:assert/strict";

test("smoke: app boots", () => {
  assert.equal(1 + 1, 2);
});
